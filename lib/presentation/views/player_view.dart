import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../main.dart';
import '../../logic/controller_state_machine.dart';

/// 클라이언트(모바일) 컨트롤러 뷰.
/// phone_info/code.html 디자인 "그대로" 적용:
/// - 암석 텍스처 배경 + 비네팅 + 하단 table-edge
/// - 부채꼴(Fan) 카드: 카드 폭의 1/10만 겹침
/// - Identity Card: 뒤집힌 상태(뒷면)로 하단에 숨어있다가 탭 시 올라오며 뒤집기 애니메이션
class PlayerView extends StatefulWidget {
  final String roomId;
  final String playerId;

  const PlayerView({super.key, required this.roomId, required this.playerId});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with TickerProviderStateMixin {
  ControllerStateMachine _csm = const ControllerStateMachine();
  bool _isPending = false;
  int? _selectedCardIndex;

  // Identity Card 애니메이션
  late AnimationController _identitySlideController;
  late AnimationController _identityFlipController;
  late Animation<double> _identitySlideAnimation;
  late Animation<double> _identityFlipAnimation;
  bool _identityRevealed = false;

  // 더미 손패 카드 이미지
  final List<String> _handCardImages = [
    'assets/board_info/001_action/001_action_01.png',
    'assets/board_info/004_path/004_path_01.png',
    'assets/board_info/001_action/001_action_03.png',
    'assets/board_info/004_path/004_path_02.png',
    'assets/board_info/003_mixed/003_mixed_01.png',
    'assets/board_info/001_action/001_action_05.png',
  ];

  // 역할 카드 (앞면: 난쟁이, 뒷면: 빨간 카드백)
  final String _identityFrontImage = 'assets/board_info/002_dwarves/002_dwarves_01.png';
  final String _identityBackImage = 'assets/board_info/010_red/010_red_01.png';

  @override
  void initState() {
    super.initState();

    // 역할 카드 슬라이드 (아래→위) 애니메이션
    _identitySlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _identitySlideAnimation = CurvedAnimation(
      parent: _identitySlideController,
      curve: Curves.easeOutCubic,
    );

    // 역할 카드 뒤집기 (0→π) 애니메이션
    _identityFlipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _identityFlipAnimation = CurvedAnimation(
      parent: _identityFlipController,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _identitySlideController.dispose();
    _identityFlipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: _isPending,
        child: Stack(
          children: [
            _buildBackground(),
            _buildMainContent(),
            _buildIdentityCard(),
            if (_isPending) _buildPendingOverlay(),
            // Identity 모달 오버레이 (열렸을 때)
            if (_identityRevealed) _buildIdentityOverlay(),
          ],
        ),
      ),
    );
  }

