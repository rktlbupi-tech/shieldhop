import '../../../../core/errors/failures.dart';
import '../../domain/entities/duty_entities.dart';
import '../../domain/repositories/duties_repository.dart';
import '../datasources/duties_remote_datasource.dart';

class DutiesRepositoryImpl implements DutiesRepository {
  final DutiesRemoteDatasource _ds;
  DutiesRepositoryImpl(this._ds);

  @override
  Future<(DutyCurrentEntity?, Failure?)> fetchCurrent() async {
    try {
      return ((await _ds.fetchCurrent()).toEntity(), null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<UpcomingShiftEntity>, Failure?)> fetchUpcoming() async {
    try {
      final models = await _ds.fetchUpcoming();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on NotFoundFailure {
      return (const <UpcomingShiftEntity>[], null);
    } on Failure catch (f) {
      return (<UpcomingShiftEntity>[], f);
    } catch (e) {
      return (<UpcomingShiftEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<TodayTaskEntity>, Failure?)> fetchTodayTasks() async {
    try {
      final models = await _ds.fetchTodayTasks();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on NotFoundFailure {
      return (const <TodayTaskEntity>[], null);
    } on Failure catch (f) {
      return (<TodayTaskEntity>[], f);
    } catch (e) {
      return (<TodayTaskEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(DutyHistoryEntity?, Failure?)> fetchHistory({
    DutyHistoryRange range = DutyHistoryRange.lastYear,
  }) async {
    try {
      return ((await _ds.fetchHistory(range: range)).toEntity(), null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(HandoverReportEntity?, Failure?)> submitHandoverReport({
    required String siteName,
    required String details,
  }) async {
    try {
      final model = await _ds.submitHandoverReport(
        siteName: siteName,
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
