import 'package:flutter/material.dart';
import '../../data/game_state.dart';
import '../widgets/board_grid_widget.dart';
import '../widgets/player_status_bar.dart';

/// 호스트(태블릿) 뷰어
/// - /table?room={roomId} 경로로 접속한 기기에서 렌더링됩니다.
/// - MaskedGameState를 구독하여 전역 보드와 플레이어 상태를 표시합니다.
/// - InteractiveViewer로 멀티터치 팬/줌을 지원합니다.
class TableView extends StatelessWidget {
  final String roomId;

  const TableView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    // TODO (Phase 3): Firestore 스트림 연결 후 StreamBuilder로 교체
    // 현재는 UI 뼈대 확인을 위한 더미 상태를 사용합니다.
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 플레이어 상태 바
            _buildTopBar(),
            // 보드 영역 (InteractiveViewer)
            Expanded(
              child: _buildBoardArea(),
            ),
            // 하단 게임 정보 바 (라운드, 덱 장수 등)
            _buildBottomInfoBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // TODO: Firestore 구독 후 실제 maskedState로 교체
    return PlayerStatusBar(
      players: const [], // maskedState.maskedPlayers
      currentTurnPlayerId: '',
    );
  }

  Widget _buildBoardArea() {
    return Stack(
      children: [
        // 보드 배경 텍스처 느낌
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [Color(0xFF1C1C1C), Color(0xFF0D1117)],
            ),
          ),
        ),
        // InteractiveViewer: 멀티터치 팬/줌 지원 (context.md 규칙 1)
        Center(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.3,
            maxScale: 3.0,
            child: BoardGridWidget(
              board: const [],       // TODO: maskedState.board
              goalCards: const [],   // TODO: maskedState.goalCards
              cardSize: 72.0,
            ),
          ),
        ),
        // 방 ID 표시 (우측 상단 오버레이)
        Positioned(
          top: 12,
          right: 16,
          child: _RoomIdBadge(roomId: roomId),
        ),
      ],
    );
  }

  Widget _buildBottomInfoBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF161B22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 라운드 표시
          Row(
            children: const [
              Icon(Icons.loop, color: Colors.white54, size: 16),
              SizedBox(width: 6),
              Text(
                'Round 1',  // TODO: maskedState.currentRound
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          // 덱 남은 장수
          Row(
            children: const [
              Icon(Icons.layers, color: Colors.white54, size: 16),
              SizedBox(width: 6),
              Text(
                'Deck: --',  // TODO: maskedState.deckCount
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 방 코드 배지 (태블릿 화면 우측 상단)
class _RoomIdBadge extends StatelessWidget {
  final String roomId;
  const _RoomIdBadge({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.meeting_room_outlined, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Text(
            roomId.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
