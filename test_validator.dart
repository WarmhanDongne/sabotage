import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final board = [
    GridNode(x: 1, y: 3, card: startCard),
  ];

  // Try placing a card with right & bottom paths below the start card
  // Start card has bottom=true. New card has top=false.
  final newCard = CardDatabase.pathCards.firstWhere((c) => c.id == '006_path_02');
  print('New card: hasTop=${newCard.hasTop}, hasRight=${newCard.hasRight}, hasBottom=${newCard.hasBottom}, hasLeft=${newCard.hasLeft}');

  bool canPlace = Validator.canPlaceCard(board, newCard, 1, 4);
  print('Can place below start card? $canPlace');
}
