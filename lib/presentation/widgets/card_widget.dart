import 'package:flutter/material.dart';
import '../../data/models/card.dart' as game_card;

/// 보드판 위에 단일 카드 한 장을 렌더링하는 위젯.
/// [card]가 null이면 빈 격자(Placeholder)를 표시합니다.
class CardWidget extends StatelessWidget {
  final game_card.Card? card;
  final bool isRevealed;
  final bool isHighlightedValid;    // BFS 통과 → 초록 오버레이
  final bool isHighlightedInvalid;  // BFS 실패 → 빨강 오버레이
  final VoidCallback? onTap;
  final double size;

  const CardWidget({
    super.key,
    required this.card,
    this.isRevealed = true,
    this.isHighlightedValid = false,
    this.isHighlightedInvalid = false,
    this.onTap,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            _buildCardBody(),
            if (isHighlightedValid) _buildOverlay(Colors.green.withOpacity(0.45)),
            if (isHighlightedInvalid) _buildOverlay(Colors.red.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody() {
    if (card == null) {
      // 빈 격자: 얇은 점선 테두리만 표시
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white10,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // 목적지 카드이며 아직 뒤집히지 않은 상태: 카드 뒷면 표시
    if (card!.type == game_card.CardType.goal && !isRevealed) {
      return _buildCardBack();
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: _buildCardContent(),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B2A1A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF7A5C3A), width: 1.5),
      ),
      child: const Center(
        child: Icon(Icons.help_outline, color: Color(0xFF7A5C3A), size: 28),
      ),
    );
  }

  Widget _buildCardContent() {
    switch (card!.type) {
      case game_card.CardType.start:
        return const Center(
          child: Icon(Icons.flag, color: Colors.amber, size: 28),
        );
      case game_card.CardType.goal:
        return Center(
          child: Icon(
            card!.isGold ? Icons.diamond : Icons.circle,
            color: card!.isGold ? Colors.amber : Colors.blueGrey,
            size: 28,
          ),
        );
      case game_card.CardType.action:
        return Center(
          child: Icon(_actionIcon(), color: Colors.orangeAccent, size: 24),
        );
      case game_card.CardType.path:
        return CustomPaint(
          painter: PathCardPainter(
            hasTop: card!.hasTop,
            hasRight: card!.hasRight,
            hasBottom: card!.hasBottom,
            hasLeft: card!.hasLeft,
            hasCenter: card!.hasCenter,
          ),
        );
    }
  }

  IconData _actionIcon() {
    switch (card!.actionType) {
      case game_card.ActionType.breakPickaxe:
      case game_card.ActionType.breakLantern:
      case game_card.ActionType.breakCart:
        return Icons.build_circle_outlined;
      case game_card.ActionType.fixPickaxe:
      case game_card.ActionType.fixLantern:
      case game_card.ActionType.fixCart:
        return Icons.build_circle;
      case game_card.ActionType.rockfall:
        return Icons.landslide;
      case game_card.ActionType.map:
        return Icons.map;
      default:
        return Icons.credit_card;
    }
  }

  Color _cardColor() {
    switch (card!.type) {
      case game_card.CardType.start:
        return const Color(0xFF1B4332);
      case game_card.CardType.goal:
        return const Color(0xFF3B2A1A);
      case game_card.CardType.action:
        return const Color(0xFF2C2C54);
      case game_card.CardType.path:
        return const Color(0xFF3D2B1F);
    }
  }

  Widget _buildOverlay(Color color) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// 굴(Path) 카드의 연결 방향에 따라 통로 모양을 그리는 CustomPainter.
class PathCardPainter extends CustomPainter {
  final bool hasTop;
  final bool hasRight;
  final bool hasBottom;
  final bool hasLeft;
  final bool hasCenter;

  const PathCardPainter({
    required this.hasTop,
    required this.hasRight,
    required this.hasBottom,
    required this.hasLeft,
    required this.hasCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A853)
      ..strokeWidth = size.width * 0.3
      ..strokeCap = StrokeCap.square;

    final center = Offset(size.width / 2, size.height / 2);

    if (hasTop) {
      canvas.drawLine(center, Offset(center.dx, 0), paint);
    }
    if (hasBottom) {
      canvas.drawLine(center, Offset(center.dx, size.height), paint);
    }
    if (hasLeft) {
      canvas.drawLine(center, Offset(0, center.dy), paint);
    }
    if (hasRight) {
      canvas.drawLine(center, Offset(size.width, center.dy), paint);
    }
    if (hasCenter || hasTop || hasBottom || hasLeft || hasRight) {
      // 중앙 교차점
      canvas.drawCircle(center, size.width * 0.12, paint);
    }
  }

  @override
  bool shouldRepaint(PathCardPainter old) =>
      hasTop != old.hasTop ||
      hasRight != old.hasRight ||
      hasBottom != old.hasBottom ||
      hasLeft != old.hasLeft ||
      hasCenter != old.hasCenter;
}
