import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket/socket_manager.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/documents/data/datasources/documents_remote_datasource.dart';
import '../../features/documents/data/repositories/documents_repository_impl.dart';
import '../../features/documents/domain/repositories/documents_repository.dart';
import '../../features/documents/presentation/bloc/documents_bloc.dart';
import '../../features/earnings/data/datasources/earnings_remote_datasource.dart';
import '../../features/earnings/data/repositories/earnings_repository_impl.dart';
import '../../features/earnings/domain/repositories/earnings_repository.dart';
import '../../features/earnings/presentation/bloc/earnings_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/tasks/data/datasources/tasks_remote_datasource.dart';
import '../../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../../features/tasks/domain/repositories/tasks_repository.dart';
import '../../features/tasks/presentation/bloc/tasks_bloc.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

// Team Chat
import '../../features/team_chat/data/datasources/team_chat_remote_datasource.dart';
import '../../features/team_chat/data/repositories/team_chat_repository_impl.dart';
import '../../features/team_chat/domain/repositories/team_chat_repository.dart';
import '../../features/team_chat/presentation/bloc/team_chat_bloc.dart';

// Submit Forms
import '../../features/submit_forms/data/datasources/submit_forms_remote_datasource.dart';
import '../../features/submit_forms/data/repositories/submit_forms_repository_impl.dart';
import '../../features/submit_forms/domain/repositories/submit_forms_repository.dart';
import '../../features/submit_forms/presentation/bloc/submit_forms_bloc.dart';

// SOS
import '../../features/sos/data/datasources/sos_remote_datasource.dart';
import '../../features/sos/data/repositories/sos_repository_impl.dart';
import '../../features/sos/domain/repositories/sos_repository.dart';
import '../../features/sos/presentation/bloc/sos_bloc.dart';

// Duties
import '../../features/duties/data/datasources/duties_remote_datasource.dart';
import '../../features/duties/data/repositories/duties_repository_impl.dart';
import '../../features/duties/domain/repositories/duties_repository.dart';
import '../../features/duties/presentation/bloc/duties_bloc.dart';

// Claims
import '../../features/claims/data/datasources/claims_remote_datasource.dart';
import '../../features/claims/data/repositories/claims_repository_impl.dart';
import '../../features/claims/domain/repositories/claims_repository.dart';
import '../../features/claims/presentation/bloc/claims_bloc.dart';

// Mileage
import '../../features/mileage/data/datasources/mileage_remote_datasource.dart';
import '../../features/mileage/data/repositories/mileage_repository_impl.dart';
import '../../features/mileage/domain/repositories/mileage_repository.dart';
import '../../features/mileage/presentation/bloc/mileage_bloc.dart';

// Payslip
import '../../features/payslip/data/datasources/payslip_remote_datasource.dart';
import '../../features/payslip/data/repositories/payslip_repository_impl.dart';
import '../../features/payslip/domain/repositories/payslip_repository.dart';
import '../../features/payslip/presentation/bloc/payslip_bloc.dart';

// Leave
import '../../features/leave/data/datasources/leave_remote_datasource.dart';
import '../../features/leave/data/repositories/leave_repository_impl.dart';
import '../../features/leave/domain/repositories/leave_repository.dart';
import '../../features/leave/presentation/bloc/leave_cubits.dart';

