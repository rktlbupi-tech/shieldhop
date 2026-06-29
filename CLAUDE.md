# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This monorepo contains two Flutter projects:

| Folder | Status | Purpose |
|---|---|---|
| `presshop_enterprise/` | **Active** | Enterprise employee app (Hoppers) — clean architecture rewrite |
| `Presshop_App_Dev-old-app/` | Legacy | Original app; reference only, do not modify |

All active development happens inside `presshop_enterprise/`.

---

## Commands

All commands must be run from inside `presshop_enterprise/`.

```bash
cd presshop_enterprise

# Install / regenerate dependencies
flutter pub get

# Run on device (dev flavor is hardcoded in main.dart via AppConfig.init(AppFlavor.dev))
flutter run

# Code generation (freezed models, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for codegen during development
dart run build_runner watch --delete-conflicting-outputs

# Lint
flutter analyze

# Format
dart format lib/

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build APK (release)
flutter build apk --release

# Build iOS (release)
flutter build ios --release
```

---

## Architecture

The enterprise app follows **Clean Architecture** strictly. Every feature lives in `lib/features/<feature>/` with three layers:

```
features/<feature>/
  data/
    datasources/   # HTTP calls via ApiClient; returns raw Maps
    models/        # JSON ↔ Dart (json_serializable / freezed)
    repositories/  # Implements domain interfaces; maps models → entities
  domain/
    entities/      # Pure Dart, no Flutter, no JSON
    repositories/  # Abstract interfaces
    usecases/      # Single-method classes (optional; not every feature has them)
  presentation/
    bloc/          # flutter_bloc BLoC or Cubit
    screens/       # Full-page widgets
    widgets/       # Feature-scoped reusable widgets
```

Shared presentation components (app bars, loading spinners, stat cards) live in `lib/presentation/widgets/`.

---

## Dependency Injection

`get_it` is the service locator. The single `getIt` instance is configured in `lib/config/di/injection.dart` and initialised at app start.

- **Datasources, repositories, use cases** → `registerLazySingleton`
- **BLoCs** → `registerFactory` (new instance per use; dispose is automatic via `BlocProvider`)

When adding a new feature, register its graph in `injection.dart` in the same pattern as existing features.

---

## Navigation

`go_router` with a redirect guard in `lib/config/routes/app_router.dart`.

**Defined routes:**

| Route constant | Path | Screen |
|---|---|---|
| `AppRoutes.splash` | `/` | `SplashScreen` |
| `AppRoutes.onboarding` | `/onboarding` | `OnboardingScreen` |
| `AppRoutes.login` | `/login` | `LoginScreen` |
| `AppRoutes.signup` | `/signup` | `SignupScreen` |
| `AppRoutes.dashboard` | `/dashboard` | `DashboardScreen` |

**Redirect logic:**
1. `onboarding_seen` (SharedPreferences bool) gates the onboarding screen.
2. `auth_token` (SharedPreferences string) gates all authenticated routes.
3. 401 responses (via `TokenInterceptor`) clear the token and the GoRouter guard redirects to `/login` on the next navigation.

Post-auth navigation between tabs is internal to `DashboardScreen` (bottom nav `IndexedStack`). Screens inside the dashboard call `context.findAncestorStateOfType<DashboardScreenState>()?.changeTab(index)` to switch tabs programmatically.

---

## Bottom Navigation (Dashboard)

`DashboardScreen` hosts five tabs in an `IndexedStack`:

| Index | Label | Screen |
|---|---|---|
| 0 | Evidence | `EvidenceScreen` |
| 1 | Task | `TaskScheduleScreen` |
| 2 | Home (default) | `HomeScreen2` |
| 3 | Team | `TeamMapScreen` (wrapped in `MapCubit` + `EmployeeMapCubit`) |
| 4 | Menu | `MenuScreen` |

`ProfileBloc` is provided at the `DashboardScreen` level so the Home and AppBar always have fresh profile data.

---

## Networking

