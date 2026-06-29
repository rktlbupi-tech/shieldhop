# Employee App API — Attendance Log Screen

This is the API for the **"Attendance log"** screen in the employee mobile app (Flutter):
the four stat cards, the **Attendance Log** list, and the **Attendance Issues** tab.
Everything here is **self-scoped** — the team member is taken from the login token, so
you never send an employee id.

> Clock-in / clock-out (the "Log On Duty" button) is documented separately in
> `attendance-capture.md` and is already implemented via `POST /app/attendance/punch`.

---

## 1. Basics

**Base URL**

```
https://dev-api.presshop.news:5019/enterprise
```

**Auth** — send the team member's login token on every request:

```
Authorization: Bearer <token>
Content-Type: application/json
```

The caller must be logged in as an **enterprise employee** account (an admin account
gets `403`).

**Response shape**

```jsonc
// success
{ "success": true, "data": { ... } }
// error
{ "success": false, "code": "BAD_REQUEST", "message": "Invalid issue type" }
```

Read `success` first; on error show `message`.

---

## 2. Stat cards — `GET /app/attendance/summary`

The four cards at the top of the screen. No params.

```jsonc
{
  "success": true,
  "data": {
    "hours_this_week": { "worked": 0, "target": 8 }, // Hours This Week: 0 / 8h
    "attendance_rate": 100,                            // Attendance Rate: 100%
    "late_arrivals": 0,                                // Late Arrivals: 0
    "duty_days": { "present": 1, "total": 1 }          // Duty Days: 1 / 1d
  }
}
```

- **hours_this_week** — `worked` hours so far this week (Mon→today) vs the `target`
  (scheduled working days this week × 8h).
- **attendance_rate** — `present / scheduled` working days **this calendar month**, as a
  percentage (1 decimal).
- **late_arrivals** — late clock-ins **this month**.
- **duty_days** — `present` (days clocked in) of `total` scheduled working days **this month**.

Render as: `Hours This Week {worked} / {target}h`, `Attendance Rate {rate}%`,
`Late Arrivals {n} arrivals`, `Duty Days {present} / {total}d`.

---

## 3. Attendance Log list — `GET /app/attendance/log`

Per-day history, newest first.

**Query**: `days` (optional, default `30`, max `92`).

```jsonc
{
  "success": true,
  "data": [
    {
      "date": "2026-06-24",
      "in": "2026-06-24T05:19:02.334Z",   // ISO, null if not clocked in
      "out": "2026-06-24T05:19:20.063Z",  // ISO, null if still on duty
      "hours": 8.5,                         // worked hours (1 decimal)
      "status": "on_time"
    }
  ]
}
```

**`status` values** → badge to show:

| status | badge |
| --- | --- |
| `on_time` | On Time (green) |
| `late` | Late Arrival (amber) |
| `present` | On Duty — clocked in, not out yet |
| `absent` | Absent (red) — a scheduled day with no clock-in |
| `off` | non-working day (only appears if they worked it) |
| `upcoming` | a future scheduled day |

Pure non-working days with no activity are omitted. Format `in`/`out` to local time
(e.g. `09:15 AM`).

---

## 4. Attendance Issues tab

A team member raises an attendance issue (e.g. a missing clock-out, a medical reason),
and HR or a manager approves/rejects it. The team member sees the status and the
reply.

### 4a. Raise an issue — `POST /app/attendance/issues`

**Body**

```jsonc
{
  "type": "missing_clock_out",          // required, see table below
  "date": "2026-06-22",                  // YYYY-MM-DD the issue is about (default: today)
  "details": "Forgot to clock out..."    // free text
}
```

**`type` values** (the dropdown):

| value | label |
| --- | --- |
| `medical_issue` | Medical Issue |
| `missing_clock_in` | Missing Clock In |
| `missing_clock_out` | Missing Clock Out |
| `late_arrival` | Late Arrival |
| `wrong_time` | Wrong Time |
| `other` | Other |

**Response** (`201`):

```jsonc
{
  "success": true,
  "data": {
    "id": "6a3b72634f237f3e79db7253",
    "code": "Q-8137",                    // human reference, show this
    "type": "missing_clock_out",
    "date": "2026-06-22",
    "details": "Forgot to clock out...",
    "status": "pending",                  // pending | approved | rejected
    "hr_response": null,                  // HR/Admin reply once decided
    "decided_by": null,
    "decided_at": null,
    "created_at": "2026-06-24T06:00:03.862Z"
  }
}
```

An invalid `type` returns `400 BAD_REQUEST` ("Invalid issue type").

### 4b. My issue log — `GET /app/attendance/issues`

**Query**: `limit` (optional, default `50`, max `100`). Newest first, same item shape as
above. Once HR/a manager decides it:

```jsonc
{
  "id": "6a3b72634f237f3e79db7253",
  "code": "Q-8137",
  "type": "missing_clock_out",
  "date": "2026-06-22",
  "details": "Forgot to clock out...",
  "status": "approved",
  "hr_response": "Approved. Your clock-out has been corrected to 5:45 PM.",
  "decided_by": "Rishabh Vishwakarma",
  "decided_at": "2026-06-24T06:00:31.090Z",
  "created_at": "2026-06-24T06:00:03.862Z"
}
```

Render the `Q-####` code, a status pill (`pending` / `approved` / `rejected`), the
`details`, and — when present — the `hr_response` as "Response from HR/Admin".

---

## 5. Quick reference

| Action | Method | Path |
| --- | --- | --- |
| Stat cards | GET | `/app/attendance/summary` |
| Attendance log list | GET | `/app/attendance/log?days=30` |
| Raise an issue | POST | `/app/attendance/issues` |
| My issues | GET | `/app/attendance/issues?limit=50` |
| Log On Duty (clock in/out) | POST | `/app/attendance/punch` (see attendance-capture.md) |

> Approving/rejecting an issue is an **admin** action on the marketplace side, not part
> of the employee app.

> Note: paths above are relative to the `enterprise` base. Full endpoint is e.g.
> `enterprise/app/attendance/summary`.
