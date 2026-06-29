import '../../../../core/errors/failures.dart';

abstract class SettingsRepository {
  Future<(bool, Failure?)> deleteAccount(Map<String, String> reason);
  Future<(bool, Failure?)> contactUs(Map<String, String> data);
  Future<(String?, Failure?)> fetchAdminDetails();
  Future<(String?, Failure?)> fetchLegalTerms(String type);
  Future<(bool, Failure?)> changePassword(Map<String, String> data);
}
