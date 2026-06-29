# Employee App API — Claim Expenses Screen

API for the **Claim expenses** screen in the employee mobile app (Flutter): the
"My Expense Summary" cards, the "Recent Claims" list, and the "Add New Expense"
form. Self-scoped — the team member comes from the login token.

---

## 1. Basics

**Base URL**

```
https://dev-api.presshop.news:5019/enterprise
```

**Auth** — team member's login token on every request:

```
Authorization: Bearer <token>
Content-Type: application/json
```

Must be an **enterprise employee** account (admin accounts get `403`). Money is a
number + `currency` (the employee's preferred currency, e.g. `GBP`).

---

## 2. Summary cards — `GET /app/claims/summary`

The four "My Expense Summary" cards.

**Query**: `period` — `this_month` (default) or `all`.

```jsonc
{
  "success": true,
  "data": {
    "submitted":  { "amount": 289.00, "count": 6 },  // ALL claims (total)
    "in_review":  { "amount": 84.00,  "count": 2 },
    "approved":   { "amount": 160.00, "count": 3 },
    "rejected":   { "amount": 45.00,  "count": 1 }
  }
}
```

- **submitted** = the total of every claim in the period (the other three add up to it:
  `in_review + approved + rejected == submitted`).
- Render: `Submitted £{amount} · {count} Claims`, etc.

---

## 3. Recent claims — `GET /app/claims`

The "Recent Claims" list, newest first.

**Query**: `limit` (optional, default `50`, max `100`).

```jsonc
{
  "success": true,
  "data": [
    {
      "id": "6a3b9d05670893a0c9a21ff2",
      "category": "meal",
      "description": "Client Meeting",
      "date": "2026-06-07",
      "amount": 28.00,
      "currency": "GBP",
      "status": "approved",          // in_review | approved | rejected
      "reimbursed": true,            // show "Reimbursed" when true
      "receipt_url": null,
      "decision_note": "Approved and reimbursed.",  // HR/Admin reply, may be null
      "created_at": "2026-06-24T..."
    }
  ]
}
```

Status badge: `in_review` → "In Review" (amber), `approved` → "Approved" (green, plus a
"Reimbursed" tag when `reimbursed` is true), `rejected` → "Rejected" (red).

---

## 4. Add a claim — `POST /app/claims`

The "Add New Expense" form. New claims start as `in_review`.

**Body**

```jsonc
{
  "category": "fuel",                 // required, see table
  "claim_date": "2026-06-08",          // YYYY-MM-DD (default: today)
  "description": "Site Visit - Building A",
  "amount": 65.50,                     // required, > 0
  "receipt_url": "https://..."         // optional; upload the file first (media flow)
}
```

**`category` values** (the dropdown):

| value | label |
| --- | --- |
| `fuel` | Fuel |
| `meal` | Meal |
| `parking_toll` | Parking & Toll |
| `travel` | Travel |
| `accommodation` | Accommodation |
| `office_supplies` | Office Supplies |
| `other` | Other |

**Response** (`201`): the created claim (same item shape as section 3, `status: "in_review"`).

Errors: invalid `category` → `400` ("Invalid expense category"); missing/zero/negative
`amount` → `400` ("A valid amount is required").

> **Receipts**: upload the photo/file through the existing media-upload flow first, then
> pass the resulting URL as `receipt_url`. This endpoint only stores the URL.

---

## 5. Quick reference

| Action | Method | Path |
| --- | --- | --- |
| Summary cards | GET | `/app/claims/summary?period=this_month` |
| Recent claims | GET | `/app/claims` |
| Add a claim | POST | `/app/claims` |

> Approving / rejecting / reimbursing a claim is an **admin** action on the marketplace
> side, not part of the employee app.

> Note: paths are relative to the `enterprise` base — full endpoint e.g.
> `enterprise/app/claims/summary`. Receipts reuse `hopper/uploadUserMedia`.
