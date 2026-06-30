import 'package:flutter/material.dart';
import '../widgets/board_grid_widget.dart';

/// 호스트(태블릿) 뷰어.
/// 기존 다크모드/커스텀 디자인 완전 폐기.
/// 오리지널 에셋(Ipad.png)의 톤앤매너와 구조(9x5 대리석 보드 + 반투명 다크 사이드바) 100% 준수.
class TableView extends StatelessWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 오리지널 태블릿 배경 (Ipad.png)
          Positioned.fill(
            child: Image.asset(
              'assets/start_the_game/Ipad.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. 메인 게임 보드 (대리석 배경 위에 올려질 실제 카드들)
          // Ipad.png 이미지 자체에 이미 그리드가 그려져 있으므로,
          // 여기서는 그 그리드 비율에 맞게 카드들이 배치되도록 렌더링해야 함.
          // 편의상 InteractiveViewer로 감싸서 사용자가 패닝/줌 할 수 있게 하되,
          // 배경 이미지와의 정렬을 위해 배경 이미지 자체를 InteractiveViewer 안에 넣는 것이 이상적일 수 있음.
          // 하지만 Ipad.png에는 사이드바(DRAW DECK 등)도 포함되어 있으므로, 
          // 뷰포트 내에 9x5 그리드를 Ipad.png의 왼쪽 보드 영역에 맞춰 렌더링합니다.
          SafeArea(
            child: Row(
              children: [
                // 왼쪽 9x5 보드 영역
                Expanded(
                  flex: 75, // 대략 Ipad.png의 75%가 보드 영역
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 9열 5행 기준 정사각형 슬롯 크기 계산
                        final cardWidth = constraints.maxWidth / 9;
                        final cardHeight = constraints.maxHeight / 5;
                        final cardSize = cardWidth < cardHeight * 0.7 ? cardWidth : cardHeight * 0.7; // 카드 비율 약 1:1.5 고려 (하지만 보드 타일은 정사각형에 가까움)

                        return BoardGridWidget(
                          board: const [], // TODO: 실제 보드 상태 연결
                          goalCards: const [],
                          cardSize: cardSize,
                          // Ipad.png의 타일 비율 및 라운딩 스펙을 BoardGridWidget 내부에서 적용
                        );
                      },
                    ),
                  ),
                ),
                // 오른쪽 사이드바 영역 (Ipad.png에 이미 그려져 있으므로 투명하게 유지하며 터치 영역만 배치할 수도 있으나,
                // 동적 텍스트(예: 42 REMAINING) 렌더링을 위해 투명 위젯 레이어를 올림)
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

  /// Ipad.png의 오른쪽 사이드바 영역 위에 얹어질 동적 데이터 오버레이
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
              ),
            ),
            const SizedBox(height: 12),
            // 동적 덱 남은 수량 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[400],
                borderRadius: BorderRadius.circular(4),
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
              ),
            ),
            SizedBox(height: 16),
            // 임시 진행 타이머 (Ipad.png에 그려진 노란 링 위에 위치)
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
              ),
            ),
            SizedBox(height: 80), // 카드 렌더링 공간
          ],
        ),
      ],
    );
  }
}
