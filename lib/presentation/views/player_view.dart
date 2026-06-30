import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../logic/controller_state_machine.dart';

/// 클라이언트(모바일) 뷰.
/// 기존 다크모드/커스텀 디자인 완전 폐기.
/// 오리지널 에셋(screen.png, Phone.png) 구조와 1/10 겹침 스펙 절대 준수.
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
  
  // 불변 상태: 역할 카드의 공개 여부 (false = 뒷면/숨김, true = 앞면/중앙 팝업)
  bool _identityRevealed = false;

  // 더미 손패 카드 (오리지널 이미지들)
  final List<String> _handCardImages = [
    'assets/board_info/004_path/004_path_01.png',
    'assets/board_info/001_action/001_action_01.png',
    'assets/board_info/008_cave_action/008_cave_action_01.png',
    'assets/board_info/004_path/004_path_02.png',
    'assets/board_info/004_path/004_path_03.png',
    'assets/board_info/001_action/001_action_05.png',
  ];

  // 역할 카드 이미지
  final String _identityFrontImage = 'assets/start_the_game/Phone Role 광부.png';
  final String _identityBackImage = 'assets/board_info/010_red/010_red_01.png'; // 빨간 뒷면

  @override
  void initState() {
    super.initState();

    _identitySlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _identitySlideAnimation = CurvedAnimation(
      parent: _identitySlideController,
      curve: Curves.easeOutCubic,
    );

    _identityFlipController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
            // 1. 오리지널 대리석 배경 (다크모드/비네팅/커스텀 컬러 모두 배제)
            Positioned.fill(
              child: Image.asset(
                'assets/phone_info/screen.png',
                fit: BoxFit.cover,
              ),
            ),
            
            // 2. 메인 게임 콘텐츠 (카드 부채꼴 배치)
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20), // 상단 여백
                  // 확정 버튼 (선택 시에만 노출되도록 간소화)
                  if (_csm.currentState == ControllerState.targetSelected)
                    _buildConfirmButton(),
                  
                  // 부채꼴 카드 영역
                  Expanded(child: _buildFanCards()),
                ],
              ),
            ),

            // 3. 역할 카드 (초기 뒷면, 탭 시 팝업 및 뒤집기)
            if (!_identityRevealed) _buildIdentityCardTrigger(),
            
            if (_isPending) _buildPendingOverlay(),
            if (_identityRevealed) _buildIdentityOverlay(),
          ],
        ),
      ),
    );
  }

  /// 부채꼴(Fan) 카드 배치 — 정확히 너비의 1/10만 겹침
  Widget _buildFanCards() {
    final cardCount = _handCardImages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 카드 크기 설정
        final cardWidth = constraints.maxWidth * 0.22;
        final cardHeight = cardWidth * 1.5;

        // [제약 준수]: 각 카드는 가로 너비의 정확히 "1/10"만 겹치도록 배치.
        // 겹침이 width의 1/10이므로, 각 카드의 중심간 간격(step)은 width의 9/10 (0.9)
        final cardStep = cardWidth * 0.9;
        final totalFanWidth = cardWidth + (cardCount - 1) * cardStep;
        
        // 부채꼴을 화면 중앙에 정렬하기 위한 시작 X 좌표
        final startX = (constraints.maxWidth - totalFanWidth) / 2;

        // 전체 펼침 각도 (카드가 많을수록 넓어짐)
        final totalSpread = 30.0;
        final angleStep = cardCount > 1 ? totalSpread / (cardCount - 1) : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(cardCount, (index) {
            final isSelected = _selectedCardIndex == index;

            // X축 위치 (1/10 겹침 스펙 유지)
            final xPos = startX + index * cardStep;

            // 회전 각도
            final angle = cardCount > 1
                ? (-totalSpread / 2 + angleStep * index)
                : 0.0;
            final radians = angle * math.pi / 180;

            // Y축 아치형 높이 계산 (양 끝 카드가 아래로 내려감)
            final normalizedPos = cardCount > 1
                ? (index - (cardCount - 1) / 2).abs() / ((cardCount - 1) / 2)
                : 0.0;
            final archOffset = normalizedPos * normalizedPos * 40; 
            
            // 팝업 효과: 탭하면 위로 솟아오름 (단, 부채꼴 정렬 X축은 그대로 유지)
            final selectOffset = isSelected ? -60.0 : 0.0;

            return Positioned(
              left: xPos,
              bottom: 40 - archOffset - selectOffset,
              child: Transform.rotate(
                angle: radians,
                alignment: Alignment.bottomCenter, // 하단을 기준으로 회전
                child: GestureDetector(
                  onTap: () => _onCardTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        _handCardImages[index],
                        fit: BoxFit.cover,
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

  /// Identity Card 트리거 (화면 하단 중앙에 살짝 보이는 뒷면)
  Widget _buildIdentityCardTrigger() {
    return Positioned(
      bottom: -60, // 카드 윗부분만 보이게 숨김
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _onIdentityTapped,
          child: Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _identityBackImage, // 항상 빨간 뒷면
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Identity 오버레이: 탭 시 화면 중앙에 올라오며 뒤집어짐
  Widget _buildIdentityOverlay() {
    return GestureDetector(
      onTap: _dismissIdentity,
      child: Container(
        color: Colors.black.withOpacity(0.5), // 주변 어둡게
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_identitySlideController, _identityFlipController]),
            builder: (context, child) {
              // 1. 슬라이드 애니메이션 (화면 밖 아래에서 중앙으로)
              final slideOffset = (1 - _identitySlideAnimation.value) * 300;
              
              // 2. 뒤집기 애니메이션 (0 -> 180도)
              final flipAngle = _identityFlipAnimation.value * math.pi;
              final showFront = flipAngle > math.pi / 2;
              // 뒷면일 때는 원래 방향, 앞면일 때는 좌우 반전 보정
              final displayAngle = showFront ? math.pi - flipAngle : flipAngle;

              return Transform.translate(
                offset: Offset(0, slideOffset),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // 3D 원근감
                    ..rotateY(displayAngle),
                  child: Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        showFront ? _identityFrontImage : _identityBackImage,
                        fit: BoxFit.cover,
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

  /// 카드 선택 시 노출되는 간소화된 확인 버튼 (다크모드 스타일 배제)
  Widget _buildConfirmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber[700], // 게임 테마에 맞는 노란색
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: _dispatchAction,
      child: const Text('위치 선택', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPendingOverlay() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // ──── Event Handlers ────

  void _onCardTapped(int index) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.selectionClick();
    setState(() => _identityRevealed = true);
    
    // 시퀀스: 슬라이드하며 등장 -> 중간에 뒤집기 시작
    _identitySlideController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _identityFlipController.forward();
    });
  }

  void _dismissIdentity() {
    // 역순: 뒤집기 -> 아래로 슬라이드
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
