import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/earning_model.dart';

class EarningsRemoteDatasource {
  final ApiClient _client;
  EarningsRemoteDatasource(this._client);

  Future<YearlyEarningsModel> fetchEarnings({int? year}) async {
    final res = await _client.get(
      ApiEndpoints.earnings,
      queryParameters: {if (year != null) 'year': year},
    );
    return YearlyEarningsModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
