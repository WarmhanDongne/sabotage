import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; 
  
  // Test 1: Straight horizontal path
  List<GridNode> board1 = [ GridNode(x: 1, y: 3, card: startCard) ];
  final straightH = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom);
  for(int x = 2; x <= 8; x++) board1.add(GridNode(x: x, y: 3, card: straightH));
  bool res1 = Validator.isConnectedToStart(board1, 8, 3, requireTunnelPath: true);
  
  // Test 2: Path from Top to Left node
  List<GridNode> board2 = [ GridNode(x: 1, y: 3, card: startCard) ];
  for(int x = 2; x <= 8; x++) board2.add(GridNode(x: x, y: 3, card: straightH)); // path to 8,3
  // Wait, let's make a path that goes UP, then RIGHT, then DOWN to 8,3
  List<GridNode> board3 = [ GridNode(x: 1, y: 3, card: startCard) ];
  final elbowUpRight = CardDatabase.pathCards.firstWhere((c) => c.hasBottom && c.hasRight && !c.hasTop && !c.hasLeft && c.hasCenter);
  // Wait, I will just manually create cards to test BFS deeply.
  final allOpen = CardDatabase.startCard; // use start card as a fully open path for testing
  List<GridNode> board4 = [ GridNode(x: 1, y: 3, card: startCard) ];
  for(int x = 2; x <= 8; x++) board4.add(GridNode(x: x, y: 3, card: allOpen));
  bool res4 = Validator.isConnectedToStart(board4, 8, 3, requireTunnelPath: true);
  
  print('Res1: $res1, Res4: $res4');
}
