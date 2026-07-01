import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/models/lobby_state.dart';

class HostWaitingView extends StatefulWidget {
  final String roomId;
  const HostWaitingView({super.key, required this.roomId});

  @override
  State<HostWaitingView> createState() => _HostWaitingViewState();
}

class _HostWaitingViewState extends State<HostWaitingView> {
  bool _isStarting = false;

  Future<void> _startGame(LobbyState lobby) async {
    if (lobby.players.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플레이어가 한 명 이상 필요합니다.')),
      );
      return;
    }
    setState(() => _isStarting = true);
    try {
      final repo = context.read<GameRepository>();
      await repo.startGameFromLobby(widget.roomId);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/table?room=${widget.roomId}');
      }
    } catch (e) {
      setState(() => _isStarting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 시작 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GameRepository>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1F),
      appBar: AppBar(
        title: const Text('대기실'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<LobbyState?>(
        stream: repo.lobbyStream(widget.roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lobby = snapshot.data!;
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '입장 코드',
                  style: TextStyle(color: Colors.white70, fontSize: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  lobby.roomId,
                  style: const TextStyle(
                    color: Colors.amber, 
                    fontSize: 64, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  '접속한 플레이어',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 16),
                if (lobby.players.isEmpty)
                  const Text('플레이어를 기다리는 중...', style: TextStyle(color: Colors.white54)),
                ...lobby.players.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(p.nickname, style: const TextStyle(color: Colors.white, fontSize: 18)),
                )),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  onPressed: _isStarting ? null : () => _startGame(lobby),
                  child: _isStarting
                      ? const CircularProgressIndicator()
                      : const Text('게임 시작', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

