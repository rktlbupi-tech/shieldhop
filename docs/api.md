# API Reference — Presshop Enterprise

All endpoints are constants in `presshop_enterprise/lib/core/network/api_endpoints.dart`.  
Base URL is set per flavor in `AppConfig.apiBaseUrl` (`https://<host>:5019/`).

---

## HTTP Client

`ApiClient` wraps Dio. All methods throw a `Failure` subclass on error — they never throw raw `DioException`.

```dart
// Injected via GetIt
final api = getIt<ApiClient>();

await api.get(ApiEndpoints.tasks, queryParameters: {'limit': 20});
await api.post(ApiEndpoints.login, data: {'email': ..., 'password': ...});
await api.patch(ApiEndpoints.updateProfile, data: {...});
await api.put(path, data: data);
await api.delete(path);
```

Interceptors (applied in order):
1. `TokenInterceptor` — clears session on 401
2. `AuthInterceptor` — adds `Authorization: Bearer <token>` header
3. `AppLogInterceptor` — logs in debug mode

---

## Auth Endpoints

| Constant | Method | Path | Notes |
|---|---|---|---|
| `login` | POST | `auth/loginEnterpriseEmployee` | Returns JWT token |
| `signup` | POST | `auth/registerEnterpriseEmployee` | |
| `refreshToken` | POST | `auth/refreshToken` | |
| `logout` | POST | `auth/logout` | |
| `sendOtp` | POST | `hopper/sendEmailOTP` | Forgot password step 1 |
| `verifyOtp` | POST | `hopper/verifyEmailOTP` | Forgot password step 2 |
| `forgotPassword` | POST | `auth/forgotPassword` | |
| `resetPassword` | POST | `auth/resetPassword` | |
| `changePassword` | POST | `users/changePassword` | Authenticated |
| `deleteAccount` | POST | `hopper/verifyAndDeleteAccount` | OTP-confirmed deletion |

---

## Profile

| Constant | Method | Path |
|---|---|---|
| `getProfile` | GET | `hopper/getEnterpriseUserProfile` |
| `updateProfile` | PATCH | `hopper/updateEnterpriseUserProfile` |

---

## Attendance

| Constant | Method | Path |
|---|---|---|
| `checkIn` | POST | `enterprise/attendance/check-in` |
| `checkOut` | POST | `enterprise/attendance/check-out` |
| `attendanceLog` | GET | `enterprise/attendance/log` |

---

## Tasks

| Constant | Method | Path | Notes |
|---|---|---|---|
| `tasks` | GET | `enterprise/tasks` | Supports `startDate`, `endDate`, `limit` query params |
| `taskDetails` | GET | `enterprise/tasks/<id>` | Append ID to constant |

---

## Documents

| Constant | Method | Path |
|---|---|---|
| `documents` | GET | `enterprise/documents` |

---

## Earnings

| Constant | Method | Path |
|---|---|---|
| `earnings` | GET | `enterprise/earnings` |

---

## Map / Heatmap

| Constant | Method | Path |
|---|---|---|
| `heatmapLocation` | GET/POST | `enterprise/heatmap/location` |
| `heatmapWorkers` | GET | `enterprise/heatmap/workers` |
| `heatmapAlerts` | GET | `enterprise/heatmap/alerts` |

---

## SOS

| Constant | Method | Path |
|---|---|---|
| `sosStart` | POST | `enterprise/sos/start` |
| `sosStop` | POST | `enterprise/sos/stop` |
| `sosMe` | GET | `enterprise/sos/me` |

---

## Notifications / Devices

| Constant | Method | Path |
|---|---|---|
| `fcmToken` | POST | `enterprise/devices/fcm-token` |
| `notifications` | GET | `enterprise/notifications` |

---

## Feed

| Constant | Method | Path |
|---|---|---|
| `feed` | GET | `enterprise/feed/assigned` |

---

## Settings / CMS

| Constant | Method | Path |
|---|---|---|
| `getGeneralMgmtApp` | GET | `hopper/getGenralMgmtApp` |
| `getCategory` | GET | `hopper/getCategory` |
| `contactUs` | POST | `hopper/Addcontact_us` |

---

## Deep Links

| Constant | Method | Path |
|---|---|---|
| `resolveDeepLink` | GET | `api/deep-links/<id>` |
| `matchDevice` | POST | `api/deep-links/match-device` |

---

## WebSocket Events (Map / Live)

Connected via `MapSocketClient` in `features/map/core/`. Event names are in `MapSocketConstants`.

### Emitters (client → server)

| Event | Purpose |
|---|---|
| `heatmap.subscribe` | Start receiving heatmap updates |
| `heatmap.unsubscribe` | Stop receiving heatmap updates |
| `heatmap.location.update` | Send own GPS position |
| `heatmap.alert.share` | Broadcast an alert to team |
| `heatmap.alert.resolve` | Mark an alert resolved |

### Listeners (server → client)

| Event | Payload |
|---|---|
| `heatmap.snapshot` | Full initial state of all workers + alerts |
| `heatmap.worker.updated` | Single worker position update |
| `heatmap.alert.created` | New alert created |
| `heatmap.alert.updated` | Alert updated |
| `heatmap.error` | Server-side error |
| `sos.session.started` | SOS session opened by a team member |
| `sos.session.updated` | SOS location update |
| `sos.session.resolved` | SOS session closed |

---

## CDN URLs

Built via `AppConfig` helpers. All take a relative path from the API response.

```dart
AppConfig.contentImage(path)   // /public/contentData/<path>
AppConfig.taskMedia(path)      // /public/uploadContent/<path>
AppConfig.thumbnail(path)      // /public/thumbnail/<path>
AppConfig.avatarImage(path)    // /public/avatarImages/<path>
AppConfig.profileImage(path)   // /public/userImages/<path>
```
