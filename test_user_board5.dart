import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';
import 'lib/data/models/card.dart';

void main() {
  final startCard = CardDatabase.startCard;
  final cross = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final topLeft = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && !c.hasRight && !c.hasBottom && c.hasCenter);
  final bottomRight = CardDatabase.pathCards.firstWhere((c) => !c.hasLeft && !c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  
  // Here we explicitly simulate the old card which was hasCenter: false
  final bottomLeft = Card(id: '006_path_01', type: CardType.path, hasLeft: true, hasTop: false, hasRight: false, hasBottom: true, hasCenter: false);
  
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

  final goal = Card(id: 'goal_0', type: CardType.goal);
  board.add(GridNode(x: 9, y: 1, card: goal, isRevealed: false));
  board.add(GridNode(x: 9, y: 3, card: goal, isRevealed: false));
  board.add(GridNode(x: 9, y: 5, card: goal, isRevealed: false));
  
  final newCard = CardDatabase.pathCards.firstWhere((c) => c.id == '004_path_04');
  String? error = Validator.getPlacementError(board, newCard, 8, 3);
  print('Error at 8,3 with OLD card state: ' + (error ?? 'null'));
}
