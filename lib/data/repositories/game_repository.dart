import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card.dart' as game_card;
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
    List<game_card.Card> deck = _generateBasicDeck();
    deck.shuffle(random);

    // 3. 목적지 카드 3장 생성 (랜덤 배치)
    List<GridNode> goalNodes = [];
    List<bool> isGoldList = [true, false, false];
    isGoldList.shuffle(random);
    
    // 원래 dummy 설정값: 도착 (9, 1), (9, 3), (9, 5)
    goalNodes.add(GridNode(x: 9, y: 1, card: game_card.Card(id: 'goal_1', type: game_card.CardType.goal, isGold: isGoldList[0]), isRevealed: false));
    goalNodes.add(GridNode(x: 9, y: 3, card: game_card.Card(id: 'goal_2', type: game_card.CardType.goal, isGold: isGoldList[1]), isRevealed: false));
    goalNodes.add(GridNode(x: 9, y: 5, card: game_card.Card(id: 'goal_3', type: game_card.CardType.goal, isGold: isGoldList[2]), isRevealed: false));

    // 4. 시작 카드: 원래 dummy 설정값 (1, 3)
    final startNode = GridNode(
      x: 1, y: 3, 
      card: const game_card.Card(id: 'start_card', type: game_card.CardType.start, hasTop: true, hasBottom: true, hasLeft: true, hasRight: true, hasCenter: true),
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
  Future<void> playPathCard(String roomId, String playerId, String cardId, int targetX, int targetY) async {
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

      // 패에서 카드 찾기 (원래는 id만 알면 전체 카드 정보를 알아야 함. 여기서는 간략히 생성)
      // 실제로는 deck에 있던 원본 정보가 필요하지만, 
      // MVP에서는 ID를 파싱해서 임시 생성하거나 별도의 카드 사전(Dictionary)을 써야 합니다.
      // 편의상 id가 'path_...' 형식이면 기본 연결 형태 부여.
      final card = game_card.Card(
        id: cardId, type: game_card.CardType.path, 
        hasTop: true, hasBottom: true, hasLeft: true, hasRight: true, hasCenter: true
      ); // 임시

      if (!Validator.canPlaceCard(state.board, card, targetX, targetY)) {
        throw Exception("Invalid card placement");
      }

      List<GridNode> newBoard = List.from(state.board)..add(GridNode(x: targetX, y: targetY, card: card));
      
      // End-game Trigger 검사 (Gold 도착)
      bool isMinerWin = false;
      List<GridNode> newGoalCards = List.from(state.goalCards);
      
      // 방금 놓은 카드가 목적지와 닿아있는지 검사
      for (int i = 0; i < newGoalCards.length; i++) {
        final goal = newGoalCards[i];
        if (!goal.isRevealed) {
          bool adjacent = (targetX == goal.x && (targetY == goal.y - 1 || targetY == goal.y + 1)) ||
                          (targetY == goal.y && (targetX == goal.x - 1 || targetX == goal.x + 1));
          if (adjacent && Validator.isConnectedToStart(newBoard, targetX, targetY)) {
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

      game_card.ActionType actionType = game_card.ActionType.none;
      if (cardId.startsWith('act_break_pick')) actionType = game_card.ActionType.breakPickaxe;
      else if (cardId.startsWith('act_break_lan')) actionType = game_card.ActionType.breakLantern;
      else if (cardId.startsWith('act_break_cart')) actionType = game_card.ActionType.breakCart;
      else if (cardId.startsWith('act_fix_pick')) actionType = game_card.ActionType.fixPickaxe;
      else if (cardId.startsWith('act_fix_lan')) actionType = game_card.ActionType.fixLantern;
      else if (cardId.startsWith('act_fix_cart')) actionType = game_card.ActionType.fixCart;
      else if (cardId.startsWith('act_map')) actionType = game_card.ActionType.map;
      else if (cardId.startsWith('act_rock')) actionType = game_card.ActionType.rockfall;

      final card = game_card.Card(id: cardId, type: game_card.CardType.action, actionType: actionType);

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
          if (targetPlayerId == null) throw Exception('Target player required');
          final targetIdx = newPlayers.indexWhere((p) => p.id == targetPlayerId);
          final tp = newPlayers[targetIdx];
          if (card.actionType == game_card.ActionType.fixPickaxe) newPlayers[targetIdx] = tp.copyWith(isPickaxeBroken: false);
          if (card.actionType == game_card.ActionType.fixLantern) newPlayers[targetIdx] = tp.copyWith(isLanternBroken: false);
          if (card.actionType == game_card.ActionType.fixCart) newPlayers[targetIdx] = tp.copyWith(isCartBroken: false);
          break;

        case game_card.ActionType.rockfall:
          if (targetX == null || targetY == null) throw Exception('Target coordinates required for rockfall');
          final nodeIdx = newBoard.indexWhere((n) => n.x == targetX && n.y == targetY && n.card.type == game_card.CardType.path);
          if (nodeIdx == -1) throw Exception('Invalid rockfall target');
          newBoard.removeAt(nodeIdx);
          break;

        default:
          break;
      }

      // 상태 업데이트 (players 객체를 변경했으므로 state 객체 교체)
      final tempState = GameState(
        roomId: state.roomId, players: newPlayers, currentTurnPlayerId: state.currentTurnPlayerId,
        board: newBoard, deck: state.deck, discardPile: state.discardPile, goalCards: state.goalCards,
        currentRound: state.currentRound, isGameOver: state.isGameOver, goldDistribution: state.goldDistribution
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
  Future<void> setPendingAction(String roomId, String playerId, String cardId) async {
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
          // 액션 타입 파싱 개선
          'type': cardId.startsWith('path') ? 'path' : (cardId.startsWith('act_') ? 'action' : 'unknown')
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
      );
      transaction.update(docRef, newState.toJson());
    });
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
      pendingAction: null,
    );

    transaction.update(docRef, newState.toJson());
  }

  List<game_card.Card> _generateBasicDeck() {
    List<game_card.Card> deck = [];
    int idCounter = 0;

    void addPath(int count, bool top, bool bottom, bool left, bool right, bool center) {
      String shapeStr = '${top?1:0}${right?1:0}${bottom?1:0}${left?1:0}${center?1:0}';
      for (int i = 0; i < count; i++) {
        deck.add(game_card.Card(
          id: 'path_${shapeStr}_${idCounter++}', 
          type: game_card.CardType.path, 
          hasTop: top, hasBottom: bottom, hasLeft: left, hasRight: right, hasCenter: center
        ));
      }
    }

    // 1. Path Cards (총 40장 - 오리지널 구성 대략적 비율)
    // 십자 길 (Cross) - 5장
    addPath(5, true, true, true, true, true);
    // T자 길 (T-Shape) - 위,왼,오 (5장) / 아래,왼,오 (5장) / 위,아래,왼 (5장) / 위,아래,오 (5장) => 20장
    addPath(5, true, false, true, true, true);
    addPath(5, false, true, true, true, true);
    addPath(5, true, true, true, false, true);
    addPath(5, true, true, false, true, true);
    // 직선 (Straight) - 위,아래 (7장) / 왼,오 (3장) => 10장
    addPath(7, true, true, false, false, true);
    addPath(3, false, false, true, true, true);
    // ㄱ자 꺾임 (Corner) - 5장 (임의 방향 배분)
    addPath(2, true, false, true, false, true);
    addPath(2, false, true, false, true, true);
    addPath(1, true, false, false, true, true);
    // 막힌 길 (Dead ends) - 임의 배분
    addPath(5, true, true, true, true, false);

    void addAction(int count, game_card.ActionType type, String prefix) {
      for (int i = 0; i < count; i++) {
        deck.add(game_card.Card(
          id: '${prefix}_${idCounter++}', 
          type: game_card.CardType.action, 
          actionType: type
        ));
      }
    }

    // 2. Action Cards (총 27장)
    addAction(3, game_card.ActionType.breakPickaxe, 'act_break_pick');
    addAction(3, game_card.ActionType.breakLantern, 'act_break_lan');
    addAction(3, game_card.ActionType.breakCart, 'act_break_cart');
    
    addAction(2, game_card.ActionType.fixPickaxe, 'act_fix_pick');
    addAction(2, game_card.ActionType.fixLantern, 'act_fix_lan');
    addAction(2, game_card.ActionType.fixCart, 'act_fix_cart');
    // 복합 수리 카드는 구현상 임시로 단일 수리로 대체하거나 별도 로직 필요 (MVP에선 단일로)
    addAction(1, game_card.ActionType.fixPickaxe, 'act_fix_pick_m');
    addAction(1, game_card.ActionType.fixLantern, 'act_fix_lan_m');
    addAction(1, game_card.ActionType.fixCart, 'act_fix_cart_m');

    addAction(6, game_card.ActionType.map, 'act_map');
    addAction(3, game_card.ActionType.rockfall, 'act_rock');

    deck.shuffle();
    return deck;
  }
}
