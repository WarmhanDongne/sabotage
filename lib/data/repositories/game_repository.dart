import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card.dart' as game_card;
import '../models/card_database.dart';
import '../models/grid_node.dart';
import '../models/player.dart';
import '../models/lobby_state.dart';
import '../game_state.dart';
import '../../logic/validator.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 방 상태 스트림
  Stream<GameState?> roomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GameState.fromJson(doc.data()!);
    });
  }

  // 대기방(Lobby) 스트림
  Stream<LobbyState?> lobbyStream(String roomId) {
    return _firestore.collection('lobbies').doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LobbyState.fromJson(doc.data()!);
    });
  }

  // 대기방 생성 (호스트)
  Future<void> createLobby(String roomId, String hostId) async {
    final lobby = LobbyState(roomId: roomId, hostId: hostId);
    await _firestore.collection('lobbies').doc(roomId).set(lobby.toJson());
  }

  // 플레이어 입장
  Future<void> joinLobby(String roomId, String uid, String nickname) async {
    final docRef = _firestore.collection('lobbies').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      final lobby = LobbyState.fromJson(snapshot.data()!);
      if (lobby.status != 'waiting') throw Exception("Game already started");
      
      // 이미 들어온 유저인지 체크
      if (!lobby.players.any((p) => p.uid == uid)) {
        final newPlayers = List<LobbyPlayer>.from(lobby.players)..add(LobbyPlayer(uid: uid, nickname: nickname));
        final newLobby = LobbyState(
          roomId: lobby.roomId,
          hostId: lobby.hostId,
          players: newPlayers,
          status: lobby.status,
        );
        transaction.update(docRef, newLobby.toJson());
      }
    });
  }

  // 방 생성 (기본판 덱 세팅 및 초기 상태) -> 대기방에서 게임 시작 시 호출
  Future<void> createRoom(String roomId, String hostId, List<String> playerIds) async {
    final random = Random();

    // 1. 역할 분배
    int saboteurCount = 1;
    if (playerIds.length >= 5) saboteurCount = 2;
    if (playerIds.length >= 7) saboteurCount = 3;

    List<PlayerRole> roles = List.generate(saboteurCount, (_) => PlayerRole.saboteur)
      ..addAll(List.generate(playerIds.length - saboteurCount, (_) => PlayerRole.miner));
    roles.shuffle(random);

    // 2. 덱 생성
    List<game_card.Card> deck = List.from(CardDatabase.allDeckCards);
    deck.shuffle(random);

    // 3. 목적지 카드 3장 생성 (랜덤 배치)
    List<GridNode> goalNodes = [];
    List<bool> isGoldList = [true, false, false];
    isGoldList.shuffle(random);
    
    // 원래 dummy 설정값: 도착 (9, 1), (9, 3), (9, 5)
    // 금은 008_cave_action_03, 돌은 008_cave_action_02, 008_cave_action_04
    String getGoalId(bool isGold, int rockIndex) {
      if (isGold) return '008_cave_action_03';
      return rockIndex == 0 ? '008_cave_action_02' : '008_cave_action_04';
    }
    
    int rockCount = 0;
    for (int i = 0; i < 3; i++) {
      int yPos = (i * 2) + 1; // 1, 3, 5
      bool isGold = isGoldList[i];
      String id = getGoalId(isGold, rockCount);
      if (!isGold) rockCount++;
      goalNodes.add(GridNode(x: 9, y: yPos, card: game_card.Card(id: id, type: game_card.CardType.goal, isGold: isGold), isRevealed: false));
    }

    // 4. 시작 카드: 원래 dummy 설정값 (1, 3)
    final startNode = GridNode(
      x: 1, y: 3, 
      card: CardDatabase.startCard,
    );

    // 5. 플레이어 손패 나누기 (인원수에 따라 다름: 3~5명=6장, 6~7명=5장)
    int handSize = playerIds.length <= 5 ? 6 : 5;
    List<Player> players = [];
    for (int i = 0; i < playerIds.length; i++) {
      List<String> hand = [];
      for (int j = 0; j < handSize; j++) {
        if (deck.isNotEmpty) hand.add(deck.removeLast().id);
      }
      players.add(Player(id: playerIds[i], name: 'Player ${i+1}', role: roles[i], handCardIds: hand));
    }

    final initialState = GameState(
      roomId: roomId,
      players: players,
      currentTurnPlayerId: playerIds.first,
      board: [startNode],
      deck: deck,
      discardPile: [],
      goalCards: goalNodes,
    );

    await _firestore.collection('rooms').doc(roomId).set(initialState.toJson());
  }

  // 로비에서 게임 시작하기
  Future<void> startGameFromLobby(String roomId) async {
    final lobbyRef = _firestore.collection('lobbies').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(lobbyRef);
      if (!snapshot.exists) throw Exception("Lobby not found");
      final lobby = LobbyState.fromJson(snapshot.data()!);
      if (lobby.players.isEmpty) throw Exception("Need at least 1 player"); 
      
      // 방 생성 로직 호출
      await createRoom(roomId, lobby.hostId, lobby.players.map((p) => p.uid).toList());
      
      // 상태 업데이트
      final newLobby = LobbyState(
        roomId: lobby.roomId,
        hostId: lobby.hostId,
        players: lobby.players,
        status: 'playing',
      );
      transaction.update(lobbyRef, newLobby.toJson());
    });
  }

  // 거래 트랜잭션: 굴 카드 놓기
  Future<void> playPathCard(String roomId, String playerId, String cardId, int targetX, int targetY, {bool isRotated = false}) async {
    final docRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      
      final state = GameState.fromJson(snapshot.data()!);
      if (state.isGameOver) throw Exception("Game is already over");
      if (state.currentTurnPlayerId != playerId) throw Exception("Not your turn");

      final playerIndex = state.players.indexWhere((p) => p.id == playerId);
      final player = state.players[playerIndex];

      if (player.isPickaxeBroken || player.isLanternBroken || player.isCartBroken) {
        throw Exception("Cannot play path card while equipment is broken");
      }

      if (!player.handCardIds.contains(cardId)) throw Exception("Card not in hand");

      // 패에서 카드 정보 가져오기 (CardDatabase 이용)
      final baseCard = CardDatabase.getCardById(cardId);
      if (baseCard == null) throw Exception("Card not found in database");
      
      // 회전 상태 적용
      final card = baseCard.copyWith(isRotated: isRotated);

      if (!Validator.canPlaceCard(state.board, card, targetX, targetY)) {
        throw Exception("Invalid card placement");
      }

      List<GridNode> newBoard = List.from(state.board)..add(GridNode(x: targetX, y: targetY, card: card));
      
      // End-game Trigger 검사 (Gold 도착)
      bool isMinerWin = false;
      List<GridNode> newGoalCards = List.from(state.goalCards);
      
      // 보드의 어떤 변경이든 목적지 도달을 트리거할 수 있으므로, 목적지 주변 카드를 모두 검사
      for (int i = 0; i < newGoalCards.length; i++) {
        final goal = newGoalCards[i];
        if (!goal.isRevealed) {
          bool isConnected = false;

          // 위쪽 검사
          final topNodeIdx = newBoard.indexWhere((n) => n.x == goal.x && n.y == goal.y - 1);
          if (topNodeIdx != -1 && newBoard[topNodeIdx].card.currentBottom) {
             if (Validator.isConnectedToStart(newBoard, goal.x, goal.y - 1, requireTunnelPath: true)) isConnected = true;
          }
          // 아래쪽 검사
          final bottomNodeIdx = newBoard.indexWhere((n) => n.x == goal.x && n.y == goal.y + 1);
          if (!isConnected && bottomNodeIdx != -1 && newBoard[bottomNodeIdx].card.currentTop) {
             if (Validator.isConnectedToStart(newBoard, goal.x, goal.y + 1, requireTunnelPath: true)) isConnected = true;
          }
          // 왼쪽 검사
          final leftNodeIdx = newBoard.indexWhere((n) => n.x == goal.x - 1 && n.y == goal.y);
          if (!isConnected && leftNodeIdx != -1 && newBoard[leftNodeIdx].card.currentRight) {
             if (Validator.isConnectedToStart(newBoard, goal.x - 1, goal.y, requireTunnelPath: true)) isConnected = true;
          }
          // 오른쪽 검사
          final rightNodeIdx = newBoard.indexWhere((n) => n.x == goal.x + 1 && n.y == goal.y);
          if (!isConnected && rightNodeIdx != -1 && newBoard[rightNodeIdx].card.currentLeft) {
             if (Validator.isConnectedToStart(newBoard, goal.x + 1, goal.y, requireTunnelPath: true)) isConnected = true;
          }

          if (isConnected) {
            newGoalCards[i] = goal.copyWith(isRevealed: true);
            if (goal.card.isGold) {
              isMinerWin = true;
            }
          }
        }
      }

      // 상태 업데이트 (손패 -1, 덱 -1)
      _advanceTurn(state, playerIndex, cardId, newBoard, newGoalCards, isMinerWin ? 'miner' : null, transaction, docRef);
    });
  }

  // 거래 트랜잭션: 행동 카드 사용
  Future<void> playActionCard(String roomId, String playerId, String cardId, {String? targetPlayerId, int? targetX, int? targetY}) async {
    final docRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      
      final state = GameState.fromJson(snapshot.data()!);
      if (state.isGameOver) throw Exception("Game is already over");
      if (state.currentTurnPlayerId != playerId) throw Exception("Not your turn");

      final playerIndex = state.players.indexWhere((p) => p.id == playerId);
      if (!state.players[playerIndex].handCardIds.contains(cardId)) throw Exception("Card not in hand");

      final card = CardDatabase.getCardById(cardId);
      if (card == null || card.type != game_card.CardType.action) throw Exception("Invalid action card");

      List<Player> newPlayers = List.from(state.players);
      List<GridNode> newBoard = List.from(state.board);

      switch (card.actionType) {
        case game_card.ActionType.breakPickaxe:
        case game_card.ActionType.breakLantern:
        case game_card.ActionType.breakCart:
          if (targetPlayerId == null) throw Exception('Target player required');
          final targetIdx = newPlayers.indexWhere((p) => p.id == targetPlayerId);
          final tp = newPlayers[targetIdx];
          if (card.actionType == game_card.ActionType.breakPickaxe) newPlayers[targetIdx] = tp.copyWith(isPickaxeBroken: true);
          if (card.actionType == game_card.ActionType.breakLantern) newPlayers[targetIdx] = tp.copyWith(isLanternBroken: true);
          if (card.actionType == game_card.ActionType.breakCart) newPlayers[targetIdx] = tp.copyWith(isCartBroken: true);
          break;
          
        case game_card.ActionType.fixPickaxe:
        case game_card.ActionType.fixLantern:
        case game_card.ActionType.fixCart:
        case game_card.ActionType.fixCartOrLantern:
        case game_card.ActionType.fixCartOrPickaxe:
        case game_card.ActionType.fixLanternOrPickaxe:
          if (targetPlayerId == null) throw Exception('Target player required');
          final targetIdx = newPlayers.indexWhere((p) => p.id == targetPlayerId);
          final tp = newPlayers[targetIdx];
          
          bool fixed = false;
          if ((card.actionType == game_card.ActionType.fixPickaxe || card.actionType == game_card.ActionType.fixCartOrPickaxe || card.actionType == game_card.ActionType.fixLanternOrPickaxe) && tp.isPickaxeBroken && !fixed) {
            newPlayers[targetIdx] = tp.copyWith(isPickaxeBroken: false);
            fixed = true;
          }
          if ((card.actionType == game_card.ActionType.fixLantern || card.actionType == game_card.ActionType.fixCartOrLantern || card.actionType == game_card.ActionType.fixLanternOrPickaxe) && tp.isLanternBroken && !fixed) {
            newPlayers[targetIdx] = tp.copyWith(isLanternBroken: false);
            fixed = true;
          }
          if ((card.actionType == game_card.ActionType.fixCart || card.actionType == game_card.ActionType.fixCartOrLantern || card.actionType == game_card.ActionType.fixCartOrPickaxe) && tp.isCartBroken && !fixed) {
            newPlayers[targetIdx] = tp.copyWith(isCartBroken: false);
            fixed = true;
          }
          if (!fixed) {
            // 아무것도 고치지 않았더라도 (어차피 고장난 게 없는데 사용한 경우), 카드는 소모됨
          }
          break;

        case game_card.ActionType.rockfall:
          if (targetX == null || targetY == null) throw Exception('Target coordinates required for rockfall');
          final nodeIdx = newBoard.indexWhere((n) => n.x == targetX && n.y == targetY && n.card.type == game_card.CardType.path);
          if (nodeIdx == -1) throw Exception('Invalid rockfall target');
          newBoard.removeAt(nodeIdx);
          break;

        case game_card.ActionType.map:
          if (targetX == null || targetY == null) throw Exception('Target coordinates required for map');
          final goalIdx = state.goalCards.indexWhere((g) => g.x == targetX && g.y == targetY);
          if (goalIdx == -1) throw Exception('Invalid map target');
          break;

        default:
          break;
      }

      final Map<String, dynamic>? newMapResult = card.actionType == game_card.ActionType.map 
        ? {
            'playerId': playerId,
            'isGold': state.goalCards.firstWhere((g) => g.x == targetX && g.y == targetY).card.isGold,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        : null;

      // 상태 업데이트 (players 객체를 변경했으므로 state 객체 교체)
      final tempState = GameState(
        roomId: state.roomId, players: newPlayers, currentTurnPlayerId: state.currentTurnPlayerId,
        board: newBoard, deck: state.deck, discardPile: state.discardPile, goalCards: state.goalCards,
        currentRound: state.currentRound, isGameOver: state.isGameOver, goldDistribution: state.goldDistribution,
        lastMapResult: newMapResult,
      );

      _advanceTurn(tempState, playerIndex, cardId, newBoard, state.goalCards, null, transaction, docRef);
    });
  }

  // 거래 트랜잭션: 카드 버리기
  Future<void> discardCard(String roomId, String playerId, String cardId) async {
    final docRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      
      final state = GameState.fromJson(snapshot.data()!);
      if (state.isGameOver) throw Exception("Game is already over");
      if (state.currentTurnPlayerId != playerId) throw Exception("Not your turn");

      final playerIndex = state.players.indexWhere((p) => p.id == playerId);
      if (!state.players[playerIndex].handCardIds.contains(cardId)) throw Exception("Card not in hand");

      _advanceTurn(state, playerIndex, cardId, state.board, state.goalCards, null, transaction, docRef);
    });
  }

  // ──── 크로스 디바이스 상호작용 (Pending Action) ────

  // 모바일 기기에서 "사용 준비" 누를 때 호출
  Future<void> setPendingAction(String roomId, String playerId, String cardId, {bool isRotated = false}) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      
      final state = GameState.fromJson(snapshot.data()!);
      if (state.isGameOver) throw Exception("Game is already over");
      if (state.currentTurnPlayerId != playerId) throw Exception("Not your turn");
      
      final playerIndex = state.players.indexWhere((p) => p.id == playerId);
      if (!state.players[playerIndex].handCardIds.contains(cardId)) throw Exception("Card not in hand");

      final newState = GameState(
        roomId: state.roomId, players: state.players, currentTurnPlayerId: state.currentTurnPlayerId,
        board: state.board, deck: state.deck, discardPile: state.discardPile, goalCards: state.goalCards,
        currentRound: state.currentRound, isGameOver: state.isGameOver, goldDistribution: state.goldDistribution,
        winner: state.winner,
        pendingAction: {
          'playerId': playerId,
          'cardId': cardId,
          'isRotated': isRotated,
          // 액션 타입 파싱 개선
          'type': cardId.startsWith('path') || cardId.startsWith('004_path') || cardId.startsWith('005_path') || cardId.startsWith('006_path') || cardId.startsWith('007_path') ? 'path' : (cardId.startsWith('act_') || cardId.startsWith('001_action') || cardId.startsWith('009_cave_sword') ? 'action' : 'unknown')
        }
      );
      transaction.update(docRef, newState.toJson());
    });
  }

  // "사용 취소" 누를 때 호출
  Future<void> clearPendingAction(String roomId, String playerId) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Room does not exist!");
      
      final state = GameState.fromJson(snapshot.data()!);
      if (state.pendingAction?['playerId'] != playerId) return; // 본인의 액션만 취소 가능

      final newState = GameState(
        roomId: state.roomId, players: state.players, currentTurnPlayerId: state.currentTurnPlayerId,
        board: state.board, deck: state.deck, discardPile: state.discardPile, goalCards: state.goalCards,
        currentRound: state.currentRound, isGameOver: state.isGameOver, goldDistribution: state.goldDistribution,
        winner: state.winner,
        pendingAction: null,
        lastMapResult: state.lastMapResult,
      );
      transaction.update(docRef, newState.toJson());
    });
  }

  // 지도 확인 완료 누를 때 호출
  Future<void> clearMapResult(String roomId) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    await docRef.update({'lastMapResult': null});
  }

  // 내부 헬퍼: 턴 종료
  void _advanceTurn(GameState state, int playerIndex, String usedCardId, List<GridNode> newBoard, List<GridNode> newGoalCards, String? winner, Transaction transaction, DocumentReference docRef) {
    final player = state.players[playerIndex];
    List<String> newHand = List.from(player.handCardIds)..remove(usedCardId);
    List<game_card.Card> newDeck = List.from(state.deck);
    
    if (newDeck.isNotEmpty) {
      newHand.add(newDeck.removeLast().id);
    }

    List<Player> newPlayers = List.from(state.players);
    newPlayers[playerIndex] = player.copyWith(handCardIds: newHand);

    String nextTurnPlayerId = state.players[(playerIndex + 1) % state.players.length].id;

    // Saboteur Win Check: 덱이 비고 모든 플레이어 패가 0장
    bool isSaboteurWin = newDeck.isEmpty && newPlayers.every((p) => p.handCardIds.isEmpty);
    
    bool isGameOver = winner != null || isSaboteurWin;
    String? finalWinner = winner ?? (isSaboteurWin ? 'saboteur' : null);

    final newState = GameState(
      roomId: state.roomId,
      players: newPlayers,
      currentTurnPlayerId: nextTurnPlayerId,
      board: newBoard,
      deck: newDeck,
      discardPile: List.from(state.discardPile)..add(game_card.Card(id: usedCardId, type: game_card.CardType.path)),
      goalCards: newGoalCards,
      currentRound: state.currentRound,
      isGameOver: isGameOver,
      winner: finalWinner,
      goldDistribution: state.goldDistribution,
      lastMapResult: state.lastMapResult,
      pendingAction: null,
    );

    transaction.update(docRef, newState.toJson());
  }
}
