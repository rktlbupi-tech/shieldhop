import '../../../../core/network/api_client.dart';

class SubmitFormsRemoteDataSource {
  final ApiClient _client;
  SubmitFormsRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getAvailableForms({String? query}) async {
    final response = await _client.get(
      'enterprise/forms/available',
      queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubmissions({String? query}) async {
    final response = await _client.get(
      'enterprise/forms/submissions/mine',
      queryParameters: query != null && query.isNotEmpty ? {'q': query} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAppTokenUrl() async {
    final response = await _client.post('enterprise/forms/app-token');
    return response.data as Map<String, dynamic>;
  }
}
