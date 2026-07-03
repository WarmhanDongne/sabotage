import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

/// Edge-case test for the fixed validator focusing on:
/// 1. Cards using actual CardDatabase entries (real game cards)
/// 2. Dead-end cards near goals
/// 3. All possible Goal-adjacent placement scenarios
/// 4. BFS traversal through revealed vs unrevealed goals

int passed = 0;
int failed = 0;

void expect(bool condition, String description) {
  if (condition) {
    passed++;
    print('  ✅ $description');
  } else {
    failed++;
    print('  ❌ FAIL: $description');
  }
}

void main() {
  print('=== Edge Case Tests for Fixed Validator ===\n');

  testActualCardDatabase();
  testGoalEdgeCases();
  testDeadEndNearGoal();
  testBFSThroughGoals();
  testRevealedGoalCards();
  testWallOnlyCardNearGoal();

  print('\n=== Results: $passed passed, $failed failed ===');
  if (failed > 0) {
    print('❌ SOME TESTS FAILED');
  } else {
    print('✅ ALL TESTS PASSED');
  }
}

void testActualCardDatabase() {
  print('\n--- Actual CardDatabase Cards ---');
  
  final cross = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Build a path from start (1,3) to right near goals
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    // Goal cards at (9,1), (9,3), (9,5) 
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];
  
  // Iterate all path cards and test which can be placed at key positions
  int validAt8_2 = 0;
  int validAt8_4 = 0;
  
  for (var card in CardDatabase.pathCards) {
    // At (8,2): left neighbor is nothing, bottom neighbor is cross(8,3)
    // top neighbor is nothing, right neighbor is nothing
    // Must have: bottom=true (to match cross.top=true... wait (8,2) is ABOVE (8,3))
    // (8,2) top neighbor = nothing, bottom neighbor = (8,3) cross
    // cross at (8,3) has top=true → new card must have bottom=true
    // Connected to start via (8,3)→...→start
    if (Validator.canPlaceCard(board, card, 8, 2)) validAt8_2++;
    if (Validator.canPlaceCard(board, card, 8, 4)) validAt8_4++;
  }
  
  print('  Cards that can go at (8,2): $validAt8_2');
  print('  Cards that can go at (8,4): $validAt8_4');
  
  // No card with bottom=false should be valid at (8,2) because cross(8,3).top=true
  for (var card in CardDatabase.pathCards) {
    if (!card.currentBottom && Validator.canPlaceCard(board, card, 8, 2)) {
      print('  ❌ BUG: ${card.id} has bottom=false but was allowed at (8,2)');
      failed++;
    }
    if (!card.currentTop && Validator.canPlaceCard(board, card, 8, 4)) {
      print('  ❌ BUG: ${card.id} has top=false but was allowed at (8,4)');
      failed++;
    }
  }
  
  expect(true, 'Verified all path cards respect edge matching at (8,2) and (8,4)');
}

