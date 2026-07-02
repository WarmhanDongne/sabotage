import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard; // T:t, B:t, L:t, R:t
  final board = [
    GridNode(x: 0, y: 0, card: startCard),
  ];

  final validCard = CardDatabase.pathCards.firstWhere((c) => c.hasTop && !c.hasBottom && !c.hasLeft && !c.hasRight);
  print('Case 1 Valid Place: ${Validator.canPlaceCard(board, validCard, 0, 1)}');

  final invalidCard1 = CardDatabase.pathCards.firstWhere((c) => !c.hasTop && c.hasBottom && !c.hasLeft && !c.hasRight);
  print('Case 2 Path-Wall Collision: ${Validator.canPlaceCard(board, invalidCard1, 0, 1)}');

  board.add(GridNode(x: 0, y: 1, card: validCard));

  final wallTouchCard = CardDatabase.pathCards.firstWhere((c) => !c.hasLeft && c.hasRight && c.hasTop && c.hasBottom);
  print('Case 3 Wall-Wall Touch without path to Start: ${Validator.canPlaceCard(board, wallTouchCard, 1, 1)}');

  final rightPathCard = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasBottom && !c.hasRight && !c.hasTop);
  board.add(GridNode(x: 1, y: 0, card: rightPathCard)); 

  print('Case 4 Path-Path AND Wall-Wall valid connection: ${Validator.canPlaceCard(board, wallTouchCard, 1, 1)}');
}
