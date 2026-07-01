import '../data/models/card.dart' as game_card;

class CardImageMapper {
  static String getImagePath(game_card.Card card, {bool isRevealed = true}) {
    if (!isRevealed) {
      if (card.type == game_card.CardType.goal) {
        return 'assets/board_info/009_cave_sword/009_cave_sword_02.png'; // 목적지 뒷면 에셋
      }
      return 'assets/board_info/009_cave_sword/009_cave_sword_03.png'; // 기본 임시 뒷면
    }

    if (card.type == game_card.CardType.path) {
      return _getPathImage(card);
    } else if (card.type == game_card.CardType.action) {
      if (card.actionType == game_card.ActionType.breakPickaxe || card.actionType == game_card.ActionType.breakLantern || card.actionType == game_card.ActionType.breakCart) {
        return 'assets/board_info/001_action/001_action_01.png';
      } else if (card.actionType == game_card.ActionType.fixPickaxe || card.actionType == game_card.ActionType.fixLantern || card.actionType == game_card.ActionType.fixCart) {
        return 'assets/board_info/001_action/001_action_05.png'; // 수리
      } else if (card.actionType == game_card.ActionType.map) {
        return 'assets/board_info/008_cave_action/008_cave_action_01.png';
      } else if (card.actionType == game_card.ActionType.rockfall) {
        return 'assets/board_info/008_cave_action/008_cave_action_03.png';
      }
      return 'assets/board_info/001_action/001_action_01.png';
    } else if (card.type == game_card.CardType.goal) {
      if (card.isGold == true) {
        return 'assets/board_info/009_cave_sword/009_cave_sword_03.png'; // 실제 에셋
      } else {
        return 'assets/board_info/009_cave_sword/009_cave_sword_04.png'; 
      }
    } else if (card.type == game_card.CardType.start) {
      return 'assets/board_info/009_cave_sword/009_cave_sword_01.png';
    }

    return 'assets/board_info/010_red/010_red_01.png'; // 기본 fallback
  }

  // 연결 형태에 따라 임의의 길 이미지 반환
  static String _getPathImage(game_card.Card card) {
    int shapeHash = (card.hasTop ? 1 : 0) + (card.hasRight ? 2 : 0) + (card.hasBottom ? 4 : 0) + (card.hasLeft ? 8 : 0) + (card.hasCenter ? 16 : 0);
    // 다양한 폴더 활용
    int fileIdx = (shapeHash % 9) + 1;
    if (!card.hasCenter) {
      return 'assets/board_info/007_path/007_path_0$fileIdx.png'; // 막힌 길 계열
    }
    if (shapeHash % 3 == 0) return 'assets/board_info/004_path/004_path_0$fileIdx.png';
    if (shapeHash % 3 == 1) return 'assets/board_info/005_path/005_path_0$fileIdx.png';
    return 'assets/board_info/006_path/006_path_0$fileIdx.png';
  }

  /// 단순 ID 기반으로 에셋을 가져오는 헬퍼 (모바일 핸드 카드 등에서 사용)
  static String getImagePathById(String cardId) {
    if (cardId.startsWith('path')) {
      // ID 구조: path_11111_0 (shapeStr은 1과 0으로 이루어진 5자리 문자열)
      final parts = cardId.split('_');
      if (parts.length >= 3) {
        final shapeStr = parts[1];
        if (shapeStr.length == 5) {
          int shapeHash = (shapeStr[0] == '1' ? 1 : 0) + 
                          (shapeStr[1] == '1' ? 2 : 0) + 
                          (shapeStr[2] == '1' ? 4 : 0) + 
                          (shapeStr[3] == '1' ? 8 : 0) + 
                          (shapeStr[4] == '1' ? 16 : 0);
          
          int fileIdx = (shapeHash % 9) + 1;
          if (shapeStr[4] == '0') { // !hasCenter
            fileIdx = (shapeHash % 7) + 1; // 007_path has 7 files
            return 'assets/board_info/007_path/007_path_0$fileIdx.png';
          }
          if (shapeHash % 3 == 0) return 'assets/board_info/004_path/004_path_0$fileIdx.png';
          if (shapeHash % 3 == 1) return 'assets/board_info/005_path/005_path_0$fileIdx.png';
          return 'assets/board_info/006_path/006_path_0$fileIdx.png';
        }
      }
      return 'assets/board_info/004_path/004_path_01.png';
    } else if (cardId.startsWith('act_break')) {
      return 'assets/board_info/001_action/001_action_01.png';
    } else if (cardId.startsWith('act_fix')) {
      return 'assets/board_info/001_action/001_action_05.png';
    } else if (cardId.startsWith('act_map')) {
      return 'assets/board_info/008_cave_action/008_cave_action_01.png';
    } else if (cardId.startsWith('act_rock')) {
      return 'assets/board_info/008_cave_action/008_cave_action_03.png';
    }
    return 'assets/board_info/004_path/004_path_01.png';
  }
}
