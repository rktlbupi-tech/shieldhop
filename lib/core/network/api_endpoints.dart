class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ─────────────────────────────────────────────────
  static const String login = 'auth/loginEnterpriseEmployee';
  static const String signup = 'auth/registerEnterpriseEmployee';
  static const String refreshToken = 'auth/refreshToken';
  static const String logout = 'auth/logout';
  static const String sendOtp = 'hopper/sendEmailOTP';
  static const String verifyOtp = 'hopper/verifyEmailOTP';
  static const String forgotPassword = 'auth/forgotPassword';
  static const String resetPassword = 'auth/resetPassword';
  static const String changePassword = 'users/changePassword';
  static const String deleteAccount = 'hopper/verifyAndDeleteAccount';

  // ── Profile ──────────────────────────────────────────────
  static const String getProfile = 'hopper/getEnterpriseUserProfile';
  static const String updateProfile = 'hopper/updateEnterpriseUserProfile';

  // ── Attendance ───────────────────────────────────────────
  static const String checkIn = 'enterprise/attendance/check-in';
  static const String checkOut = 'enterprise/attendance/check-out';
  static const String attendanceLog = 'enterprise/attendance/log';

  // ── Attendance (worker app — self-scoped clock in/out) ────
  static const String attendanceToday = 'enterprise/app/attendance/today';
  static const String attendancePunch = 'enterprise/app/attendance/punch';

  // ── Attendance log screen (worker app — self-scoped) ──────
  // See docs/api/attendance-log.md
  static const String attendanceSummary = 'enterprise/app/attendance/summary';
  static const String attendanceAppLog = 'enterprise/app/attendance/log';
  static const String attendanceIssues = 'enterprise/app/attendance/issues';

  // ── Duties screen (worker app — self-scoped) ──────────────
  // See docs/api/duties-screen.md
  static const String dutiesCurrent = 'enterprise/app/duties/current';
  static const String dutiesUpcoming = 'enterprise/app/duties/upcoming';
  static const String dutiesTodayTasks = 'enterprise/app/duties/today-tasks';
  static const String dutiesHistory = 'enterprise/app/duties/history';
  static const String dutiesHandoverReport =
      'enterprise/app/duties/handover-report';

  // ── Claim expenses screen (worker app — self-scoped) ──────
  // See docs/api/claim-expenses.md
  static const String claimsSummary = 'enterprise/app/claims/summary';
  static const String claims = 'enterprise/app/claims';

  // ── Track mileage screen (worker app — self-scoped) ───────
  // See docs/api/track-mileage.md
  static const String mileageSummary = 'enterprise/app/mileage/summary';
  static const String mileageTrips = 'enterprise/app/mileage/trips';
  static const String mileageTrip = 'enterprise/app/mileage/trip';

  // ── Media upload (returns a hosted file URL) ──────────────
  static const String uploadUserMedia = 'hopper/uploadUserMedia';

  // ── Tasks ────────────────────────────────────────────────
  static const String tasks = 'enterprise/tasks';
  static const String taskDetails = 'enterprise/tasks/'; // + id

  // ── Documents (worker app — self-scoped) ─────────────────
  // See docs/api/my-documents.md
  static const String documents = 'enterprise/app/documents';

  // ── Earnings & Payslips (worker app — self-scoped) ───────
  // See docs/api/payslip-earnings.md
  static const String earnings = 'enterprise/app/earnings';
  static const String payslips = 'enterprise/app/payslips'; // + /:id for detail

  // ── Leave (worker app — self-scoped) ─────────────────────
  // See docs/api/leave.md
  static const String leaveTypes = 'enterprise/app/leave/types';
  static const String leaveBalances = 'enterprise/app/leave/balances';
  static const String leave = 'enterprise/app/leave'; // POST apply / GET list / + /:id / + /:id/cancel
  static const String leaveCalendar = 'enterprise/app/leave/calendar';

  // ── Home (worker app — single aggregate endpoint) ────────
  // See docs/api/home.md
  static const String home = 'enterprise/app/home';

  // ── Map / Heatmap ────────────────────────────────────────
  static const String heatmapLocation = 'enterprise/heatmap/location';
  static const String heatmapWorkers = 'enterprise/heatmap/workers';
  static const String heatmapAlerts = 'enterprise/heatmap/alerts';

  // ── SOS ──────────────────────────────────────────────────
  static const String sosStart = 'enterprise/sos/start';
  static const String sosStop = 'enterprise/sos/stop';
  static const String sosMe = 'enterprise/sos/me';

  // ── Notifications ────────────────────────────────────────
  static const String fcmToken = 'enterprise/devices/fcm-token';
  static const String notifications = 'enterprise/notifications';

  // ── Feed ─────────────────────────────────────────────────
  static const String feed = 'enterprise/feed/assigned';

  // ── Deep Links ───────────────────────────────────────────
  static const String resolveDeepLink = 'api/deep-links/';
  static const String matchDevice = 'api/deep-links/match-device';

  // ── Settings & CMS ───────────────────────────────────────
  static const String getGeneralMgmtApp = 'hopper/getGenralMgmtApp';
  static const String getCategory = 'hopper/getCategory';
  static const String contactUs = 'hopper/Addcontact_us';
  // static const String deleteAccount = 'hopper/verifyAndDeleteAccount';
}
