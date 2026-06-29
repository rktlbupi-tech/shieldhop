import '../../../../core/errors/failures.dart';
import '../entities/duty_entities.dart';

abstract class DutiesRepository {
  /// Current shift banner + site card + this-month summary.
  Future<(DutyCurrentEntity?, Failure?)> fetchCurrent();

  /// Future-dated assigned duties, soonest first.
  Future<(List<UpcomingShiftEntity>, Failure?)> fetchUpcoming();

  /// Today's task checklist.
  Future<(List<TodayTaskEntity>, Failure?)> fetchTodayTasks();

  /// Shift history summary + rows for the given [range].
  Future<(DutyHistoryEntity?, Failure?)> fetchHistory({DutyHistoryRange range});

  /// Notify the supervisor of a handover issue.
  Future<(HandoverReportEntity?, Failure?)> submitHandoverReport({
    required String siteName,
    required String details,
  });
}