// Home
import '../../features/dashboard/data/datasources/home_remote_datasource.dart';
import '../../features/dashboard/data/repositories/home_repository_impl.dart';
import '../../features/dashboard/domain/repositories/home_repository.dart';
import '../../features/dashboard/presentation/bloc/home_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Network
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));

  // Socket
  SocketManager.instance.init();

  // Auth
  getIt.registerLazySingleton<AuthRemoteDatasource>(() => AuthRemoteDatasource(getIt()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt()));
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerFactory(() => AuthBloc(loginUseCase: getIt(), logoutUseCase: getIt(), authRepository: getIt()));

  // Attendance
  getIt.registerLazySingleton(() => AttendanceRemoteDatasource(getIt()));
  getIt.registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryImpl(getIt()));
  getIt.registerFactory(() => AttendanceBloc(getIt()));

  // Tasks
  getIt.registerLazySingleton(() => TasksRemoteDatasource(getIt()));
  getIt.registerLazySingleton<TasksRepository>(() => TasksRepositoryImpl(getIt()));
  getIt.registerFactory(() => TasksBloc(getIt()));

  // Earnings
  getIt.registerLazySingleton(() => EarningsRemoteDatasource(getIt()));
  getIt.registerLazySingleton<EarningsRepository>(() => EarningsRepositoryImpl(getIt()));
  getIt.registerFactory(() => EarningsBloc(getIt()));

  // Documents
  getIt.registerLazySingleton(() => DocumentsRemoteDatasource(getIt()));
  getIt.registerLazySingleton<DocumentsRepository>(() => DocumentsRepositoryImpl(getIt()));
  getIt.registerFactory(() => DocumentsBloc(getIt()));

  // Profile
  getIt.registerLazySingleton(() => ProfileRemoteDatasource(getIt()));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(getIt(), getIt()));
  getIt.registerFactory(() => ProfileBloc(getIt()));

  // Settings
  getIt.registerLazySingleton(() => SettingsRemoteDatasource(getIt()));
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt()));
  getIt.registerFactory(() => SettingsBloc(getIt()));

  // Notifications
  getIt.registerLazySingleton(() => NotificationsRemoteDatasource(getIt()));
  getIt.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(getIt()));
  getIt.registerFactory(() => NotificationsBloc(getIt()));

  // Team Chat
  getIt.registerLazySingleton(() => TeamChatRemoteDataSource(getIt()));
  getIt.registerLazySingleton<TeamChatRepository>(() => TeamChatRepositoryImpl(getIt()));
  getIt.registerFactory(() => TeamChatBloc(getIt()));

  // Submit Forms
  getIt.registerLazySingleton(() => SubmitFormsRemoteDataSource(getIt()));
  getIt.registerLazySingleton<SubmitFormsRepository>(() => SubmitFormsRepositoryImpl(getIt()));
  getIt.registerFactory(() => SubmitFormsBloc(getIt()));

  // SOS
  getIt.registerLazySingleton(() => SosRemoteDataSource(getIt()));
  getIt.registerLazySingleton<SosRepository>(() => SosRepositoryImpl(getIt()));
  getIt.registerFactory(() => SosBloc(getIt()));

  // Duties
  getIt.registerLazySingleton(() => DutiesRemoteDatasource(getIt()));
  getIt.registerLazySingleton<DutiesRepository>(
      () => DutiesRepositoryImpl(getIt()));
  getIt.registerFactory(() => DutiesBloc(getIt()));

  // Claims
  getIt.registerLazySingleton(() => ClaimsRemoteDatasource(getIt()));
  getIt.registerLazySingleton<ClaimsRepository>(
      () => ClaimsRepositoryImpl(getIt()));
  getIt.registerFactory(() => ClaimsBloc(getIt()));

  // Mileage
  getIt.registerLazySingleton(() => MileageRemoteDatasource(getIt()));
  getIt.registerLazySingleton<MileageRepository>(
      () => MileageRepositoryImpl(getIt()));
  getIt.registerFactory(() => MileageBloc(getIt()));

  // Payslip
  getIt.registerLazySingleton(() => PayslipRemoteDatasource(getIt()));
  getIt.registerLazySingleton<PayslipRepository>(
      () => PayslipRepositoryImpl(getIt()));
  getIt.registerFactory(() => PayslipBloc(getIt()));

  // Leave
  getIt.registerLazySingleton(() => LeaveRemoteDatasource(getIt()));
  getIt.registerLazySingleton<LeaveRepository>(
      () => LeaveRepositoryImpl(getIt()));
  getIt.registerFactory(() => LeaveApplyCubit(getIt()));
  getIt.registerFactory(() => LeaveRequestsCubit(getIt()));
  getIt.registerFactory(() => LeaveBalancesCubit(getIt()));
  getIt.registerFactory(() => LeaveCalendarCubit(getIt()));

  // Home
  getIt.registerLazySingleton(() => HomeRemoteDatasource(getIt()));
  getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt()));
  getIt.registerFactory(() => HomeBloc(getIt()));
}
