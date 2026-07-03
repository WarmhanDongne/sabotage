import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

/// Final comprehensive test simulating a real game scenario.
/// Uses actual CardDatabase cards and verifies:
/// 1. Wall→Goal rejection for ALL database cards
/// 2. Edge matching for ALL database cards in every orientation
/// 3. Dead-end card placement rules
/// 4. BFS connectivity with goals
/// 5. Rotated card scenarios

int passed = 0;
int failed = 0;

void expect(bool condition, String description) {
  if (condition) {
    passed++;
  } else {
    failed++;
    print('  ❌ FAIL: $description');
  }
}

void main() {
  print('=== Final Real-Game Validation ===\n');

  testAllCardsNearGoal();
  testAllCardsEdgeMatching();
  testDeadEndCardsFromDatabase();
  testRotatedCardsNearGoal();
  testMultiGoalAdjacency();
  testGoalRevealDoesNotBreak();

  print('\n=== Final Results: $passed passed, $failed failed ===');
  if (failed > 0) {
    print('❌ SOME TESTS FAILED');
  } else {
    print('✅ ALL TESTS PASSED - Validator is correct');
  }
}

void testAllCardsNearGoal() {
  print('\n--- Test 1: ALL cards near Goal at (8,3) ---');
  
  final cross = CardDatabase.pathCards.firstWhere(
    (c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Path from start to (7,3), goal at (9,3)
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];
  
  // Position (8,3): left=cross(7,3).right=true, right=goal(9,3) unrevealed
  // Requirements for valid placement:
  //   - left=true (to match cross at (7,3))
  //   - right=true (to open toward goal at (9,3)) 
  //   - Connected to start via tunnel
  
  int validCount = 0;
  int rejectedWallGoal = 0;
  int rejectedWallPath = 0;
  int rejectedNoTunnel = 0;
  
  for (var card in CardDatabase.pathCards) {
    String? error = Validator.getPlacementError(board, card, 8, 3);
    if (error == null) {
      // Should have left=true AND right=true AND connected to start
      expect(card.currentLeft && card.currentRight, 
        '${card.id}: accepted but left=${card.currentLeft} right=${card.currentRight}');
      validCount++;
    } else if (error.contains('도착지점')) {
      // Should have right=false (wall facing goal)
      expect(!card.currentRight,
        '${card.id}: rejected for wall→goal but right=${card.currentRight}');
      rejectedWallGoal++;
    } else if (error.contains('벽/통로가 충돌')) {
      // Should have left=false (wall facing cross)
      expect(!card.currentLeft,
        '${card.id}: rejected for wall/path conflict but left=${card.currentLeft}');
      rejectedWallPath++;
    } else if (error.contains('시작점과 연결')) {
      rejectedNoTunnel++;
    }
  }
  
  print('  Valid: $validCount, WallGoal: $rejectedWallGoal, WallPath: $rejectedWallPath, NoTunnel: $rejectedNoTunnel');
  expect(validCount + rejectedWallGoal + rejectedWallPath + rejectedNoTunnel == CardDatabase.pathCards.length,
    'All ${CardDatabase.pathCards.length} cards accounted for');
  
  // Verify: no card with right=false was accepted (would mean wall facing goal was allowed)
  for (var card in CardDatabase.pathCards) {
    if (!card.currentRight && Validator.canPlaceCard(board, card, 8, 3)) {
      print('  ❌ CRITICAL BUG: ${card.id} has right=false but was allowed next to goal!');
      failed++;
    }
  }
  expect(true, 'No card with wall facing goal was accepted');
}

void testAllCardsEdgeMatching() {
  print('\n--- Test 2: Edge matching for ALL cards below start ---');
  
  // Start card has all directions open
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
  ];
  
  // Position (1,4) below start: start.bottom=true → need currentTop=true
  for (var card in CardDatabase.pathCards) {
    bool canPlace = Validator.canPlaceCard(board, card, 1, 4);
    if (!card.currentTop && canPlace) {
      print('  ❌ BUG: ${card.id} has currentTop=false but placed below start (bottom=true)');
      failed++;
    }
    if (card.currentTop && !canPlace) {
      // Might fail for other reasons (no tunnel connection via dead-end)
      String? error = Validator.getPlacementError(board, card, 1, 4);
      if (error != null && !error.contains('시작점과 연결')) {
        print('  ❌ BUG: ${card.id} has currentTop=true but rejected: $error');
        failed++;
      }
    }
  }
  
  // Position (2,3) right of start: start.right=true → need currentLeft=true
  for (var card in CardDatabase.pathCards) {
    bool canPlace = Validator.canPlaceCard(board, card, 2, 3);
    if (!card.currentLeft && canPlace) {
      print('  ❌ BUG: ${card.id} has currentLeft=false but placed right of start');
      failed++;
    }
  }
  
  expect(true, 'All edge matching verified for positions around start');
}

