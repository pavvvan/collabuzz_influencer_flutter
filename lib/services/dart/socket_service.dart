import 'package:influencer_dashboard/services/dart/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  void connect(String token) {
    _socket = IO.io(
      BASE_URL, // Replace with your server URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) => print('✅ Socket connected (Influencer)'));
    _socket?.onDisconnect((_) => print('❌ Socket disconnected'));
    _socket?.onError((err) => print('Socket error: $err'));
  }

  void joinChat(String chatId) {
    _socket?.emit('joinChat', chatId);
  }

  void sendMessage(String chatId, String message, {String type = 'text'}) {
    _socket?.emit('sendMessage', {
      'chatId': chatId,
      'message': message,
      'messageType': type,
    });
  }

  void listenMessages(Function(Map<String, dynamic>) onMessage) {
    _socket?.on('newMessage', (data) {
      if (data != null) {
        onMessage(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}
