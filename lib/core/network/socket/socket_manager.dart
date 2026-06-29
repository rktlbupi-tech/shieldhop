import '../../config/app_config.dart';
import 'socket_client.dart';

class SocketManager {
  SocketManager._();
  static final SocketManager instance = SocketManager._();

  late final SocketClient chatSocket;
  late final SocketClient liveSocket;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    chatSocket = SocketClient(url: AppConfig.chatSocketUrl, name: 'Chat');
    liveSocket = SocketClient(url: AppConfig.liveSocketUrl, name: 'Live');
    _initialized = true;
  }

  void connectAll(String token) {
    _assertInitialized();
    chatSocket.connect(token);
    liveSocket.connect(token);
  }

  void disconnectAll() {
    _assertInitialized();
    chatSocket.disconnect();
    liveSocket.disconnect();
  }

  bool get isChatConnected => _initialized && chatSocket.isConnected;
  bool get isLiveConnected => _initialized && liveSocket.isConnected;

  void _assertInitialized() {
    assert(_initialized, 'SocketManager must be initialized before use. Call SocketManager.instance.init() first.');
  }
}
