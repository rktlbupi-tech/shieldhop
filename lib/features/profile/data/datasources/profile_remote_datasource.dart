import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final ApiClient _client;
  ProfileRemoteDatasource(this._client);

  Future<ProfileModel> fetchProfile() async {
    final res = await _client.get(ApiEndpoints.getProfile);
    final data = res.data['user'] ?? res.data['data'] ?? res.data;
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final res = await _client.patch(ApiEndpoints.updateProfile, data: data);
    return res.data['success'] == true || res.data['status'] == 'success';
  }

  Future<String> uploadMedia(File file) async {
    final fileName = path.basename(file.path);
    final uploadFormData = FormData.fromMap({
      "media": await MultipartFile.fromFile(file.path, filename: fileName),
      "path": "user",
    });

    final res = await _client.post("hopper/uploadUserMedia", data: uploadFormData);
    final responseData = res.data;
    
    String? uploadedImageUrl = responseData['mediaurl'] ?? responseData['mediaUrl'];
    if (uploadedImageUrl == null && responseData['fileName'] != null) {
      uploadedImageUrl = AppConfig.apiBaseUrl + responseData['fileName'];
    }
    
    if (uploadedImageUrl == null) {
      throw const ServerFailure("Failed to upload image");
    }
    return uploadedImageUrl;
  }
}
