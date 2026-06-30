import 'package:flutter/material.dart';
import '../../data/models/player.dart';

/// 클라이언트(모바일)의 자기 자신 상태를 표시하는 헤더 위젯.
/// 역할(마스킹됨/공개), 파괴된 장비, 현재 턴 여부를 보여줍니다.
class PlayerSelfStatusHeader extends StatelessWidget {
  final Player me;
  final bool isMyTurn;

  const PlayerSelfStatusHeader({
    super.key,
    required this.me,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: isMyTurn
            ? const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF0D1B14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)],
              ),
        border: Border(
          bottom: BorderSide(
            color: isMyTurn ? Colors.greenAccent.withOpacity(0.5) : Colors.white12,
          ),
        ),
      ),
      child: Row(
        children: [
          // 아바타 영역
          _buildAvatar(),
          const SizedBox(width: 16),
          // 이름 및 상태
          Expanded(child: _buildInfo()),
          // 내 턴 배지
          if (isMyTurn) _buildMyTurnBadge(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: isMyTurn ? const Color(0xFF2D6A4F) : const Color(0xFF2C2C3E),
      child: Icon(
        Icons.person,
        color: isMyTurn ? Colors.greenAccent : Colors.white54,
        size: 28,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          me.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // 장비 상태 아이콘 행
        Row(
          children: [
            _equipIcon(Icons.hardware, me.isPickaxeBroken, '곡괭이'),
            const SizedBox(width: 10),
            _equipIcon(Icons.lightbulb_outline, me.isLanternBroken, '램프'),
            const SizedBox(width: 10),
            _equipIcon(Icons.shopping_cart_outlined, me.isCartBroken, '수레'),
          ],
        ),
      ],
    );
  }

  Widget _equipIcon(IconData icon, bool isBroken, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isBroken ? Colors.redAccent : Colors.white38),
        if (isBroken) ...[
          const SizedBox(width: 2),
          const Icon(Icons.close, size: 10, color: Colors.redAccent),
        ],
      ],
    );
  }

  Widget _buildMyTurnBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, color: Colors.greenAccent, size: 16),
          SizedBox(width: 4),
          Text(
            '내 차례',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