void testGoalEdgeCases() {
  print('\n--- Goal Edge Cases: Every Direction ---');
  
  final cross = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Test 1: Card to LEFT of goal, wall facing right (toward goal)
  List<GridNode> board1 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
  ];

  // 004_path_09: L-R, T has left and top but NOT right
  final cardNoRight = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && !c.hasRight && !c.hasBottom && c.hasCenter);
  expect(
    !Validator.canPlaceCard(board1, cardNoRight, 8, 3), // wait, (8,3) already has cross
    'Position (8,3) already occupied',
  );

  // Test 2: Card BELOW goal, wall facing top (toward goal)
  List<GridNode> board2 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 8, y: 4, card: cross),
    GridNode(x: 8, y: 5, card: cross),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];
  // Place at (9,6) below goal(9,5): needs top=true to face goal
  final cardNoTop = CardDatabase.pathCards.firstWhere((c) => !c.hasTop && c.hasRight && c.hasBottom && !c.hasLeft && c.hasCenter);
  
  // But (9,6) is not connected to start unless we go through goal(9,5)
  // Let's also add (8,6) to have a path not through goal
  List<GridNode> board2b = List.from(board2)..add(GridNode(x: 8, y: 6, card: cross));
  
  // cardNoTop at (9,6): left=(8,6)cross.right=true, new card.left=false → CONFLICT!
  // Let's try a card with left=true but top=false
  final cardNoTopWithLeft = Card(id: 'test_no_top', type: CardType.path, 
    hasTop: false, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  
  String? error = Validator.getPlacementError(board2b, cardNoTopWithLeft, 9, 6);
  expect(
    error != null && error.contains('도착지점'),
    'Card with wall facing goal from below should be REJECTED: ${error ?? "null"}',
  );

  // Test 3: Card ABOVE goal, wall facing bottom
  List<GridNode> board3 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 7, y: 2, card: cross),
    GridNode(x: 7, y: 1, card: cross),
    GridNode(x: 8, y: 1, card: cross),
    GridNode(x: 8, y: 0, card: cross),
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
  ];
  // Place at (9,0) above goal(9,1): needs bottom=true to face goal
  final cardNoBottom = Card(id: 'test_no_bottom', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: false, hasLeft: true, hasCenter: true);
  
  // (9,0): bottom=goal(9,1), left=(8,0)=cross 
  error = Validator.getPlacementError(board3, cardNoBottom, 9, 0);
  expect(
    error != null && error.contains('도착지점'),
    'Card with wall facing goal from above should be REJECTED: ${error ?? "null"}',
  );
}

void testDeadEndNearGoal() {
  print('\n--- Dead-End Cards Near Goal ---');
  
  final cross = CardDatabase.pathCards.firstWhere((c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
  ];

  // Dead-end card with all paths open BUT hasCenter=false → tunnels don't connect through
  // Should still be placeable (dead-end cards ARE valid in Saboteur)
  final deadEnd = Card(id: 'dead_end', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: false);
  
  expect(
    Validator.canPlaceCard(board, deadEnd, 8, 3) == true,
    'Dead-end card with all openings CAN be placed adjacent to goal',
  );

  // Dead-end card with wall facing goal → should be rejected
  final deadEndWallGoal = Card(id: 'dead_end_wall', type: CardType.path,
    hasTop: true, hasRight: false, hasBottom: true, hasLeft: true, hasCenter: false);
  
  expect(
    Validator.canPlaceCard(board, deadEndWallGoal, 8, 3) == false,
    'Dead-end card with wall facing goal should be REJECTED',
  );

  // Use actual dead-end cards from database
  for (var card in CardDatabase.pathCards.where((c) => !c.hasCenter)) {
    bool canPlace = Validator.canPlaceCard(board, card, 8, 3);
    // At (8,3): left=(7,3)cross.right=true, right=goal(9,3) unrevealed
    // Need: left=true (to match cross), right=true (to face goal)
    bool shouldBeValid = card.currentLeft && card.currentRight;
    if (canPlace != shouldBeValid) {
      print('  ❌ Dead-end ${card.id}: expected ${shouldBeValid}, got $canPlace');
      print('     L=${card.currentLeft} T=${card.currentTop} R=${card.currentRight} B=${card.currentBottom}');
      failed++;
    }
  }
  expect(true, 'All dead-end cards validated correctly near goal');
}

void testBFSThroughGoals() {
  print('\n--- BFS Traversal Through Unrevealed Goals ---');
  
  final cross = Card(id: 'cross', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Scenario: Can we reach a position that requires going THROUGH an unrevealed goal?
  // In Saboteur, you shouldn't normally need to traverse through a goal card,
  // but the BFS should handle this correctly.
  
  // Board: start(1,3) → cross path to (8,3) → goal(9,3)
  // Try to place at (10,3): would need to go through goal(9,3)
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
  ];
  
  // In the real game, you can't place cards beyond goals (they're the end of the line)
  // But technically, the validator should handle this: (10,3) adjacent to goal(9,3)
  // BFS needs to go: start→...→(8,3)→goal(9,3)→(10,3)
  // With our fix, unrevealed goals are traversable
  expect(
    Validator.canPlaceCard(board, cross, 10, 3) == true,
    'Can place card beyond unrevealed goal (BFS traverses through goal)',
  );

  // Verify start connectivity works for positions between goals
  // board with path going up to (8,1) and goal at (9,1) unrevealed
  List<GridNode> board2 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 8, y: 2, card: cross),
    GridNode(x: 8, y: 1, card: cross),
    // Goals
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];
  
  // Place at (9,2) between two goals: top=goal(9,1), bottom=goal(9,3), left=(8,2)
  // Need all three edges to match. Goals are unrevealed → require opening toward them
  expect(
    Validator.canPlaceCard(board2, cross, 9, 2) == true,
    'Cross card between two goals is valid (all openings face goals)',
  );
  
  // Card with top=false between goals: wall faces goal(9,1)
  final noTop = Card(id: 'no_top', type: CardType.path,
    hasTop: false, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  expect(
    Validator.canPlaceCard(board2, noTop, 9, 2) == false,
    'Card with wall facing upper goal is REJECTED',
  );
}

