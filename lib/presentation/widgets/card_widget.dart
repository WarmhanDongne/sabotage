import 'package:flutter/material.dart';
import '../../data/models/card.dart' as game_card;

/// 보드판 위에 단일 카드 한 장을 렌더링하는 위젯.
/// 오리지널 에셋(board_info) 이미지를 로드하여 표시합니다.
class CardWidget extends StatelessWidget {
  final game_card.Card? card;
  final bool isRevealed;
  final double size;

  const CardWidget({
    super.key,
    required this.card,
    this.isRevealed = true,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      // 빈 격자: 완전 투명 (Ipad.png에 이미 빈 격자가 그려져 있음)
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          _buildCardImage(),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    // 뒷면 처리 (목적지 등)
    if (!isRevealed) {
      return _buildImage('assets/board_info/010_red/010_red_01.png');
    }

    // 카드 타입에 따른 오리지널 에셋 이미지 매핑 (더미 처리, 실제 로직은 모델 확장 필요)
    String assetPath;
    switch (card!.type) {
      case game_card.CardType.start:
        assetPath = 'assets/board_info/004_path/004_path_01.png'; // 시작 카드와 유사한 에셋
        break;
      case game_card.CardType.goal:
        assetPath = 'assets/board_info/004_path/004_path_03.png'; // 목적지 카드와 유사한 에셋
        break;
      case game_card.CardType.action:
        assetPath = 'assets/board_info/001_action/001_action_01.png';
        break;
      case game_card.CardType.path:
        assetPath = 'assets/board_info/005_path/005_path_01.png';
        break;
      default:
        assetPath = 'assets/board_info/010_red/010_red_01.png';
    }

    return _buildImage(assetPath);
  }

  Widget _buildImage(String path) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6), // Ipad.png의 모서리 라운딩과 유사하게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.brown[700],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}
