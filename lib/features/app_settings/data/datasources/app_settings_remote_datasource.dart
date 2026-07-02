import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/app_settings_model.dart';

class AppSettingsRemoteDatasource {
  final ApiClient _client;
  AppSettingsRemoteDatasource(this._client);

  /// GET enterprise/app/app-settings — self-scoped (employee from the token).
  Future<AppSettingsModel> fetch() async {
    final res = await _client.get(ApiEndpoints.appSettings);
    final data = res.data['data'] as Map<String, dynamic>? ?? const {};
    return AppSettingsModel.fromJson(data);
  }
}
