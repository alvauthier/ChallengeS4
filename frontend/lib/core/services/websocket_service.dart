import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  
  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  WebSocketChannel? _channel;
  Stream? _broadcastStream;

  Stream? get stream => _broadcastStream;

  void connect(String concertId, String userId) {
    if (_channel != null) {
      debugPrint('WebSocket already connected.');
      return;
    }

    final protocol = dotenv.env['API_PROTOCOL'] == 'http' ? 'ws' : 'wss';
    final wsUrl = Uri.parse('$protocol://${dotenv.env['API_HOST']}${dotenv.env['API_PORT']}/ws-queue?concertId=$concertId&userId=$userId');

    debugPrint('Attempting WebSocket connection to: $wsUrl');
    
    _channel = WebSocketChannel.connect(wsUrl);
    _broadcastStream = _channel!.stream.asBroadcastStream();
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _broadcastStream = null;
      debugPrint('WebSocket disconnected.');
    } else {
      debugPrint('No active WebSocket channel to disconnect.');
    }
  }
}
