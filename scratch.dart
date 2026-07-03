import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';
import 'lib/data/models/card.dart';

void main() {
  var board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && c.hasTop && c.hasBottom)),
    GridNode(x: 3, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && !c.hasBottom && c.hasCenter)),
    GridNode(x: 4, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && !c.hasTop && c.hasBottom && c.hasCenter)),
    GridNode(x: 5, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && c.hasTop && c.hasBottom)),
    GridNode(x: 6, y: 3, card: CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasRight && c.hasTop && c.hasBottom)),
    GridNode(x: 7, y: 3, card: CardDatabase.getCardById('005_path_01')!) // A dead-end card
  ];
  var newCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasBottom && c.hasRight && !c.hasTop && c.hasCenter);
  print('Result: ' + (Validator.getPlacementError(board, newCard, 7, 2) ?? 'null'));
}
