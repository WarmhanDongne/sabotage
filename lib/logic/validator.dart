import '../data/models/card.dart';
import '../data/models/grid_node.dart';
import 'dart:collection';

class Validator {
  /// 지정된 (x, y) 위치에 [newCard]를 놓을 수 있는지 검증합니다.
  static bool canPlaceCard(
    List<GridNode> board,
    Card newCard,
    int targetX,
    int targetY,
  ) {
    if (newCard.type != CardType.path) return false;

    // 1. 이미 카드가 놓여있는지 확인
    if (board.any((node) => node.x == targetX && node.y == targetY)) {
      return false;
    }

    // 2. 인접한 카드와 연결 상태(문)가 일치하는지 확인
    bool hasAdjacent = false;

    final topNode = _getNodeAt(board, targetX, targetY - 1);
    final bottomNode = _getNodeAt(board, targetX, targetY + 1);
    final leftNode = _getNodeAt(board, targetX - 1, targetY);
    final rightNode = _getNodeAt(board, targetX + 1, targetY);

    if (topNode != null) {
      if (topNode.card.hasBottom != newCard.hasTop) return false;
      hasAdjacent = true;
    }
    if (bottomNode != null) {
      if (bottomNode.card.hasTop != newCard.hasBottom) return false;
      hasAdjacent = true;
    }
    if (leftNode != null) {
      if (leftNode.card.hasRight != newCard.hasLeft) return false;
      hasAdjacent = true;
    }
    if (rightNode != null) {
      if (rightNode.card.hasLeft != newCard.hasRight) return false;
      hasAdjacent = true;
    }

    // 완전히 동떨어진 곳에는 놓을 수 없음 (최소 하나 이상의 카드와 인접해야 함)
    if (!hasAdjacent) return false;

    // 3. 놓으려는 위치가 시작점(Start Card)으로부터 연결된 굴을 통해 도달 가능한지 BFS로 확인
    // (시작점에서 뻗어나간 굴과 이어져야만 카드를 놓을 수 있음)
    // 가상의 보드를 만들어서 테스트
    List<GridNode> testBoard = List.from(board)..add(GridNode(x: targetX, y: targetY, card: newCard));
    return isConnectedToStart(testBoard, targetX, targetY);
  }

  static GridNode? _getNodeAt(List<GridNode> board, int x, int y) {
    try {
      return board.firstWhere((node) => node.x == x && node.y == y);
    } catch (_) {
      return null;
    }
  }

  /// BFS를 사용하여 특정 좌표(x,y)가 시작점(Start)과 굴로 연결되어 있는지 확인합니다.
  static bool isConnectedToStart(List<GridNode> board, int targetX, int targetY) {
    // 시작점 찾기
    final startNode = board.firstWhere(
      (node) => node.card.type == CardType.start,
      orElse: () => throw Exception('Start card not found on board'),
    );

    if (startNode.x == targetX && startNode.y == targetY) return true;

    final queue = Queue<GridNode>();
    final visited = <String>{};

    queue.add(startNode);
    visited.add('${startNode.x},${startNode.y}');

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (current.x == targetX && current.y == targetY) {
        return true;
      }

      // 인접 노드 탐색
      final neighbors = [
        if (current.card.hasTop) _getNodeAt(board, current.x, current.y - 1),
        if (current.card.hasBottom) _getNodeAt(board, current.x, current.y + 1),
        if (current.card.hasLeft) _getNodeAt(board, current.x - 1, current.y),
        if (current.card.hasRight) _getNodeAt(board, current.x + 1, current.y),
      ];

      for (var neighbor in neighbors) {
        if (neighbor != null && !visited.contains('${neighbor.x},${neighbor.y}')) {
          // 상대방 굴도 내 쪽으로 열려있어야 함 (2단계에서 검증하지만 경로 탐색시 한번 더 확인)
          bool canMove = false;
          if (neighbor.x == current.x && neighbor.y == current.y - 1 && neighbor.card.hasBottom) canMove = true;
          if (neighbor.x == current.x && neighbor.y == current.y + 1 && neighbor.card.hasTop) canMove = true;
          if (neighbor.x == current.x - 1 && neighbor.y == current.y && neighbor.card.hasRight) canMove = true;
          if (neighbor.x == current.x + 1 && neighbor.y == current.y && neighbor.card.hasLeft) canMove = true;

          if (canMove) {
            visited.add('${neighbor.x},${neighbor.y}');
            queue.add(neighbor);
          }
        }
      }
    }

    return false;
  }
}
