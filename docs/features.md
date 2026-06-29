# Features — Presshop Enterprise

Each feature lives at `presshop_enterprise/lib/features/<name>/`. This document describes what each feature does and its key files.

---

## auth

Login, signup, forgot/reset password, logout.

| File | Purpose |
|---|---|
| `domain/usecases/login_usecase.dart` | Calls `AuthRepository.login`, stores token + user data in SharedPreferences |
| `domain/usecases/logout_usecase.dart` | Calls `AuthRepository.logout`, clears SharedPreferences |
| `presentation/bloc/auth_bloc.dart` | Events: `LoginSubmitted`, `SignupSubmitted`, `LogoutRequested`, `AuthCheckRequested` |
| `presentation/screens/login_screen.dart` | Email + password form |
| `presentation/screens/signup_screen.dart` | Registration form |
| `presentation/screens/forgot_password_screen.dart` | OTP email flow |

SharedPreferences keys written on login: `auth_token`, `user_id`, `user_email`, `user_first_name`, `user_last_name`.

---

## dashboard

Shell screen — hosts the bottom navigation and provides `ProfileBloc` to all child tabs.

| File | Purpose |
|---|---|
| `presentation/screens/dashboard_screen.dart` | `IndexedStack` with 5 tabs; exposes `changeTab(index)` via `DashboardScreenState` |
| `presentation/screens/home_screen_v2.dart` | **Active** home tab (`HomeScreen2`) — greeting, on-duty status, quick-action cards |
| `presentation/screens/home_screen.dart` | **Dead code** — superseded by v2 |
| `presentation/screens/home_screen copy.dart` | **Dead code** — copy of above |

Child screens navigate between tabs by calling `context.findAncestorStateOfType<DashboardScreenState>()?.changeTab(index)`.

---

## attendance

Check-in / check-out, attendance history log.

| File | Purpose |
|---|---|
| `presentation/screens/attendance_screen.dart` | History list with sliding tabs (Today / This Week / This Month) |
| `presentation/screens/check_in_out_screen.dart` | Check-in/out action with location capture |
| `presentation/bloc/attendance_bloc.dart` | Handles `FetchAttendance`, `CheckIn`, `CheckOut` events |

---

## tasks

Task list, task details, task-linked scheduling.

| File | Purpose |
|---|---|
| `presentation/screens/tasks_screen.dart` | Full task list |
| `presentation/screens/task_schedule_screen.dart` | Calendar/timeline view (used as the Task bottom-nav tab) |
| `presentation/screens/task_details_screen.dart` | Single task detail + status update |
| `presentation/screens/task_chat_screen.dart` | Per-task chat thread |
| `presentation/bloc/tasks_bloc.dart` | Fetches tasks, handles task status updates |
| `presentation/controllers/task_schedule_controller.dart` | Date/week state for the calendar |
| `presentation/widgets/calendar_grid.dart` | Monthly calendar grid |
| `presentation/widgets/day_schedule_timeline.dart` | Day-view timeline |
| `data/models/employee_task_model.dart` | Task model with JSON parsing |

---

## camera

Capture (photo / video / audio / document scan), preview, and publish content linked to a task.

| File | Purpose |
|---|---|
| `presentation/screens/employee_camera_screen.dart` | Main capture screen — toggles photo, video, audio, doc modes |
| `presentation/screens/employee_preview_screen.dart` | Preview captured media before publish |
| `presentation/screens/employee_publish_content_screen.dart` | Form to attach task, description, location; triggers upload |
| `presentation/screens/custom_gallery_screen.dart` | Pick from device gallery |
| `presentation/screens/audio_recorder_screen.dart` | Standalone audio recording |
| `presentation/screens/content_submitted_screen.dart` | Success confirmation |
| `presentation/screens/permission_error_screen.dart` | Shown when camera/mic permissions denied |
| `utils/camera_task_service.dart` | Dedicated Dio instance for multipart upload (separate from `ApiClient`) |
| `utils/camera_location_service.dart` | GPS + reverse geocoding for the capture location |
| `utils/upload_progress_notifier.dart` | `ValueNotifier<double>` for upload progress bar |
| `utils/camera_constants.dart` | String constants for media types (`photoText`, `videoText`, etc.) |

The camera screen uses the global `cameras` list (populated in `main.dart`).

---

## content / evidence

Evidence feed — shows content published by the employee and team.

| File | Purpose |
|---|---|
| `presentation/screens/evidence_screen.dart` | Bottom-nav tab 0; lists submitted content |
| `data/models/enterprise_feed_model.dart` | Feed item model |

---

## map

Live team map, heatmap, SOS, alert sharing, team chat list entry point.

