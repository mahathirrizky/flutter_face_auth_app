import 'dart:convert';
import 'package:web_socket_channel/io.dart';


class WebSocketService {
  IOWebSocketChannel? _channel;
  final String fullWebSocketUrl;
  final Function(dynamic) onMessageReceived;
  final Function(String) onError;
  final Function() onDisconnected;

  WebSocketService({
    required this.fullWebSocketUrl,
    required this.onMessageReceived,
    required this.onError,
    required this.onDisconnected,
  });

  void connect() {
    if (_channel != null) {
      print('WebSocket already connected or connecting.');
      return;
    }

    if (fullWebSocketUrl.isEmpty) {
      onError('WebSocket URL not provided. WebSocket connection failed.');
      return;
    }

    print('Attempting to connect to WebSocket: $fullWebSocketUrl');

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(fullWebSocketUrl));

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
          onDisconnected();
          _channel = null; // Clear the channel on disconnect
        },
        onError: (error) {
          print('WebSocket error: $error');
          onError('WebSocket error: $error');
          _channel = null; // Clear the channel on error
        },
        cancelOnError: true, // Close the stream if an error occurs
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      onError('WebSocket connection failed: $e');
      _channel = null;
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      print('WebSocket not connected. Cannot send message: $message');
    }
  }

  void disconnect() {
    if (_channel != null) {
      print('Disconnecting WebSocket.');
      _channel!.sink.close();
      _channel = null;
    }
  }
}