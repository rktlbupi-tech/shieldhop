import '../../../../core/errors/failures.dart';
import '../../domain/entities/payslip_entities.dart';
import '../../domain/repositories/payslip_repository.dart';
import '../datasources/payslip_remote_datasource.dart';

class PayslipRepositoryImpl implements PayslipRepository {
  final PayslipRemoteDatasource _ds;
  PayslipRepositoryImpl(this._ds);

  @override
  Future<(List<PayslipListItem>, Failure?)> fetchPayslips() async {
    try {
      final models = await _ds.fetchPayslips();
      return (models.map((m) => m.entity).toList(), null);
    } on NotFoundFailure {
      return (const <PayslipListItem>[], null);
    } on Failure catch (f) {
      return (<PayslipListItem>[], f);
    } catch (e) {
      return (<PayslipListItem>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(PayslipDetail?, Failure?)> fetchPayslip(String id) async {
    try {
      return ((await _ds.fetchPayslip(id)).entity, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
