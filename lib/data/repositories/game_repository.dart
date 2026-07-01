import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card.dart' as game_card;
import '../models/grid_node.dart';
import '../models/player.dart';
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

  // 방 생성 (기본판 덱 세팅 및 초기 상태)
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

      // 임시 행동 카드 생성 (마찬가지로 딕셔너리 연동 필요)
      game_card.ActionType actionType = game_card.ActionType.none;
      if (cardId.contains('breakPickaxe')) actionType = game_card.ActionType.breakPickaxe;
      else if (cardId.contains('fixPickaxe')) actionType = game_card.ActionType.fixPickaxe;
      // ... 그 외 맵핑 ...

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
    );

    transaction.update(docRef, newState.toJson());
  }

  List<game_card.Card> _generateBasicDeck() {
    List<game_card.Card> deck = [];
    // 간략화된 생성기: 40장의 길 카드, 20장의 행동 카드
    for (int i = 0; i < 40; i++) {
      deck.add(game_card.Card(id: 'path_$i', type: game_card.CardType.path, hasTop: true, hasBottom: true, hasLeft: true, hasRight: true, hasCenter: true));
    }
    for (int i = 0; i < 10; i++) {
      deck.add(game_card.Card(id: 'act_break_$i', type: game_card.CardType.action, actionType: game_card.ActionType.breakPickaxe));
    }
    for (int i = 0; i < 10; i++) {
      deck.add(game_card.Card(id: 'act_fix_$i', type: game_card.CardType.action, actionType: game_card.ActionType.fixPickaxe));
    }
    return deck;
  }
}
