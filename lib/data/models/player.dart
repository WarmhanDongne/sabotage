enum PlayerRole {
  miner,         // 광부 (사보타지 1)
  saboteur,      // 방해꾼
  blueMiner,     // 파란색 광부 (사보타지 2)
  greenMiner,    // 녹색 광부 (사보타지 2)
  boss,          // 대장 (사보타지 2)
  profiteer,     // 부당이익자 (사보타지 2)
  geologist,     // 지질학자 (사보타지 2)
}

class Player {
  final String id;
  final String name;
  final PlayerRole? role; // 마스킹 뷰에서는 null일 수 있음
  
  // 손패 (마스킹 뷰에서는 개수만 표시될 수 있으므로 분리해서 관리하거나 id 리스트 사용)
  final List<String> handCardIds; 
  
  // 디버프 상태 (true면 파괴됨 = 행동 불가)
  final bool isPickaxeBroken;
  final bool isLanternBroken;
  final bool isCartBroken;
  
  // 사보타지 2 특수 상태
  final bool isTrapped; // 감옥 카드

  const Player({
    required this.id,
    required this.name,
    this.role,
    this.handCardIds = const [],
    this.isPickaxeBroken = false,
    this.isLanternBroken = false,
    this.isCartBroken = false,
    this.isTrapped = false,
  });

  Player copyWith({
    String? id,
    String? name,
    PlayerRole? role,
    List<String>? handCardIds,
    bool? isPickaxeBroken,
    bool? isLanternBroken,
    bool? isCartBroken,
    bool? isTrapped,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      handCardIds: handCardIds ?? this.handCardIds,
      isPickaxeBroken: isPickaxeBroken ?? this.isPickaxeBroken,
      isLanternBroken: isLanternBroken ?? this.isLanternBroken,
      isCartBroken: isCartBroken ?? this.isCartBroken,
      isTrapped: isTrapped ?? this.isTrapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role?.name,
      'handCardIds': handCardIds,
      'isPickaxeBroken': isPickaxeBroken,
      'isLanternBroken': isLanternBroken,
      'isCartBroken': isCartBroken,
      'isTrapped': isTrapped,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] != null 
          ? PlayerRole.values.firstWhere((e) => e.name == json['role'], orElse: () => PlayerRole.miner)
          : null,
      handCardIds: (json['handCardIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isPickaxeBroken: json['isPickaxeBroken'] as bool? ?? false,
      isLanternBroken: json['isLanternBroken'] as bool? ?? false,
      isCartBroken: json['isCartBroken'] as bool? ?? false,
      isTrapped: json['isTrapped'] as bool? ?? false,
    );
  }
}
