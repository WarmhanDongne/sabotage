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
          
          // 2. 메인 게임 보드 (화면 전체 9x5 비율 채우기)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 화면 전체를 9열 5행으로 정확히 나눕니다.
                final cellWidth = constraints.maxWidth / 9;
                final cellHeight = constraints.maxHeight / 5;

                return BoardGridWidget(
                  board: dummyBoard,
                  goalCards: dummyGoalCards,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                );
              },
            ),
          ),

          // 3. 상단 중앙 덱 정보 HUD (스크린샷 매칭)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildTopHUD(),
            ),
          ),
        ],
      ),
    );
  }

  /// 스크린샷 상단 중앙의 하얀 반투명 박스 (남은 카드 개수 등 표시)
  Widget _buildTopHUD() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왼쪽 덱 아이콘 (임시 에셋 연결, 스크린샷의 카드 뒷면 모양)
          Container(
            width: 24,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              image: const DecorationImage(
                image: AssetImage('assets/board_info/010_red/010_red_01.png'), // 임시 카드 뒷면
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 중앙 "X 30" 텍스트
          const Text(
            'X 30',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w300, // 얇은 폰트 스타일
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 32),
          // 오른쪽 달/반달 모양 아이콘 (임시로 Icon 사용)
          const Icon(
            Icons.nightlight_round,
            color: Colors.black,
            size: 28,
          ),
        ],
      ),
    );
  }
}
