import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../logic/controller_state_machine.dart';
import '../../data/game_state.dart';
import '../../data/models/player.dart';
import '../../data/repositories/game_repository.dart';
import '../../logic/card_image_mapper.dart';
import '../../data/models/card.dart' as game_card;
import '../../data/models/card_database.dart';

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
  bool _isRotated = false;
  int? _seenMapResultTimestamp;

  // Identity Card 애니메이션
  late AnimationController _identitySlideController;
  late AnimationController _identityFlipController;
  late Animation<double> _identitySlideAnimation;
  late Animation<double> _identityFlipAnimation;
  
  // 불변 상태: 역할 카드의 공개 여부 (false = 뒷면/숨김, true = 앞면/중앙 팝업)
  bool _identityRevealed = false;



  // 역할 카드 이미지
  final String _identityFrontImage = 'assets/board_info/002_dwarves/002_dwarves_01.png';
  static const String _identityBackImage = 'assets/board_info/006_card_back_side/010_red_01.png'; // 빨간 뒷면

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
      body: StreamBuilder<GameState?>(
        stream: context.read<GameRepository>().roomStream(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("방 정보를 불러올 수 없습니다."));
          }

          final state = snapshot.data!;
          final meIndex = state.players.indexWhere((p) => p.id == widget.playerId);
          if (meIndex == -1) return const Center(child: Text("플레이어를 찾을 수 없습니다."));

          final me = state.players[meIndex];
          final isMyTurn = state.currentTurnPlayerId == widget.playerId;
          
          // 패 업데이트 (실제 카드 ID 기반 매핑)
          final handCardIds = me.handCardIds;
          final currentHandImages = handCardIds.map((id) {
            return CardImageMapper.getImagePathById(id);
          }).toList();

          return Stack(
            children: [
              // 1. 오리지널 대리석 배경 (다크모드/비네팅/커스텀 컬러 모두 배제)
              Positioned.fill(
                child: Image.asset(
                  'assets/phone_info/basic_image.png',
                  fit: BoxFit.cover,
                ),
              ),
              
              // 2. 메인 게임 콘텐츠 (카드 부채꼴 배치)
              AbsorbPointer(
                absorbing: _isPending || !isMyTurn,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20), // 상단 여백
                      // 현재 턴 알림 표시
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: isMyTurn ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                        child: Text(isMyTurn ? "내 턴입니다!" : "상대방 턴을 기다려주세요", style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      // 내 장비 상태 표시
                      if (me.isPickaxeBroken || me.isLanternBroken || me.isCartBroken)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '장비 고장: ' + 
                            [
                              if (me.isPickaxeBroken) '곡괭이',
                              if (me.isLanternBroken) '랜턴',
                              if (me.isCartBroken) '수레',
                            ].join(', '),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      // 확정 버튼 영역
                      if (state.pendingAction != null && state.pendingAction!['playerId'] == widget.playerId)
                        _buildPendingActionUI(state.pendingAction!)
                      else if (_csm.currentState == ControllerState.cardSelected && isMyTurn)
                        _buildActionButtons(currentHandImages),
                      
                      // 부채꼴 카드 영역
                      Expanded(
                        child: _buildFanCards(currentHandImages),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 역할 카드 (초기 뒷면, 탭 시 팝업 및 뒤집기)
                if (!_identityRevealed) _buildIdentityCardTrigger(),
                
                if (_isPending) _buildPendingOverlay(),
                if (_identityRevealed) _buildIdentityOverlay(me.role),

                // 지도 카드 결과 알림 (가장 위로)
                if (state.lastMapResult != null && 
                    state.lastMapResult!['playerId'] == widget.playerId && 
                    state.lastMapResult!['timestamp'] != _seenMapResultTimestamp)
                  _buildMapResultOverlay(state.lastMapResult!['isGold'], state.lastMapResult!['timestamp']),

                // 4. 게임 종료 패널
                if (state.isGameOver)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '게임 종료!\n승리: ${state.winner == 'miner' ? '광부' : '방해꾼'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/');
                            },
                            child: const Text('로비로 돌아가기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
        }
      ),
    );
  }

  /// 부채꼴(Fan) 카드 배치 — 정확히 너비의 1/10만 겹침
  Widget _buildFanCards(List<String> currentHandImages) {
    final cardCount = currentHandImages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 스크린샷처럼 화면 양옆에 여유로운 여백을 남기기 위해 부채꼴이 차지하는 최대 너비를 65%로 더 줄입니다.
        final availableWidth = constraints.maxWidth * 0.65;
        final stepRatio = 0.50; // 50% 겹침
        
        final cardWidth = availableWidth / (1 + (cardCount - 1) * stepRatio);
        final cardHeight = cardWidth * 1.5;

        final cardStep = cardWidth * stepRatio;
        final totalFanWidth = cardWidth + (cardCount - 1) * cardStep;
        
        final startX = (constraints.maxWidth - totalFanWidth) / 2;

        // 스크린샷 기준: 양끝 카드가 상당히 많이 기울어져 있음 (약 45도 Spread)
        final totalSpread = 45.0; 
        final angleStep = cardCount > 1 ? totalSpread / (cardCount - 1) : 0.0;
        
        // 스크린샷 기준: 중앙 카드가 화면 하단에서 꽤 높이 떠 있음
        // 화면 높이의 약 22% 정도로 기본 높이를 설정합니다.
        final baseBottom = constraints.maxHeight * 0.22;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(cardCount, (index) {
            final isSelected = _selectedCardIndex == index;

            final xPos = startX + index * cardStep;

            final angle = cardCount > 1
                ? (-totalSpread / 2 + angleStep * index)
                : 0.0;
            final radians = angle * math.pi / 180;

            final normalizedPos = cardCount > 1
                ? (index - (cardCount - 1) / 2).abs() / ((cardCount - 1) / 2)
                : 0.0;
            
            // 스크린샷 기준: 양끝 카드가 역할 카드(빨간색) 부근까지 가파르게 떨어지는 가파른 아치
            final archOffset = normalizedPos * normalizedPos * 110; 
            
            // 팝업 효과: 탭하면 위로 솟아오름
            final selectOffset = isSelected ? -60.0 : 0.0;

            return Positioned(
              left: xPos,
              bottom: baseBottom - archOffset - selectOffset,
              child: Transform.rotate(
                angle: radians,
                alignment: Alignment.bottomCenter, // 하단을 기준으로 회전
                child: GestureDetector(
                  onTap: () => _onCardTapped(index),
                  child: Transform.rotate(
                    angle: (isSelected && _isRotated) ? math.pi : 0.0,
                    alignment: Alignment.center,
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
                        currentHandImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  ), // Transform.rotate (inner) closing paren
                ), // GestureDetector closing paren
              ), // Transform.rotate (outer) closing paren
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
  Widget _buildIdentityOverlay(PlayerRole? role) {
    final frontImage = role == PlayerRole.miner 
        ? 'assets/board_info/002_dwarves/002_dwarves_01.png'
        : 'assets/board_info/002_dwarves/002_dwarves_03.png'; 

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
                        showFront ? frontImage : _identityBackImage,
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

  Widget _buildActionButtons(List<String> currentHandImages) {
    bool isPathCard = false;
    if (_selectedCardIndex != null && _selectedCardIndex! < currentHandImages.length) {
      final cardId = currentHandImages[_selectedCardIndex!];
      isPathCard = cardId.startsWith('004_path') || cardId.startsWith('005_path') || cardId.startsWith('006_path') || cardId.startsWith('007_path');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPathCard) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRotated ? Colors.deepPurple : Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _isRotated = !_isRotated;
              });
            },
            child: const Text('180도 회전', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _useCard,
          child: const Text('이 카드 사용하기', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _discardCard,
          child: const Text('버리기', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMapResultOverlay(bool isGold, int timestamp) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '지도 카드 결과',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Text(
                isGold ? '확인한 목적지는\n✨ 금 ✨\n입니다!' : '확인한 목적지는\n🪨 돌 🪨\n입니다!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isGold ? Colors.amber[700] : Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  setState(() => _seenMapResultTimestamp = timestamp);
                  context.read<GameRepository>().clearMapResult(widget.roomId);
                },
                child: const Text('확인', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActionUI(Map<String, dynamic> pendingAction) {
    final cardId = pendingAction['cardId'] as String;
    final isRotated = pendingAction['isRotated'] == true;
    final imagePath = CardImageMapper.getImagePathById(cardId);

    return Column(
      children: [
        const Text(
          '태블릿 화면에서 대상을 선택해주세요.',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // 선택된 카드 미리보기
        Transform.rotate(
          angle: isRotated ? math.pi : 0.0,
          child: Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
          onPressed: _cancelAction,
          child: const Text('사용 취소', style: TextStyle(color: Colors.white)),
        ),
      ],
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
        _isRotated = false;
        _csm = _csm.cancelSelection();
      } else {
        _selectedCardIndex = index;
        _isRotated = false;
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

  Future<void> _useCard() async {
    if (_csm.currentState != ControllerState.cardSelected) return;
    
    setState(() => _isPending = true);
    try {
      final repo = context.read<GameRepository>();
      final state = await repo.roomStream(widget.roomId).first;
      if (state == null) throw Exception("State not found");
      
      final me = state.players.firstWhere((p) => p.id == widget.playerId);
      final realCardId = me.handCardIds[_selectedCardIndex!];

      // 고장 상태인지 확인하고 길 카드라면 차단
      final card = CardDatabase.getCardById(realCardId);
      if (card != null && card.type == game_card.CardType.path) {
        if (me.isPickaxeBroken || me.isLanternBroken || me.isCartBroken) {
          setState(() => _isPending = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('장비가 고장나서 굴 카드를 놓을 수 없습니다! (먼저 장비를 수리하세요)')),
            );
          }
          return;
        }
      }

      if (card != null && card.type == game_card.CardType.action) {
        bool isTargetCard = card.actionType == game_card.ActionType.breakPickaxe ||
                            card.actionType == game_card.ActionType.breakLantern ||
                            card.actionType == game_card.ActionType.breakCart ||
                            card.actionType == game_card.ActionType.fixPickaxe ||
                            card.actionType == game_card.ActionType.fixLantern ||
                            card.actionType == game_card.ActionType.fixCart ||
                            card.actionType == game_card.ActionType.fixCartOrLantern ||
                            card.actionType == game_card.ActionType.fixCartOrPickaxe ||
                            card.actionType == game_card.ActionType.fixLanternOrPickaxe;
        if (isTargetCard) {
          _showActionTargetDialog(context, state, me.id, realCardId, _isRotated);
          setState(() => _isPending = false);
          return;
        }
      }

      await repo.setPendingAction(widget.roomId, widget.playerId, realCardId, isRotated: _isRotated);
      
      if (mounted) {
        setState(() {
          _isPending = false;
        });
      }
    } catch (e) {
      setState(() => _isPending = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('동작 실패: $e')));
    }
  }

  void _showActionTargetDialog(BuildContext context, GameState state, String currentPlayerId, String cardId, bool isRotated) {
    showDialog(
      context: context,
      builder: (context) {
        final players = state.players;
        return AlertDialog(
          title: const Text('대상 선택', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900],
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: players.length,
              itemBuilder: (context, idx) {
                final player = players[idx];
                
                bool isSelf = player.id == currentPlayerId;
                
                final actionCard = CardDatabase.getCardById(cardId);
                bool isBreakCard = actionCard != null && (
                  actionCard.actionType == game_card.ActionType.breakPickaxe ||
                  actionCard.actionType == game_card.ActionType.breakLantern ||
                  actionCard.actionType == game_card.ActionType.breakCart
                );
                
                if (isSelf && isBreakCard) {
                  return const SizedBox.shrink(); // 자기 자신에게는 고장 카드 사용 불가
                }
                
                return ListTile(
                  title: Text(player.id, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '곡괭이:${player.isPickaxeBroken?'❌':'✅'} 수레:${player.isCartBroken?'❌':'✅'} 랜턴:${player.isLanternBroken?'❌':'✅'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isPending = true;
                    });
                    context.read<GameRepository>().playActionCard(
                          widget.roomId,
                          currentPlayerId,
                          cardId,
                          targetPlayerId: player.id,
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _isPending = false;
                              _selectedCardIndex = null;
                              _csm = const ControllerStateMachine();
                            });
                          }
                        }).catchError((e) {
                          if (mounted) {
                            setState(() => _isPending = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('동작 실패: $e')));
                          }
                        });
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelAction() async {
    setState(() => _isPending = true);
    try {
      final repo = context.read<GameRepository>();
      await repo.clearPendingAction(widget.roomId, widget.playerId);
      
      if (mounted) {
        setState(() {
          _isPending = false;
          _csm = const ControllerStateMachine();
          _selectedCardIndex = null;
        });
      }
    } catch (e) {
      setState(() => _isPending = false);
    }
  }

  Future<void> _discardCard() async {
    if (_csm.currentState != ControllerState.cardSelected) return;
    
    setState(() => _isPending = true);
    
    try {
      final repo = context.read<GameRepository>();
      final state = await repo.roomStream(widget.roomId).first;
      if (state == null) throw Exception("State not found");
      
      final me = state.players.firstWhere((p) => p.id == widget.playerId);
      final realCardId = me.handCardIds[_selectedCardIndex!];

      await repo.discardCard(widget.roomId, widget.playerId, realCardId);
      
      if (mounted) {
        setState(() {
          _isPending = false;
          _csm = const ControllerStateMachine();
          _selectedCardIndex = null;
        });
      }
    } catch (e) {
      setState(() => _isPending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('버리기 실패: $e')),
        );
      }
    }
  }
}
