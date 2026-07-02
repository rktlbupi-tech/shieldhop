# Employee App API — App Settings (dashboard + menu visibility)

Per-team-member visibility config the operator controls from the marketplace.
It tells the app **which Home/dashboard widgets and which menu items to show**
for the signed-in team member. Booleans only.

The app reads it from **one** endpoint. It is **self-scoped** — the team member
is taken from the login token, so you never send an employee id. Fetch it once on
launch / login (and on resume) and use the flags to show/hide surfaces.

---

## 1. Basics

**Base URL**

```
https://dev-api.presshop.news:5019/enterprise
```

**Auth** — the team member's login token on every request:

```
Authorization: Bearer <token>
Content-Type: application/json
```

Must be an **enterprise employee** account (admin / MediaHouse accounts get
`403 FORBIDDEN`). Response shape: `{ "success": true, "data": ... }` on success,
`{ "success": false, "code", "message" }` on error.

**Defaults / forward-compatibility:** every known key is always present and
defaults to `true`. If the operator has never touched a team member's settings,
you get all-`true`. Treat a **missing** key as `true` as well, so older apps keep
working when new keys are added later.

---

## 2. Get my app settings — `GET /app/app-settings`

No params. Returns the caller's config.

```jsonc
{
  "success": true,
  "data": {
    "employee_id": "6a1fd734e96730abbc8ddaec",
    "dashboard": {
      "captureMoment": true,
      "task": true,
      "duties": true,
      "attendance": true,
      "viewEarnings": true,
      "mileageTrips": true,
      "needsAttention": true
    },
    "menu": {
      "form": true,
      "mileage": true,
      "claimExpenses": true,
      "payslip": true,
      "viewEarnings": true,
      "faq": true,
      "legalTerms": true,
      "privacyPolicy": true
    }
  }
}
```

### What each flag gates

**`dashboard.*`** — Home screen sections (see `home-screen.md`):

| Key | Show this when `true` |
|-----|-----------------------|
| `captureMoment`  | "Capture the moment" quick action |
| `task`           | Tasks summary card |
| `duties`         | Duties / shift summary card |
| `attendance`     | This-week attendance strip |
| `viewEarnings`   | Earnings / latest-payslip card |
| `mileageTrips`   | Mileage + my-vehicle card |
| `needsAttention` | "Needs your attention" row |

**`menu.*`** — app menu / drawer entries:

| Key | Menu item |
|-----|-----------|
| `form`          | Forms |
| `mileage`       | Mileage |
| `claimExpenses` | Claim expenses |
| `payslip`       | Payslip |
| `viewEarnings`  | View earnings |
| `faq`           | FAQ |
| `legalTerms`    | Legal & terms |
| `privacyPolicy` | Privacy policy |

Rule of thumb: **`true` → render the surface, `false` → hide it.** The config
only controls visibility; the underlying data endpoints are unchanged. Hiding a
menu item should also make its route unreachable (don't rely on hiding alone).

---

## 3. Errors

| Status | code | When |
|--------|------|------|
| 401 | `UNAUTHORIZED` | missing / invalid token |
| 403 | `FORBIDDEN` | token is not an enterprise employee (admin account) |

---

## 4. Notes for the app

- **Cache it** for the session; re-fetch on login and on app resume so operator
  changes take effect without a reinstall.
- **Unknown keys = `true`.** New dashboard widgets / menu items may be added to
  the config over time; default anything you don't recognise to visible.
- This is **read-only** for the app. Operators change it in the marketplace
  (`GET/PUT /enterprise/app-settings/:userId`, admin only) — not from the app.

---

## 5. Implementation notes (this repo)

- **Full path (relative to `AppConfig.apiBaseUrl` = `https://<host>:5019/`):**
  `enterprise/app/app-settings` → `ApiEndpoints.appSettings`.
- **Feature:** `lib/features/app_settings/` (clean architecture; `AppSettingsCubit`).
- **Fail-open:** on any error/`403`/network failure the cubit falls back to
  `AppSettingsEntity.allVisible()` (everything `true`) — an error must never hide
  the whole app.
- **Consumers:**
  - Dashboard flags gate the Home cards in `home_screen.dart` (`HomeScreen3`).
  - Menu flags gate items in `menu_screen.dart`, **and** the router
    (`app_router.dart`) redirects the corresponding routes to `/dashboard` when a
    flag is `false`, using flags cached in `SharedPreferences`
    (`app_settings_menu_<key>`).
  - `legalTerms` / `privacyPolicy` share the `/term-check` route, so they are
    gated at the **menu-item level only** (the route itself is not guarded).
- **Lifecycle:** provided at `DashboardScreen`; fetched on init and re-fetched on
  `AppLifecycleState.resumed`.
