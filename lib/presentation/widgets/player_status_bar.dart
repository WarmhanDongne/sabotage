import 'package:flutter/material.dart';
import '../../data/models/player.dart';

/// 호스트(태블릿) 화면 상단에 표시되는 플레이어 상태 바.
/// 각 플레이어의 이름, 장비 상태(파괴 여부), 현재 턴 여부를 표시합니다.
class PlayerStatusBar extends StatelessWidget {
  final List<Player> players;
  final String currentTurnPlayerId;

  const PlayerStatusBar({
    super.key,
    required this.players,
    required this.currentTurnPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1A1A2E),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final player = players[index];
          final isCurrentTurn = player.id == currentTurnPlayerId;
          return _PlayerChip(player: player, isCurrentTurn: isCurrentTurn);
        },
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;

  const _PlayerChip({required this.player, required this.isCurrentTurn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTurn ? const Color(0xFF2D6A4F) : const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentTurn ? Colors.greenAccent : Colors.white24,
          width: isCurrentTurn ? 2 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 8, spreadRadius: 1)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 턴 인디케이터
          if (isCurrentTurn) ...[
            const Icon(Icons.arrow_right, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 4),
          ],
          // 플레이어 이름
          Text(
            player.name,
            style: TextStyle(
              color: isCurrentTurn ? Colors.white : Colors.white70,
              fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          // 장비 상태 아이콘
          _EquipmentIcon(
            icon: Icons.hardware,       // 곡괭이
            isBroken: player.isPickaxeBroken,
          ),
          const SizedBox(width: 4),
          _EquipmentIcon(
            icon: Icons.lightbulb_outline, // 램프
            isBroken: player.isLanternBroken,
          ),
          const SizedBox(width: 4),
          _EquipmentIcon(
            icon: Icons.shopping_cart_outlined, // 수레
            isBroken: player.isCartBroken,
          ),
        ],
      ),
    );
  }
}

class _EquipmentIcon extends StatelessWidget {
  final IconData icon;
  final bool isBroken;

  const _EquipmentIcon({required this.icon, required this.isBroken});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: isBroken ? Colors.redAccent : Colors.white54,
        ),
        if (isBroken)
          const Icon(Icons.close, size: 10, color: Colors.redAccent),
      ],
    );
  }
}
