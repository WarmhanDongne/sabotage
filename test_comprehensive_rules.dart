import 'lib/data/models/card.dart';
import 'lib/data/models/card_database.dart';
import 'lib/data/models/grid_node.dart';
import 'lib/logic/validator.dart';

/// Comprehensive test for Saboteur card placement rules.
/// 
/// Saboteur Rules for card placement:
/// 1. A path card can only be placed adjacent to at least one existing card.
/// 2. All touching edges must match: path-to-path, wall-to-wall.
///    If one card has a tunnel opening on a side and the adjacent card has a wall on that side, it is INVALID.
/// 3. The new card must be connected via a tunnel path back to the Start card.
///    Dead-end cards (hasCenter=false) block tunnel connectivity.
/// 4. A dead-end card (hasCenter=false) CAN be placed if:
///    - All adjacent edges are compatible (rule 2)
///    - The card itself doesn't need to provide a path through it
///    BUT: it must still be in a connected "network" (even if not a tunnel path)
/// 5. Goal cards that are unrevealed are treated as having all paths open for adjacency checking.

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

// Helper to make cards
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
  print('=== Saboteur Card Placement Rules Test ===\n');

  testRule1_Adjacency();
  testRule2_EdgeMatching();
  testRule3_ConnectedToStart();
  testRule4_DeadEndCards();
  testRule5_GoalCards();
  testRule6_RotatedCards();
  testRule7_ComplexScenarios();

  print('\n=== Results: $passed passed, $failed failed ===');
  if (failed > 0) {
    print('❌ SOME TESTS FAILED');
  } else {
    print('✅ ALL TESTS PASSED');
  }
}

void testRule1_Adjacency() {
  print('\n--- Rule 1: Adjacency ---');
  
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
  ];

  // Cannot place a card that is not adjacent to anything
  final card = makeCard('test', top: true, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(board, card, 5, 5) == false,
    'Cannot place a card with no adjacent cards',
  );

  // Can place adjacent to start card
  expect(
    Validator.canPlaceCard(board, card, 2, 3) == true,
    'Can place a fully-connected card to the right of start',
  );
}

void testRule2_EdgeMatching() {
  print('\n--- Rule 2: Edge Matching ---');
  
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard), // All 4 directions open
  ];

  // Card with all sides open → should work next to start
  final allOpen = makeCard('all_open', top: true, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(board, allOpen, 2, 3) == true,
    'All-open card can be placed right of start (left-right match)',
  );

  // Card with left=false → CANNOT be placed to the right of start (start has right=true, this has left=false → mismatch!)
  final noLeft = makeCard('no_left', top: true, right: true, bottom: true, left: false);
  expect(
    Validator.canPlaceCard(board, noLeft, 2, 3) == false,
    'Card without left opening CANNOT be placed right of start (path-wall collision)',
  );

  // Card with top=false → CANNOT be placed below start (start has bottom=true, this has top=false → mismatch!)
  final noTop = makeCard('no_top', top: false, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(board, noTop, 1, 4) == false,
    'Card without top opening CANNOT be placed below start (path-wall collision)',
  );

  // Card with top=true → CAN be placed below start
  final hasTop = makeCard('has_top', top: true, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(board, hasTop, 1, 4) == true,
    'Card with top opening CAN be placed below start',
  );

  // Wall-wall match: both sides are wall → should be OK IF connected through another path
  // Place a card to the right of start first
  final boardWithRight = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: allOpen),
  ];
  // Now place a card at (2,4) that has top=true (matching allOpen's bottom=true) but left=false
  // Start card has bottom=true, but our card at (1,4) would need top=true, but we're placing at (2,4)
  // At (2,4): neighbor above is allOpen (bottom=true → needs top=true), neighbor left is (1,4)=empty
  final topOnly = makeCard('top_only', top: true, right: false, bottom: false, left: false);
  expect(
    Validator.canPlaceCard(boardWithRight, topOnly, 2, 4) == true,
    'Card with only top opening can be placed below all-open card (wall-wall on other empty sides)',
  );
}

