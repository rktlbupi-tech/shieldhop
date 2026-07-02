import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/features/onboarding/presentation/screens/onboarding_screen_v2.dart';
import 'package:presshop_enterprise/features/settings/presentation/screens/account_delete_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:presshop_enterprise/main.dart';
import '../../config/di/injection.dart';

// Splash & Onboarding
import '../../features/splash/presentation/screens/splash_screen.dart';
// Auth
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';

// Dashboard & Home
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

// Profile
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/digital_id_screen.dart';

// Notifications
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Tasks
import '../../features/tasks/presentation/screens/task_schedule_screen.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/screens/task_chat_screen.dart';
import '../../features/tasks/data/models/employee_task_model.dart';

// Evidence & Content
import '../../features/content/presentation/screens/evidence_screen.dart';
import '../../features/content/presentation/screens/evidence_details_screen.dart';
import '../../features/content/data/models/enterprise_feed_model.dart';

// Camera
import '../../features/camera/presentation/screens/employee_camera_screen.dart';

// Forms
import '../../features/submit_forms/presentation/screens/submit_forms_screen.dart';
import '../../features/submit_forms/presentation/screens/web_view_form_screen.dart';

// Mileage & Expenses
import '../../features/mileage/presentation/screens/track_mileage_screen.dart';
import '../../features/mileage/presentation/screens/claim_expenses_screen.dart';

// Duties
import '../../features/duties/presentation/screens/duties_screen.dart';
import '../../features/duties/presentation/screens/duties_history_screen.dart';
import '../../features/duties/presentation/screens/duties_history_details_screen.dart';
import '../../features/duties/data/models/duty_shift_model.dart';

// Attendance
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/leave/presentation/screens/leave_screen.dart';
import '../../features/attendance/presentation/screens/uniform_verification_screen.dart';
import '../../features/attendance/presentation/screens/check_in_out_screen.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';

// Payslip & Earnings
import '../../features/payslip/presentation/screens/payslip_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';

// Documents
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/documents/presentation/screens/document_preview_screen.dart';
import '../../features/documents/domain/entities/document_entity.dart';

// Map & Chat
import '../../features/team_chat/presentation/screens/team_chat_screen_v2.dart';
import '../../features/team_chat/presentation/screens/team_chat_message_page.dart';

// Settings
import '../../features/settings/presentation/screens/faq_screen.dart';
import '../../features/settings/presentation/screens/term_check_screen.dart';

// App Settings (server-driven route visibility guard)
import '../../features/app_settings/presentation/cubit/app_settings_cubit.dart';

// Common
import '../../common/widgets/coming_soon_screen.dart';

import '../../core/services/crashlytics_navigation_observer.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  static const String digitalId = '/digital-id';
  static const String notifications = '/notifications';
  static const String tasks = '/tasks';
  static const String evidence = '/evidence';
  static const String submitForms = '/submit-forms';
  static const String trackMileage = '/track-mileage';
  static const String claimExpenses = '/claim-expenses';
  static const String duties = '/duties';
  static const String attendance = '/attendance';
  static const String leave = '/leave';
  static const String payslip = '/payslip';
  static const String earnings = '/earnings';
  static const String documents = '/documents';
  static const String teamChatList = '/team-chat-list';
  static const String faq = '/faq';
  static const String termCheck = '/term-check';
  static const String uniformVerification = '/uniform-verification';
  static const String checkInOut = '/check-in-out';
  static const String webViewForm = '/web-view-form';
  static const String documentPreview = '/document-preview';
  static const String teamChatMessage = '/team-chat-message';
  static const String evidenceDetails = '/evidence-details';
  static const String taskChat = '/task-chat';
  static const String comingSoon = '/coming-soon';
  static const String dutiesHistory = '/duties-history';
  static const String dutiesHistoryDetails = '/duties-history-details';
  static const String employeeCamera = '/employee-camera';
  static const String taskDetails = '/task-details/:taskId';
  static const String deleteAccount = '/delete-account';
}

