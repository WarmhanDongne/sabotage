import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; 
  final straightH = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom);
  
  // Create a board with a path from 1,3 to 8,3
  List<GridNode> board = [ GridNode(x: 1, y: 3, card: startCard) ];
  for(int x = 2; x <= 8; x++) {
    board.add(GridNode(x: x, y: 3, card: straightH));
  }
  
  // Test if 8,3 is connected
  bool res = Validator.isConnectedToStart(board, 8, 3, requireTunnelPath: true);
  print('Is 8,3 connected? $res'); // Should be true

  // Now, what if we have a T-junction at 8,3?
  final tJunction = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasBottom && !c.hasRight);
  board[7] = GridNode(x: 8, y: 3, card: tJunction);
  
  bool res2 = Validator.isConnectedToStart(board, 8, 3, requireTunnelPath: true);
  print('Is 8,3 (T-junction) connected? $res2'); // Should be true
}
