import 'package:flutter/material.dart';
import '../../data/models/grid_node.dart';
import 'card_widget.dart';

/// 오리지널 에셋(Ipad.png) 기반 보드 격자 렌더링 위젯.
/// Ipad.png의 9x5 그리드 구조 위에 투명하게 올라가며, 실제 카드가 배치되는 역할을 합니다.
class BoardGridWidget extends StatelessWidget {
  final List<GridNode> board;
  final List<GridNode> goalCards;
  final double cellWidth;
  final double cellHeight;
  final Set<String>? validOverlayCoords;
  final Set<String>? invalidOverlayCoords;
  final void Function(int x, int y)? onGridTap;

  const BoardGridWidget({
    super.key,
    required this.board,
    required this.goalCards,
    required this.cellWidth,
    required this.cellHeight,
    this.validOverlayCoords,
    this.invalidOverlayCoords,
    this.onGridTap,
  });

  @override
  Widget build(BuildContext context) {
    // 9x5 고정 그리드 렌더링 (Ipad.png 에셋 구조 매칭)
    const int cols = 9;
    const int rows = 5;
    
    // 시작 카드 위치 보정
    // 스크린샷 기준: 9열 중 1번째 열 (0-indexed: 0)
    // 5행 중 3번째 행 (0-indexed: 2) -> 시작 Y는 -2 (원래 게임 기준 0이 중앙이 되도록)
    const int startX = 0;
    const int startY = -2;

    final Map<String, GridNode> boardMap = {
      for (var n in [...board, ...goalCards]) '${n.x},${n.y}': n,
    };

    return SizedBox(
      width: cols * cellWidth,
      height: rows * cellHeight,
      child: Stack(
        children: [
          for (int row = 0; row < rows; row++)
            for (int col = 0; col < cols; col++)
              _buildCell(
                col: col,
                row: row,
                x: startX + col,
                y: startY + row,
                boardMap: boardMap,
              ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required int col,
    required int row,
    required int x,
    required int y,
    required Map<String, GridNode> boardMap,
  }) {
    final key = '$x,$y';
    final node = boardMap[key];
    final isValid = validOverlayCoords?.contains(key) ?? false;
    final isInvalid = invalidOverlayCoords?.contains(key) ?? false;

    return Positioned(
      left: col * cellWidth,
      top: row * cellHeight,
      child: GestureDetector(
        onTap: onGridTap != null ? () => onGridTap!(x, y) : null,
        child: Container(
          width: cellWidth,
          height: cellHeight,
          // 사용자가 놓을 수 있는 유효/무효 위치일 경우에만 오리지널 톤에 맞는 오버레이 표시.
          decoration: BoxDecoration(
            color: isValid
                ? Colors.green.withOpacity(0.3)
                : (isInvalid ? Colors.red.withOpacity(0.3) : Colors.transparent),
            // 보드 그리드 셀 모서리 둥글게
            borderRadius: BorderRadius.circular(6),
          ),
          // 카드 크기는 그리드 한 칸(네모)에 여백 없이 꽉 차도록 패딩 조정
          // 아주 약간의 패딩만 남겨 서로 붙어보이면서도 자연스럽게
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: node != null
                ? CardWidget(
                    card: node.card,
                    isRevealed: node.isRevealed,
                    width: cellWidth - 4, // padding 제외 크기
                    height: cellHeight - 4,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
