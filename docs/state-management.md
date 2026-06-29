# State Management — Presshop Enterprise

## Library

`flutter_bloc` v8. Both `Bloc` (event-driven) and `Cubit` (method-driven) are used.

---

## When to use Bloc vs Cubit

| Use `Bloc` | Use `Cubit` |
|---|---|
| Multiple named input events | Single axis of state change (fetch/refresh) |
| Logging/replaying events is useful | Simple flag or loaded-data toggle |
| Examples: `AuthBloc`, `TasksBloc`, `AttendanceBloc` | Examples: `MapCubit`, `EmployeeMapCubit` |

---

## Standard State Pattern

Every feature follows the same four-state pattern:

```dart
abstract class FeatureState extends Equatable {}

class FeatureInitial extends FeatureState {
  const FeatureInitial();
  @override List<Object?> get props => [];
}

class FeatureLoading extends FeatureState {
  const FeatureLoading();
  @override List<Object?> get props => [];
}

class FeatureLoaded extends FeatureState {
  final DataType data;
  const FeatureLoaded(this.data);
  @override List<Object?> get props => [data];
}

class FeatureFailure extends FeatureState {
  final String message;
  const FeatureFailure(this.message);
  @override List<Object?> get props => [message];
}
```

---

## Registered BLoCs

All BLoCs are registered as **factories** in `injection.dart` (new instance per `BlocProvider`):

| BLoC / Cubit | Feature | Events / Methods |
|---|---|---|
| `AuthBloc` | auth | `LoginSubmitted`, `SignupSubmitted`, `LogoutRequested`, `AuthCheckRequested` |
| `AttendanceBloc` | attendance | `FetchAttendance`, `CheckIn`, `CheckOut` |
| `TasksBloc` | tasks | `FetchTasks`, `UpdateTaskStatus` |
| `EarningsBloc` | earnings | `FetchEarnings` |
| `DocumentsBloc` | documents | `FetchDocuments` |
| `ProfileBloc` | profile | `FetchProfile`, `UpdateProfile` |
| `SettingsBloc` | settings | `FetchSettings`, `UpdateSettings` |
| `MapCubit` | map | `loadMap`, `selectMarker`, `applyFilter` |
| `EmployeeMapCubit` | map | `startTracking`, `stopTracking`, `updateLocation` |

---

## BLoC Provision Patterns

### Screen-scoped BLoC (standard)
```dart
BlocProvider(
  create: (_) => getIt<FeatureBloc>()..add(const FetchFeature()),
  child: const FeatureScreen(),
)
```

### Dashboard-level BLoC (ProfileBloc)
`ProfileBloc` is provided at `DashboardScreen` level so the app bar in every tab has access:
```dart
BlocProvider(
  create: (_) => getIt<ProfileBloc>()..add(const FetchProfile()),
  child: Scaffold(...)
)
```

### Multi-BLoC (TeamMapScreen)
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => MapCubit()),
    BlocProvider(create: (_) => EmployeeMapCubit()),
  ],
  child: TeamMapScreen(...),
)
```

---

## Consuming State

```dart
// Rebuild only on state change
BlocBuilder<FeatureBloc, FeatureState>(
  builder: (context, state) {
    if (state is FeatureLoading) return const LoadingWidget();
    if (state is FeatureLoaded) return FeatureContent(data: state.data);
    if (state is FeatureFailure) return EmptyState(message: state.message);
    return const SizedBox.shrink();
  },
)

// Side effects (navigation, snackbars) + rebuilds
BlocConsumer<FeatureBloc, FeatureState>(
  listener: (context, state) {
    if (state is FeatureFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) { ... },
)
```

---

## Equatable

All state and event classes extend `Equatable` and override `props`. This enables BLoC to skip rebuilds when state is unchanged:

```dart
@override
List<Object?> get props => [field1, field2];
```

---

## Error Surface

Failures returned from the repository are converted to `FeatureFailure(failure.message)` in the BLoC. Screens read `state.message` and display it inline or via a snackbar — there is no global error handler.
