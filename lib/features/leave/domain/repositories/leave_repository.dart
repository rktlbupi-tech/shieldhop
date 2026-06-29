import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/leave_entities.dart';

abstract class LeaveRepository {
  Future<(String?, Failure?)> uploadAttachment(File file);
  Future<(List<LeaveTypeEntity>, Failure?)> fetchTypes();
  Future<(List<LeaveBalanceEntity>, Failure?)> fetchBalances();

  Future<(LeaveRequestEntity?, Failure?)> applyLeave({
    required String leaveTypeId,
    required String from,
    required String to,
    String halfDay,
    String reason,
    List<LeaveAttachment> attachments,
  });

  Future<(LeaveRequestPage?, Failure?)> fetchRequests({
    String? status,
    int? year,
    int page,
    int limit,
  });

  Future<(LeaveRequestEntity?, Failure?)> fetchRequest(String id);
  Future<(LeaveRequestEntity?, Failure?)> cancelRequest(String id);
  Future<(LeaveCalendarEntity?, Failure?)> fetchCalendar({String? month});
}
