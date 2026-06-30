import '../data/game_state.dart';
import '../data/models/card.dart';
import '../data/models/player.dart';
import '../data/models/grid_node.dart';
import 'validator.dart';

class GameEngine {
  /// 플레이어가 카드를 보드판(특정 x, y)에 놓는 액션을 처리합니다.
  static GameState playPathCard(
    GameState currentState,
    String playerId,
    Card card,
    int targetX,
    int targetY,
  ) {
    if (currentState.currentTurnPlayerId != playerId) {
      throw Exception('Not your turn');
    }

    // 플레이어가 장비 파괴 상태이면 굴 카드를 놓을 수 없음
    final player = currentState.players.firstWhere((p) => p.id == playerId);
    if (player.isPickaxeBroken || player.isLanternBroken || player.isCartBroken) {
      throw Exception('Cannot play path card while equipment is broken');
    }

    // 유효성 검사 (Validator)
    if (!Validator.canPlaceCard(currentState.board, card, targetX, targetY)) {
      throw Exception('Invalid card placement');
    }

    // 1. 보드에 카드 추가
    final newBoard = List<GridNode>.from(currentState.board)
      ..add(GridNode(x: targetX, y: targetY, card: card));

    // 2. 목적지 카드 오픈 여부 체크 (생략 - 실제로는 BFS로 목적지 도달 여부 추가 검사 필요)
    
    // 3. 플레이어 손패에서 카드 제거 및 새 카드 뽑기
    final newPlayers = _updatePlayerHand(currentState, playerId, card.id);

    // 4. 덱에서 카드 뽑기
    final newDeck = List<Card>.from(currentState.deck);
    if (newDeck.isNotEmpty) {
      newDeck.removeLast(); // 간략화: 맨 위 카드 뽑기 (실제 로직은 newPlayers 업데이트 시 적용)
    }

    // 5. 다음 턴으로 넘어가기
    final nextTurnPlayerId = _getNextTurnPlayerId(currentState.players, playerId);

    return GameState(
      roomId: currentState.roomId,
      players: newPlayers,
      currentTurnPlayerId: nextTurnPlayerId,
      board: newBoard,
      deck: newDeck,
      discardPile: currentState.discardPile,
      goalCards: currentState.goalCards,
      currentRound: currentState.currentRound,
      isGameOver: currentState.isGameOver,
      goldDistribution: currentState.goldDistribution,
    );
  }

  /// 카드를 버리는 액션을 처리합니다.
  static GameState discardCard(
    GameState currentState,
    String playerId,
    String cardIdToDiscard,
  ) {
    if (currentState.currentTurnPlayerId != playerId) {
      throw Exception('Not your turn');
    }

    final newPlayers = _updatePlayerHand(currentState, playerId, cardIdToDiscard);
    
    // 버려진 카드 더미에 추가 로직 등 구현 필요
    
    final nextTurnPlayerId = _getNextTurnPlayerId(currentState.players, playerId);

    return GameState(
      roomId: currentState.roomId,
      players: newPlayers,
      currentTurnPlayerId: nextTurnPlayerId,
      board: currentState.board, // 보드 변경 없음
      deck: currentState.deck,
      discardPile: currentState.discardPile,
      goalCards: currentState.goalCards,
      currentRound: currentState.currentRound,
    );
  }

  static List<Player> _updatePlayerHand(GameState state, String playerId, String usedCardId) {
    return state.players.map((p) {
      if (p.id == playerId) {
        final newHand = List<String>.from(p.handCardIds)..remove(usedCardId);
        // 덱에서 한 장 가져오기 (실제로는 deck 리스트에서도 빼야 함)
        if (state.deck.isNotEmpty) {
          newHand.add(state.deck.last.id);
        }
        return p.copyWith(handCardIds: newHand);
      }
      return p;
    }).toList();
  }

  static String _getNextTurnPlayerId(List<Player> players, String currentPlayerId) {
    final currentIndex = players.indexWhere((p) => p.id == currentPlayerId);
    final nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex].id;
  }
}