void testRule3_ConnectedToStart() {
  print('\n--- Rule 3: Connected to Start via Tunnel ---');

  // Build a path: start(1,3) → cross(2,3)
  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
  ];

  // Place a card at (3,3) connected via tunnel through cross
  expect(
    Validator.canPlaceCard(board, cross, 3, 3) == true,
    'Card connected to start via continuous tunnel path is valid',
  );

  // Place a dead-end card that blocks the path, then try placing beyond it
  final deadEnd = makeCard('dead_end', top: true, right: true, bottom: true, left: true, center: false);
  final boardWithDeadEnd = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: deadEnd), // Dead end - blocks tunnel
  ];

  // A card at (3,3) touching the dead end: edges match, but tunnel blocked
  // The card IS adjacent and edges match, but there's no tunnel path to start
  // In Saboteur rules, you CAN place a card next to a dead end even without tunnel connectivity
  // But wait - the current implementation requires tunnel connectivity (requireTunnelPath: true in getPlacementError)
  // This is actually WRONG per Saboteur rules! You should be able to place cards that 
  // are physically adjacent with matching edges, even if the tunnel path to start is blocked.
  
  // Actually, let me re-read the rules more carefully...
  // In the original Saboteur game, a path card MUST be placed so that it connects 
  // to the start card through a continuous tunnel. Dead-end cards block this connectivity.
  // So the current rule (requireTunnelPath: true) IS actually correct for the base game.
  
  // Wait, no - in Saboteur, you CAN place a card next to a dead end. The dead end
  // doesn't prevent placement. The rule is that the card must be "connected" to 
  // the network of path cards that traces back to the start - but dead ends don't
  // block this connectivity for placement purposes. Dead ends only matter for 
  // determining if the gold has been reached (win condition).
  
  // Let me verify: In the original Saboteur rules:
  // "A Path Card may only be placed if it 'fits' to adjacent path cards 
  //  (openings touch openings, rocks touch rocks) AND creates a continuous 
  //  path to the Start Card."
  // The key question is: does a dead-end card break the "continuous path" requirement?
  // 
  // In the actual board game: YES, a dead-end card has no center connection,
  // so it does NOT provide a through-path. But you can still PLACE cards next to it
  // because the NEW card might connect to the start through OTHER cards.
  // 
  // The current validator uses requireTunnelPath: true for placement, which means
  // dead-end cards (hasCenter: false) block BFS traversal. This is too strict IF
  // the new card can reach start through an alternative path that doesn't go through
  // the dead end.
  
  // Let me test: dead-end with alternative path available
  final boardWithAlternative = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),          // Through path
    GridNode(x: 2, y: 4, card: cross),          // Alternative route down
    GridNode(x: 3, y: 4, card: cross),          // Alternative route right
    GridNode(x: 3, y: 3, card: deadEnd),         // Dead end at (3,3) blocks through
  ];
  // Place at (4,3): needs left path. Has deadEnd at (3,3) on left which has right=true
  // but dead end blocks tunnel. However, there's NO alternative path to (4,3).
  // So this should fail.
  expect(
    Validator.canPlaceCard(boardWithAlternative, cross, 4, 3) == false,
    'Cannot place card beyond dead end with no alternative tunnel path',
  );

  // Place at (3,4) in alternative scenario: going through (2,4)→(3,4) 
  // This bypasses the dead end entirely
  final boardAlternative2 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 2, y: 4, card: cross),
    GridNode(x: 3, y: 3, card: deadEnd), // Dead end
  ];
  // (3,4): adjacent to (2,4) which has bottom=true, and (3,3) which has bottom=true
  // Tunnel path from (3,4) through (2,4)→(2,3)→(1,3) exists
  expect(
    Validator.canPlaceCard(boardAlternative2, cross, 3, 4) == true,
    'Can place card with alternative tunnel path that bypasses dead end',
  );
}

