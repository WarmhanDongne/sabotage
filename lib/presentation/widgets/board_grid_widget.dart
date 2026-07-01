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
    // 새 배경 이미지(basic_image.png)를 위해 12x7 가상 그리드를 화면 전체에 사용합니다.
    const int cols = 12;
    const int rows = 7;

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
                x: col,
                y: row,
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
        child: SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: Center(
            child: AspectRatio(
              aspectRatio: 2 / 3, // 실제 사보타지 카드 비율에 근접한 직사각형
              child: Container(
                // 흰색 카드 자리 (카드가 없을 때 표시되는 빈 슬롯)
                decoration: BoxDecoration(
                  color: node == null ? Colors.white.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2), 
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 유효/무효 위치 오버레이 표시
                    if (isValid)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    if (isInvalid)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    // 카드 렌더링
                    if (node != null)
                      CardWidget(
                        card: node.card,
                        isRevealed: node.isRevealed,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
