import '../../../../core/errors/failures.dart';
import '../../domain/entities/form_entity.dart';
import '../../domain/repositories/submit_forms_repository.dart';
import '../datasources/submit_forms_remote_datasource.dart';
import '../models/form_model.dart';

class SubmitFormsRepositoryImpl implements SubmitFormsRepository {
  final SubmitFormsRemoteDataSource _remoteDataSource;
  SubmitFormsRepositoryImpl(this._remoteDataSource);

  @override
  Future<(List<FormEntity>?, Failure?)> getAvailableForms({String? query}) async {
    try {
      final response = await _remoteDataSource.getAvailableForms(query: query);
      if (response['success'] == true) {
        final items = (response['items'] as List<dynamic>?) ?? [];
        final forms = items
            .map((e) => FormModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
            .toList();
        return (forms, null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to fetch available forms'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<FormSubmissionEntity>?, Failure?)> getSubmissions({String? query}) async {
    try {
      final response = await _remoteDataSource.getSubmissions(query: query);
      if (response['success'] == true) {
        final items = (response['items'] as List<dynamic>?) ?? [];
        final submissions = items
            .map((e) => FormSubmissionModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
            .toList();
        return (submissions, null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to fetch submissions'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(String?, Failure?)> getAppTokenUrl() async {
    try {
      final response = await _remoteDataSource.getAppTokenUrl();
      if (response['success'] == true && response['url'] != null) {
        return (response['url'].toString(), null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to get app token URL'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
