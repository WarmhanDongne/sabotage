import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/game_state.dart';
import '../../data/models/card.dart' as game_card;
import '../../data/models/player.dart';
import '../../logic/controller_state_machine.dart';
import '../../logic/validator.dart';
import '../widgets/board_grid_widget.dart';
import '../widgets/hand_card_widget.dart';
import '../widgets/action_target_panel.dart';
import '../widgets/player_self_status_header.dart';

/// 클라이언트(모바일) 컨트롤러 뷰.
/// - /player?room={roomId}&id={playerId} 경로로 접속한 기기에서 렌더링됩니다.
/// - PrivateGameState를 구독하여 본인 역할과 손패를 표시합니다.
/// - [Idle -> CardSelected -> TargetSelected -> Dispatched] 흐름을 준수합니다.
class PlayerView extends StatefulWidget {
  final String roomId;
  final String playerId;

  const PlayerView({super.key, required this.roomId, required this.playerId});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  // 컨트롤러 상태 머신 (context.md 규칙 2)
  ControllerStateMachine _csm = const ControllerStateMachine();

  // UI Locking: 네트워크 요청 중 전체 조작 비활성화 (context.md 규칙 4)
  bool _isPending = false;

  // BFS 기반 유효/무효 오버레이 좌표 세트 (context.md 규칙 3)
  Set<String> _validOverlayCoords = {};
  Set<String> _invalidOverlayCoords = {};

  // 선택한 카드 객체 캐시
  game_card.Card? _selectedCard;

