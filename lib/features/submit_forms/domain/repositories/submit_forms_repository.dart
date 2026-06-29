import '../../../../core/errors/failures.dart';
import '../entities/form_entity.dart';

abstract class SubmitFormsRepository {
  Future<(List<FormEntity>?, Failure?)> getAvailableForms({String? query});
  Future<(List<FormSubmissionEntity>?, Failure?)> getSubmissions({String? query});
  Future<(String?, Failure?)> getAppTokenUrl();
}
