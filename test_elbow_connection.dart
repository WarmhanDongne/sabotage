import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final crossCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  // ㄱ-shaped card (Bottom-Right elbow)
  final elbowCard = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_01');
  
  // Board setup mimicking the user's board somewhat
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: startCard),
    GridNode(x: 2, y: 3, card: crossCard),
    GridNode(x: 3, y: 3, card: crossCard),
    // Elbow going UP
    GridNode(x: 4, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_09')), // Top-Left elbow
    // ㄱ-shaped card above it, path comes from DOWN, goes RIGHT
    GridNode(x: 4, y: 2, card: elbowCard),
  ];

  // User wants to place a cross card to the right of the ㄱ-shaped card (at x=5, y=2)
  bool canPlace = Validator.canPlaceCard(board, crossCard, 5, 2);
  print('Can place cross card to the right of ㄱ-shaped card: $canPlace');
  
  String? error = Validator.getPlacementError(board, crossCard, 5, 2);
  if (error != null) {
    print('Error: $error');
  }
}
