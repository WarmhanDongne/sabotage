import 'card.dart';

class GridNode {
  final int x;
  final int y;
  final Card card; // 해당 위치에 놓인 굴/목적지/시작점 카드
  
  // 목적지 카드인 경우 뒤집혔는지 여부
  final bool isRevealed;

  const GridNode({
    required this.x,
    required this.y,
    required this.card,
    this.isRevealed = true, // 일반 굴 카드는 항상 true, 목적지 카드만 기본 false
  });

  GridNode copyWith({
    int? x,
    int? y,
    Card? card,
    bool? isRevealed,
  }) {
    return GridNode(
      x: x ?? this.x,
      y: y ?? this.y,
      card: card ?? this.card,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'card': card.toJson(),
      'isRevealed': isRevealed,
    };
  }

  factory GridNode.fromJson(Map<String, dynamic> json) {
    return GridNode(
      x: json['x'] as int,
      y: json['y'] as int,
      card: Card.fromJson(json['card'] as Map<String, dynamic>),
      isRevealed: json['isRevealed'] as bool? ?? true,
    );
  }
}
