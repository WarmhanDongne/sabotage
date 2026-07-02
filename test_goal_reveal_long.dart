import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; 
  
  // Create a board with start at (1,3)
  final board = [
    GridNode(x: 1, y: 3, card: startCard),
  ];
  
  // We need to build a path to (8,3) to be the "left" of the goal at (9,3).
  // A straight horizontal path is 004_path_01 (hasLeft: false, hasRight: true, hasTop: false, hasBottom: true) -> wait, we need straight.
  // '006_path_02' hasLeft: false, hasRight: true, hasBottom: true.
  // Let's just find a card with L: true, R: true, T: false, B: false
  final straightCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom);
  
  for(int x = 2; x <= 8; x++) {
    board.add(GridNode(x: x, y: 3, card: straightCard));
  }
  
  bool isConnected = Validator.isConnectedToStart(board, 8, 3, requireTunnelPath: true);
  print('isConnected to 8,3: $isConnected');
}
