import '../data/models/card.dart';

enum ControllerState {
  idle,
  cardSelected,
  targetSelected,
  dispatched,
}

/// 클라이언트의 터치 입력에 따른 상태 전이를 관리합니다.
class ControllerStateMachine {
  final ControllerState currentState;
  final String? selectedCardId; // 선택한 내 손패의 카드 ID
  final dynamic target; // 보드 좌표 {x, y} 또는 타겟 플레이어 ID

  const ControllerStateMachine({
    this.currentState = ControllerState.idle,
    this.selectedCardId,
    this.target,
  });

  /// 1. 카드를 선택했을 때 (Idle -> CardSelected)
  ControllerStateMachine selectCard(String cardId) {
    if (currentState != ControllerState.idle && currentState != ControllerState.cardSelected) {
      return this; // 유효하지 않은 상태 전이
    }
    return ControllerStateMachine(
      currentState: ControllerState.cardSelected,
      selectedCardId: cardId,
      target: null,
    );
  }

  /// 2. 타겟(보드 좌표 등)을 선택했을 때 (CardSelected -> TargetSelected)
  ControllerStateMachine selectTargetGrid(int x, int y) {
    if (currentState != ControllerState.cardSelected && currentState != ControllerState.targetSelected) {
      return this;
    }
    return ControllerStateMachine(
      currentState: ControllerState.targetSelected,
      selectedCardId: selectedCardId,
      target: {'x': x, 'y': y},
    );
  }

  /// 2-1. 타겟(다른 플레이어)을 선택했을 때 (행동 카드용)
  ControllerStateMachine selectTargetPlayer(String playerId) {
    if (currentState != ControllerState.cardSelected && currentState != ControllerState.targetSelected) {
      return this;
    }
    return ControllerStateMachine(
      currentState: ControllerState.targetSelected,
      selectedCardId: selectedCardId,
      target: playerId,
    );
  }

  /// 선택 취소 (Any -> Idle)
  ControllerStateMachine cancelSelection() {
    return const ControllerStateMachine(
      currentState: ControllerState.idle,
    );
  }

  /// 3. 최종 확인 시 (TargetSelected -> Dispatched)
  ControllerStateMachine dispatchAction() {
    if (currentState != ControllerState.targetSelected) {
      return this;
    }
    return ControllerStateMachine(
      currentState: ControllerState.dispatched,
      selectedCardId: selectedCardId,
      target: target,
    );
  }
}
