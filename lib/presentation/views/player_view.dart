// Placeholder for PlayerView — will be fully implemented in Phase 4
import 'package:flutter/material.dart';

class PlayerView extends StatelessWidget {
  final String roomId;
  final String playerId;

  const PlayerView({super.key, required this.roomId, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Text(
          'Phase 4에서 구현 예정\nRoom: $roomId / Player: $playerId',
          style: const TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
