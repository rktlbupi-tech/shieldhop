import 'package:equatable/equatable.dart';

/// Per-team-member visibility config (see `docs/api/app-settings.md`).
///
/// Every flag defaults to `true`. A missing / unrecognised key is treated as
/// `true` as well, so new server-side keys keep older builds working and an
/// error never hides the whole app.
class AppSettingsEntity extends Equatable {
  final String employeeId;
  final DashboardVisibility dashboard;
  final MenuVisibility menu;

  const AppSettingsEntity({
    required this.employeeId,
    required this.dashboard,
    required this.menu,
  });

  /// Fallback used before the first load and whenever the fetch fails
  /// (including `403`): show everything.
  const AppSettingsEntity.allVisible()
      : employeeId = '',
        dashboard = const DashboardVisibility(),
        menu = const MenuVisibility();

  @override
  List<Object?> get props => [employeeId, dashboard, menu];
}

/// Home screen sections. `true` → render, `false` → hide.
class DashboardVisibility extends Equatable {
  final bool captureMoment;
  final bool task;
  final bool duties;
  final bool attendance;
  final bool viewEarnings;
  final bool mileageTrips;
  final bool needsAttention;

  const DashboardVisibility({
    this.captureMoment = true,
    this.task = true,
    this.duties = true,
    this.attendance = true,
    this.viewEarnings = true,
    this.mileageTrips = true,
    this.needsAttention = true,
  });

  @override
  List<Object?> get props => [
        captureMoment,
        task,
        duties,
        attendance,
        viewEarnings,
        mileageTrips,
        needsAttention,
      ];
}

/// Menu / drawer entries. `true` → render, `false` → hide.
class MenuVisibility extends Equatable {
  final bool form;
  final bool mileage;
  final bool claimExpenses;
  final bool payslip;
  final bool viewEarnings;
  final bool faq;
  final bool legalTerms;
  final bool privacyPolicy;

  const MenuVisibility({
    this.form = true,
    this.mileage = true,
    this.claimExpenses = true,
    this.payslip = true,
    this.viewEarnings = true,
    this.faq = true,
    this.legalTerms = true,
    this.privacyPolicy = true,
  });

  @override
  List<Object?> get props => [
        form,
        mileage,
        claimExpenses,
        payslip,
        viewEarnings,
        faq,
        legalTerms,
        privacyPolicy,
      ];
}
