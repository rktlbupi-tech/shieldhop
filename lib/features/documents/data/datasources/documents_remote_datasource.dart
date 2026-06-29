import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/document_model.dart';

class DocumentsRemoteDatasource {
  final ApiClient _client;
  DocumentsRemoteDatasource(this._client);

  Future<List<DocumentModel>> fetchDocuments() async {
    final res = await _client.get(ApiEndpoints.documents);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads the file via the shared media flow and returns its hosted URL.
  Future<String> uploadFile(File file) async {
    final fileName = p.basename(file.path);
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path, filename: fileName),
      'path': 'documents',
    });
    final res = await _client.post(ApiEndpoints.uploadUserMedia, data: form);
    final data = res.data;
    String? url = data['mediaurl'] ?? data['mediaUrl'];
    if (url == null && data['fileName'] != null) {
      url = AppConfig.apiBaseUrl + data['fileName'];
    }
    if (url == null || url.isEmpty) {
      throw const ServerFailure('Failed to upload file');
    }
    return url;
  }

  Future<DocumentModel> addDocument({
    required String name,
    required String category,
    String? fileUrl,
    int? sizeBytes,
  }) async {
    final res = await _client.post(ApiEndpoints.documents, data: {
      'name': name,
      'category': category,
      if (fileUrl != null && fileUrl.isNotEmpty) 'file_url': fileUrl,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
    });
    return DocumentModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteDocument(String id) async {
    await _client.delete('${ApiEndpoints.documents}/$id');
  }
}
