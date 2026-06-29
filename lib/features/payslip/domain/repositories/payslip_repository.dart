import '../../../../core/errors/failures.dart';
import '../entities/payslip_entities.dart';

abstract class PayslipRepository {
  Future<(List<PayslipListItem>, Failure?)> fetchPayslips();
  Future<(PayslipDetail?, Failure?)> fetchPayslip(String id);
}
