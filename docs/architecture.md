# Architecture — Presshop Enterprise

## Overview

The app uses **Clean Architecture** with a strict three-layer separation inside each feature folder. There is no cross-feature domain coupling; features communicate only through shared `presentation/widgets/` and via bottom-nav tab switching.

```
lib/
├── main.dart                    # App entry point, globals (cameras, sharedPreferences, navigatorKey)
├── config/
│   ├── di/injection.dart        # GetIt service locator setup
│   └── routes/app_router.dart   # GoRouter definition + auth redirect guard
├── core/
│   ├── config/app_config.dart   # Flavor-based URLs (dev / staging / prod)
│   ├── constants/               # AppColors, AppIcons, AppStrings, AppTextStyles
│   ├── errors/failures.dart     # Failure class hierarchy
│   ├── network/
│   │   ├── api_client.dart      # Dio wrapper (shared HTTP client)
│   │   ├── api_endpoints.dart   # All endpoint string constants
│   │   ├── interceptors.dart    # AuthInterceptor + AppLogInterceptor
│   │   ├── token_interceptor.dart # 401 handler — clears session
│   │   └── socket/
│   │       ├── socket_client.dart    # Low-level socket.io wrapper
│   │       ├── socket_events.dart    # Generic event name constants
│   │       └── socket_manager.dart   # Singleton — chat + live sockets
│   ├── theme/app_theme.dart     # ThemeData (light)
│   └── utils/responsive.dart   # Screen size helpers
├── features/                    # One folder per domain feature (see Features doc)
└── presentation/
    └── widgets/                 # Shared widgets used across features
```

---

## Layers

### Data Layer

- **Datasource** — makes HTTP calls through `ApiClient`. Returns raw `Map<String, dynamic>` or throws a `Failure`.
- **Model** — annotated with `@JsonSerializable` (or `@freezed`). Has `fromJson`/`toJson`. Extends or maps to the domain entity.
- **Repository impl** — implements the domain `abstract class`. Calls the datasource, maps models to entities, catches exceptions and wraps them in `Failure`.

### Domain Layer

- **Entity** — plain Dart class, no Flutter, no JSON, no third-party imports.
- **Repository (abstract)** — the only type visible to the presentation layer.
- **Use case** (optional) — single `call()` method. Used for login and logout; most features call the repository directly from the BLoC.

### Presentation Layer

- **BLoC / Cubit** — resolves from `getIt` via a factory. Injects repository.
- **Screens** — consume BLoC state with `BlocBuilder` / `BlocConsumer`.
- **Widgets** — stateless or minimal-state helper widgets scoped to the feature.

---

## Globals in `main.dart`

Three global variables are set before `runApp`:

| Variable | Type | Why global |
|---|---|---|
| `cameras` | `List<CameraDescription>` | Camera screens need it synchronously on first frame |
| `sharedPreferences` | `SharedPreferences?` | Camera publish screen reads lat/lon cache synchronously |
| `navigatorKey` | `GlobalKey<NavigatorState>` | Camera async callbacks push routes outside the widget tree |

Do not add new globals. These three exist for unavoidable timing reasons.

---

## Dependency Injection

`GetIt` is configured once at `setupDependencies()` before `runApp`. The registration order matters — upstream singletons must be registered before downstream ones.

```
SharedPreferences (singleton)
  └── ApiClient (lazySingleton)
        └── XxxRemoteDatasource (lazySingleton)
              └── XxxRepository (lazySingleton)
                    └── XxxBloc (factory)
```

`SocketManager` is a hand-rolled singleton (not registered with GetIt) initialised immediately after `ApiClient`.

---

## Error Handling

All HTTP errors are caught in `ApiClient._mapError` and converted to:

| HTTP / Dio condition | Failure type |
|---|---|
| Timeout | `NetworkFailure` |
| Connection error | `NetworkFailure` |
| 401 | `UnauthorizedFailure` |
| 404 | `NotFoundFailure` |
| Other 4xx/5xx | `ServerFailure(message)` |
| Unknown | `UnknownFailure` |

Repositories pass these up as `(null, failure)`. BLoCs emit `FeatureFailure(failure.message)`. Screens show inline error messages or snackbars — there is no global error boundary.

---

## Real-time (WebSocket)

Two Socket.io namespaces, both managed by `SocketManager`:

| Name | URL | Purpose |
|---|---|---|
| `chatSocket` | `/chat-v2` | Team chat messages |
| `liveSocket` | `/enterprise-live` | (reserved for future live events) |

The map feature uses a *separate* `MapSocketClient` (in `features/map/core/`) that connects to the same host but manages heatmap, location updates, alerts, and SOS independently from `SocketManager`.

Connect lifecycle:

1. After successful login → `SocketManager.instance.connectAll(token)`
2. After logout / 401 clear → `SocketManager.instance.disconnectAll()`

# Flutter Clean Architecture Rules

