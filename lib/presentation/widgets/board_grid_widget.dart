import 'package:flutter/material.dart';
import '../../data/models/grid_node.dart';
import 'card_widget.dart';

/// 오리지널 에셋(Ipad.png) 기반 보드 격자 렌더링 위젯.
/// Ipad.png의 9x5 그리드 구조 위에 투명하게 올라가며, 실제 카드가 배치되는 역할을 합니다.
class BoardGridWidget extends StatelessWidget {
  final List<GridNode> board;
  final List<GridNode> goalCards;
  final double cardSize;
  final Set<String>? validOverlayCoords;
  final Set<String>? invalidOverlayCoords;
  final void Function(int x, int y)? onGridTap;

  const BoardGridWidget({
    super.key,
    required this.board,
    required this.goalCards,
    required this.cardSize,
    this.validOverlayCoords,
    this.invalidOverlayCoords,
    this.onGridTap,
  });

  @override
  Widget build(BuildContext context) {
    // 9x5 고정 그리드 렌더링 (Ipad.png 에셋 구조 매칭)
    // 실제 게임 진행 시 범위가 넓어지면 스크롤이 필요할 수 있으나, 
    // 초기 뷰는 오리지널 에셋의 9x5를 기준으로 렌더링합니다.
    const int cols = 9;
    const int rows = 5;
    
    // 시작 카드 위치 보정 (오리지널 이미지는 좌측 중앙쯤에 카드가 있음)
    // 원본 게임에서 시작 카드는 (0,0)이고 목적지 카드는 (8, 0), (8, 2), (8, -2) 식입니다.
    // 여기서는 단순히 9x5 격자를 렌더링합니다.
    const int startX = 0;
    const int startY = -2; // 5행이므로 y는 -2, -1, 0, 1, 2 

    final Map<String, GridNode> boardMap = {
      for (var n in [...board, ...goalCards]) '${n.x},${n.y}': n,
    };

    return SizedBox(
      width: cols * cardSize,
      height: rows * cardSize,
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
      left: col * cardSize,
      top: row * cardSize,
      child: GestureDetector(
        onTap: onGridTap != null ? () => onGridTap!(x, y) : null,
        child: Container(
          width: cardSize,
          height: cardSize,
          // Ipad.png에 이미 그리드가 있으므로 컨테이너 자체는 투명하게 유지.
          // 단, 사용자가 놓을 수 있는 유효/무효 위치일 경우에만 오리지널 톤에 맞는 오버레이 표시.
          decoration: BoxDecoration(
            color: isValid
                ? Colors.green.withOpacity(0.3)
                : (isInvalid ? Colors.red.withOpacity(0.3) : Colors.transparent),
            // 보드 그리드 셀 모서리 둥글게 (오리지널 이미지 기반)
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: node != null
                ? CardWidget(
                    card: node.card,
                    isRevealed: node.isRevealed,
                    size: cardSize,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
