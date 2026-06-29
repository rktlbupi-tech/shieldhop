# Agent Guide — Presshop Enterprise

This document is for AI agents (Claude Code or similar) operating autonomously in this repository. Read `CLAUDE.md` first for build commands and architecture.

---

## What this app is

**Presshop Enterprise** is a Flutter mobile app for field journalists ("Hoppers") employed by news organisations. It lets an employee:

- Clock in/out (Attendance)
- View and accept assigned journalism tasks (Tasks)
- Capture and publish photo/video/audio/document content tied to a task (Camera → Evidence)
- See team members on a live map with SOS alerts (Team Map)
- Track mileage and earnings (Mileage / Earnings)
- Manage documents, payslips, and profile (Documents / Payslip / Profile)
- Chat with the team (Team Chat)
- Submit forms via a WebView (Submit Forms)

The backend is headless REST + Socket.io. This Flutter app is employee-facing only; the employer-facing dashboard is a separate web product.

---

## Safe autonomous actions

The following are safe to do without asking the user:

- Add a new screen inside an existing feature following the existing layer pattern
- Add a new route to `AppRoutes` and `createRouter`
- Register a new dependency in `injection.dart`
- Add or update `ApiEndpoints` constants
- Fix lint warnings (`flutter analyze`)
- Run `dart run build_runner build --delete-conflicting-outputs` after editing models
- Format with `dart format lib/`

---

## Decisions that require user confirmation

- Changing `AppConfig.init(AppFlavor.X)` in `main.dart` (affects which backend is targeted)
- Adding a new package to `pubspec.yaml`
- Modifying `SocketManager` connection lifecycle
- Touching SharedPreferences key names (breaks existing installs)
- Any change to `TokenInterceptor` or `AuthInterceptor` (auth security boundary)
- Removing or renaming existing `AppRoutes` constants (breaks deep links)

---

## Adding a new feature — checklist

1. Create `lib/features/<name>/data/datasources/<name>_remote_datasource.dart` — inject `ApiClient`
2. Create `lib/features/<name>/data/models/<name>_model.dart` — use `json_serializable`
3. Create `lib/features/<name>/data/repositories/<name>_repository_impl.dart`
4. Create `lib/features/<name>/domain/entities/<name>_entity.dart`
5. Create `lib/features/<name>/domain/repositories/<name>_repository.dart` (abstract)
6. Create `lib/features/<name>/presentation/bloc/<name>_bloc.dart` or `_cubit.dart`
7. Create screens under `lib/features/<name>/presentation/screens/`
8. Register in `lib/config/di/injection.dart`
9. Add route(s) to `lib/config/routes/app_router.dart` if the feature has its own route
10. Run `dart run build_runner build --delete-conflicting-outputs`

---

## Patterns to follow

### Repository return type
```dart
Future<(EntityType?, Failure?)> someMethod(args);
```
Return `(entity, null)` on success, `(null, failure)` on error.

### BLoC state naming
```dart
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState { final Data data; }
class FeatureFailure extends FeatureState { final String message; }
```

### BLoC event handler
```dart
Future<void> _onSomethingRequested(
  SomethingRequested event,
  Emitter<FeatureState> emit,
) async {
  emit(const FeatureLoading());
  final (data, failure) = await _repository.fetchSomething();
  if (failure != null) {
    emit(FeatureFailure(failure.message));
  } else {
    emit(FeatureLoaded(data!));
  }
}
```

### DI registration
```dart
// Datasource and repository — lazy singletons
getIt.registerLazySingleton(() => FeatureRemoteDatasource(getIt()));
getIt.registerLazySingleton<FeatureRepository>(
  () => FeatureRepositoryImpl(getIt()),
);
// BLoC — factory (new instance each time)
getIt.registerFactory(() => FeatureBloc(getIt()));
```

### Providing a BLoC in a screen
```dart
BlocProvider(
  create: (_) => getIt<FeatureBloc>()..add(const FetchFeature()),
  child: const FeatureScreen(),
)
```

---

## Common gotchas

- **ScreenUtil suffixes are mandatory** on all sizes: `.w`, `.h`, `.sp`, `.r`. Bare `double` values will break on non-360-width devices.
- **Camera screens** use the global `cameras` and `sharedPreferences` from `main.dart` directly — these are populated before `runApp`.
- **TeamMapScreen** must be wrapped in both `MapCubit` and `EmployeeMapCubit` providers and receives `isScreenActive` to pause/resume location tracking when not visible.
- **`home_screen.dart` and `home_screen copy.dart`** are dead code — the live home screen is `HomeScreen2` in `home_screen_v2.dart`.
- Map socket events go through `MapSocketConstants` + `MapSocketClient` (a separate socket wrapper in `features/map/core/`), not `SocketManager`.
- `CameraTaskService` has its own `Dio` instance. Do not merge it into `ApiClient` — it needs a 60 s receive timeout and multipart streaming.
