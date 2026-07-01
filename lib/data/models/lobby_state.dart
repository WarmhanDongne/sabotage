class LobbyPlayer {
  final String uid;
  final String nickname;

  const LobbyPlayer({required this.uid, required this.nickname});

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'nickname': nickname,
  };

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) {
    return LobbyPlayer(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String,
    );
  }
}

class LobbyState {
  final String roomId;
  final String hostId;
  final List<LobbyPlayer> players;
  final String status; // 'waiting', 'playing'

  const LobbyState({
    required this.roomId,
    required this.hostId,
    this.players = const [],
    this.status = 'waiting',
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'hostId': hostId,
    'players': players.map((p) => p.toJson()).toList(),
    'status': status,
  };

  factory LobbyState.fromJson(Map<String, dynamic> json) {
    return LobbyState(
      roomId: json['roomId'] as String,
      hostId: json['hostId'] as String,
      players: (json['players'] as List<dynamic>?)
              ?.map((e) => LobbyPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'waiting',
    );
  }
}

