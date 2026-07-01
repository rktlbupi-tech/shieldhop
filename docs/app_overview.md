# ShieldHop Enterprise — Complete App Overview

## Business Idea

ShieldHop Enterprise (internally "Presshop Enterprise") is a **field-worker management platform** built for news organisations and media companies. It gives **Hoppers** (field employees / journalists / press workers) a single mobile app to manage every aspect of their working day — from clocking in to capturing content to getting paid — while giving their newsroom real-time visibility of where every employee is and what they are doing.

The core value proposition is:
- **Safety first** — live GPS tracking, SOS distress button, heatmap of incidents, and instant alert sharing keep field workers protected.
- **Content pipeline** — employees capture photos, videos, audio, and documents on their phone and publish them directly to the newsroom from the field.
- **Operational control** — duty schedules, task assignment, attendance logs, mileage tracking, and expense claims all live in one place, reducing admin overhead.
- **Financial transparency** — payslips, earnings breakdowns, and HR documents are accessible on-device, reducing paper and back-office queries.

---

## Who Uses It

| Role | What they do in the app |
|---|---|
| **Hopper (field employee)** | Checks in/out, captures & submits content, views assigned tasks, tracks mileage, claims expenses, reads payslips, and raises SOS if in danger |
| **Newsroom / Manager** | (Managed via a separate admin portal) — assigns tasks, views the live map, reviews submitted evidence |

---

## App Structure

```
presshop_enterprise/
  lib/
    config/               # DI (get_it), routing (go_router), app config/flavors
    core/                 # ApiClient (Dio), SocketManager, error types, constants
    features/             # One folder per feature — Clean Architecture inside each
    presentation/widgets/ # Shared UI components
  assets/
    icons/                # SVG + PNG icons
    markers/              # Map marker images
    rabbits/              # Mascot illustrations used in dialogs
```

Every feature follows the same three-layer pattern:

```
features/<name>/
  data/        → datasources (HTTP/socket), models (JSON), repositories (impl)
  domain/      → entities (pure Dart), repository interfaces, use-cases
  presentation → BLoC/Cubit, screens, widgets
```

---

## Bottom Navigation — 5 Tabs

| Index | Tab | Screen |
|---|---|---|
| 0 | Evidence | `EvidenceScreen` — submitted content feed |
| 1 | Task | `TaskScheduleScreen` — calendar + timeline of tasks |
| 2 | Home (default) | `HomeScreen3` — greeting, duty toggle, quick actions |
| 3 | Team | `TeamMapScreen` — live GPS map of all field workers |
| 4 | Menu | `MenuScreen` — full feature list + settings |

---

## Features (A–Z)

### 1. Authentication (`auth`)
**What it does:** Login, signup, forgot-password (OTP email flow), and logout.

On login the app writes `auth_token`, `user_id`, `user_email`, `user_first_name`, `user_last_name` to SharedPreferences. A `TokenInterceptor` clears the session on any 401 response and the GoRouter guard redirects to `/login`.

| Screen | Purpose |
|---|---|
| `login_screen.dart` | Email + password form |
| `signup_screen.dart` | Registration form |
| `forgot_password_screen.dart` | OTP email reset flow |

---

### 2. Attendance (`attendance`)
**What it does:** Employees clock in and out. GPS location is captured at each event. An attendance history log is shown with sliding tabs (Today / This Week / This Month).

| Screen | Purpose |
|---|---|
| `check_in_out_screen.dart` | Clock-in / clock-out action with location capture |
| `attendance_screen.dart` | History list with period filter |

BLoC events: `FetchAttendanceLog`, `CheckIn`, `CheckOut`.

---

### 3. Camera & Content Capture (`camera`)
**What it does:** The core content-capture feature. Employees capture photos, videos, audio recordings, or document scans in the field and publish them with a task tag, description, and GPS location.

| Screen | Purpose |
|---|---|
| `employee_camera_screen.dart` | Main capture — toggles photo / video / audio / doc modes |
| `employee_preview_screen.dart` | Preview before publishing |
| `employee_publish_content_screen.dart` | Attach task, description, location — triggers upload |
| `custom_gallery_screen.dart` | Pick from device gallery |
| `audio_recorder_screen.dart` | Standalone audio recording |
| `content_submitted_screen.dart` | Upload success confirmation |

Upload uses a **dedicated Dio instance** with long timeouts and multipart encoding (`CameraTaskService`). GPS + reverse geocoding is handled by `CameraLocationService`.

---

### 4. Evidence / Content Feed (`content`)
**What it does:** Tab 0 of the bottom nav. Shows a scrollable feed of all content submitted by the employee (and optionally their team). Each card shows media type, thumbnail, timestamp, and linked task.

