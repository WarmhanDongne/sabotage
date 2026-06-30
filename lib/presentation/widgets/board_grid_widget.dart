import 'package:flutter/material.dart';
import '../../data/models/grid_node.dart';
import '../../data/models/card.dart' as game_card;
import 'card_widget.dart';

/// 보드 격자 전체를 렌더링하는 위젯.
/// InteractiveViewer로 감싸지며 멀티터치 팬/줌을 지원합니다.
/// [board]의 좌표계를 기준으로 카드를 배치하며, 보드 외부 여백도 렌더링합니다.
class BoardGridWidget extends StatelessWidget {
  final List<GridNode> board;
  final List<GridNode> goalCards;
  final double cardSize;

  // Phase 4에서 클라이언트 뷰에서 사용하기 위한 오버레이 세트
  // 호스트 뷰에서는 사용하지 않음 (null)
  final Set<String>? validOverlayCoords;   // "x,y" 형식
  final Set<String>? invalidOverlayCoords;
  final void Function(int x, int y)? onGridTap;

  const BoardGridWidget({
    super.key,
    required this.board,
    required this.goalCards,
    this.cardSize = 64.0,
    this.validOverlayCoords,
    this.invalidOverlayCoords,
    this.onGridTap,
  });

  @override
  Widget build(BuildContext context) {
    // 렌더링 범위 계산: 보드에 놓인 카드의 min/max 좌표 기준으로 확장
    final allNodes = [...board, ...goalCards];
    final int minX, maxX, minY, maxY;

    if (allNodes.isEmpty) {
      minX = -4; maxX = 4; minY = -3; maxY = 3;
    } else {
      minX = allNodes.map((n) => n.x).reduce((a, b) => a < b ? a : b) - 2;
      maxX = allNodes.map((n) => n.x).reduce((a, b) => a > b ? a : b) + 2;
      minY = allNodes.map((n) => n.y).reduce((a, b) => a < b ? a : b) - 2;
      maxY = allNodes.map((n) => n.y).reduce((a, b) => a > b ? a : b) + 2;
    }

    final cols = maxX - minX + 1;
    final rows = maxY - minY + 1;
    final totalWidth = cols * cardSize;
    final totalHeight = rows * cardSize;

    // 보드 노드를 좌표 맵으로 변환 (빠른 검색)
    final Map<String, GridNode> boardMap = {
      for (var n in [...board, ...goalCards]) '${n.x},${n.y}': n,
    };

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        children: [
          // 배경 격자 (모든 격자 셀)
          for (int row = 0; row < rows; row++)
            for (int col = 0; col < cols; col++)
              _buildCell(
                col: col,
                row: row,
                x: minX + col,
                y: minY + row,
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
      child: CardWidget(
        card: node?.card,
        isRevealed: node?.isRevealed ?? true,
        isHighlightedValid: isValid,
        isHighlightedInvalid: isInvalid,
        size: cardSize,
        onTap: onGridTap != null ? () => onGridTap!(x, y) : null,
      ),
    );
  }
}
