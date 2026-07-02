import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; // T:t, B:t, L:t, R:t
  final goalCard = Card(id: '008_cave_action_03', type: CardType.goal, isGold: true);
  
  // We place a straight horizontal path to the left of the goal
  // Let's say start is at (0,0), goal is at (2,0).
  // We place a horizontal path at (1,0).
  final pathCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom);
  
  final board = [
    GridNode(x: 0, y: 0, card: startCard),
    GridNode(x: 1, y: 0, card: pathCard),
  ];
  
  bool isConnected = Validator.isConnectedToStart(board, 1, 0, requireTunnelPath: true);
  print('isConnected: $isConnected');
}