  /// 배경: phone_info/code.html의 rock-bg + vignette 재현
  Widget _buildBackground() {
    return Stack(
      children: [
        // 기본 배경색 (#0d0e11 = surface-container-lowest)
        Container(color: SabotageColors.surfaceContainerLowest),
        // 비네팅 효과 (radial-gradient: transparent 10% → rgba(0,0,0,0.9) 100%)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Color(0xE5000000),
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
          _buildTopStatusBar(),
          _buildStateLabel(),
          // 부채꼴 카드 영역
          Expanded(child: _buildFanCards()),
          // 확정 버튼
          if (_csm.currentState == ControllerState.targetSelected)
            _buildConfirmBar(),
          // Table Edge (code.html: .table-edge)
          _buildTableEdge(),
        ],
      ),
    );
  }

  /// 상단 상태 바 (code.html 스타일)
  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 방 정보 뱃지 (brass border pill)
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
          // YOUR TURN 배지 (gold glow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: SabotageColors.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: SabotageColors.primaryContainer.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: SabotageColors.goldGlow, blurRadius: 12),
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
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'JetBrains Mono', letterSpacing: 0.5)),
    );
  }

  /// 부채꼴(Fan) 카드 배치 — 카드 폭의 1/10만 겹침
  Widget _buildFanCards() {
    final cardCount = _handCardImages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 카드 크기: 화면 폭의 22% (2:3 비율)
        final cardWidth = constraints.maxWidth * 0.22;
        final cardHeight = cardWidth * 1.5;

        // 1/10만 겹침 → 각 카드 간격 = cardWidth * 9/10
        final cardStep = cardWidth * 0.9;
        final totalFanWidth = cardWidth + (cardCount - 1) * cardStep;
        final startX = (constraints.maxWidth - totalFanWidth) / 2;

        // 부채꼴 각도: 중앙 카드는 0도, 좌우로 점점 기울어짐
        final totalSpread = 24.0; // 전체 펼침 각도 (도)
        final angleStep = cardCount > 1 ? totalSpread / (cardCount - 1) : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(cardCount, (index) {
            final isSelected = _selectedCardIndex == index;

            // X 위치: 1/10만 겹치도록 균등 배치
            final xPos = startX + index * cardStep;

            // 각도 계산
            final angle = cardCount > 1
                ? (-totalSpread / 2 + angleStep * index)
                : 0.0;
            final radians = angle * math.pi / 180;

            // Y 오프셋: 부채꼴 아치형 + 선택 시 솟아오름
            final normalizedPos = cardCount > 1
                ? (index - (cardCount - 1) / 2).abs() / ((cardCount - 1) / 2)
                : 0.0;
            final archOffset = normalizedPos * normalizedPos * 35; // 양 끝이 더 아래로
            final selectOffset = isSelected ? -100.0 : 0.0;

            return Positioned(
              left: xPos,
              bottom: 30 - archOffset + (isSelected ? 100 : 0),
              child: Transform.rotate(
                angle: radians,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () => _onCardTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // code.html: border: 1px solid #4d4732
                      border: Border.all(
                        color: isSelected
                            ? SabotageColors.primaryContainer
                            : SabotageColors.borderBrass,
                        width: isSelected ? 2 : 1,
                      ),
                      // code.html: box-shadow: 0 15px 35px rgba(0,0,0,0.7)
                      // hover: box-shadow: 0 0 40px rgba(255, 215, 0, 0.3)
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: SabotageColors.primaryContainer.withOpacity(0.3),
                            blurRadius: 40,
                          )
                        else
                          const BoxShadow(
                            color: Color(0xB3000000),
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
                          child: const Center(child: Icon(Icons.style, color: SabotageColors.muted, size: 32)),
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

  /// Table Edge (code.html: .table-edge)
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

  /// Identity Card 트리거 (하단 중앙에 카드 뒷면이 살짝 삐져나옴)
  Widget _buildIdentityCard() {
    return Positioned(
      bottom: -70, // 카드의 상단 일부만 보임
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _onIdentityTapped,
          child: Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SabotageColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                _identityBackImage,  // 항상 뒷면만 표시
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF8B0000),
                  child: const Center(child: Icon(Icons.help_outline, color: Colors.white38)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Identity 오버레이: 탭 시 화면 중앙에 카드가 올라오며 뒤집기 애니메이션
  Widget _buildIdentityOverlay() {
    return GestureDetector(
      onTap: _dismissIdentity,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_identitySlideController, _identityFlipController]),
            builder: (context, child) {
              // 슬라이드: 아래에서 위로
              final slideOffset = (1 - _identitySlideAnimation.value) * 300;
              // 뒤집기: 0 → π
              final flipAngle = _identityFlipAnimation.value * math.pi;
              // 뒷면(0~π/2) vs 앞면(π/2~π)
              final showFront = flipAngle > math.pi / 2;
              // 실제 회전값 보정 (앞면일 때 반대로)
              final displayAngle = showFront ? math.pi - flipAngle : flipAngle;

              return Transform.translate(
                offset: Offset(0, slideOffset),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(displayAngle),
                  child: Container(
                    width: 180,
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: showFront
                            ? SabotageColors.primaryContainer.withOpacity(0.6)
                            : SabotageColors.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        if (showFront)
                          BoxShadow(
                            color: SabotageColors.primaryContainer.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 8,
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        showFront ? _identityFrontImage : _identityBackImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: showFront ? SabotageColors.surfaceContainer : const Color(0xFF8B0000),
                          child: Center(
                            child: Icon(
                              showFront ? Icons.person : Icons.help_outline,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
          boxShadow: [BoxShadow(color: SabotageColors.goldGlow, blurRadius: 24)],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: SabotageColors.primaryContainer,
            foregroundColor: SabotageColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _dispatchAction,
          child: const Text('카드 사용 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  /// 네트워크 대기 오버레이
  Widget _buildPendingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: SabotageColors.primaryContainer),
            SizedBox(height: 16),
            Text('처리 중...', style: TextStyle(color: SabotageColors.onSurface, fontFamily: 'JetBrains Mono')),
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
        _selectedCardIndex = null;
        _csm = _csm.cancelSelection();
      } else {
        _selectedCardIndex = index;
        _csm = _csm.selectCard('card_$index');
      }
    });
  }

  void _onIdentityTapped() {
    HapticFeedback.mediumImpact();
    setState(() => _identityRevealed = true);
    // 1. 슬라이드 시작
    _identitySlideController.forward();
    // 2. 슬라이드가 40% 진행된 후 뒤집기 시작
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _identityFlipController.forward();
    });
  }

  void _dismissIdentity() {
    // 역순 애니메이션으로 닫기
    _identityFlipController.reverse().then((_) {
      _identitySlideController.reverse().then((_) {
        if (mounted) setState(() => _identityRevealed = false);
      });
    });
  }

  Future<void> _dispatchAction() async {
    if (_csm.currentState != ControllerState.targetSelected) return;
    setState(() {
      _isPending = true;
      _csm = _csm.dispatchAction();
    });
    try {
      await Future.delayed(const Duration(milliseconds: 800));
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
