import '../../domain/entities/app_settings_entity.dart';

/// Missing / non-bool → `true` (forward-compat default from the doc).
bool _b(dynamic v) => v is bool ? v : true;

class AppSettingsModel {
  final String employeeId;
  final DashboardVisibility dashboard;
  final MenuVisibility menu;

  const AppSettingsModel({
    required this.employeeId,
    required this.dashboard,
    required this.menu,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final dash = (json['dashboard'] as Map<String, dynamic>?) ?? const {};
    final menu = (json['menu'] as Map<String, dynamic>?) ?? const {};
    return AppSettingsModel(
      employeeId: (json['employee_id'] ?? json['employeeId'] ?? '').toString(),
      dashboard: DashboardVisibility(
        captureMoment: _b(dash['captureMoment']),
        task: _b(dash['task']),
        duties: _b(dash['duties']),
        attendance: _b(dash['attendance']),
        viewEarnings: _b(dash['viewEarnings']),
        mileageTrips: _b(dash['mileageTrips']),
        needsAttention: _b(dash['needsAttention']),
      ),
      menu: MenuVisibility(
        form: _b(menu['form']),
        mileage: _b(menu['mileage']),
        claimExpenses: _b(menu['claimExpenses']),
        payslip: _b(menu['payslip']),
        viewEarnings: _b(menu['viewEarnings']),
        faq: _b(menu['faq']),
        legalTerms: _b(menu['legalTerms']),
        privacyPolicy: _b(menu['privacyPolicy']),
      ),
    );
  }

  AppSettingsEntity toEntity() => AppSettingsEntity(
        employeeId: employeeId,
        dashboard: dashboard,
        menu: menu,
      );
}
