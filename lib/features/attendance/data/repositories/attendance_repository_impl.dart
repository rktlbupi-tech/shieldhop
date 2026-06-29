import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDatasource _ds;
  AttendanceRepositoryImpl(this._ds);

  @override
  Future<(bool, Failure?)> checkIn(double lat, double lng) async {
    try { return (await _ds.checkIn(lat, lng), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }

  @override
  Future<(String?, Failure?)> uploadSelfie(File file) async {
    try { return (await _ds.uploadSelfie(file), null); }
    on Failure catch (f) { return (null, f); }
    catch (e) { return (null, UnknownFailure(e.toString())); }
  }

  @override
  Future<(bool, Failure?)> punch({
    required String kind,
    double? lat,
    double? lng,
    double? accuracyMeters,
    String? photoUrl,
  }) async {
    try {
      final ok = await _ds.punch(
        kind: kind,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracyMeters,
        photoUrl: photoUrl,
      );
      return (ok, null);
    } on Failure catch (f) {
      return (false, f);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> checkOut(double lat, double lng) async {
    try { return (await _ds.checkOut(lat, lng), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }

  @override
  Future<(List<AttendanceLogEntity>, Failure?)> fetchLog({int days = 30}) async {
    try {
      final models = await _ds.fetchLog(days: days);
      return (models.map((m) => m.toEntity()).toList(), null);
    } on NotFoundFailure {
      return (const <AttendanceLogEntity>[], null);
    } on Failure catch (f) {
      return (<AttendanceLogEntity>[], f);
    } catch (e) {
      return (<AttendanceLogEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AttendanceSummaryEntity?, Failure?)> fetchSummary() async {
    try {
      return ((await _ds.fetchSummary()).toEntity(), null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<AttendanceIssueEntity>, Failure?)> fetchIssues({
    int limit = 50,
  }) async {
    try {
      final models = await _ds.fetchIssues(limit: limit);
      return (models.map((m) => m.toEntity()).toList(), null);
    } on NotFoundFailure {
      return (const <AttendanceIssueEntity>[], null);
    } on Failure catch (f) {
      return (<AttendanceIssueEntity>[], f);
    } catch (e) {
      return (<AttendanceIssueEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AttendanceIssueEntity?, Failure?)> raiseIssue({
    required String type,
    String? date,
    required String details,
  }) async {
    try {
      final model = await _ds.raiseIssue(
        type: type,
        date: date,
        details: details,
      );
      return (model.toEntity(), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
