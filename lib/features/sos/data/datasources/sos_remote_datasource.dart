import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/socket/socket_events.dart';
import '../../../../core/network/socket/socket_manager.dart';

class SosRemoteDataSource {
  final ApiClient _client;

  SosRemoteDataSource(this._client);

  Future<bool> startSos({required double lat, required double lng}) async {
    final response = await _client.post(
      ApiEndpoints.sosStart,
      data: {'lat': lat, 'lng': lng},
    );
    final success = response.data['success'] == true;
    if (success) {
      emitSosAlert(active: true);
    }
    return success;
  }

  Future<bool> stopSos() async {
    final response = await _client.post(
      ApiEndpoints.sosStop,
      data: {},
    );
    final success = response.data['success'] == true;
    if (success) {
      emitSosAlert(active: false);
    }
    return success;
  }

  void emitSosAlert({required bool active}) {
    if (active) {
      SocketManager.instance.liveSocket.emit(SocketEvents.sosAlert, {'active': true});
    } else {
      SocketManager.instance.liveSocket.emit(SocketEvents.sosStopped, {'active': false});
    }
  }
}
