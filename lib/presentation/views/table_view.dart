import 'package:flutter/material.dart';
import '../widgets/board_grid_widget.dart';
import '../../data/models/grid_node.dart';
import '../../data/models/card.dart' as game_card;

/// 호스트(태블릿) 뷰어.
/// 기존 다크모드/커스텀 디자인 완전 폐기.
/// 오리지널 에셋(board.png) 배경 적용 및 Ipad.png 기준의 사이드바/카드 배치 준수.
class TableView extends StatelessWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // 임시 더미 데이터: 시작 카드 1장, 도착 카드 3장
    final List<GridNode> dummyBoard = [
      const GridNode(
        x: 0,
        y: 0,
        card: game_card.Card(id: 'start', type: game_card.CardType.start),
      ),
    ];
    
    final List<GridNode> dummyGoalCards = [
      const GridNode(
        x: 8,
        y: -2,
        card: game_card.Card(id: 'goal1', type: game_card.CardType.goal),
        isRevealed: false,
      ),
      const GridNode(
        x: 8,
        y: 0,
        card: game_card.Card(id: 'goal2', type: game_card.CardType.goal),
        isRevealed: false,
      ),
      const GridNode(
        x: 8,
        y: 2,
        card: game_card.Card(id: 'goal3', type: game_card.CardType.goal),
        isRevealed: false,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. 오리지널 태블릿 배경 (board.png)
          Positioned.fill(
            child: Image.asset(
              'assets/start_the_game/board.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. 메인 게임 보드
          SafeArea(
            child: Row(
              children: [
                // 왼쪽 9x5 보드 영역
                Expanded(
                  flex: 75,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 9열 5행 기준 정사각형 슬롯 크기 계산
                        final cardWidth = constraints.maxWidth / 9;
                        final cardHeight = constraints.maxHeight / 5;
                        final cardSize = cardWidth < cardHeight * 0.7 ? cardWidth : cardHeight * 0.7;

                        return BoardGridWidget(
                          board: dummyBoard,
                          goalCards: dummyGoalCards,
                          cardSize: cardSize,
                        );
                      },
                    ),
                  ),
                ),
                // 오른쪽 사이드바 영역
                Expanded(
                  flex: 25,
                  child: _buildSidebarOverlay(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ipad.png의 오른쪽 사이드바 영역 구조
  Widget _buildSidebarOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 상단 DRAW DECK
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DRAW DECK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[400],
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
              ),
              child: const Text(
                '42 REMAINING',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        
        // 중앙 TURN TIME
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TURN TIME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: 0.6,
                color: Colors.amber,
                strokeWidth: 8,
              ),
            ),
          ],
        ),

        // 하단 DRAW DECK (Discard Pile)
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DISCARD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ],
    );
  }
}
