enum CardType {
  path,    // 굴(길) 카드
  action,  // 행동 카드 (파괴, 수리, 낙석, 지도 등)
  goal,    // 목적지(금/돌) 카드
  start,   // 시작점 카드
}

enum ActionType {
  none,
  breakPickaxe,
  fixPickaxe,
  breakLantern,
  fixLantern,
  breakCart,
  fixCart,
  fixCartOrLantern, // 001_action_03
  fixCartOrPickaxe, // 001_action_04
  fixLanternOrPickaxe, // 일반적인 사보타지에 존재하는 다중 수리
  rockfall, // 낙석
  map,      // 지도
}

class Card {
  final String id;
  final CardType type;
  
  // 굴 카드 관련 속성 (상, 우, 하, 좌 연결 여부)
  final bool hasTop;
  final bool hasRight;
  final bool hasBottom;
  final bool hasLeft;
  final bool hasCenter; // 중앙 교차 여부
  
  // 목적지 카드 관련 속성
  final bool isGold;
  
  // 행동 카드 관련 속성
  final ActionType actionType;
  
  // 사보타지 2 확장용 (문의 색상 등)
  final String? doorColor;
  final bool hasCrystal;

  const Card({
    required this.id,
    required this.type,
    this.hasTop = false,
    this.hasRight = false,
    this.hasBottom = false,
    this.hasLeft = false,
    this.hasCenter = false,
    this.isGold = false,
    this.actionType = ActionType.none,
    this.doorColor,
    this.hasCrystal = false,
  });

  // 복사 생성자 (불변성 유지)
  Card copyWith({
    String? id,
    CardType? type,
    bool? hasTop,
    bool? hasRight,
    bool? hasBottom,
    bool? hasLeft,
    bool? hasCenter,
    bool? isGold,
    ActionType? actionType,
    String? doorColor,
    bool? hasCrystal,
  }) {
    return Card(
      id: id ?? this.id,
      type: type ?? this.type,
      hasTop: hasTop ?? this.hasTop,
      hasRight: hasRight ?? this.hasRight,
      hasBottom: hasBottom ?? this.hasBottom,
      hasLeft: hasLeft ?? this.hasLeft,
      hasCenter: hasCenter ?? this.hasCenter,
      isGold: isGold ?? this.isGold,
      actionType: actionType ?? this.actionType,
      doorColor: doorColor ?? this.doorColor,
      hasCrystal: hasCrystal ?? this.hasCrystal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'hasTop': hasTop,
      'hasRight': hasRight,
      'hasBottom': hasBottom,
      'hasLeft': hasLeft,
      'hasCenter': hasCenter,
      'isGold': isGold,
      'actionType': actionType.name,
      'doorColor': doorColor,
      'hasCrystal': hasCrystal,
    };
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'] as String,
      type: CardType.values.firstWhere((e) => e.name == json['type'], orElse: () => CardType.path),
      hasTop: json['hasTop'] as bool? ?? false,
      hasRight: json['hasRight'] as bool? ?? false,
      hasBottom: json['hasBottom'] as bool? ?? false,
      hasLeft: json['hasLeft'] as bool? ?? false,
      hasCenter: json['hasCenter'] as bool? ?? false,
      isGold: json['isGold'] as bool? ?? false,
      actionType: ActionType.values.firstWhere((e) => e.name == json['actionType'], orElse: () => ActionType.none),
      doorColor: json['doorColor'] as String?,
      hasCrystal: json['hasCrystal'] as bool? ?? false,
    );
  }
}
