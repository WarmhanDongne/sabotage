import '../data/models/card.dart';
import '../data/models/grid_node.dart';
import 'dart:collection';

class Validator {
  // Goal 카드나 일반 카드의 특정 방향 연결 상태를 반환하는 헬퍼
  static bool _hasEdge(GridNode node, String direction) {
    if (node.card.type == CardType.goal && !node.isRevealed) {
      // 도착지점 카드는 앞면이 공개되기 전까지는 모든 방향이 통로인 것으로 간주
      return true;
    }
    // 공개된 Goal 카드이거나 일반 카드인 경우 실제 통로 속성 반환
    switch (direction) {
      case 'top': return node.card.currentTop;
      case 'bottom': return node.card.currentBottom;
      case 'left': return node.card.currentLeft;
      case 'right': return node.card.currentRight;
      default: return false;
    }
  }

  /// 지정된 (x, y) 위치에 [newCard]를 놓으려 할 때, 규칙을 위반하면 에러 메시지를 반환합니다.
  /// 에러가 없으면 null을 반환합니다.
  static String? getPlacementError(
    List<GridNode> board,
    Card newCard,
    int targetX,
    int targetY,
  ) {
    if (newCard.type != CardType.path) return '굴 카드만 배치할 수 있습니다.';

    // 1. 이미 카드가 놓여있는지 확인
    if (board.any((node) => node.x == targetX && node.y == targetY)) {
      return '이미 카드가 놓여있는 자리입니다.';
    }

    // 2. 인접한 카드와 연결 상태(문)가 일치하는지 엄격히 확인
    //    비공개 Goal 카드 인접 시: Goal 방향으로 반드시 통로가 열려있어야 함.
    //    (벽이 Goal을 향하면 배치 불가)
    bool hasAdjacent = false;

    final topNode = _getNodeAt(board, targetX, targetY - 1);
    final bottomNode = _getNodeAt(board, targetX, targetY + 1);
    final leftNode = _getNodeAt(board, targetX - 1, targetY);
    final rightNode = _getNodeAt(board, targetX + 1, targetY);

    if (topNode != null) {
      if (topNode.card.type == CardType.goal && !topNode.isRevealed) {
        // 비공개 Goal: 규칙상 벽이든 통로든 상관없이 배치 가능
        hasAdjacent = true;
      } else if (_hasEdge(topNode, 'bottom') != newCard.currentTop) {
        return '위쪽 카드와 벽/통로가 충돌합니다.';
      } else {
        hasAdjacent = true;
      }
    }
    if (bottomNode != null) {
      if (bottomNode.card.type == CardType.goal && !bottomNode.isRevealed) {
        // 비공개 Goal: 규칙상 벽이든 통로든 상관없이 배치 가능
        hasAdjacent = true;
      } else if (_hasEdge(bottomNode, 'top') != newCard.currentBottom) {
        return '아래쪽 카드와 벽/통로가 충돌합니다.';
      } else {
        hasAdjacent = true;
      }
    }
    if (leftNode != null) {
      if (leftNode.card.type == CardType.goal && !leftNode.isRevealed) {
        // 비공개 Goal: 규칙상 벽이든 통로든 상관없이 배치 가능
        hasAdjacent = true;
      } else if (_hasEdge(leftNode, 'right') != newCard.currentLeft) {
        return '왼쪽 카드와 벽/통로가 충돌합니다.';
      } else {
        hasAdjacent = true;
      }
    }
    if (rightNode != null) {
      if (rightNode.card.type == CardType.goal && !rightNode.isRevealed) {
        // 비공개 Goal: 규칙상 벽이든 통로든 상관없이 배치 가능
        hasAdjacent = true;
      } else if (_hasEdge(rightNode, 'left') != newCard.currentRight) {
        return '오른쪽 카드와 벽/통로가 충돌합니다.';
      } else {
        hasAdjacent = true;
      }
    }

    // 완전히 동떨어진 곳에는 놓을 수 없음 (최소 하나 이상의 카드와 인접해야 함)
    if (!hasAdjacent) return '적어도 하나의 카드와 인접해야 합니다.';

    // 3. 놓으려는 위치가 시작점(Start Card)으로부터 연결된 굴을 통해 도달 가능한지 BFS로 확인
    List<GridNode> testBoard = List.from(board)..add(GridNode(x: targetX, y: targetY, card: newCard));
    // 막힌 길(hasCenter: false) 너머로는 새 카드를 이어붙일 수 없도록 엄격하게 검증 (옵션 A 통일)
    if (!isConnectedToStart(testBoard, targetX, targetY, requireTunnelPath: true)) {
      return '시작점과 연결된 통로가 없습니다.';
    }

    return null;
  }

