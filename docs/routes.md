# Routes — Presshop Enterprise

## Top-Level Routes (GoRouter)

Defined in `presshop_enterprise/lib/config/routes/app_router.dart`.

| Constant | Path | Screen | Access |
|---|---|---|---|
| `AppRoutes.splash` | `/` | `SplashScreen` | Always |
| `AppRoutes.onboarding` | `/onboarding` | `OnboardingScreen` | Until `onboarding_seen = true` |
| `AppRoutes.login` | `/login` | `LoginScreen` | Unauthenticated only |
| `AppRoutes.signup` | `/signup` | `SignupScreen` | Unauthenticated only |
| `AppRoutes.dashboard` | `/dashboard` | `DashboardScreen` | Authenticated only |

### Redirect guard logic

```
1. Is splash?  → allow through (no redirect)
2. onboarding_seen == false?
     → redirect to /onboarding (unless already there)
3. auth_token == null and not on login/signup?
     → redirect to /login
4. auth_token present and on login/signup?
     → redirect to /dashboard
```

Session token is stored at key `auth_token` in `SharedPreferences`. The guard re-evaluates on every navigation event.

---

## In-App Navigation (Dashboard tabs)

After `/dashboard` loads, all navigation happens within the `DashboardScreen` `IndexedStack`. There are no sub-routes for tabs — they are switched by index.

```dart
// Switch to a specific tab from any child widget:
context.findAncestorStateOfType<DashboardScreenState>()?.changeTab(index);
```

| Index | Tab Label | Root Screen |
|---|---|---|
| 0 | Evidence | `EvidenceScreen` |
| 1 | Task | `TaskScheduleScreen` |
| 2 | Home | `HomeScreen2` |
| 3 | Team | `TeamMapScreen` |
| 4 | Menu | `MenuScreen` |

---

## Screen Navigation Flows

### Authentication flow
```
SplashScreen
  └─► OnboardingScreen (first launch)
        └─► LoginScreen
              ├─► SignupScreen (new user)
              └─► ForgotPasswordScreen (OTP email reset)
                    └─► LoginScreen (after reset)
```

### Home tab flows
```
HomeScreen2
  ├─► CheckInOutScreen (attendance)
  ├─► TrackMileageScreen
  ├─► SosDialog (modal overlay)
  ├─► NotificationsScreen
  └─► [tab switch] → MenuScreen (tab 4)
```

### Task tab flows
```
TaskScheduleScreen
  ├─► TaskDetailsScreen
  │     └─► TaskChatScreen
  └─► EmployeeCameraScreen (capture for task)
```

### Evidence tab flows
```
EvidenceScreen
  └─► EmployeeCameraScreen
        ├─► CustomGalleryScreen
        ├─► AudioRecorderScreen
        ├─► EmployeePreviewScreen
        │     └─► EmployeePublishContentScreen
        │           └─► ContentSubmittedScreen
        └─► PermissionErrorScreen (if permissions denied)
```

### Team tab flows
```
TeamMapScreen
  ├─► TeamChatListPage
  │     └─► TeamChatMessagePage
  └─► LocationErrorScreenMapNews (if GPS denied)
```

### Menu tab flows
```
MenuScreen
  ├─► ProfileScreen
  │     └─► DigitalIdScreen
  ├─► AttendanceScreen
  ├─► EarningsScreen
  ├─► DocumentsScreen
  │     └─► DocumentPreviewScreen
  ├─► PayslipScreen
  ├─► DutiesScreen
  ├─► ClaimExpensesScreen
  ├─► SubmitFormsScreen
  │     └─► WebViewFormScreen
  ├─► TeamChatScreen
  ├─► NotificationsScreen
  └─► AccountSettingsScreen
        ├─► ChangePasswordScreen
        ├─► FaqScreen
        ├─► ContactUsScreen
        ├─► TermCheckScreen
        └─► AccountDeleteScreen
```

---

## Deep Links

The API has a deep link resolver at `api/deep-links/` and a device matcher at `api/deep-links/match-device`. The old app had a `refrredlink.dart` for referral link handling. Deep link handling in the enterprise app is not yet fully implemented at the Flutter layer.

---

## Adding a new route

1. Add a string constant to `AppRoutes` in `app_router.dart`.
2. Add a `GoRoute` entry in the `routes` list inside `createRouter`.
3. If it needs auth, no extra work is needed — the redirect guard blocks unauthenticated access to all non-auth paths.
4. To push imperatively from outside a widget context (e.g., a camera callback), use the global `navigatorKey`:
   ```dart
   navigatorKey.currentState?.pushNamed('/your-route');
   ```
