import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          if (state.pendingAction != null && state.pendingAction!['type'] == 'path') {
            validCoords = {};
            final card = game_card.Card(
              id: state.pendingAction!['cardId'],
              type: game_card.CardType.path,
              hasTop: true, hasBottom: true, hasLeft: true, hasRight: true, hasCenter: true,
            );
            
            // 현재 보드의 모든 노드 범위에서 한 칸씩 더 넓게 탐색
            int minX = 0, maxX = 11, minY = 0, maxY = 6;
            for (var node in [...board, ...goalCards]) {
              if (node.x < minX) minX = node.x;
              if (node.x > maxX) maxX = node.x;
              if (node.y < minY) minY = node.y;
              if (node.y > maxY) maxY = node.y;
            }
            
            for (int x = minX - 1; x <= maxX + 1; x++) {
              for (int y = minY - 1; y <= maxY + 1; y++) {
                if (Validator.canPlaceCard(board, card, x, y)) {
                  validCoords.add('$x,$y');
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
                    child: Center(
                      child: Stack(
                        children: [
                          // 배경 이미지
                          Positioned.fill(
                            child: Image.asset(
                              'assets/phone_info/basic_image.png',
                              repeat: ImageRepeat.repeat,
                              fit: BoxFit.none,
                            ),
                          ),
                          
                          // 보드 격자
                          BoardGridWidget(
                            board: board,
                            goalCards: goalCards,
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            validOverlayCoords: validCoords,
                            onGridTap: (x, y) async {
                              if (validCoords != null && validCoords!.contains('$x,$y')) {
                                try {
                                  await context.read<GameRepository>().playPathCard(
                                    widget.roomId,
                                    state.pendingAction!['playerId'],
                                    state.pendingAction!['cardId'],
                                    x,
                                    y,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('카드 놓기 실패: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
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
              // 승리 알림 패널
              if (state.isGameOver)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '게임 종료! 승리: ${state.winner == 'miner' ? '광부' : '방해꾼'}',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber),
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                image: const DecorationImage(
                  image: AssetImage('assets/board_info/012_black/012_black_01.png'), // 블랙 에셋
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
}