**HTTP** — `ApiClient` (`lib/core/network/api_client.dart`): wraps Dio, adds three interceptors:
- `TokenInterceptor` — clears session on 401
- `AuthInterceptor` — injects `Authorization: Bearer <token>` from SharedPreferences
- `AppLogInterceptor` — debug logging

All endpoints are string constants in `ApiEndpoints` (`lib/core/network/api_endpoints.dart`).

**WebSocket** — `SocketManager` (singleton) manages two `SocketClient` instances:
- `chatSocket` → `<host>:3005/chat-v2`
- `liveSocket` → `<host>:3005/enterprise-live`

Socket events for the live/map feature are in `MapSocketConstants`. Call `SocketManager.instance.connectAll(token)` after login, `disconnectAll()` after logout.

**Camera uploads** bypass `ApiClient` and use a separate `Dio` instance inside `CameraTaskService` with a manual auth interceptor. This is intentional (long timeouts, multipart).

---

## Environment / Flavors

`AppConfig` (`lib/core/config/app_config.dart`) holds all environment-specific URLs. Switch flavors by changing `AppConfig.init(AppFlavor.dev|staging|prod)` in `main.dart`.

| Flavor | API host | Socket host | CDN host |
|---|---|---|---|
| dev | `dev-api.presshop.news:5019` | `:3005` | `dev-cdn.presshop.news` |
| staging | `staging-api.presshop.news:5019` | `:3005` | `staging-cdn.presshop.news` |
| prod | `api.presshop.news:5019` | `:3005` | `cdn.presshop.news` |

CDN helper methods (`AppConfig.contentImage`, `.taskMedia`, `.thumbnail`, `.avatarImage`, `.profileImage`) build full URLs from relative paths returned by the API.

---

## State Management Conventions

- Use `Cubit` for simple read/fetch state (map, profile).
- Use `Bloc` when there are multiple named events (auth, tasks, attendance, earnings, documents, settings).
- States follow the pattern: `Initial → Loading → Loaded(data) | Failure(message)`.
- Errors surface as `Failure` subclasses (`lib/core/errors/failures.dart`): `ServerFailure`, `NetworkFailure`, `UnauthorizedFailure`, `CacheFailure`, `ValidationFailure`, `NotFoundFailure`, `UnknownFailure`.

---

## UI Conventions

- **Design baseline**: 390 × 844 (iPhone 14). Use `flutter_screenutil` — suffix `.w`, `.h`, `.r`, `.sp` on all layout values.
- **Fonts**: `Poppins` (body/UI copy) and `AirbnbCereal` (nav labels, headers).
- **Colors**: always use `AppColors` constants from `lib/core/constants/app_colors.dart`. Primary brand blue is `AppColors.primary` (`#1877F2`).
- **Text styles**: shared presets in `lib/core/constants/app_text_styles.dart`.
- **Shared widgets**: `EmployeeAppBar`, `CompanyLogoWidget`, `EmptyState`, `LoadingWidget`, `StatCard`, `SlidingTabs`, `ComingSoonScreen` in `lib/presentation/widgets/`.

---

## Session Storage Keys (SharedPreferences)

| Key | Type | Purpose |
|---|---|---|
| `auth_token` | String | JWT bearer token |
| `user_id` | String | Logged-in user ID |
| `user_email` | String | Cached email |
| `user_first_name` | String | Cached first name |
| `user_last_name` | String | Cached last name |
| `onboarding_seen` | bool | Whether onboarding has been dismissed |
| `on_duty` | bool | Employee duty status shown on HomeScreen AppBar |

---

## Pending / Known Items

- `important.txt` inside `presshop_enterprise/` notes: **"Multiple language support to be added"** (i18n not yet implemented).
- `home_screen.dart` and `home_screen copy.dart` are superseded by `home_screen_v2.dart`; they remain for reference.
- `lib/features/others/` contains loose screens (`ContactUsScreen`, `TermCheckScreen`, `UploadDocumentsScreen`, `account_delete_screen`) that have not yet been migrated into their respective feature folders.
