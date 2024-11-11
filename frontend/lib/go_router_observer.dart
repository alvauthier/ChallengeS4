import 'package:flutter/material.dart';
import 'package:weezemaster/core/services/websocket_service.dart';

class MyRouteObserver extends NavigatorObserver {
  final WebSocketService webSocketService = WebSocketService();

  @override
  void didPush(Route route, Route? previousRoute) {
    _manageWebSocketConnection(route.settings.name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _manageWebSocketConnection(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _manageWebSocketConnection(newRoute?.settings.name);
  }

  void _manageWebSocketConnection(String? routeName) {
    const keepConnectedRoutes = ['queue', 'concert', 'booking'];

    if (keepConnectedRoutes.contains(routeName)) {
      debugPrint('Keeping WebSocket connected on $routeName');
    } else {
      debugPrint('Disconnecting WebSocket from $routeName');
      webSocketService.disconnect();
    }
  }
}

final routeObserver = MyRouteObserver();
