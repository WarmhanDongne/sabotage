
import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final crossroad = CardDatabase.pathCards.firstWhere((c) => c.id == '005_path_02'); 
  final tJunc = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_07'); 
  
  final board = [
    GridNode(x: 1, y: 3, card: startCard), // Start at (1,3)
    GridNode(x: 1, y: 4, card: crossroad), // Connect down
    GridNode(x: 1, y: 5, card: crossroad), // Connect down
    GridNode(x: 1, y: 6, card: crossroad), // Crossroad at (1,6)
    GridNode(x: 2, y: 6, card: tJunc),     // T-junction at (2,6)
  ];

  final fullBoard = [...board];

  final c1 = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_04');
  final c2 = CardDatabase.pathCards.firstWhere((c) => c.id == '005_path_01');

  final err1 = Validator.getPlacementError(fullBoard, c1, 1, 7);
  print('Error for 004_path_04 below Crossroad (1,7): ');
  
  final err2 = Validator.getPlacementError(fullBoard, c2, 1, 7);
  print('Error for 005_path_01 below Crossroad (1,7): ');

  final err3 = Validator.getPlacementError(fullBoard, c1, 2, 7);
  print('Error for 004_path_04 below T-Junction (2,7): ');
}
