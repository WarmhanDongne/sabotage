import 'package:flutter/material.dart';
import '../widgets/board_grid_widget.dart';
import '../../data/models/grid_node.dart';
import '../../data/models/card.dart' as game_card;

/// 호스트(태블릿) 뷰어.
/// 기존 다크모드/커스텀 디자인 완전 폐기.
/// 오리지널 에셋(board.png) 배경 적용 및 Ipad.png 기준의 사이드바/카드 배치 준수.
class TableView extends StatefulWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  // 실제 게임 플레이 시 통신을 통해 업데이트되어야 할 상태값입니다.
  int _remainingCards = 30;

  // 카드 더미를 탭했을 때 카드가 줄어드는 것을 시뮬레이션하기 위한 임시 함수
  void _simulateDrawCard() {
    if (_remainingCards > 0) {
      setState(() {
        _remainingCards--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 12x7 그리드 기준: 시작은 (1, 3), 도착은 (9, 1), (9, 3), (9, 5)
    final List<GridNode> dummyBoard = [
      const GridNode(
        x: 1,
        y: 3,
        card: game_card.Card(id: 'start', type: game_card.CardType.start),
      ),
    ];
    
    final List<GridNode> dummyGoalCards = [
      const GridNode(
        x: 9,
        y: 1,
        card: game_card.Card(id: 'goal1', type: game_card.CardType.goal),
        isRevealed: false,
      ),
      const GridNode(
        x: 9,
        y: 3,
        card: game_card.Card(id: 'goal2', type: game_card.CardType.goal),
        isRevealed: false,
      ),
      const GridNode(
        x: 9,
        y: 5,
        card: game_card.Card(id: 'goal3', type: game_card.CardType.goal),
        isRevealed: false,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1 & 2. 원본 비율을 유지하는 게임 보드 영역
          // board.png의 원본 해상도(1366x1107) 비율을 강제로 유지하여, 
          // 크롬 같이 가로로 긴 화면에서도 그리드가 정사각형으로 찌그러지지 않고 원래의 세로형 직사각형 모양을 유지하게 합니다.
          Center(
            child: AspectRatio(
              aspectRatio: 1393 / 1129,
              child: Stack(
                children: [
                  // 배경 이미지
                  Positioned.fill(
                    child: Image.asset(
                      'assets/phone_info/basic_image.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  
                  // 보드 격자
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 새 배경 이미지 전체를 12x7 가상 그리드로 꽉 채워서 사용합니다.
                      final double leftPercent = 0.0;
                      final double topPercent = 0.0;
                      final double widthPercent = 1.0;
                      final double heightPercent = 1.0;

                      final gridWidth = constraints.maxWidth * widthPercent;
                      final gridHeight = constraints.maxHeight * heightPercent;
                      final cellWidth = gridWidth / 12;
                      final cellHeight = gridHeight / 7;

                      return Stack(
                        children: [
                          Positioned(
                            left: constraints.maxWidth * leftPercent,
                            top: constraints.maxHeight * topPercent,
                            width: gridWidth,
                            height: gridHeight,
                            child: BoardGridWidget(
                              board: dummyBoard,
                              goalCards: dummyGoalCards,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
    return GestureDetector(
      onTap: _simulateDrawCard, // 테스트를 위해 탭 시 카드 줄어듦 구현
      child: Container(
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
            // 왼쪽 덱 아이콘 (사용자가 첨부한 012_black_01.png 에셋 매핑)
            Container(
              width: 24,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                image: const DecorationImage(
                  image: AssetImage('assets/board_info/012_black/012_black_01.png'), // 블랙 에셋
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 중앙 "X 30" 텍스트 (상태 연동)
            Text(
              'X $_remainingCards',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w300, // 얇은 폰트 스타일
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 32),
            // 오른쪽 달/반달 모양 아이콘
            const Icon(
              Icons.nightlight_round,
              color: Colors.black,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
