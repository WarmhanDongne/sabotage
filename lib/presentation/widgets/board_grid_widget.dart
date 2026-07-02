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
    int minX = 0;
    int maxX = 11;
    int minY = 0;
    int maxY = 6;

    // 현재 놓여진 모든 카드의 좌표를 기준으로 경계 확장
    for (var node in [...board, ...goalCards]) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
    }

    // 유효한 배치 위치가 렌더링되도록 오버레이 좌표도 경계에 포함
    if (validOverlayCoords != null) {
      for (var coord in validOverlayCoords!) {
        final parts = coord.split(',');
        if (parts.length == 2) {
          final px = int.tryParse(parts[0]);
          final py = int.tryParse(parts[1]);
          if (px != null && py != null) {
            if (px < minX) minX = px;
            if (px > maxX) maxX = px;
            if (py < minY) minY = py;
            if (py > maxY) maxY = py;
          }
        }
      }
    }

    final int cols = maxX - minX + 1;
    final int rows = maxY - minY + 1;

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
                x: minX + col,
                y: minY + row,
                boardMap: boardMap,
                minX: minX,
                minY: minY,
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
    required int minX,
    required int minY,
  }) {
    final key = '$x,$y';
    final node = boardMap[key];
    final isValid = validOverlayCoords?.contains(key) ?? false;
    final isInvalid = invalidOverlayCoords?.contains(key) ?? false;

    return Positioned(
      left: (x - minX) * cellWidth,
      top: (y - minY) * cellHeight,
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
                    // 카드 렌더링 (아래)
                    if (node != null)
                      CardWidget(
                        card: node.card,
                        isRevealed: node.isRevealed,
                      ),
                    // 유효/무효 위치 오버레이 표시 (위)
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
