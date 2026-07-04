import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';
import 'lib/data/models/card.dart';

void main() {
  var goalCards = [
    GridNode(x: 9, y: 1, card: CardDatabase.getCardById('goal_temp')!),
    GridNode(x: 9, y: 3, card: CardDatabase.getCardById('goal_temp')!),
    GridNode(x: 9, y: 5, card: CardDatabase.getCardById('goal_temp')!),
  ];
  
  var board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: CardDatabase.getCardById('007_path_06')!), // T-junction
  ];
  
  var card = CardDatabase.getCardById('007_path_01')!; // 4-way crossroad
  
  int minX = 0, maxX = 11, minY = 0, maxY = 6;
  for (var node in [...board, ...goalCards]) {
    if (node.x < minX) minX = node.x;
    if (node.x > maxX) maxX = node.x;
    if (node.y < minY) minY = node.y;
    if (node.y > maxY) maxY = node.y;
  }
  
  final fullBoard = [...board, ...goalCards];
  Set<String> validCoords = {};
  for (int x = minX - 1; x <= maxX + 1; x++) {
    for (int y = minY - 1; y <= maxY + 1; y++) {
      if (goalCards.any((g) => g.x == x && g.y == y)) continue;
      if (Validator.canPlaceCard(fullBoard, card, x, y)) {
        validCoords.add('$x,$y');
      }
    }
  }
  
  print('minX: $minX, maxX: $maxX, minY: $minY, maxY: $maxY');
  print('validCoords contains (1,4): ${validCoords.contains('1,4')}');
  print('validCoords contains (2,4): ${validCoords.contains('2,4')}');
  print('All validCoords: $validCoords');
}