void testRevealedGoalCards() {
  print('\n--- Revealed Goal Cards ---');
  
  final cross = Card(id: 'cross', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  
  // Revealed gold goal card: has actual path definitions
  final revealedGold = Card(id: '008_cave_action_03', type: CardType.goal,
    hasTop: true, hasRight: false, hasBottom: true, hasLeft: true, hasCenter: true, isGold: true);
  
  // Board with revealed goal
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 9, y: 3, card: revealedGold, isRevealed: true),
  ];
  
  // Place to the right of revealed goal: goal has right=false → wall
  // Card with left=true would conflict (path-wall)
  final cardWithLeft = Card(id: 'test_left', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  
  expect(
    Validator.canPlaceCard(board, cardWithLeft, 10, 3) == false,
    'Card with left opening CANNOT be placed right of revealed goal with right=false',
  );
  
  // Card with left=false → wall-wall match
  final cardNoLeft = Card(id: 'test_no_left', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: false, hasCenter: true);
  
  // But does it connect to start? BFS: start→...→(8,3)→goal(9,3) → (10,3)?
  // goal(9,3) is revealed with right=false → BFS can't go right from goal
  // So (10,3) would not be connected via tunnel to start
  expect(
    Validator.canPlaceCard(board, cardNoLeft, 10, 3) == false,
    'Card with wall-wall match but no tunnel connection is also REJECTED',
  );
}

void testWallOnlyCardNearGoal() {
  print('\n--- Wall-Only Side Facing Goal ---');
  
  final cross = Card(id: 'cross', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
  ];
  
  // Count how many cards from database can go at (8,3)
  // Requirements: left=true (match cross.right), right=true (opening toward goal)
  // Must be connected to start via tunnel
  int totalValid = 0;
  int totalInvalidWallGoal = 0;
  int totalInvalidWallPath = 0;
  int totalInvalidNoPath = 0;
  
  for (var card in CardDatabase.pathCards) {
    String? error = Validator.getPlacementError(board, card, 8, 3);
    if (error == null) {
      totalValid++;
    } else if (error.contains('도착지점')) {
      totalInvalidWallGoal++;
    } else if (error.contains('벽/통로가 충돌')) {
      totalInvalidWallPath++;
    } else if (error.contains('시작점과 연결')) {
      totalInvalidNoPath++;
    }
  }
  
  print('  At position (8,3) next to goal:');
  print('    Valid placements: $totalValid');
  print('    Rejected (wall facing goal): $totalInvalidWallGoal');
  print('    Rejected (wall/path conflict): $totalInvalidWallPath');
  print('    Rejected (no path to start): $totalInvalidNoPath');
  
  expect(totalInvalidWallGoal > 0, 'Some cards are rejected for wall facing goal');
  expect(totalValid > 0, 'Some cards are valid near goal');
  expect(totalInvalidWallGoal + totalInvalidWallPath + totalInvalidNoPath + totalValid == CardDatabase.pathCards.length,
    'All cards accounted for');
}
