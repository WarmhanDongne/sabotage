import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

/// Test specifically for the bugs the user reported:
/// Cards being placed against Goal/adjacent cards with wall-path conflicts

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

Card makeCard(String id, {
  bool top = false, bool right = false, bool bottom = false, bool left = false, 
  bool center = true, bool isRotated = false,
}) {
  return Card(
    id: id, type: CardType.path,
    hasTop: top, hasRight: right, hasBottom: bottom, hasLeft: left,
    hasCenter: center, isRotated: isRotated,
  );
}

void main() {
  print('=== Bug-Specific Tests ===\n');

  testBug1_GoalAdjacentWallBypass();
  testBug2_GoalAdjacentPlacementRules();
  testBug3_DeadEndPlacementNearGoal();
  testBug4_BFSGoalNodeTraversal();

  print('\n=== Results: $passed passed, $failed failed ===');
  if (failed > 0) {
    print('❌ SOME TESTS FAILED - THESE ARE THE BUGS TO FIX');
  } else {
    print('✅ ALL TESTS PASSED');
  }
}

void testBug1_GoalAdjacentWallBypass() {
  print('\n--- Bug 1: Goal-Adjacent Wall Bypass ---');
  print('   When a card has a wall facing an unrevealed Goal card,');
  print('   it should NOT be allowed (wall blocks the path to goal).\n');

  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Build a path from start to near the goal column
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    // Goal cards
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // BUG: Card with right=false placed at (8,3) — wait, (8,3) already has a card
  // Let me use a different scenario: a card with top=false placed at (9,2)
  // This is between two unrevealed goal cards at (9,1) and (9,3)
  // The new card has top=false → wall faces goal at (9,1)
  // and bottom=false → wall faces goal at (9,3)
  // But we need it connected to start... we don't have path to (9,2)
  
  // Better: place a card at (8,1) with right=false (wall facing goal at (9,1))
  // Need connection to start through (8,3)→(8,2)→(8,1)... no (8,2) exists
  
  // Let me build a path to (8,1):
  final boardToGoal = [
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
    // Goal cards
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];
  
  // At this point, (8,1) has a cross card with right=true, adjacent to goal(9,1)
  // Goal is unrevealed. The current code treats this as connected → that's fine
  // But let me test: a card with right=FALSE at (8,1) would have wall facing goal
  // Since (8,1) already has a card, let me use a modified board:
  
  final boardForGoalTest = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 7, y: 2, card: cross),
    GridNode(x: 7, y: 1, card: cross),
    // Goal cards
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // Place a card at (8,1) with right=false (wall facing goal at (9,1))
  // This card has left=true (matching cross at (7,1).right=true)
  // In Saboteur rules: this should be INVALID because wall faces the goal
  final wallFacingGoal = makeCard('wall_to_goal', 
    top: true, right: false, bottom: true, left: true);
  
  String? error = Validator.getPlacementError(boardForGoalTest, wallFacingGoal, 8, 1);
  print('   Error for wall facing goal: ${error ?? "null (BUG: should be rejected!)"}');
  expect(
    error != null,
    'Card with wall facing unrevealed Goal should be REJECTED',
  );

  // But card with right=true at (8,1) should be fine
  final pathFacingGoal = makeCard('path_to_goal', 
    top: true, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(boardForGoalTest, pathFacingGoal, 8, 1) == true,
    'Card with path facing unrevealed Goal should be ACCEPTED',
  );
}