| File | Purpose |
|---|---|
| `presentation/screens/team_map_screen.dart` | Bottom-nav tab 3; Google Maps with live worker markers, heatmap layer, SOS |
| `presentation/screens/team_chat_list_page.dart` | Chat list accessible from the map |
| `presentation/screens/team_chat_message_page.dart` | Individual chat thread |
| `presentation/screens/location_error_screen_map_news.dart` | Shown when GPS permission denied |
| `presentation/bloc/map_cubit.dart` | Manages map camera, marker selection, filters |
| `presentation/bloc/employee_map_cubit.dart` | Manages own employee's live location updates |
| `core/map_socket_client.dart` | Separate Socket.io wrapper for map-specific events |
| `core/map_socket_constants.dart` | Socket event name constants |
| `data/services/heatmap_service.dart` | Renders heatmap tiles |
| `data/services/marker_service.dart` | Builds custom Google Maps markers |
| `data/services/sos_service.dart` | SOS start/stop REST calls |
| `data/services/map_service.dart` | Directions, place search |

`TeamMapScreen` must receive `isScreenActive` to start/stop background location updates when the tab is not visible.

---

## sos

SOS modal dialog triggered from the home screen or map.

| File | Purpose |
|---|---|
| `presentation/widgets/sos_dialog.dart` | Countdown + confirm dialog; calls `SosService` |

---

## profile

Employee profile view and edit, digital ID card.

| File | Purpose |
|---|---|
| `presentation/screens/profile_screen.dart` | Profile detail + edit |
| `presentation/screens/digital_id_screen.dart` | QR-based digital employee ID |
| `presentation/bloc/profile_bloc.dart` | `FetchProfile`, `UpdateProfile` events |

---

## earnings

Earnings summary and history.

| File | Purpose |
|---|---|
| `presentation/screens/earnings_screen.dart` | Earnings list with period filter |
| `presentation/bloc/earnings_bloc.dart` | Fetches earnings data |

---

## documents

HR documents viewer (payslips, contracts, etc.).

| File | Purpose |
|---|---|
| `presentation/screens/documents_screen.dart` | Document list |
| `presentation/screens/document_preview_screen.dart` | PDF viewer (`syncfusion_flutter_pdfviewer`) |
| `presentation/bloc/documents_bloc.dart` | Fetches document list |

---

## payslip

| File | Purpose |
|---|---|
| `presentation/screens/payslip_screen.dart` | Payslip list/preview |

---

## mileage

Mileage tracking and expense claims.

| File | Purpose |
|---|---|
| `presentation/screens/track_mileage_screen.dart` | GPS-based mileage tracker |
| `presentation/screens/claim_expenses_screen.dart` | Submit mileage expense claim |

---

## notifications

Push notification history.

| File | Purpose |
|---|---|
| `presentation/screens/notifications_screen.dart` | Notification list |

---

## settings

Account settings, password change, FAQ, contact us, account deletion.

| File | Purpose |
|---|---|
| `presentation/screens/account_settings_screen.dart` | Settings menu |
| `presentation/screens/change_password_screen.dart` | Password change form |
| `presentation/screens/faq_screen.dart` | FAQ WebView or static content |
| `presentation/screens/contact_us_screen.dart` | Contact form |
| `presentation/screens/term_check_screen.dart` | T&C viewer |
| `presentation/screens/account_delete_screen.dart` | Delete account with OTP confirmation |
| `presentation/bloc/settings_bloc.dart` | Handles settings fetch and updates |

---

## submit_forms

Embeds external forms in a WebView.

| File | Purpose |
|---|---|
| `presentation/screens/submit_forms_screen.dart` | List of available forms |
| `presentation/screens/web_view_form_screen.dart` | `webview_flutter` wrapper |

---

## duties

| File | Purpose |
|---|---|
| `presentation/screens/duties_screen.dart` | Duty roster / schedule |

---

## team_chat

Standalone chat feature (separate from map chat).

| File | Purpose |
|---|---|
| `presentation/screens/team_chat_screen.dart` | Full-screen team chat |

---

## menu

Side/bottom menu listing all features accessible from tab 4.

| File | Purpose |
|---|---|
| `presentation/screens/menu_screen.dart` | Grid/list of all app sections |

---

## onboarding / splash

| Feature | Screen |
|---|---|
| `onboarding` | `OnboardingScreen` — shown once; sets `onboarding_seen=true` |
| `splash` | `SplashScreen` — initialises and redirects |

---

## others (legacy / unmigrated)

`lib/features/others/` contains screens not yet moved into their correct feature folder:

- `ContactUsScreen.dart`
- `TermCheckScreen.dart`
- `UploadDocumentsScreen.dart`
- `accountSetting/account_delete_screen.dart`

These are superseded by the counterparts in `settings/` and should eventually be deleted.
