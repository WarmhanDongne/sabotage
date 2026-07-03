import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final cross = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final topLeft = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && !c.hasRight && !c.hasBottom && c.hasCenter);
  final bottomRight = CardDatabase.pathCards.firstWhere((c) => !c.hasLeft && !c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final bottomLeft = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && !c.hasTop && !c.hasRight && c.hasBottom && c.hasCenter);
  
  // T-shape (Top, Bottom, Right). Left is rock.
  final newCard = CardDatabase.pathCards.firstWhere((c) => !c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);

  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: topLeft),
    GridNode(x: 7, y: 2, card: bottomRight),
    GridNode(x: 8, y: 2, card: bottomLeft),
  ];

  // Trying to place newCard at 8,3
  String? error = Validator.getPlacementError(board, newCard, 8, 3);
  print('Error at 8,3: $error');
}
