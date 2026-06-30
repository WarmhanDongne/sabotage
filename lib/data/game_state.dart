import 'models/card.dart';
import 'models/player.dart';
import 'models/grid_node.dart';

// 전체 게임의 원본 상태 (Firestore에 저장)
class GameState {
  final String roomId;
  final List<Player> players;
  final String currentTurnPlayerId;
  final List<GridNode> board;
  
  // 덱과 버려진 카드
  final List<Card> deck;
  final List<Card> discardPile;
  
  // 목적지 카드 3장 위치
  final List<GridNode> goalCards;

  // 게임 진행 메타데이터
  final int currentRound;
  final bool isGameOver;
  final Map<String, int> goldDistribution; // playerId : 금덩이 개수

  const GameState({
    required this.roomId,
    required this.players,
    required this.currentTurnPlayerId,
    required this.board,
    required this.deck,
    required this.discardPile,
    required this.goalCards,
    this.currentRound = 1,
    this.isGameOver = false,
    this.goldDistribution = const {},
  });
}

// 호스트 뷰어용 상태 (역할, 패 등 은닉)
class MaskedGameState {
  final String roomId;
  final List<Player> maskedPlayers; // 역할은 null, handCardIds는 개수만큼 빈 문자열 또는 뒷면 ID
  final String currentTurnPlayerId;
  final List<GridNode> board;
  final int deckCount;
  final List<GridNode> goalCards; // 아직 isRevealed == false 인 상태

  const MaskedGameState({
    required this.roomId,
    required this.maskedPlayers,
    required this.currentTurnPlayerId,
    required this.board,
    required this.deckCount,
    required this.goalCards,
  });
}

// 클라이언트 뷰어용 상태 (본인 정보만 구체화)
class PrivateGameState {
  final String roomId;
  final Player me; // 본인 정보
  final String currentTurnPlayerId;
  final bool isMyTurn;
  
  const PrivateGameState({
    required this.roomId,
    required this.me,
    required this.currentTurnPlayerId,
    required this.isMyTurn,
  });
}
