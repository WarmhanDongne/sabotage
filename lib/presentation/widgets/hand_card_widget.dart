import 'package:flutter/material.dart';
import '../../data/models/card.dart' as game_card;

/// 클라이언트의 손패 한 장을 렌더링하는 위젯.
/// 선택 여부에 따라 위로 솟는 애니메이션과 테두리 강조를 표시합니다.
class HandCardWidget extends StatelessWidget {
  final game_card.Card card;
  final bool isSelected;
  final bool isMyTurn;
  final VoidCallback onTap;

  const HandCardWidget({
    super.key,
    required this.card,
    required this.isSelected,
    required this.isMyTurn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isMyTurn ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        // 선택 시 카드가 위로 솟아오름
        margin: EdgeInsets.only(
          top: isSelected ? 0 : 16,
          bottom: isSelected ? 16 : 0,
        ),
        width: 72,
        height: 104,
        decoration: BoxDecoration(
          color: _cardColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.amberAccent
                : (isMyTurn ? Colors.white24 : Colors.white10),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.amberAccent.withOpacity(0.5)
                  : Colors.black38,
              blurRadius: isSelected ? 16 : 4,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_cardIcon(), color: _iconColor(), size: 28),
              const SizedBox(height: 6),
              Text(
                _cardLabel(),
                style: TextStyle(
                  color: isMyTurn ? Colors.white : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _cardColor() {
    switch (card.type) {
      case game_card.CardType.path:
        return const Color(0xFF3D2B1F);
      case game_card.CardType.action:
        return const Color(0xFF2C2C54);
      case game_card.CardType.goal:
        return const Color(0xFF3B2A1A);
      case game_card.CardType.start:
        return const Color(0xFF1B4332);
    }
  }

  IconData _cardIcon() {
    switch (card.type) {
      case game_card.CardType.path:
        return Icons.timeline;
      case game_card.CardType.action:
        switch (card.actionType) {
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
            return Icons.map_outlined;
          default:
            return Icons.credit_card;
        }
      case game_card.CardType.goal:
        return Icons.flag_outlined;
      case game_card.CardType.start:
        return Icons.flag;
    }
  }

  Color _iconColor() {
    switch (card.type) {
      case game_card.CardType.path:
        return const Color(0xFFD4A853);
      case game_card.CardType.action:
        return Colors.purpleAccent;
      case game_card.CardType.goal:
        return Colors.amberAccent;
      case game_card.CardType.start:
        return Colors.greenAccent;
    }
  }

  String _cardLabel() {
    switch (card.type) {
      case game_card.CardType.path:
        return '굴 카드';
      case game_card.CardType.action:
        switch (card.actionType) {
          case game_card.ActionType.breakPickaxe: return '곡괭이\n파괴';
          case game_card.ActionType.breakLantern: return '램프\n파괴';
          case game_card.ActionType.breakCart:    return '수레\n파괴';
          case game_card.ActionType.fixPickaxe:   return '곡괭이\n수리';
          case game_card.ActionType.fixLantern:   return '램프\n수리';
          case game_card.ActionType.fixCart:      return '수레\n수리';
          case game_card.ActionType.rockfall:     return '낙석';
          case game_card.ActionType.map:          return '지도';
          default:                                return '행동';
        }
      case game_card.CardType.goal:
        return '목적지';
      case game_card.CardType.start:
        return '시작';
    }
  }
}
