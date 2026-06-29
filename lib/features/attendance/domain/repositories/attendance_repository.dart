import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  Future<(bool, Failure?)> checkIn(double lat, double lng);
  Future<(bool, Failure?)> checkOut(double lat, double lng);
  Future<(List<AttendanceLogEntity>, Failure?)> fetchLog({int days});
  Future<(AttendanceSummaryEntity?, Failure?)> fetchSummary();

  /// My raised attendance issues, newest first.
  Future<(List<AttendanceIssueEntity>, Failure?)> fetchIssues({int limit});

  /// Raise an attendance issue. [date] is YYYY-MM-DD (or null for today).
  Future<(AttendanceIssueEntity?, Failure?)> raiseIssue({
    required String type,
    String? date,
    required String details,
  });

  /// Uploads the uniform selfie, returning its hosted URL (or a [Failure]).
  Future<(String?, Failure?)> uploadSelfie(File file);

  /// Records an attendance punch (clock_in / break_start / break_end /
  /// clock_out) for the logged-in worker.
  Future<(bool, Failure?)> punch({
    required String kind,
    double? lat,
    double? lng,
    double? accuracyMeters,
    String? photoUrl,
  });
}
