import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; 
  
  // Board setup
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: startCard),
  ];
  
  final straightCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom);
  
  // Add path from 2,3 to 7,3
  for(int x = 2; x <= 7; x++) {
    board.add(GridNode(x: x, y: 3, card: straightCard));
  }
  
  // Goal cards
  List<GridNode> goalCards = [
    GridNode(x: 9, y: 3, card: Card(id: '008_cave_action_03', type: CardType.goal, isGold: true), isRevealed: false)
  ];
  
  // Now simulate playPathCard at 8,3
  int targetX = 8;
  int targetY = 3;
  Card newCard = straightCard;
  
  // 1. Validator check
  final fullBoard = [...board, ...goalCards];
  bool canPlace = Validator.canPlaceCard(fullBoard, newCard, targetX, targetY);
  print('Can place at 8,3: $canPlace');
  
  if (canPlace) {
    List<GridNode> newBoard = List.from(board)..add(GridNode(x: targetX, y: targetY, card: newCard));
    
    // 2. Reveal check
    for (int i = 0; i < goalCards.length; i++) {
        final goal = goalCards[i];
        if (!goal.isRevealed) {
          bool isConnected = false;

          // 위쪽 검사
          final topNodeIdx = newBoard.indexWhere((n) => n.x == goal.x && n.y == goal.y - 1);
          if (topNodeIdx != -1 && newBoard[topNodeIdx].card.currentBottom) {
             if (Validator.isConnectedToStart(newBoard, goal.x, goal.y - 1, requireTunnelPath: true)) isConnected = true;
          }
          // 아래쪽 검사
          final bottomNodeIdx = newBoard.indexWhere((n) => n.x == goal.x && n.y == goal.y + 1);
          if (!isConnected && bottomNodeIdx != -1 && newBoard[bottomNodeIdx].card.currentTop) {
             if (Validator.isConnectedToStart(newBoard, goal.x, goal.y + 1, requireTunnelPath: true)) isConnected = true;
          }
          // 왼쪽 검사
          final leftNodeIdx = newBoard.indexWhere((n) => n.x == goal.x - 1 && n.y == goal.y);
          if (!isConnected && leftNodeIdx != -1 && newBoard[leftNodeIdx].card.currentRight) {
             if (Validator.isConnectedToStart(newBoard, goal.x - 1, goal.y, requireTunnelPath: true)) isConnected = true;
          }
          // 오른쪽 검사
          final rightNodeIdx = newBoard.indexWhere((n) => n.x == goal.x + 1 && n.y == goal.y);
          if (!isConnected && rightNodeIdx != -1 && newBoard[rightNodeIdx].card.currentLeft) {
             if (Validator.isConnectedToStart(newBoard, goal.x + 1, goal.y, requireTunnelPath: true)) isConnected = true;
          }

          print('isConnected to goal at ${goal.x},${goal.y}: $isConnected');
        }
    }
  }
}