  // TODO (Phase 3 Firestore 연동): StreamBuilder로 privateState를 받아야 함
  // 현재는 UI 뼈대 확인을 위한 더미 상태 사용
  late final Player _dummyMe = Player(
    id: widget.playerId,
    name: '테스트 플레이어',
    isPickaxeBroken: false,
  );
  final bool _isMyTurn = true; // 더미 턴 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      // UI Locking 오버레이 (context.md 규칙 4): 네트워크 대기 중 전체 터치 차단
      body: AbsorbPointer(
        absorbing: _isPending,
        child: Stack(
          children: [
            _buildMainLayout(),
            if (_isPending) _buildPendingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLayout() {
    return SafeArea(
      child: Column(
        children: [
          // 상단: 본인 상태 헤더
          PlayerSelfStatusHeader(me: _dummyMe, isMyTurn: _isMyTurn),

          // 중간: 미니 보드 뷰 (전체 보드를 축소해서 보여줌)
          Expanded(
            flex: 5,
            child: _buildMiniBoardArea(),
          ),

          // 행동 카드 타겟 플레이어 선택 패널 (CardSelected + 행동 카드인 경우)
          if (_csm.currentState == ControllerState.cardSelected &&
              _selectedCard?.type == game_card.CardType.action)
            _buildActionTargetPanel(),

          // 하단: 손패 패널
          Expanded(
            flex: 3,
            child: _buildHandPanel(),
          ),

          // 최종 확인 버튼 (TargetSelected 상태에서만 표시)
          if (_csm.currentState == ControllerState.targetSelected)
            _buildConfirmBar(),
        ],
      ),
    );
  }

  /// 미니 보드 뷰 + InteractiveViewer
  Widget _buildMiniBoardArea() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1C1C1C), Color(0xFF0D1117)],
              radius: 1.0,
            ),
          ),
        ),
        Center(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.3,
            maxScale: 2.5,
            child: BoardGridWidget(
              board: const [],       // TODO: privateState의 보드 데이터
              goalCards: const [],
              cardSize: 56.0,
              // BFS 오버레이 좌표 전달 (context.md 규칙 3)
              validOverlayCoords: _validOverlayCoords,
              invalidOverlayCoords: _invalidOverlayCoords,
              // 굴 카드 선택 후 보드 셀 탭 → TargetSelected 전이
              onGridTap: (_csm.currentState == ControllerState.cardSelected &&
                  _selectedCard?.type == game_card.CardType.path)
                  ? _onGridTapped
                  : null,
            ),
          ),
        ),
        // 상태 라벨 (현재 머신 상태 안내 텍스트)
        Positioned(
          top: 12,
          left: 16,
          child: _buildStateLabel(),
        ),
      ],
    );
  }

  /// 손패 가로 스크롤 패널
  Widget _buildHandPanel() {
    // TODO: privateState.me.handCardIds → 실제 Card 객체로 변환
    // 현재는 더미 카드 3장으로 시각 확인
    final dummyHand = [
      const game_card.Card(
        id: 'c1',
        type: game_card.CardType.path,
        hasTop: true,
        hasBottom: true,
      ),
      const game_card.Card(
        id: 'c2',
        type: game_card.CardType.action,
        actionType: game_card.ActionType.breakPickaxe,
      ),
      const game_card.Card(
        id: 'c3',
        type: game_card.CardType.action,
        actionType: game_card.ActionType.rockfall,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '내 손패 (${dummyHand.length}장)',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dummyHand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final card = dummyHand[i];
                return HandCardWidget(
                  card: card,
                  isSelected: _csm.selectedCardId == card.id,
                  isMyTurn: _isMyTurn,
                  onTap: () => _onCardTapped(card),
                );
              },
            ),
          ),
          // 카드 선택 중일 때 취소 버튼
          if (_csm.currentState != ControllerState.idle)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: TextButton.icon(
                  onPressed: _cancelSelection,
                  icon: const Icon(Icons.undo, size: 14, color: Colors.white38),
                  label: const Text(
                    '선택 취소',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 행동 카드 대상 플레이어 선택 패널
  Widget _buildActionTargetPanel() {
    // TODO: privateState의 다른 플레이어 목록으로 교체
    final dummyOthers = [
      const Player(id: 'p2', name: '플레이어2'),
      const Player(id: 'p3', name: '플레이어3', isPickaxeBroken: true),
    ];

    final isRepair = _selectedCard?.actionType == game_card.ActionType.fixPickaxe ||
        _selectedCard?.actionType == game_card.ActionType.fixLantern ||
        _selectedCard?.actionType == game_card.ActionType.fixCart;

    return ActionTargetPanel(
      otherPlayers: dummyOthers,
      selectedTargetPlayerId: _csm.target is String ? _csm.target as String : null,
      isRepairCard: isRepair,
      onSelectPlayer: _onTargetPlayerSelected,
      onCancel: _cancelSelection,
    );
  }

  /// 최종 확인 버튼 바
  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF0D1117),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
          ),
          onPressed: _dispatchAction,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 20),
              SizedBox(width: 8),
              Text('카드 사용 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  /// 현재 상태 머신 상태를 안내하는 레이블
  Widget _buildStateLabel() {
    final (text, color) = switch (_csm.currentState) {
      ControllerState.idle => ('카드를 선택하세요', Colors.white38),
      ControllerState.cardSelected => (
          _selectedCard?.type == game_card.CardType.path
              ? '보드에서 놓을 위치를 탭하세요'
              : '대상을 선택하세요',
          Colors.amberAccent
        ),
      ControllerState.targetSelected => ('확정 버튼을 눌러 카드를 사용하세요', Colors.greenAccent),
      ControllerState.dispatched => ('처리 중...', Colors.white54),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  /// 네트워크 대기 중 화면 전체 오버레이
  Widget _buildPendingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4A853)),
            SizedBox(height: 16),
            Text('처리 중...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 이벤트 핸들러
  // ──────────────────────────────────────────────

  /// 손패 카드 탭: Idle → CardSelected 전이
  void _onCardTapped(game_card.Card card) {
    HapticFeedback.selectionClick();
    setState(() {
      _csm = _csm.selectCard(card.id);
      _selectedCard = card;
      _clearOverlays();

      // 굴 카드인 경우 즉시 BFS로 유효한 셀 계산하여 오버레이 표시
      if (card.type == game_card.CardType.path) {
        _computeValidCells(card);
      }
    });
  }

  /// 보드 셀 탭: CardSelected → TargetSelected 전이 (굴 카드)
  void _onGridTapped(int x, int y) {
    if (_selectedCard == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _csm = _csm.selectTargetGrid(x, y);
      // 선택된 셀을 강조
      _validOverlayCoords = {'$x,$y'};
      _invalidOverlayCoords = {};
    });
  }

  /// 행동 카드 타겟 플레이어 선택: CardSelected → TargetSelected 전이
  void _onTargetPlayerSelected(String targetPlayerId) {
    HapticFeedback.selectionClick();
    setState(() {
      _csm = _csm.selectTargetPlayer(targetPlayerId);
    });
  }

  /// 최종 확인: TargetSelected → Dispatched, Firestore Transaction 실행
  Future<void> _dispatchAction() async {
    if (_csm.currentState != ControllerState.targetSelected) return;

    setState(() {
      _isPending = true; // UI Locking ON
      _csm = _csm.dispatchAction();
    });

    try {
      // TODO (Firestore 연동): Firestore Transaction으로 GameEngine의 결과 상태를 기록
      // await FirestoreRepository.applyAction(
      //   roomId: widget.roomId,
      //   playerId: widget.playerId,
      //   cardId: _csm.selectedCardId!,
      //   target: _csm.target,
      // );
      await Future.delayed(const Duration(milliseconds: 800)); // 더미 네트워크 딜레이

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false; // UI Locking OFF
          _csm = const ControllerStateMachine(); // Idle로 리셋
          _selectedCard = null;
          _clearOverlays();
        });
      }
    }
  }

  /// 선택 취소: 어느 상태에서든 Idle로 복귀
  void _cancelSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _csm = _csm.cancelSelection();
      _selectedCard = null;
      _clearOverlays();
    });
  }

  /// 선택된 굴 카드에 대해 보드 전체를 스캔하여
  /// 유효한 위치(초록)와 무효한 위치(빨강) 오버레이 좌표를 계산합니다.
  void _computeValidCells(game_card.Card card) {
    // TODO: 실제 privateState.board를 사용하여 BFS 적용
    // Validator.canPlaceCard(board, card, x, y)를 각 빈 셀에 대해 호출
    // 현재는 더미로 비워둠
    _validOverlayCoords = {};
    _invalidOverlayCoords = {};
  }

  void _clearOverlays() {
    _validOverlayCoords = {};
    _invalidOverlayCoords = {};
  }
}
