import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/lobby_state.dart';

class PlayerWaitingView extends StatefulWidget {
  final String roomId;
  final String playerId;

  const PlayerWaitingView({super.key, required this.roomId, required this.playerId});

  @override
  State<PlayerWaitingView> createState() => _PlayerWaitingViewState();
}

class _PlayerWaitingViewState extends State<PlayerWaitingView> {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1F),
      body: StreamBuilder<LobbyState?>(
        stream: repo.lobbyStream(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lobby = snapshot.data!;
          
          // 호스트가 게임을 시작하면 status가 'playing'으로 변경됨
          if (lobby.status == 'playing') {
            // 빌드 도중 네비게이션을 피하기 위해 addPostFrameCallback 사용
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/player?room=${widget.roomId}&id=${widget.playerId}');
              }
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 24),
                const Text(
                  '호스트가 게임을 시작할 때까지 기다려주세요...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  '방 코드: ${lobby.roomId}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

