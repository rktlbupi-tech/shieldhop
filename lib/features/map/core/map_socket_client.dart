import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MapSocketClient {
  static const String _heatmapUrl =
      'https://dev-api.presshop.news:3005/enterprise-live';

  static io.Socket? _heatmapSocket;
  static io.Socket? get heatmapSocket => _heatmapSocket;

  static io.Socket connectHeatmap(String token) {
    print('[MapSocketClient] connectHeatmap called with token: ${token.substring(0, (token.length > 10 ? 10 : token.length))}...');
    if (_heatmapSocket != null && _heatmapSocket!.connected) {
      print('[MapSocketClient] Already connected to heatmap socket.');
      return _heatmapSocket!;
    }

    _heatmapSocket = io.io(
      _heatmapUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(-1)
          .setReconnectionDelay(1000)
          .build(),
    );

    _heatmapSocket?.onConnect((_) {
      print('[MapSocketClient] Connected to heatmap socket [${_heatmapSocket?.id}]');
    });
    _heatmapSocket?.onDisconnect((reason) {
      print('[MapSocketClient] Disconnected from heatmap socket [$reason]');
    });
    _heatmapSocket?.onConnectError((error) {
      print('[MapSocketClient] Connection Error on heatmap socket [$error]');
    });

    _heatmapSocket?.connect();
    return _heatmapSocket!;
  }

  static void disconnect() {
    _heatmapSocket?.disconnect();
    _heatmapSocket?.dispose();
    _heatmapSocket = null;
  }
}
