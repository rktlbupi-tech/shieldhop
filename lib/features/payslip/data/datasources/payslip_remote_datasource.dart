import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/payslip_models.dart';

class PayslipRemoteDatasource {
  final ApiClient _client;
  PayslipRemoteDatasource(this._client);

  Future<List<PayslipListItemModel>> fetchPayslips() async {
    final res = await _client.get(ApiEndpoints.payslips);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => PayslipListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PayslipDetailModel> fetchPayslip(String id) async {
    final res = await _client.get('${ApiEndpoints.payslips}/$id');
    return PayslipDetailModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
