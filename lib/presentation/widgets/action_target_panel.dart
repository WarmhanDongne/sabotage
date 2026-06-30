import 'package:flutter/material.dart';
import '../../data/models/player.dart';

/// 행동 카드 사용 시 타겟 플레이어를 선택하는 패널.
/// 자기 자신은 파괴 카드 대상에서 제외하고, 수리 카드는 자기 자신도 포함합니다.
class ActionTargetPanel extends StatelessWidget {
  final List<Player> otherPlayers;
  final String? selectedTargetPlayerId;
  final bool isRepairCard; // 수리 카드이면 자기 자신도 선택 가능
  final void Function(String playerId) onSelectPlayer;
  final VoidCallback onCancel;

  const ActionTargetPanel({
    super.key,
    required this.otherPlayers,
    required this.selectedTargetPlayerId,
    required this.isRepairCard,
    required this.onSelectPlayer,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRepairCard ? '수리할 플레이어 선택' : '파괴할 플레이어 선택',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: otherPlayers.map((p) => _PlayerTargetChip(
              player: p,
              isSelected: selectedTargetPlayerId == p.id,
              isRepairCard: isRepairCard,
              onTap: () => onSelectPlayer(p.id),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _PlayerTargetChip extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isRepairCard;
  final VoidCallback onTap;

  const _PlayerTargetChip({
    required this.player,
    required this.isSelected,
    required this.isRepairCard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 수리 카드인 경우 파괴된 장비가 있는 플레이어만 선택 가능
    // 파괴 카드인 경우 모든 플레이어 선택 가능 (이미 파괴된 장비 표시 포함)
    final hasAnyBroken = player.isPickaxeBroken || player.isLanternBroken || player.isCartBroken;
    final canSelect = isRepairCard ? hasAnyBroken : true;

    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isRepairCard ? const Color(0xFF2D6A4F) : const Color(0xFF5C1A1A))
              : const Color(0xFF2C2C3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isRepairCard ? Colors.greenAccent : Colors.redAccent)
                : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: (isRepairCard ? Colors.greenAccent : Colors.redAccent)
                      .withOpacity(0.35),
                  blurRadius: 10,
                )]
              : [],
        ),
        child: Column(
          children: [
            Text(
              player.name,
              style: TextStyle(
                color: canSelect ? Colors.white : Colors.white24,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EquipmentDot(isBroken: player.isPickaxeBroken, icon: Icons.hardware),
                const SizedBox(width: 4),
                _EquipmentDot(isBroken: player.isLanternBroken, icon: Icons.lightbulb_outline),
                const SizedBox(width: 4),
                _EquipmentDot(isBroken: player.isCartBroken, icon: Icons.shopping_cart_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentDot extends StatelessWidget {
  final bool isBroken;
  final IconData icon;
  const _EquipmentDot({required this.isBroken, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 14,
      color: isBroken ? Colors.redAccent : Colors.white30,
    );
  }
}
