import 'package:flutter/material.dart';
import 'views/table_view.dart';
import 'views/player_view.dart';
import 'views/lobby_view.dart';
import 'views/error_view.dart';
import 'views/host_waiting_view.dart';

/// URL 라우트 파라미터 기준으로 뷰를 분기합니다.
/// - /table?room={roomId}  -> TableView (호스트/태블릿)
/// - /player?room={roomId}&id={playerId} -> PlayerView (클라이언트/모바일)
/// - /host_waiting?room={roomId} -> HostWaitingView (대기실)
/// - / -> LobbyView (방 생성/입장)
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '/') ?? Uri.parse('/');

    switch (uri.path) {
      case '/host_waiting':
        final roomId = uri.queryParameters['room'];
        if (roomId == null || roomId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const ErrorView(message: 'room 파라미터가 누락되었습니다.'),
          );
        }
        return MaterialPageRoute(
          builder: (_) => HostWaitingView(roomId: roomId),
        );
      case '/table':
        final roomId = uri.queryParameters['room'];
        if (roomId == null || roomId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const ErrorView(message: 'room 파라미터가 누락되었습니다.'),
          );
        }
        return MaterialPageRoute(
          builder: (_) => TableView(roomId: roomId),
        );

      case '/player':
        final roomId = uri.queryParameters['room'];
        final playerId = uri.queryParameters['id'];
        if (roomId == null || playerId == null) {
          return MaterialPageRoute(
            builder: (_) => const ErrorView(message: 'room 또는 id 파라미터가 누락되었습니다.'),
          );
        }
        return MaterialPageRoute(
          builder: (_) => PlayerView(roomId: roomId, playerId: playerId),
        );

      case '/':
      default:
        return MaterialPageRoute(
          builder: (_) => const LobbyView(),
        );
    }
  }
}