| File | Purpose |
|---|---|
| `evidence_screen.dart` | Feed list |
| `evidence_details_screen.dart` | Full detail view of a single submission |
| `enterprise_feed_model.dart` | JSON model |

---

### 5. Tasks (`tasks`)
**What it does:** Task assignment and tracking. Tab 1 shows a calendar + day-view timeline. Employees can view task details, update status, and message within a per-task chat thread.

| Screen | Purpose |
|---|---|
| `task_schedule_screen.dart` | Calendar/timeline view (bottom-nav tab) |
| `tasks_screen.dart` | Full task list |
| `task_details_screen.dart` | Single task + status update |
| `task_chat_screen.dart` | Per-task chat thread (Socket.io) |

BLoC events: `FetchTasks`, `FetchTaskById`, `UpdateTaskStatus`, `FetchTaskMessages`, `SendTaskMessage`.

---

### 6. Live Map (`map`)
**What it does:** Tab 3. A real-time Google Map shows every online field worker as a custom marker. The employee's own location is broadcast to the server via WebSocket every few seconds. Features include:
- Live worker markers (colour-coded by duty status)
- Heatmap overlay of recent activity/incidents
- Employee search + filter by area
- Get directions to a colleague
- SOS trigger from the map
- Alert sharing to all team members
- Entry point to Team Chat

| Key file | Purpose |
|---|---|
| `team_map_screen.dart` | Main screen — wraps `MapCubit` + `EmployeeMapCubit` |
| `map_cubit.dart` | Camera, marker selection, filter state |
| `employee_map_cubit.dart` | Own location broadcast |
| `map_socket_client.dart` | Socket.io wrapper for map events |
| `heatmap_service.dart` | Renders heatmap tiles |
| `marker_service.dart` | Builds custom Google Maps markers |
| `sos_service.dart` | SOS start/stop REST calls |

Socket channels: `chatSocket` (port 3005 / `chat-v2`) and `liveSocket` (port 3005 / `enterprise-live`).

---

### 7. SOS (`sos`)
**What it does:** Emergency distress button accessible from the Home screen AppBar and from the Map tab. Shows a countdown dialog — if confirmed, triggers a server-side SOS that alerts the newsroom and broadcasts the employee's location.

| File | Purpose |
|---|---|
| `sos_dialog.dart` | Countdown + confirm dialog |
| `sos_service.dart` | REST calls to start/stop SOS |

---

### 8. Team Chat (`team_chat` + `chat`)
**What it does:** Real-time group and direct messaging between field workers and the newsroom. The chat list is accessible from the Map tab or the Menu. Individual threads use Socket.io for real-time delivery.

| Screen | Purpose |
|---|---|
| `team_chat_list_page.dart` | List of chat rooms/threads |
| `team_chat_message_page.dart` | Individual chat thread |
| `team_chat_screen.dart` | Standalone full-screen chat |

---

### 9. Duties (`duties`)
**What it does:** Shows the employee's duty roster — current duty, upcoming duties, today's tasks, history, and handover information.

| Screen | Purpose |
|---|---|
| `duties_screen.dart` | Duty roster / schedule tabs |

BLoC events: `FetchCurrentDuty`, `FetchUpcomingDuties`, `FetchTodayTasks`, `FetchDutyHistory`, `FetchHandoverInfo`.

---

### 10. Attendance Log in Pay Hub
Accessed via Menu → Pay Hub → Attendance Log. Shows a detailed punch-in/out log with issue flags for missing or anomalous records. Part of the Attendance feature (`attendance_screen.dart`).

---

### 11. Earnings (`earnings`)
**What it does:** Shows the employee's earnings broken down by month and year. Cards show gross pay, deductions, and net pay for each period.

| Screen | Purpose |
|---|---|
| `earnings_screen.dart` | Earnings list with year/month filter |

---

### 12. Payslip (`payslip`)
**What it does:** Lists payslips by month. Employees can view or download their payslip PDF directly on the device.

| Screen | Purpose |
|---|---|
| `payslip_screen.dart` | Payslip list + in-app PDF viewer |

---

### 13. Documents (`documents`)
**What it does:** HR document repository — contracts, certificates, compliance docs. Employees can view PDFs in-app, upload new documents, and delete their own uploads.

| Screen | Purpose |
|---|---|
| `documents_screen.dart` | Document list |
| `document_preview_screen.dart` | PDF viewer (`syncfusion_flutter_pdfviewer`) |

---

### 14. Mileage Tracking (`mileage`)
**What it does:** GPS-based mileage tracker. Employees start a trip, the app records distance travelled, and the trip is stored with a summary. No live route geometry is drawn on the map — only summary stats.

| Screen | Purpose |
|---|---|
| `track_mileage_screen.dart` | Start/stop trip + trip history |

---

