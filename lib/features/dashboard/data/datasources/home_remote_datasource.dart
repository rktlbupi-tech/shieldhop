import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/home_entities.dart';
import '../models/home_model.dart';

class HomeRemoteDatasource {
  final ApiClient _client;
  HomeRemoteDatasource(this._client);

  Future<HomeData> fetchHome() async {
    final res = await _client.get(ApiEndpoints.home);
    return homeFromJson(res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
