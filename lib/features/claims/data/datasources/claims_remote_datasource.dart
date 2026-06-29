import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/claim_entities.dart';
import '../models/claim_models.dart';

class ClaimsRemoteDatasource {
  final ApiClient _client;
  ClaimsRemoteDatasource(this._client);

  Future<ClaimsSummaryModel> fetchSummary({
    ClaimPeriod period = ClaimPeriod.thisMonth,
  }) async {
    final res = await _client.get(
      ApiEndpoints.claimsSummary,
      queryParameters: {'period': period.value},
    );
    return ClaimsSummaryModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<ClaimModel>> fetchClaims({int limit = 50}) async {
    final res = await _client.get(
      ApiEndpoints.claims,
      queryParameters: {'limit': limit},
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a receipt image via the shared media flow and returns its URL.
  Future<String> uploadReceipt(File file) async {
    final fileName = p.basename(file.path);
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path, filename: fileName),
      'path': 'claims',
    });
    final res = await _client.post(ApiEndpoints.uploadUserMedia, data: form);
    final data = res.data;
    String? url = data['mediaurl'] ?? data['mediaUrl'];
    if (url == null && data['fileName'] != null) {
      url = AppConfig.apiBaseUrl + data['fileName'];
    }
    if (url == null || url.isEmpty) {
      throw const ServerFailure('Failed to upload receipt');
    }
    return url;
  }

  Future<ClaimModel> addClaim({
    required String category,
    String? claimDate,
    required String description,
    required double amount,
    String? receiptUrl,
  }) async {
    final res = await _client.post(ApiEndpoints.claims, data: {
      'category': category,
      if (claimDate != null) 'claim_date': claimDate,
      'description': description,
      'amount': amount,
      if (receiptUrl != null && receiptUrl.isNotEmpty) 'receipt_url': receiptUrl,
    });
    return ClaimModel.fromJson(res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