void testRule4_DeadEndCards() {
  print('\n--- Rule 4: Dead-End Cards ---');

  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
  ];

  // A dead-end card CAN be placed adjacent to start
  // Dead-end cards have all the path openings but hasCenter=false
  // Per Saboteur rules: You CAN place dead-end cards. They just don't provide through-connectivity.
  // But the BFS requirement (requireTunnelPath: true) might block this...
  
  // Actually in Saboteur: placing a dead-end card IS valid. The card is "connected" to start 
  // because it's directly adjacent. The "continuous path" requirement means the card 
  // connects via matching edges, not that there must be a tunnel through each intermediate card.
  
  // Wait, I need to re-analyze this more carefully. Let me check what requireTunnelPath=true does:
  // It skips nodes with hasCenter=false during BFS. So for the new card being placed,
  // if the new card itself has hasCenter=false, and it's placed next to start:
  //   1. BFS starts at start card
  //   2. Traverses to the new card position (matching edges)
  //   3. Found the target → returns true
  // The hasCenter check only prevents TRAVERSAL THROUGH a node, not arrival at it.
  // So placing a dead-end card directly adjacent to start should work fine.
  
  final deadEnd = makeCard('dead_end_all', top: true, right: true, bottom: true, left: true, center: false);
  expect(
    Validator.canPlaceCard(board, deadEnd, 2, 3) == true,
    'Dead-end card CAN be placed directly adjacent to start',
  );

  // But: placing BEYOND a dead-end card should fail (no tunnel through)
  final boardWithDeadEnd = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: deadEnd),
  ];
  final normalCard = makeCard('normal', top: true, right: true, bottom: true, left: true);
  expect(
    Validator.canPlaceCard(boardWithDeadEnd, normalCard, 3, 3) == false,
    'Cannot place card beyond dead-end (no tunnel through dead end)',
  );
}

void testRule5_GoalCards() {
  print('\n--- Rule 5: Goal Card Interaction ---');

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
    // Goal cards (unrevealed)
    GridNode(x: 9, y: 1, card: goal, isRevealed: false),
    GridNode(x: 9, y: 3, card: goal, isRevealed: false),
    GridNode(x: 9, y: 5, card: goal, isRevealed: false),
  ];

  // Unrevealed goal cards should be treated as having all paths open for adjacency
  // So a card with left=false placed at (8,3) should still fail because 
  // (8,3) already has a card... let me place at (9,2) which is between two goals
  // Actually (9,2) is between goal(9,1) and goal(9,3)
  // top neighbor = goal(9,1), bottom neighbor = goal(9,3)
  // Both unrevealed → treated as all paths open
  // The new card needs top=true (to match goal's assumed bottom=true) 
  // and bottom=true (to match goal's assumed top=true)
  
  // But wait, (9,2) needs to be connected to start via tunnel. That requires path through (8,2) or similar.
  // We don't have a card at (8,2). So place at (9,2) should fail for no connection to start.
  
  // Let me test a simpler case: placing a card right next to a goal
  final noLeft = makeCard('no_left', top: true, right: true, bottom: true, left: false);
  // At (8,3), already exists. Let's try adjacent to goal at (9,1):
  // Place at (8,1): top=empty, right=goal(9,1) unrevealed (treated as all open), 
  //   bottom=empty, left=empty
  // But needs connection to start → none exists
  expect(
    Validator.canPlaceCard(board, cross, 8, 1) == false,
    'Cannot place card near goal without tunnel connection to start',
  );
}

