import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/leave_entities.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_datasource.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDatasource _ds;
  LeaveRepositoryImpl(this._ds);

  @override
  Future<(String?, Failure?)> uploadAttachment(File file) async {
    try {
      return (await _ds.uploadFile(file), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<LeaveTypeEntity>, Failure?)> fetchTypes() async {
    try {
      return (await _ds.fetchTypes(), null);
    } on NotFoundFailure {
      return (const <LeaveTypeEntity>[], null);
    } on Failure catch (f) {
      return (<LeaveTypeEntity>[], f);
    } catch (e) {
      return (<LeaveTypeEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<LeaveBalanceEntity>, Failure?)> fetchBalances() async {
    try {
      return (await _ds.fetchBalances(), null);
    } on NotFoundFailure {
      return (const <LeaveBalanceEntity>[], null);
    } on Failure catch (f) {
      return (<LeaveBalanceEntity>[], f);
    } catch (e) {
      return (<LeaveBalanceEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LeaveRequestEntity?, Failure?)> applyLeave({
    required String leaveTypeId,
    required String from,
    required String to,
    String halfDay = 'none',
    String reason = '',
    List<LeaveAttachment> attachments = const [],
  }) async {
    try {
      final r = await _ds.applyLeave(
        leaveTypeId: leaveTypeId,
        from: from,
        to: to,
        halfDay: halfDay,
        reason: reason,
        attachments: attachments,
      );
      return (r, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LeaveRequestPage?, Failure?)> fetchRequests({
    String? status,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final p = await _ds.fetchRequests(
          status: status, year: year, page: page, limit: limit);
      return (p, null);
    } on NotFoundFailure {
      return (const LeaveRequestPage(), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LeaveRequestEntity?, Failure?)> fetchRequest(String id) async {
    try {
      return (await _ds.fetchRequest(id), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LeaveRequestEntity?, Failure?)> cancelRequest(String id) async {
    try {
      return (await _ds.cancelRequest(id), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LeaveCalendarEntity?, Failure?)> fetchCalendar({String? month}) async {
    try {
      return (await _ds.fetchCalendar(month: month), null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
