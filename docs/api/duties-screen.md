# Employee App API — Duties Screen

API for the **Duties** screen in the employee mobile app (Flutter): the current
shift banner, today's tasks, upcoming shifts, the current duty site, this-month
summary, the shift-history screen, and the "Report Handover Issue" action.

Everything is **self-scoped** — the team member is taken from the login token, so
you never send an employee id.

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

Must be an **enterprise employee** account (admin accounts get `403`). Response
shape: `{ "success": true, "data": ... }` on success, `{ "success": false, "code",
"message" }` on error.

---

## 2. Current duty — `GET /app/duties/current`

The blue shift banner + Current Duty Site card + This Month's Summary. No params.

```jsonc
{
  "success": true,
  "data": {
    "shift": {
      "start_minute": 540, "end_minute": 1020,    // minutes since midnight
      "start": "09:00 AM", "end": "05:00 PM",      // pre-formatted labels
      "duty_days": ["Mon","Tue","Wed","Thu","Fri"],
      "off_days": ["Sat","Sun"]
    },
    "site": {
      "name": "Kanpur Test Site",
      "address": "Kanpur, India",
      "lat": 26.4499, "lng": 80.3319               // for "On Map" / "View Map"
    },
    "supervisor": { "name": "Rahul Sharma", "phone": "+919876543210" }, // null if none
    "this_month": { "days_completed": 1, "total_hours": 0, "attendance_rate": 100 }
  }
}
```

- `shift`, `site` come from the team member's active posting; `null` if they have no
  active assignment yet.
- `supervisor` is the team member's reporting manager (use `phone` for "Call
  Supervisor"); `null` if none set.
- **Remaining duty time** (the countdown) is computed on the client from `now` vs the
  shift end — not returned by the API.

---

## 3. Upcoming shifts — `GET /app/duties/upcoming`

The "Upcoming Tasks" list — the team member's assigned duties, future-dated, soonest
first.

```jsonc
{
  "success": true,
  "data": [
    {
      "id": "6a3b953a661d8bffe96f81b0",
      "date": "2026-06-26T08:00:00.000Z",  // duty start
      "name": "Morning Shift",
      "site": "Lucknow Mill",
      "start": "08:00 AM", "end": "04:00 PM",
      "status": "scheduled"
    }
  ]
}
```

Empty array when nothing is assigned ahead.

---

## 4. Today's tasks — `GET /app/duties/today-tasks`

The checklist on the Duties screen — the team member's task assignments due today.

```jsonc
{
  "success": true,
  "data": [
    {
      "id": "6a3b9570661d8bffe96f8268",
      "title": "Complete first patrol",
      "status": "pending",        // "completed" | "pending"
      "raw_status": "accepted"     // the underlying assignment status
    }
  ]
}
```

Show a tick for `completed`, an empty circle for `pending`.

---

## 5. Shift history — `GET /app/duties/history`

The "Duties history" screen — summary + past shifts.

**Query**: `range` — one of `last_month`, `last_3_months`, `last_6_months`,
`last_year` (default `last_year`).

```jsonc
{
  "success": true,
  "data": {
    "summary": {
      "avg_shift_minutes": 533,   // -> "8h 53m"
      "total_hours": 142.1,
      "shifts_done": 16
    },
    "rows": [
      {
        "date": "2026-06-24",
        "start": "2026-06-24T05:19:02.334Z",
        "end": "2026-06-24T05:19:20.063Z",
        "site": "Kanpur Test Site",
        "duration_minutes": 0,
        "status": "completed"     // "completed" | "late" | "present" (still on duty)
      }
    ]
  }
}
```

Format `avg_shift_minutes` / `duration_minutes` as `Hh Mm`; `start`/`end` to local time.

---

## 6. Report a handover issue — `POST /app/duties/handover-report`

The "Report Handover Issue" modal — notify the supervisor that the relief guard
hasn't arrived, etc.

**Body**

```jsonc
{
  "site_name": "ABC Corporate Office, Sector 62, Noida",   // pre-filled from current site
  "details": "Relief guard has not arrived yet; my shift ended at 6:00 PM."  // required
}
```

**Response** (`201`):

```jsonc
{
  "success": true,
  "data": {
    "id": "6a3b94bd661d8bffe96f8020",
    "site_name": "ABC Corporate Office, Sector 62, Noida",
    "details": "Relief guard has not arrived yet; my shift ended at 6:00 PM.",
    "status": "open",
    "created_at": "2026-06-24T08:26:37.737Z"
  }
}
```

Empty `details` returns `400 BAD_REQUEST` ("Report details are required"). The report
is routed to the team member's supervisor for follow-up.

---

## 7. Quick reference

| Action | Method | Path |
| --- | --- | --- |
| Current duty + site + summary | GET | `/app/duties/current` |
| Upcoming shifts | GET | `/app/duties/upcoming` |
| Today's tasks checklist | GET | `/app/duties/today-tasks` |
| Shift history | GET | `/app/duties/history?range=last_year` |
| Report handover issue | POST | `/app/duties/handover-report` |

> Clock in/out and the Attendance log live in `attendance-capture.md` and
> `attendance-log.md`.

> Note: paths above are relative to the `enterprise` base. Full endpoint is e.g.
> `enterprise/app/duties/current`.
