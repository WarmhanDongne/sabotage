import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/player.dart';
import '../../data/models/card_database.dart';
import '../widgets/board_grid_widget.dart';
import '../../data/game_state.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/card.dart' as game_card;
import '../../logic/validator.dart';

/// 호스트(태블릿) 뷰어.
/// 기존 다크모드/커스텀 디자인 완전 폐기.
/// 오리지널 에셋(board.png) 배경 적용 및 Ipad.png 기준의 사이드바/카드 배치 준수.
class TableView extends StatefulWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _transformationController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // 확대 비율이 1.0 미만(축소 상태)일 경우 3초 뒤 초기화 타이머 시작
    if (_transformationController.value.getMaxScaleOnAxis() < 1.0) {
      _resetTimer = Timer(const Duration(seconds: 3), () {
        _animateReset();
      });
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // 사용자가 다시 조작을 시작하면 타이머 취소
    _resetTimer?.cancel();
    if (_animationController?.isAnimating ?? false) {
      _animationController?.stop();
    }
  }

  void _animateReset() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));
    _animationController?.forward(from: 0);
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
          final board = state.board;
          final goalCards = state.goalCards;
          final remainingCards = state.deck.length;

          // Pending Action 감지 및 유효한 좌표 계산
          Set<String>? validCoords;
          if (state.pendingAction != null) {
            validCoords = {};
            String pType = state.pendingAction!['type'];
            String cId = state.pendingAction!['cardId'];

            final baseCard = CardDatabase.getCardById(cId);
            if (baseCard != null) {
              final isRotated = state.pendingAction!['isRotated'] == true;
              final card = baseCard.copyWith(isRotated: isRotated);
              if (card.type == game_card.CardType.path) {
                // 고장 난 장비가 있으면 굴 카드를 놓을 수 없으므로 validCoords를 생성하지 않음
                final currentPlayer = state.players.firstWhere((p) => p.id == state.pendingAction!['playerId']);
                if (!currentPlayer.isPickaxeBroken && !currentPlayer.isLanternBroken && !currentPlayer.isCartBroken) {
                  int minX = 0, maxX = 11, minY = 0, maxY = 6;
                  for (var node in [...board, ...goalCards]) {
                    if (node.x < minX) minX = node.x;
                    if (node.x > maxX) maxX = node.x;
                    if (node.y < minY) minY = node.y;
                    if (node.y > maxY) maxY = node.y;
                  }
                  final fullBoard = [...board, ...goalCards];
                  for (int x = minX - 1; x <= maxX + 1; x++) {
                    for (int y = minY - 1; y <= maxY + 1; y++) {
                      if (goalCards.any((g) => g.x == x && g.y == y)) continue;
                      if (Validator.canPlaceCard(fullBoard, card, x, y)) {
                        validCoords!.add('$x,$y');
                      }
                    }
                  }
              }
            } else if (card.type == game_card.CardType.action) {
                if (card.actionType == game_card.ActionType.map) {
                  // 지도는 목적지 카드만 타겟
                  for (var goal in goalCards) {
                    validCoords.add('${goal.x},${goal.y}');
                  }
                } else if (card.actionType == game_card.ActionType.rockfall) {
                  // 낙석은 시작점 제외한 모든 길 카드 타겟
                  for (var node in board) {
                    if (node.card.type == game_card.CardType.path) {
                    // 시작점인지 확인 (일반적으로 x=0, y=0 등, 혹은 id로 판별)
                    // 현재 시작점은 card.type == start 로 생성되므로 여기 포함 안 됨 (path만 필터)
                    validCoords.add('${node.x},${node.y}');
                  }
                }
              }
            }
          }
        }

          return Stack(
            children: [
              // 1 & 2. 원본 비율을 유지하는 게임 보드 영역
              LayoutBuilder(
                builder: (context, constraints) {
                  final cellHeight = constraints.maxHeight / 7;
                  final cellWidth = cellHeight * (2 / 3);

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    onInteractionStart: _onInteractionStart,
                    onInteractionEnd: _onInteractionEnd,
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.1,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(3000), // 화면 밖으로 충분히 스와이프 가능하도록 여백 부여
                    constrained: false, // 자식 크기 무한 확장 허용
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/phone_info/basic_image.png'),
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.none,
                        ),
                      ),
                      child: Center(
                        child: BoardGridWidget(
                          board: board,
                          goalCards: goalCards,
                          cellWidth: cellWidth,
                          cellHeight: cellHeight,
                          validOverlayCoords: validCoords,
                            onGridTap: (x, y) async {
                              // 사용자 피드백 (에러 팝업)을 위해 명시적으로 Validator.getPlacementError 호출
                              if (state.pendingAction != null && state.pendingAction!['type'] == 'path') {
                                final cardId = state.pendingAction!['cardId'];
                                final isRotated = state.pendingAction!['isRotated'] == true;
                                final baseCard = CardDatabase.getCardById(cardId);
                                if (baseCard != null) {
                                  final card = baseCard.copyWith(isRotated: isRotated);
                                  final fullBoard = [...board, ...goalCards];
                                  final error = Validator.getPlacementError(fullBoard, card, x, y);
                                  
                                  if (error != null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          backgroundColor: Colors.red[800],
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    return; // 에러가 있으면 진행 중지
                                  }
                                }
                              }

                              if (validCoords != null && validCoords!.contains('$x,$y')) {
                                try {
                                  if (state.pendingAction!['type'] == 'path') {
                                    await context.read<GameRepository>().playPathCard(
                                      widget.roomId,
                                      state.pendingAction!['playerId'],
                                      state.pendingAction!['cardId'],
                                      x,
                                      y,
                                      isRotated: state.pendingAction!['isRotated'] == true,
                                    );
                                  } else if (state.pendingAction!['type'] == 'action') {
                                    final cId = state.pendingAction!['cardId'];
                                    final actionCard = CardDatabase.getCardById(cId);
                                    if (actionCard != null && 
                                        (actionCard.actionType == game_card.ActionType.rockfall ||
                                         actionCard.actionType == game_card.ActionType.map)) {
                                      await context.read<GameRepository>().playActionCard(
                                        widget.roomId,
                                        state.pendingAction!['playerId'],
                                        cId,
                                        targetX: x,
                                        targetY: y,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('동작 실패: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                      ),
                    ),
                  );
                },
              ),
              // 3. 상단 중앙 덱 정보 HUD (스크린샷 매칭)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildTopHUD(remainingCards),
                ),
              ),
              // 4. 행동 카드 대상 선택 UI (장비 파괴/수리)
              if (state.pendingAction != null && state.pendingAction!['type'] == 'action' && 
                  _isBreakOrFixCard(state.pendingAction!['cardId']))
                Positioned(
                  right: 16,
                  top: 100,
                  bottom: 100,
                  child: _buildPlayerTargetList(context, state),
                ),
              // 승리 알림 패널 및 로비로 돌아가기
              if (state.isGameOver)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '게임 종료! 승리: ${state.winner == 'miner' ? '광부' : '방해꾼'}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          onPressed: () {
                            // 방을 떠나거나, 단순히 로비 라우트로 변경
                            Navigator.of(context).pushReplacementNamed('/');
                          },
                          child: const Text('로비로 돌아가기', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  /// 스크린샷 상단 중앙의 하얀 반투명 박스 (남은 카드 개수 등 표시)
  Widget _buildTopHUD(int remainingCards) {
    return GestureDetector(
      onTap: () {}, // 실제 드로우 로직은 엔진에서 처리
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 왼쪽 덱 아이콘 (사용자가 첨부한 012_black_01.png 에셋 매핑)
            Container(
              width: 24,
              height: 36,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/board_info/006_card_back_side/012_black_01.png'), // 블랙 에셋
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 중앙 "X 30" 텍스트 (상태 연동)
            Text(
              'X $remainingCards',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w300, // 얇은 폰트 스타일
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 32),
            // 오른쪽 달/반달 모양 아이콘
            const Icon(
              Icons.nightlight_round,
              color: Colors.black,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTargetList(BuildContext context, GameState state) {
    final pendingCardId = state.pendingAction!['cardId'];
    final pendingPlayerId = state.pendingAction!['playerId'];
    final actionCard = CardDatabase.getCardById(pendingCardId);
    final isBreakCard = actionCard != null && (
        actionCard.actionType == game_card.ActionType.breakPickaxe || 
        actionCard.actionType == game_card.ActionType.breakLantern || 
        actionCard.actionType == game_card.ActionType.breakCart);
    
    // 고장 카드는 자기 자신에게 사용 불가 (수리 카드는 가능)
    final targetPlayers = state.players.where((p) {
      if (isBreakCard && p.id == pendingPlayerId) return false;
      return true;
    }).toList();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '대상 선택',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white54),
          Expanded(
            child: ListView.builder(
              itemCount: targetPlayers.length,
              itemBuilder: (context, index) {
                final p = targetPlayers[index];
                return ListTile(
                  title: Text(p.id, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '곡괭이:${p.isPickaxeBroken?'❌':'✅'} 수레:${p.isCartBroken?'❌':'✅'} 랜턴:${p.isLanternBroken?'❌':'✅'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  onTap: () async {
                    try {
                      await context.read<GameRepository>().playActionCard(
                        widget.roomId,
                        state.pendingAction!['playerId'],
                        state.pendingAction!['cardId'],
                        targetPlayerId: p.id,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('동작 실패: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 카드 ID가 장비 파괴/수리 행동 카드인지 확인하는 헬퍼
  bool _isBreakOrFixCard(String cardId) {
    final card = CardDatabase.getCardById(cardId);
    if (card == null || card.type != game_card.CardType.action) return false;
    return card.actionType == game_card.ActionType.breakPickaxe ||
           card.actionType == game_card.ActionType.breakLantern ||
           card.actionType == game_card.ActionType.breakCart ||
           card.actionType == game_card.ActionType.fixPickaxe ||
           card.actionType == game_card.ActionType.fixLantern ||
           card.actionType == game_card.ActionType.fixCart ||
           card.actionType == game_card.ActionType.fixCartOrLantern ||
           card.actionType == game_card.ActionType.fixCartOrPickaxe ||
           card.actionType == game_card.ActionType.fixLanternOrPickaxe;
  }
}
