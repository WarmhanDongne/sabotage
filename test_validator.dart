import 'dart:io';
import 'lib/data/models/card.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/data/models/card_database.dart';
import 'lib/logic/validator.dart';
import 'dart:collection';

bool canPlaceCardWithLogs(
  List<GridNode> board,
  Card newCard,
  int targetX,
  int targetY,
) {
  print('--- canPlaceCardWithLogs at $targetX, $targetY ---');
  if (newCard.type != CardType.path) {
    print('Failed: not a path card');
    return false;
  }

  // 1. 이미 카드가 놓여있는지 확인
  if (board.any((node) => node.x == targetX && node.y == targetY)) {
    print('Failed: already occupied');
    return false;
  }

  // 2. 인접한 카드와 연결 상태(문)가 일치하는지 확인
  bool hasAdjacent = false;

  GridNode? _getNodeAtLocal(List<GridNode> board, int x, int y) {
    try {
      return board.firstWhere((node) => node.x == x && node.y == y);
    } catch (_) {
      return null;
    }
  }

  final topNode = _getNodeAtLocal(board, targetX, targetY - 1);
  final bottomNode = _getNodeAtLocal(board, targetX, targetY + 1);
  final leftNode = _getNodeAtLocal(board, targetX - 1, targetY);
  final rightNode = _getNodeAtLocal(board, targetX + 1, targetY);

  if (topNode != null) {
    print('Checking topNode: ${topNode.card.id}');
    if (topNode.card.currentBottom != newCard.currentTop) {
      print('Failed: top mismatch');
      return false;
    }
    hasAdjacent = true;
  }
  if (bottomNode != null) {
    print('Checking bottomNode: ${bottomNode.card.id}');
    if (bottomNode.card.currentTop != newCard.currentBottom) {
      print('Failed: bottom mismatch');
      return false;
    }
    hasAdjacent = true;
  }
  if (leftNode != null) {
    print('Checking leftNode: ${leftNode.card.id}');
    if (leftNode.card.currentRight != newCard.currentLeft) {
      print('Failed: left mismatch');
      return false;
    }
    hasAdjacent = true;
  }
  if (rightNode != null) {
    print('Checking rightNode: ${rightNode.card.id}');
    if (rightNode.card.currentLeft != newCard.currentRight) {
      print('Failed: right mismatch');
      return false;
    }
    hasAdjacent = true;
  }

  if (!hasAdjacent) {
    print('Failed: no adjacent');
    return false;
  }
  print('hasAdjacent check passed');

  List<GridNode> testBoard = List.from(board)..add(GridNode(x: targetX, y: targetY, card: newCard));
  bool isConnected = Validator.isConnectedToStart(testBoard, targetX, targetY, requireTunnelPath: true);
  print('isConnectedToStart with requireTunnelPath=true: $isConnected');
  
  bool isConnectedFalse = Validator.isConnectedToStart(testBoard, targetX, targetY, requireTunnelPath: false);
  print('isConnectedToStart with requireTunnelPath=false: $isConnectedFalse');

  return isConnected;
}

void main() {
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.id == '007_path_03')),
  ];
  
  Card newCard = CardDatabase.pathCards.firstWhere((c) => c.id == '006_path_03');
  
  bool result = canPlaceCardWithLogs(board, newCard, 3, 3);
  print('Final Result: $result');
}