void testRule6_RotatedCards() {
  print('\n--- Rule 6: Rotated Cards ---');

  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
  ];

  // Card with top=true, bottom=false. If placed below start, top=true matches start's bottom=true → OK
  final topOnlyCard = makeCard('top_only', top: true, right: false, bottom: false, left: false);
  expect(
    Validator.canPlaceCard(board, topOnlyCard, 1, 4) == true,
    'Non-rotated card with top=true can go below start',
  );

  // Same card rotated 180°: currentTop becomes hasBottom=false, currentBottom becomes hasTop=true
  // So placing below start: currentTop=false doesn't match start's bottom=true → INVALID
  final rotatedCard = topOnlyCard.copyWith(isRotated: true);
  expect(
    rotatedCard.currentTop == false && rotatedCard.currentBottom == true,
    'Rotated card has swapped top/bottom',
  );
  expect(
    Validator.canPlaceCard(board, rotatedCard, 1, 4) == false,
    'Rotated card with currentTop=false CANNOT go below start',
  );

  // But rotated card can go above start (currentBottom=true matches start's top=true)
  expect(
    Validator.canPlaceCard(board, rotatedCard, 1, 2) == true,
    'Rotated card with currentBottom=true CAN go above start',
  );
}

void testRule7_ComplexScenarios() {
  print('\n--- Rule 7: Complex Real-Game Scenarios ---');

  final cross = makeCard('cross', top: true, right: true, bottom: true, left: true);
  // L-shape: top and right only (elbow)
  final elbow_TR = makeCard('elbow_tr', top: true, right: true, bottom: false, left: false);
  // L-shape: bottom and left
  final elbow_BL = makeCard('elbow_bl', top: false, right: false, bottom: true, left: true);
  // T-shape: missing left
  final t_noLeft = makeCard('t_no_left', top: true, right: true, bottom: true, left: false);
  // Straight horizontal
  final straight_H = makeCard('straight_h', top: false, right: true, bottom: false, left: true);
  // Straight vertical
  final straight_V = makeCard('straight_v', top: true, right: false, bottom: true, left: false);

  // Scenario: build a path then try to place a card that would create a wall-path conflict
  final board = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 3, y: 3, card: cross),
  ];

  // Place straight_V at (3,4): top=true matches cross(3,3).bottom=true → OK, connected to start
  expect(
    Validator.canPlaceCard(board, straight_V, 3, 4) == true,
    'Vertical straight below cross is valid',
  );

  // Place straight_H at (3,4): top=false, but cross(3,3) has bottom=true → CONFLICT
  expect(
    Validator.canPlaceCard(board, straight_H, 3, 4) == false,
    'Horizontal straight below cross is INVALID (top=false vs bottom=true of cross)',
  );

  // Place elbow_TR at (4,3): left=false, but cross(3,3) has right=true → CONFLICT
  expect(
    Validator.canPlaceCard(board, elbow_TR, 4, 3) == false,
    'Elbow TR at right of cross is INVALID (left=false vs right=true of cross)',
  );

  // Place t_noLeft at (4,3): left=false, but cross(3,3) has right=true → CONFLICT
  expect(
    Validator.canPlaceCard(board, t_noLeft, 4, 3) == false,
    'T-shape (no left) at right of cross is INVALID (left=false vs right=true)',
  );

  // Place cross at (2,2): top needs to match whatever is above (nothing), left needs to match (1,2)=nothing
  // bottom matches cross(2,3).top=true, right=nothing → OK
  expect(
    Validator.canPlaceCard(board, cross, 2, 2) == true,
    'Cross above existing cross is valid',
  );

  // Scenario: Card between two existing cards - both edges must match
  final board2 = [
    GridNode(x: 1, y: 3, card: CardDatabase.startCard),
    GridNode(x: 2, y: 3, card: cross),
    GridNode(x: 2, y: 2, card: cross),
    GridNode(x: 3, y: 2, card: cross),
    GridNode(x: 3, y: 3, card: cross), // Now (3,3) is surrounded: left=(2,3), top=(3,2)
  ];
  // Try placing straight_H at (3,4): cross(3,3) has bottom=true but straight_H has top=false → CONFLICT
  expect(
    Validator.canPlaceCard(board2, straight_H, 3, 4) == false,
    'Card between existing cards must match ALL touching edges',
  );

  // Multiple adjacent card check: 
  // Place at (3,4) with cross: top=true matches (3,3).bottom=true, left=true but (2,4)=empty → OK
  expect(
    Validator.canPlaceCard(board2, cross, 3, 4) == true,
    'Cross below existing cross works (all adjacent edges match)',
  );
}