void testBug2_GoalAdjacentPlacementRules() {
  print('\n--- Bug 2: Goal-Adjacent Edge Checking ---');
  print('   Unrevealed goals should require the new card to have an opening toward them.\n');

  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    // Goals
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // (8,3) is cross, goal is at (9,3)
  // Now place at (9,2): top neighbor = goal(9,1), bottom neighbor = goal(9,3), left neighbor = empty
  // But no tunnel connection to start via (9,2) because we'd need to go through a goal
  // Actually wait: (8,3) is cross with right=true, goal(9,3) is treated as left=true
  // So BFS: start→(2,3)→...→(8,3)→ we try to go right to (9,3) which is goal...
  // In BFS, goal cards may have currentRight=false by default, blocking traversal!
  
  // This is Bug 2: BFS cannot traverse through/to unrevealed goals properly
  // Let me check if placing directly left of goal works with proper connection
  
  // Actually (8,3) already exists and has right=true. (9,3) is goal.
  // Can we reach (9,2) from start? We'd need (8,2) or to go through (9,3).
  // We don't have (8,2), so we can't reach (9,2) from start.
  
  // Let me test the direct adjacency case differently:
  // (8,2) placement: left=true matches (7,3)... no, (7,2) doesn't exist
  // Let's build a path up:
  final board2 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 8, y: 2, card: cross), // go up
    GridNode(x: 8, y: 1, card: cross), // adjacent to goal(9,1) from left
    // Goals
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // (8,1) is cross. (9,1) is unrevealed goal.
  // Now place at (9,2): 
  //   top = goal(9,1) unrevealed
  //   bottom = goal(9,3) unrevealed  
  //   left = (8,2) cross → right=true matches
  //   right = empty
  // Connection to start: BFS from start → ... → (8,2) → (9,2)? 
  // (8,2) has right=true, new card has left=true → match
  // But (8,2) is a cross card, not (8,2)... wait, (8,2) IS in the board.
  // BFS: start → (2,3) → ... → (8,3) → (8,2) → (9,2) if edges match
  // (8,2).right=true → tries (9,2). New card at (9,2).left=true → match → connected!
  
  // Card with top=false at (9,2): wall faces goal(9,1). Should be REJECTED in Saboteur.
  final wallFacingGoal = makeCard('wall_top', top: false, right: false, bottom: false, left: true);
  
  String? error = Validator.getPlacementError(board2, wallFacingGoal, 9, 2);
  print('   Error for wall facing goal at (9,2): ${error ?? "null (BUG!)"}');
  expect(
    error != null,
    'Card with wall facing goal(9,1) and goal(9,3) should be REJECTED',
  );
}

void testBug3_DeadEndPlacementNearGoal() {
  print('\n--- Bug 3: Dead-End Near Goal ---');
  
  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    // Goals
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // Dead-end card with all paths open but no center: can reach start but blocks tunnel
  // Per Saboteur rules: dead-end cards CAN be placed. They just block win condition paths.
  final deadEnd = makeCard('dead_end', top: true, right: true, bottom: true, left: true, center: false);
  // Place dead-end at (8,4): top=true matches cross(8,3).bottom=true, connected to start
  expect(
    Validator.canPlaceCard(board, deadEnd, 8, 4) == true,
    'Dead-end card can be placed adjacent to existing cards',
  );
}

void testBug4_BFSGoalNodeTraversal() {
  print('\n--- Bug 4: BFS Goal Node Traversal ---');
  print('   The BFS uses card.currentTop/Bottom etc. for goal cards,');
  print('   but unrevealed goal Card objects have all directions = false by default.\n');

  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // The default Card constructor for goal cards:
  print('   Goal card default edges: top=${goal.hasTop}, right=${goal.hasRight}, bottom=${goal.hasBottom}, left=${goal.hasLeft}');
  print('   Goal card currentTop: ${goal.currentTop}, currentRight: ${goal.currentRight}');
  
  expect(
    goal.hasTop == false && goal.hasRight == false && goal.hasBottom == false && goal.hasLeft == false,
    'Goal cards have all edges = false by default (this is a problem for BFS!)',
  );

  // In BFS isConnectedToStart, when traversing to a neighbor, it checks:
  //   neighbor.card.currentBottom (for top neighbor)
  // For an unrevealed goal card, this would be FALSE, preventing BFS from
  // recognizing the goal as a valid neighbor. But _hasEdge treats unrevealed goals
  // as having all paths open. This inconsistency means the edge-matching step (step 2)
  // treats goals as fully open, but the BFS step (step 3) may not reach through them.
  
  // This is actually by design in a way - BFS shouldn't go THROUGH goal cards.
  // But it should be able to REACH a goal card position.
  
  // The real bug is in step 2: unrevealed goals bypass edge checking entirely,
  // allowing walls to face goals without error.
}
