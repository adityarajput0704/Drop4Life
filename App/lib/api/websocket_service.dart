import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  // Callbacks — set by whoever needs to react to events
  VoidCallback? onNewRequest;
  VoidCallback? onRequestUpdated;

  void connect() {
    if (_isConnected) return;

    // Convert http URL to ws URL
    final wsUrl = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/donors'),
      );
      _isConnected = true;
      debugPrint('🔌 WebSocket connected: $wsUrl/ws/donors');

      _subscription = _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint('🔴 WebSocket error: $error');
          _isConnected = false;
          // Auto-reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), connect);
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed — reconnecting...');
          _isConnected = false;
          Future.delayed(const Duration(seconds: 5), connect);
        },
      );
    } catch (e) {
      debugPrint('🔴 WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = data['event'] as String?;
      debugPrint('📨 WebSocket event: $event');

      switch (event) {
        case 'request_created':
          onNewRequest?.call();
          break;
        case 'request_accepted':
        case 'request_fulfilled':
        case 'request_cancelled':
          onRequestUpdated?.call();
          break;
      }
    } catch (e) {
      debugPrint('🔴 WebSocket message parse error: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint('🔌 WebSocket disconnected');
  }
}