GoRouter createRouter(SharedPreferences prefs) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      CrashlyticsNavigationObserver(),
    ],
    redirect: (context, state) {
      final token = prefs.getString('auth_token');
      final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.resetPassword;

      if (isSplash) return null;

      if (!onboardingSeen) {
        return isOnboarding ? null : AppRoutes.onboarding;
      }

      if (token == null && !isAuth) return AppRoutes.login;

      if (token != null && isAuth) return AppRoutes.dashboard;

      // Server-driven visibility: make routes for hidden menu items unreachable
      // (deep links / stale pushes). Flags are cached by AppSettingsCubit and
      // default to visible when unknown. Legal & Privacy share /term-check, so
      // they are gated at the menu-item level only, not here.
      const guardedRoutes = <String, String>{
        AppRoutes.submitForms: AppSettingsMenuKeys.form,
        AppRoutes.trackMileage: AppSettingsMenuKeys.mileage,
        AppRoutes.claimExpenses: AppSettingsMenuKeys.claimExpenses,
        AppRoutes.payslip: AppSettingsMenuKeys.payslip,
        AppRoutes.earnings: AppSettingsMenuKeys.viewEarnings,
        AppRoutes.faq: AppSettingsMenuKeys.faq,
      };
      final guardKey = guardedRoutes[state.matchedLocation];
      if (guardKey != null && !AppSettingsPrefs.menuVisible(prefs, guardKey)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // GoRoute(
      //   path: AppRoutes.signup,
      //   builder: (context, state) => const SignupScreen(),
      // ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final index = tabStr != null ? int.tryParse(tabStr) ?? 2 : 2;
          final selectTabToken = state.uri.queryParameters['ts'];
          return DashboardScreen(
            initialIndex: index,
            selectTabToken: selectTabToken,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email =
              extra['email'] as String? ??
              state.uri.queryParameters['email'] ??
              '';
          final otp =
              extra['otp'] as String? ?? state.uri.queryParameters['otp'] ?? '';
          return ResetPasswordScreen(email: email, otp: otp);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.digitalId,
        builder: (context, state) => DigitalIdScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) {
          final hide = state.uri.queryParameters['hideLeading'] == 'true';
          return TaskScheduleScreen(hideLeading: hide);
        },
      ),
      GoRoute(
        path: AppRoutes.evidence,
        builder: (context, state) {
          final hide = state.uri.queryParameters['hideLeading'] != 'false';
          return EvidenceScreen(hideLeading: hide);
        },
      ),
      GoRoute(
        path: AppRoutes.submitForms,
        builder: (context, state) => const SubmitFormsScreen(),
      ),
      GoRoute(
        path: AppRoutes.trackMileage,
        builder: (context, state) => TrackMileageScreen(),
      ),
      GoRoute(
        path: AppRoutes.claimExpenses,
        builder: (context, state) => const ClaimExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.duties,
        builder: (context, state) => const DutiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.leave,
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: AppRoutes.payslip,
        builder: (context, state) => const PayslipScreen(),
      ),
      GoRoute(
        path: AppRoutes.earnings,
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.teamChatList,
        builder: (context, state) => const TeamChatScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final priceTipsSelected =
              extra['priceTipsSelected'] as bool? ??
              state.uri.queryParameters['priceTipsSelected'] == 'true';
          final type =
              extra['type'] as String? ??
              state.uri.queryParameters['type'] ??
              'faq';
          final benefits =
              extra['benefits'] as String? ??
              state.uri.queryParameters['benefits'] ??
              '';
          final index =
              extra['index'] as int? ??
              int.tryParse(state.uri.queryParameters['index'] ?? '0') ??
              0;
          return FAQScreen(
            priceTipsSelected: priceTipsSelected,
            type: type,
            benefits: benefits,
            index: index,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.termCheck,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final type =
              extra['type'] as String? ??
              state.uri.queryParameters['type'] ??
              'legal';
          return TermCheckScreen(type: type);
        },
      ),
      GoRoute(
        path: AppRoutes.uniformVerification,
        builder: (context, state) {
          final bloc =
              state.extra as AttendanceBloc? ?? getIt<AttendanceBloc>();
          return BlocProvider.value(
            value: bloc,
            child: const UniformVerificationScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkInOut,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isCheckingIn =
              extra?['isCheckingIn'] as bool? ??
              state.uri.queryParameters['isCheckingIn'] != 'false';
          final attendanceBloc =
              extra?['attendanceBloc'] as AttendanceBloc? ??
              (state.extra is AttendanceBloc
                  ? state.extra as AttendanceBloc
                  : null) ??
              getIt<AttendanceBloc>();
          return CheckInOutScreen(
            isCheckingIn: isCheckingIn,
            attendanceBloc: attendanceBloc,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.webViewForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final formId =
              extra?['formId'] as String? ??
              state.uri.queryParameters['formId'];
          final formName =
              extra?['formName'] as String? ??
              state.uri.queryParameters['formName'];
          final customUrl =
              extra?['customUrl'] as String? ??
              state.uri.queryParameters['customUrl'];
          return WebViewForFormScreen(
            formId: formId,
            formName: formName,
            customUrl: customUrl,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.documentPreview,
        builder: (context, state) {
          final document = state.extra as DocumentEntity;
          return DocumentPreviewScreen(document: document);
        },
      ),
      GoRoute(
        path: AppRoutes.teamChatMessage,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final conversationId = extra['conversationId'] as String;
          final title = extra['title'] as String;
          final image = extra['image'] as String;
          return TeamChatMessagePage(
            conversationId: conversationId,
            title: title,
            image: image,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.evidenceDetails,
        builder: (context, state) {
          final item = state.extra as EnterpriseFeedItem;
          return EvidenceDetailsScreen(item: item);
        },
      ),
      GoRoute(
        path: AppRoutes.taskChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final taskDetail = extra['taskDetail'] as EmployeeTaskModel;
          final roomId = extra['roomId'] as String;
          return TaskChatScreen(taskDetail: taskDetail, roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.taskDetails,
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          return TaskDetailsScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: AppRoutes.comingSoon,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title =
              extra['title'] as String? ??
              state.uri.queryParameters['title'] ??
              'Coming Soon';
          final icon = extra['icon'] as IconData? ?? LucideIcons.circle;
          return ComingSoonScreen(title: title, icon: icon);
        },
      ),
      GoRoute(
        path: AppRoutes.dutiesHistory,
        builder: (context, state) => const DutiesHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.dutiesHistoryDetails,
        builder: (context, state) {
          final shift = state.extra as DutyShiftHistory;
          return DutiesHistoryDetailsScreen(shift: shift);
        },
      ),
      GoRoute(
        path: AppRoutes.employeeCamera,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final picAgain = extra['picAgain'] as bool? ?? false;
          final autoInitialize = extra['autoInitialize'] as bool? ?? true;
          final isScreenActive = extra['isScreenActive'] as bool? ?? true;
          final initialType = extra['initialType'] as String?;
          final hideAppBar = extra['hideAppBar'] as bool? ?? false;
          return EmployeeCameraScreen(
            picAgain: picAgain,
            autoInitialize: autoInitialize,
            isScreenActive: isScreenActive,
            initialType: initialType,
            hideAppBar: hideAppBar,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) {
          return AccountDeleteScreen();
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
