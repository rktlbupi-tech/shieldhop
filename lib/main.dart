import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'config/di/injection.dart';
import 'config/routes/app_router.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'package:presshop_enterprise/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:presshop_enterprise/features/notifications/data/services/enterprise_fcm_service.dart';
import 'package:presshop_enterprise/features/notifications/data/services/local_notification_service.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:presshop_enterprise/features/splash/data/repositories/force_update_repository.dart';
import 'package:presshop_enterprise/features/splash/presentation/widgets/force_update_dialog.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/app_bloc_observer.dart';

List<CameraDescription> cameras = [];
SharedPreferences? sharedPreferences;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize custom BlocObserver to log Cubit/Bloc errors and transitions to Crashlytics
  Bloc.observer = AppBlocObserver();

  if (kDebugMode) {
    // Disable Crashlytics and Analytics collection programmatically in debug mode
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  } else {
    // Pass all uncaught "Fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await LocalNotificationService.instance.setup();
  EnterpriseFcmService.setupTokenRefreshListener();

  // ── Environment ───────────────────────────────────────────
  AppConfig.init(AppFlavor.dev);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Dependencies ──────────────────────────────────────────
  await setupDependencies();

  // ── Camera & Prefs ────────────────────────────────────────
  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = [];
  }
  sharedPreferences = await SharedPreferences.getInstance();

  runApp(const PresshopEnterpriseApp());
}

class PresshopEnterpriseApp extends StatefulWidget {
  const PresshopEnterpriseApp({super.key});

  @override
  State<PresshopEnterpriseApp> createState() => _PresshopEnterpriseAppState();
}

class _PresshopEnterpriseAppState extends State<PresshopEnterpriseApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createRouter(getIt());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForceUpdateManager.checkAndShowForceUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed: checking for force update");
      ForceUpdateManager.checkAndShowForceUpdate(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Enterprise',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.8, 1.0),
              ),
              child: ForceUpdateWidget(
                navigatorKey: navigatorKey,
                forceUpdateClient: ForceUpdateClient(
                  fetchRequiredVersion: () async {
                    try {
                      final force =
                          await ForceUpdateRepository.checkForceUpdate();
                      if (force) return "999.0.0";
                      final info = await PackageInfo.fromPlatform();
                      return info.version;
                    } catch (e) {
                      debugPrint("Force update check failed: $e");
                      final info = await PackageInfo.fromPlatform();
                      return info.version;
                    }
                  },
                  iosAppStoreId: '6744651614',
                ),
                allowCancel: false,
                showForceUpdateAlert: (context, allowCancel) {
                  return ForceUpdateManager.showForceUpdateAlertGlobal(
                    context,
                    allowCancel,
                  );
                },
                showStoreListing: (Uri storeUrl) async {},
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