  /// 지정된 (x, y) 위치에 [newCard]를 놓을 수 있는지 검증합니다.
  static bool canPlaceCard(
    List<GridNode> board,
    Card newCard,
    int targetX,
    int targetY,
  ) {
    return getPlacementError(board, newCard, targetX, targetY) == null;
  }

  static GridNode? _getNodeAt(List<GridNode> board, int x, int y) {
    try {
      return board.firstWhere((node) => node.x == x && node.y == y);
    } catch (_) {
      return null;
    }
  }

  /// BFS를 사용하여 특정 좌표(x,y)가 시작점(Start)과 연결되어 있는지 확인합니다.
  /// 
  /// [requireTunnelPath]가 false(기본값)이면 카드 배치 검증용:
  ///   - 막힌 카드(hasCenter: false)도 물리적으로 연결된 네트워크의 일부로 인정
  ///   - 인접한 카드 간 입구 일치 여부만 확인하여 체인 형성 검사
  ///
  /// [requireTunnelPath]가 true이면 승리 조건(금 도달) 검사용:
  ///   - 막힌 카드를 통과할 수 없음 (실제 굴이 연결되지 않으므로)
  static bool isConnectedToStart(List<GridNode> board, int targetX, int targetY, {bool requireTunnelPath = false}) {
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

      // 옵션 A 룰 통일: 배치 검증과 승리 조건 모두 막힌 카드(hasCenter: false) 통과 불가
      if (requireTunnelPath && !current.card.hasCenter && current.card.type != CardType.start) {
        continue;
      }

      // 현재 노드가 비공개 Goal인지 확인 (비공개 Goal은 모든 방향으로 탐색 가능)
      final bool isUnrevealedGoal = current.card.type == CardType.goal && 
          board.any((n) => n.x == current.x && n.y == current.y && !n.isRevealed);

      // 인접 노드 탐색
      // 비공개 Goal 카드는 모든 방향이 열린 것으로 취급
      final neighbors = [
        if (isUnrevealedGoal || current.card.currentTop) _getNodeAt(board, current.x, current.y - 1),
        if (isUnrevealedGoal || current.card.currentBottom) _getNodeAt(board, current.x, current.y + 1),
        if (isUnrevealedGoal || current.card.currentLeft) _getNodeAt(board, current.x - 1, current.y),
        if (isUnrevealedGoal || current.card.currentRight) _getNodeAt(board, current.x + 1, current.y),
      ];

      for (var neighbor in neighbors) {
        if (neighbor != null && !visited.contains('${neighbor.x},${neighbor.y}')) {
          // 상대방 굴도 내 쪽으로 열려있어야 함
          // 비공개 Goal 카드는 모든 방향이 열린 것으로 간주
          bool canMove = false;
          final bool isNeighborUnrevealedGoal = neighbor.card.type == CardType.goal &&
              board.any((n) => n.x == neighbor.x && n.y == neighbor.y && !n.isRevealed);

          if (neighbor.x == current.x && neighbor.y == current.y - 1 && (isNeighborUnrevealedGoal || neighbor.card.currentBottom)) canMove = true;
          if (neighbor.x == current.x && neighbor.y == current.y + 1 && (isNeighborUnrevealedGoal || neighbor.card.currentTop)) canMove = true;
          if (neighbor.x == current.x - 1 && neighbor.y == current.y && (isNeighborUnrevealedGoal || neighbor.card.currentRight)) canMove = true;
          if (neighbor.x == current.x + 1 && neighbor.y == current.y && (isNeighborUnrevealedGoal || neighbor.card.currentLeft)) canMove = true;

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

