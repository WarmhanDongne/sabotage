import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../main.dart';
import '../../data/models/card.dart' as game_card;
import '../../data/models/player.dart';
import '../../logic/controller_state_machine.dart';

/// 클라이언트(모바일) 컨트롤러 뷰.
/// phone_info/code.html 디자인 기반:
/// - 부채꼴(Fan) 카드 배치
/// - 암석 텍스처 배경 + 비네팅
/// - 골드/브라스 테마
/// - 하단 Identity Card 슬라이드
class PlayerView extends StatefulWidget {
  final String roomId;
  final String playerId;

  const PlayerView({super.key, required this.roomId, required this.playerId});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  ControllerStateMachine _csm = const ControllerStateMachine();
  bool _isPending = false;
  int? _selectedCardIndex;

  // 더미 손패 카드 이미지 경로
  final List<String> _handCardImages = [
    'assets/board_info/001_action/001_action_01.png',
    'assets/board_info/004_path/004_path_01.png',
    'assets/board_info/001_action/001_action_03.png',
    'assets/board_info/004_path/004_path_02.png',
    'assets/board_info/003_mixed/003_mixed_01.png',
    'assets/board_info/001_action/001_action_05.png',
  ];

  // 더미 역할 카드 이미지
  final String _identityCardImage = 'assets/board_info/002_dwarves/002_dwarves_01.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isPending,
        child: Stack(
          children: [
            // 배경 레이어
            _buildBackground(),
            // 메인 게임 콘텐츠
            _buildMainContent(),
            // Identity Card (하단 중앙, 살짝 삐져나옴)
            _buildIdentityCard(),
            // 네트워크 대기 오버레이
            if (_isPending) _buildPendingOverlay(),
          ],
        ),
      ),
    );
  }

  /// 암석 텍스처 배경 + 비네팅
  Widget _buildBackground() {
    return Stack(
      children: [
        // 기본 배경색
        Container(color: SabotageColors.surfaceContainerLowest),
        // 비네팅 효과
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Color(0xE5000000), // rgba(0,0,0,0.9)
              ],
              stops: [0.1, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  /// 메인 게임 콘텐츠
  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          // 상단 상태 바
          _buildTopStatusBar(),
          // 안내 텍스트
          _buildStateLabel(),
          // 부채꼴 카드 영역 (Expanded)
          Expanded(
            child: _buildFanCards(),
          ),
          // 확정 버튼 (TargetSelected 상태에서만 표시)
          if (_csm.currentState == ControllerState.targetSelected)
            _buildConfirmBar(),
          // Table Edge 장식
          _buildTableEdge(),
        ],
      ),
    );
  }

  /// 상단 상태 바
  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 방 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SabotageColors.panelCharcoal,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SabotageColors.borderBrass),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.meeting_room_outlined, color: SabotageColors.muted, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.roomId.toUpperCase(),
                  style: const TextStyle(
                    color: SabotageColors.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          // 내 턴 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: SabotageColors.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SabotageColors.primaryContainer.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: SabotageColors.goldGlow,
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Text(
              'YOUR TURN',
              style: TextStyle(
                color: SabotageColors.primaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 안내 라벨
  Widget _buildStateLabel() {
    final (text, color) = switch (_csm.currentState) {
      ControllerState.idle => ('카드를 선택하세요', SabotageColors.muted),
      ControllerState.cardSelected => ('보드에서 놓을 위치를 탭하세요', SabotageColors.primaryContainer),
      ControllerState.targetSelected => ('확정 버튼을 눌러 사용하세요', SabotageColors.surfaceTint),
      ControllerState.dispatched => ('처리 중...', SabotageColors.muted),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'JetBrains Mono',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 부채꼴(Fan) 카드 배치
  Widget _buildFanCards() {
    final cardCount = _handCardImages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight * 0.85; // 부채꼴 회전 중심점

        return Stack(
          children: List.generate(cardCount, (index) {
            // 카드별 각도 계산
            final totalSpread = 28.0; // 전체 펼침 각도
            final angleStep = totalSpread / (cardCount - 1);
            final angle = -totalSpread / 2 + angleStep * index;
            final radians = angle * math.pi / 180;

            // 선택된 카드는 위로 솟아오름
            final isSelected = _selectedCardIndex == index;
            final yOffset = isSelected ? -80.0 : 0.0;

            // 카드 크기
            final cardWidth = constraints.maxWidth * 0.22;
            final cardHeight = cardWidth * 1.5; // 2:3 비율

            return Positioned(
              left: centerX - cardWidth / 2,
              bottom: 20,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translate(0.0, yOffset)
                  ..rotateZ(radians),
                child: GestureDetector(
                  onTap: () => _onCardTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? SabotageColors.primaryContainer
                            : SabotageColors.borderBrass,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: SabotageColors.primaryContainer.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 4,
                          )
                        else
                          const BoxShadow(
                            color: Color(0xB3000000), // 70% 검정
                            blurRadius: 35,
                            offset: Offset(0, 15),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        _handCardImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: SabotageColors.surfaceContainer,
                          child: const Center(
                            child: Icon(Icons.style, color: SabotageColors.muted, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Table Edge 장식 (code.html 기준)
  Widget _buildTableEdge() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            SabotageColors.borderBrass.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
        border: Border(
          top: BorderSide(color: SabotageColors.outline.withOpacity(0.2)),
        ),
      ),
    );
  }

  /// Identity Card (하단 중앙, 역할 카드)
  Widget _buildIdentityCard() {
    return Positioned(
      bottom: -60,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onVerticalDragUpdate: (_) {},
          child: Container(
            width: 96,
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SabotageColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                _identityCardImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: SabotageColors.surfaceContainer,
                  child: const Icon(Icons.person, color: SabotageColors.muted),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 최종 확인 버튼
  Widget _buildConfirmBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: SabotageColors.goldGlow,
              blurRadius: 24,
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SabotageColors.primaryContainer,
            foregroundColor: SabotageColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _dispatchAction,
          child: const Text(
            '카드 사용 확정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  /// 네트워크 대기 오버레이
  Widget _buildPendingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: SabotageColors.primaryContainer),
            const SizedBox(height: 16),
            Text(
              '처리 중...',
              style: TextStyle(
                color: SabotageColors.onSurface,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──── Event Handlers ────

  void _onCardTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCardIndex == index) {
        // 이미 선택된 카드 다시 탭 → 선택 해제
        _selectedCardIndex = null;
        _csm = _csm.cancelSelection();
      } else {
        _selectedCardIndex = index;
        _csm = _csm.selectCard('card_$index');
      }
    });
  }

  Future<void> _dispatchAction() async {
    if (_csm.currentState != ControllerState.targetSelected) return;
    setState(() {
      _isPending = true;
      _csm = _csm.dispatchAction();
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800)); // 더미 딜레이
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false;
          _csm = const ControllerStateMachine();
          _selectedCardIndex = null;
        });
      }
    }
  }
}
