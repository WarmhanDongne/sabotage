
import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final crossroad = CardDatabase.pathCards.firstWhere((c) => c.id == '005_path_02'); // hasLeft, hasTop, hasRight, hasBottom
  final tJunc = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_07'); // hasLeft, hasRight, hasBottom. hasTop: false
  
  final board = [
    GridNode(x: 0, y: 0, card: startCard),
    GridNode(x: 0, y: 1, card: crossroad),
    GridNode(x: 1, y: 1, card: tJunc),
  ];

  final c1 = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_04');
  final c2 = CardDatabase.pathCards.firstWhere((c) => c.id == '005_path_01');

  final err1 = Validator.getPlacementError(board, c1, 0, 2);
  print('Error for 004_path_04 below Crossroad: ');
  
  final err2 = Validator.getPlacementError(board, c2, 0, 2);
  print('Error for 005_path_01 below Crossroad: ');

  final err3 = Validator.getPlacementError(board, c1, 1, 2);
  print('Error for 004_path_04 below T-Junction: ');
}