### 15. Expense Claims (`claims`)
**What it does:** Employees submit reimbursement claims for expenses incurred in the field (mileage, subsistence, etc.). Summary cards show total claimed, approved, and pending amounts.

| Screen | Purpose |
|---|---|
| `claim_expenses_screen.dart` | Claim list + add new claim form |

---

### 16. Submit Forms (`submit_forms`)
**What it does:** A collection of company forms (safety checklists, incident reports, etc.) rendered in a `webview_flutter` WebView. The list of available forms is fetched from the API.

| Screen | Purpose |
|---|---|
| `submit_forms_screen.dart` | Available forms list |
| `web_view_form_screen.dart` | WebView wrapper |

---

### 17. Profile (`profile`)
**What it does:** View and edit the employee's own profile (name, phone, avatar). Also shows a **Digital ID Card** — a QR code that serves as the employee's on-site identity credential.

| Screen | Purpose |
|---|---|
| `profile_screen.dart` | Profile detail + edit |
| `digital_id_screen.dart` | QR-based digital employee ID |

`ProfileBloc` is provided at `DashboardScreen` level so the AppBar always has fresh data.

---

### 18. Notifications (`notifications`)
**What it does:** Push notification history. Firebase Cloud Messaging (FCM) is used for delivery. The notification centre lists all past alerts, task assignments, and newsroom broadcasts.

| Screen | Purpose |
|---|---|
| `notifications_screen.dart` | Notification list |
| `enterprise_fcm_service.dart` | FCM token registration/removal |

---

### 19. Settings (`settings`)
**What it does:** Account management and legal pages.

| Screen | Purpose |
|---|---|
| `account_settings_screen.dart` | Settings entry list |
| `change_password_screen.dart` | Password change form |
| `faq_screen.dart` | FAQ (WebView or static) |
| `term_check_screen.dart` | T&C / Privacy Policy viewer |
| `account_delete_screen.dart` | Delete account with OTP confirmation |

---

### 20. Onboarding & Splash
| Feature | Screen | Purpose |
|---|---|---|
| `splash` | `SplashScreen` | Initialises app, checks auth token, redirects to dashboard or onboarding |
| `onboarding` | `OnboardingScreen` | Shown once on first install; sets `onboarding_seen = true` |

---

## Menu Groups Summary

The Menu tab (tab 4) organises every feature into five groups:

| Group | Items |
|---|---|
| **MY ACCOUNT** | My Profile, Digital ID, Notifications |
| **WORK HUB** | View Tasks, Evidence, Submit Form, Track Mileage, Claim Expenses |
| **PAY HUB** | Duties, Attendance Log, Payslip, View Earnings, My Documents |
| **SAFETY & SUPPORT** | Share Alert, SOS, Chat |
| **MORE** | FAQs, Legal T&Cs, Privacy Policy, Logout |

The Menu also contains the **Duty Toggle** at the top — a switch that moves the employee between On Duty (visible on the live map, location broadcasting active) and Off Duty (invisible, location paused). Switching On Duty triggers a **Uniform Verification** step before activating.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — iOS + Android |
| State management | `flutter_bloc` — BLoC for multi-event features, Cubit for simple read/fetch |
| Dependency injection | `get_it` (lazy singletons for data/domain; factory for BLoCs) |
| Navigation | `go_router` with redirect guard |
| HTTP | `Dio` via `ApiClient`; separate Dio instance for multipart uploads |
| WebSocket | `socket_io_client` via `SocketManager` (two channels: chat + live) |
| Maps | `google_maps_flutter` |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Local storage | `shared_preferences` |
| PDF viewer | `syncfusion_flutter_pdfviewer` |
| WebView | `webview_flutter` |
| Code generation | `freezed` + `json_serializable` via `build_runner` |
| Screen sizing | `flutter_screenutil` (390 × 844 baseline) |
| Fonts | Poppins (body), AirbnbCereal (headers/nav) |

---

## Environments

| Flavor | API Host | Use |
|---|---|---|
| `dev` | `dev-api.presshop.news:5019` | Development / testing |
| `staging` | `staging-api.presshop.news:5019` | Pre-production QA |
| `prod` | `api.presshop.news:5019` | Live production |

Switch by changing `AppConfig.init(AppFlavor.dev|staging|prod)` in `main.dart`.

---

## Known Gaps / Pending Work

| Item | Status |
|---|---|
| Multi-language (i18n) | Not yet implemented (`important.txt` notes this) |
| Home screen API binding | Backend + `HomeBloc` done; binding the UI (`HomeScreen3`) to live data is the remaining step |
| `lib/features/others/` | Legacy screens not yet migrated into their correct feature folders |
| `home_screen.dart` / `home_screen copy.dart` | Dead code — superseded by `home_screen_v2.dart`; kept for reference only |
