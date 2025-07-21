import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  IOWebSocketChannel? _channel;
  final String fullWebSocketUrl;
  final Function(dynamic) onMessageReceived;
  final Function(String) onError;
  final Function() onDisconnected;
  bool _isConnecting = false;
  bool _isConnected = false;
  int _retryCount = 0;
  Timer? _reconnectTimer;

  WebSocketService({
    required this.fullWebSocketUrl,
    required this.onMessageReceived,
    required this.onError,
    required this.onDisconnected,
  });

  void connect() {
    if (_isConnecting || _isConnected) {
      print('WebSocket already connected or connecting.');
      return;
    }

    if (fullWebSocketUrl.isEmpty) {
      onError('WebSocket URL not provided. WebSocket connection failed.');
      return;
    }

    _isConnecting = true;
    print('Attempting to connect to WebSocket: $fullWebSocketUrl (Attempt: ${_retryCount + 1})');

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(fullWebSocketUrl));
      _isConnected = true;
      _isConnecting = false;
      _retryCount = 0; // Reset retry count on successful connection
      print('WebSocket connected successfully.');

      _channel!.stream.listen(
        (message) {
          print('Received WebSocket message: $message');
          try {
            final decodedMessage = jsonDecode(message);
            onMessageReceived(decodedMessage);
          } catch (e) {
            print('Error decoding WebSocket message: $e');
            onError('Error decoding WebSocket message: $e');
          }
        },
        onDone: () {
          print('WebSocket disconnected.');
          _handleDisconnect();
        },
        onError: (error) {
          print('WebSocket error: $error');
          onError('WebSocket error: $error');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      onError('WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (!_isConnected) return; // Avoid multiple disconnect handlers

    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    onDisconnected();

    // Exponential backoff for reconnection
    final delay = Duration(seconds: 2 * (_retryCount + 1));
    print('Will attempt to reconnect in ${delay.inSeconds} seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _retryCount++;
      connect();
    });
  }

  void sendMessage(String message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
    } else {
      print('WebSocket not connected. Cannot send message: $message');
    }
  }

  void disconnect() {
    print('Disconnecting WebSocket manually.');
    _reconnectTimer?.cancel(); // Cancel any pending reconnection attempts
    _retryCount = 0;
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _isConnecting = false;
  }
}
