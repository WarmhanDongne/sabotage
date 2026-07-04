import '../data/models/card.dart' as game_card;

class CardImageMapper {
  static String getImagePath(game_card.Card card, {bool isRevealed = true}) {
    if (!isRevealed) {
      if (card.type == game_card.CardType.goal) {
        return 'assets/board_info/006_card_back_side/009_cave_sword_02.png'; // 목적지 뒷면
      }
      return 'assets/board_info/006_card_back_side/012_black_01.png'; // 기본 패 뒷면
    }

    return getImagePathById(card.id);
  }

  static String getImagePathById(String cardId) {
    if (cardId.startsWith('003_mixed') || cardId.startsWith('004_path') || cardId.startsWith('005_path') || cardId.startsWith('006_path') || cardId.startsWith('007_path')) {
      // 모든 길 카드가 004_path 폴더 안에 병합되어 있음
      return 'assets/board_info/004_path/$cardId.png';
    } else if (cardId.startsWith('001_action')) {
      return 'assets/board_info/001_action/$cardId.png';
    } else if (cardId == '009_cave_sword_01') {
      return 'assets/board_info/005_start_and_end_point_card/009_cave_sword_01.png';
    } else if (cardId.startsWith('008_cave_action')) {
      // 목적지 카드 (02: 돌, 03: 금, 04: 돌)
      return 'assets/board_info/005_start_and_end_point_card/$cardId.png';
    }
    
    return 'assets/board_info/006_card_back_side/012_black_01.png';
  }
}