void testDeadEndCardsFromDatabase() {
  print('\n--- Test 3: Dead-end cards from actual database ---');
  
  final cross = CardDatabase.pathCards.firstWhere(
    (c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  
  // Find all dead-end cards
  final deadEnds = CardDatabase.pathCards.where((c) => !c.hasCenter).toList();
  print('  Found ${deadEnds.length} dead-end cards in database');
  
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
  ];
  
  // Dead-end cards should be placeable directly adjacent if edges match
  for (var de in deadEnds) {
    // At (3,3): left=cross(2,3).right=true → need currentLeft=true
    bool canPlace = Validator.canPlaceCard(board, de, 3, 3);
    bool shouldWork = de.currentLeft; // Must have left opening to match cross
    
    if (canPlace != shouldWork) {
      print('  ❌ Dead-end ${de.id}: expected $shouldWork, got $canPlace');
      print('     L=${de.currentLeft} T=${de.currentTop} R=${de.currentRight} B=${de.currentBottom} center=${de.hasCenter}');
      failed++;
    }
  }
  
  // Cards beyond dead-end should be blocked
  for (var de in deadEnds.where((d) => d.currentLeft)) {
    List<GridNode> boardWithDE = [
      GridNode(x: 1, y: 3, card: CardDatabase.startCard),
      GridNode(x: 2, y: 3, card: de), // Dead-end blocks tunnel
    ];
    
    // (3,3) beyond dead-end → should fail if de.currentRight is true but has no center
    if (de.currentRight) {
      bool canPlaceBeyond = Validator.canPlaceCard(boardWithDE, cross, 3, 3);
      expect(!canPlaceBeyond, 
        'Cannot place beyond dead-end ${de.id} (hasCenter=false blocks tunnel)');
    }
  }
}

void testRotatedCardsNearGoal() {
  print('\n--- Test 4: Rotated cards near goal ---');
  
  final cross = CardDatabase.pathCards.firstWhere(
    (c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
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
  
  // Test all cards in both rotated and non-rotated state
  int normalValid = 0;
  int rotatedValid = 0;
  int normalWallGoal = 0;
  int rotatedWallGoal = 0;
  
  for (var card in CardDatabase.pathCards) {
    // Normal orientation
    String? error = Validator.getPlacementError(board, card, 8, 3);
    if (error == null) normalValid++;
    if (error != null && error.contains('도착지점')) normalWallGoal++;
    
    // Rotated 180°
    final rotated = card.copyWith(isRotated: !card.isRotated);
    error = Validator.getPlacementError(board, rotated, 8, 3);
    if (error == null) rotatedValid++;
    if (error != null && error.contains('도착지점')) rotatedWallGoal++;
    
    // Verify consistency: if right=true in normal, left should be true in rotated
    expect(card.currentRight == rotated.currentLeft,
      '${card.id}: rotation swaps left/right correctly');
    expect(card.currentLeft == rotated.currentRight,
      '${card.id}: rotation swaps right/left correctly');
  }
  
  print('  Normal: $normalValid valid, $normalWallGoal wall→goal');
  print('  Rotated: $rotatedValid valid, $rotatedWallGoal wall→goal');
}

void testMultiGoalAdjacency() {
  print('\n--- Test 5: Card between multiple goals ---');
  
  final cross = CardDatabase.pathCards.firstWhere(
    (c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  final goal = Card(id: 'goal_0', type: CardType.goal);
  
  // Path to (8,2) with goals at (9,1) and (9,3) 
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    GridNode(x: 8, y: 2, card: cross),
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
  ];
  
  // Position (9,2): top=goal(9,1), bottom=goal(9,3), left=cross(8,2)
  // Need: top=true, bottom=true, left=true (all facing goals or matching cross)
  for (var card in CardDatabase.pathCards) {
    bool canPlace = Validator.canPlaceCard(board, card, 9, 2);
    bool shouldWork = card.currentTop && card.currentBottom && card.currentLeft;
    
    if (canPlace && !shouldWork) {
      String? error = Validator.getPlacementError(board, card, 9, 2);
      print('  ❌ BUG: ${card.id} placed at (9,2) but missing required openings');
      print('     T=${card.currentTop} B=${card.currentBottom} L=${card.currentLeft} R=${card.currentRight}');
      failed++;
    }
  }
  
  // Card with top=false (wall facing upper goal) must be rejected
  final noTop = Card(id: 'test', type: CardType.path,
    hasTop: false, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  expect(!Validator.canPlaceCard(board, noTop, 9, 2),
    'Wall facing upper goal rejected between two goals');
  
  // Card with bottom=false (wall facing lower goal) must be rejected
  final noBottom = Card(id: 'test2', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: false, hasLeft: true, hasCenter: true);
  expect(!Validator.canPlaceCard(board, noBottom, 9, 2),
    'Wall facing lower goal rejected between two goals');
    
  // Card with all openings must be accepted
  expect(Validator.canPlaceCard(board, cross, 9, 2),
    'Cross card accepted between two goals');
}

void testGoalRevealDoesNotBreak() {
  print('\n--- Test 6: Revealed goal card edge matching ---');
  
  final cross = CardDatabase.pathCards.firstWhere(
    (c) => c.hasLeft && c.hasTop && c.hasRight && c.hasBottom && c.hasCenter);
  
  // Simulate a revealed goal (gold card with specific paths)
  // 008_cave_action_03 (gold): the actual path layout depends on the card
  // For testing, create a revealed goal with known paths
  final revealedGoal = Card(id: '008_cave_action_03', type: CardType.goal,
    hasTop: true, hasRight: false, hasBottom: true, hasLeft: true, 
    hasCenter: true, isGold: true);
  
  List<GridNode> board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
    GridNode(x: 4, y: 3, card: cross),
    GridNode(x: 5, y: 3, card: cross),
    GridNode(x: 6, y: 3, card: cross),
    GridNode(x: 7, y: 3, card: cross),
    GridNode(x: 8, y: 3, card: cross),
    // Revealed goal at (9,3): left=true, right=false
    GridNode(x: 9, y: 3, card: revealedGoal, isRevealed: true),
  ];
  
  // Place at (10,3): revealed goal has right=false
  // Card with left=true → conflict (path vs wall)
  final withLeft = Card(id: 'test', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  expect(!Validator.canPlaceCard(board, withLeft, 10, 3),
    'Card with left=true rejected next to revealed goal with right=false');
  
  // Card with left=false → wall-wall match, but still needs tunnel connection
  // Revealed goal has right=false → BFS can't go right → no tunnel connection
  final noLeft = Card(id: 'test2', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: false, hasCenter: true);
  expect(!Validator.canPlaceCard(board, noLeft, 10, 3),
    'Card with wall-wall match rejected (no tunnel connection through revealed goal)');
  
  // Place at (9,2): revealed goal has top=true → card needs bottom=true
  final withBottom = Card(id: 'test3', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: true, hasLeft: true, hasCenter: true);
  // Need connection to start: BFS via (8,3)→goal(9,3) revealed with top=true → (9,2)
  // goal has top=true and hasCenter=true → BFS can traverse through it
  expect(Validator.canPlaceCard(board, withBottom, 9, 2),
    'Card above revealed goal accepted (goal.top=true, edges match)');
  
  // Card with bottom=false → conflict (goal.top=true vs card.bottom=false)
  final noBottom = Card(id: 'test4', type: CardType.path,
    hasTop: true, hasRight: true, hasBottom: false, hasLeft: true, hasCenter: true);
  expect(!Validator.canPlaceCard(board, noBottom, 9, 2),
    'Card with bottom=false rejected above revealed goal with top=true');
}