## 1. Layer Structure

```text
Presentation
    ↓
Domain
    ↓
Data
```

Dependency Rule:

```text
Presentation → Domain
Data → Domain

Domain must NOT depend on Presentation or Data.
```

---

# 2. Presentation Layer Rules

Location:

```text
presentation/
├── bloc/
├── screens/
└── widgets/
```

Responsibilities:

- UI rendering
- User interaction
- Navigation
- State management
- Calling UseCases

Allowed:

```dart
Bloc
Cubit
Widgets
Screens
Navigation
Controllers
```

Not Allowed:

```dart
API Calls
Dio Requests
Firebase Calls
Database Queries
Complex Business Logic
```

Example:

```dart
Login Button Click
↓
LoginEvent
↓
AuthBloc
↓
LoginUseCase
```

---

# 3. Domain Layer Rules

Location:

```text
domain/
├── entities/
├── repositories/
└── usecases/
```

Purpose:

Contains business logic and business rules.

---

## Entities

Responsibilities:

- Pure business objects
- No API dependencies
- No Flutter imports

Example:

```dart
UserEntity
TaskEntity
WorkerEntity
```

Not Allowed:

```dart
fromJson()
toJson()
API Logic
```

---

## Repositories (Abstract)

Responsibilities:

- Define contracts
- Define available operations

Example:

```dart
abstract class AuthRepository {
  Future<UserEntity> login();
}
```

Not Allowed:

```dart
Dio Calls
API Logic
```

---

## UseCases

Responsibilities:

- Business rules
- Validation
- Workflow decisions

Examples:

```text
LoginUseCase
StartTaskUseCase
CheckInUseCase
CompleteTaskUseCase
UploadEvidenceUseCase
CalculateSalaryUseCase
```

Allowed:

```dart
Validation
Permission Checks
Business Rules
Calculations
Workflow Decisions
```

Not Allowed:

```dart
UI Code
Widgets
Navigation
API Calls
```

Example:

```dart
if (!worker.isCheckedIn) {
  throw Exception("Check in first");
}
```

---

# 4. Data Layer Rules

Location:

```text
data/
├── datasources/
├── models/
└── repositories/
```

Responsibilities:

- API communication
- Database communication
- Data conversion

---

## DataSources

Responsibilities:

```text
REST API Calls
Firebase Calls
Local Storage
Database Access
```

Example:

```dart
auth_remote_datasource.dart
task_remote_datasource.dart
```

Allowed:

```dart
Dio
Http
Firebase
SharedPreferences
Hive
```

---

## Models

Responsibilities:

```text
JSON Parsing
Serialization
Deserialization
```

Example:

```dart
UserModel
TaskModel
```

Allowed:

```dart
fromJson()
toJson()
```

---

## Repository Implementations

Responsibilities:

```text
Connect Domain and Data
Convert Models → Entities
Call DataSources
```

Example:

```dart
AuthRepositoryImpl
TaskRepositoryImpl
```

---

# 5. Bloc Rules

Responsibilities:

```text
Receive Events
Call UseCases
Emit States
Handle Loading/Error/Success
```

Allowed:

```dart
emit(Loading)
emit(Success)
emit(Error)
Call UseCases
```

Not Allowed:

```dart
Business Logic
API Calls
Complex Calculations
```

Good Example:

```dart
on<LoginRequested>((event, emit) async {
  emit(AuthLoading());

  final user = await loginUseCase(
    event.email,
    event.password,
  );

  emit(AuthSuccess(user));
});
```

Bad Example:

```dart
on<LoginRequested>((event, emit) async {

  if(email.isEmpty) {
     ...
  }

  await dio.post(...);

});
```

---

# 6. Testing Rules

Priority:

```text
UseCase Tests     → Highest Priority
Bloc Tests        → Medium Priority
Repository Tests  → Low Priority
Widget Tests      → Optional
```

UseCases must be independently testable.

Example:

```dart
test(
  'worker must check in before starting task',
  () {}
);
```

---

# 7. Naming Conventions

UseCases:

```text
LoginUseCase
LogoutUseCase
CheckInUseCase
CheckOutUseCase
StartTaskUseCase
CompleteTaskUseCase
```

Repositories:

```text
AuthRepository
TaskRepository
AttendanceRepository
```

Repository Implementations:

```text
AuthRepositoryImpl
TaskRepositoryImpl
AttendanceRepositoryImpl
```

Data Sources:

```text
AuthRemoteDataSource
TaskRemoteDataSource
AttendanceRemoteDataSource
```

Entities:

```text
UserEntity
TaskEntity
AttendanceEntity
```

Models:

```text
UserModel
TaskModel
AttendanceModel
```

---

# Golden Rule

```text
Screen → Bloc → UseCase → Repository → DataSource → API

API → DataSource → Repository → UseCase → Bloc → Screen
```

Never skip layers unless there is a strong technical reason.
