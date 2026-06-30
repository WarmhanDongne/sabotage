import 'package:flutter/material.dart';
import '../../main.dart';
import '../widgets/board_grid_widget.dart';

/// 호스트(태블릿) 보드 뷰어
/// DESIGN.md 기준: 패널 차콜 + 브라스 테두리 + 골드 포인트
class TableView extends StatelessWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 플레이어 상태 바
            _buildTopBar(),
            // 보드 영역
            Expanded(child: _buildBoardArea()),
            // 하단 게임 정보 바
            _buildBottomInfoBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: SabotageColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: SabotageColors.borderBrass, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 게임 타이틀
          Text(
            'SABOTEUR',
            style: TextStyle(
              color: SabotageColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontFamily: 'Literata',
            ),
          ),
          const Spacer(),
          // 방 코드 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: SabotageColors.panelCharcoal,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SabotageColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.meeting_room_outlined, color: SabotageColors.muted, size: 14),
                const SizedBox(width: 6),
                Text(
                  roomId.toUpperCase(),
                  style: const TextStyle(
                    color: SabotageColors.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    return Stack(
      children: [
        // 배경 그라디언트
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                SabotageColors.surfaceContainerLow,
                SabotageColors.surfaceContainerLowest,
              ],
            ),
          ),
        ),
        // InteractiveViewer 보드판
        Center(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.3,
            maxScale: 3.0,
            child: BoardGridWidget(
              board: const [],
              goalCards: const [],
              cardSize: 72.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfoBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: SabotageColors.panelCharcoal,
        border: Border(
          top: BorderSide(color: SabotageColors.borderBrass, width: 2),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 라운드 표시
          Row(
            children: [
              Icon(Icons.loop, color: SabotageColors.muted, size: 16),
              SizedBox(width: 6),
              Text(
                'ROUND 1',
                style: TextStyle(
                  color: SabotageColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          // 덱 남은 장수
          Row(
            children: [
              Icon(Icons.layers, color: SabotageColors.muted, size: 16),
              SizedBox(width: 6),
              Text(
                '42 REMAINING',
                style: TextStyle(
                  color: SabotageColors.primaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
