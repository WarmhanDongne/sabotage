import 'card.dart';

class CardDatabase {
  // === 길 카드 34장 정의 ===
  // hasTop, hasRight, hasBottom, hasLeft, hasCenter (연결 여부)
  // user's definitions: 
  // 좌(Left), 우(Right), 상(Top), 하(Bottom)
  static final List<Card> pathCards = [
    const Card(id: '004_path_01', type: CardType.path, hasLeft: false, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '004_path_02', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: false, hasCenter: true),
    const Card(id: '004_path_03', type: CardType.path, hasLeft: true, hasTop: false, hasRight: false, hasBottom: true, hasCenter: false),
    const Card(id: '004_path_04', type: CardType.path, hasLeft: false, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '004_path_05', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: false),
    const Card(id: '004_path_06', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '004_path_07', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '004_path_08', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: false, hasCenter: true),
    const Card(id: '004_path_09', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: false, hasCenter: true),
    const Card(id: '005_path_01', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '005_path_02', type: CardType.path, hasLeft: true, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '005_path_03', type: CardType.path, hasLeft: false, hasTop: true, hasRight: true, hasBottom: false, hasCenter: true),
    const Card(id: '005_path_04', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '005_path_05', type: CardType.path, hasLeft: false, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '005_path_06', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '005_path_07', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: false, hasCenter: true),
    const Card(id: '005_path_08', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: false, hasCenter: true),
    const Card(id: '005_path_09', type: CardType.path, hasLeft: true, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_01', type: CardType.path, hasLeft: true, hasTop: false, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_02', type: CardType.path, hasLeft: false, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_03', type: CardType.path, hasLeft: true, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_04', type: CardType.path, hasLeft: false, hasTop: true, hasRight: true, hasBottom: false, hasCenter: true),
    const Card(id: '006_path_05', type: CardType.path, hasLeft: false, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_06', type: CardType.path, hasLeft: true, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_07', type: CardType.path, hasLeft: true, hasTop: false, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_08', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '006_path_09', type: CardType.path, hasLeft: true, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '007_path_01', type: CardType.path, hasLeft: true, hasTop: true, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '007_path_02', type: CardType.path, hasLeft: false, hasTop: true, hasRight: false, hasBottom: false, hasCenter: true),
    const Card(id: '007_path_03', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: false, hasCenter: true),
    const Card(id: '007_path_04', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '007_path_05', type: CardType.path, hasLeft: false, hasTop: true, hasRight: false, hasBottom: true, hasCenter: true),
    const Card(id: '007_path_06', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
    const Card(id: '007_path_07', type: CardType.path, hasLeft: true, hasTop: false, hasRight: true, hasBottom: true, hasCenter: true),
  ];

  // === 행동 카드 11장 정의 ===
  static final List<Card> actionCards = [
    const Card(id: '001_action_02', type: CardType.action, actionType: ActionType.breakLantern),
    const Card(id: '001_action_05', type: CardType.action, actionType: ActionType.breakCart),
    const Card(id: '001_action_08', type: CardType.action, actionType: ActionType.breakPickaxe),
    const Card(id: '001_action_07', type: CardType.action, actionType: ActionType.fixPickaxe),
    const Card(id: '001_action_06', type: CardType.action, actionType: ActionType.rockfall),
    const Card(id: '001_action_09', type: CardType.action, actionType: ActionType.map),
    const Card(id: '001_action_01', type: CardType.action, actionType: ActionType.fixCart),
    const Card(id: '001_action_03', type: CardType.action, actionType: ActionType.fixCartOrLantern),
    const Card(id: '001_action_04', type: CardType.action, actionType: ActionType.fixCartOrPickaxe),
    const Card(id: '001_action_10', type: CardType.action, actionType: ActionType.fixLantern),
    const Card(id: '001_action_11', type: CardType.action, actionType: ActionType.fixLantern),
  ];

  // === 게임 시작용 카드 및 기타 ===
  static const Card startCard = Card(
    id: '009_cave_sword_01', 
    type: CardType.start, 
    hasTop: true, hasBottom: true, hasLeft: true, hasRight: true, hasCenter: true
  );

  static final List<Card> allDeckCards = [...pathCards, ...actionCards];

  static Card? getCardById(String id) {
    if (id == startCard.id) return startCard;
    if (id.startsWith('goal_')) {
      return const Card(id: 'goal_temp', type: CardType.goal);
    }
    try {
      return allDeckCards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
