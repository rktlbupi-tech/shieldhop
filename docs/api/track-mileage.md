# Employee App API — Track Mileage Screen

API for the **Track mileage** screen: KPI cards (Total distance, Total trips, Total
duration, Est. fuel cost), the day-wise **Trips** history, and posting a day's travel.
Self-scoped — the team member comes from the login token.

Base: `https://dev-api.presshop.news:5019/enterprise`. Distance is metres; render in the
org `unit` (`km`/`mi`). Money is a number + `currency`. One consolidated record per day —
posting again for the same date replaces it.

## GET /app/mileage/summary
Query: `period` = daily | weekly | monthly (default) | yearly; `date` = YYYY-MM-DD.
data: period, date, unit, currency, total_distance_meters, distance_delta_meters,
active_days, active_days_delta, total_duration_minutes, duration_delta_minutes,
est_fuel_cost, est_fuel_cost_delta.
Cards: Total distance = total_distance_meters; Total trips = active_days; Total duration
= total_duration_minutes (Xh Ym); Est. fuel cost = est_fuel_cost. Subtitles use *_delta
(green up / red down).

## GET /app/mileage/trips
Query: period + date; limit (default 90, max 366). One row per day, newest first.
item: id, vehicle_id, date, source('gps'|'manual'), distance_meters, duration_minutes,
start_label, end_label, odometer_start, odometer_end, clock_in_at, clock_out_at,
est_fuel_cost, reimbursement_amount, currency, created_at.
Render `{start_label} to {end_label}` + distance + duration; fall back to date when labels null.

## POST /app/mileage/trip
Body: date (optional), distance_meters (GPS) OR odometer_start+odometer_end (manual km),
duration_minutes (optional), source (optional), start_label/end_label (optional),
vehicle_id (optional). Vehicle attribution: explicit vehicle_id → personal → assigned
company; none → 400. Reimbursement computed only for personal vehicles (company = 0).
clock_in_at/out filled server-side (do not send). 201 → the day record (same shape as trips).
Errors: no distance + no odometer → 400; odometer_end < odometer_start → 400.

## Quick reference
| Action | Method | Path |
| --- | --- | --- |
| KPI cards | GET | enterprise/app/mileage/summary?period=&date= |
| Trips (day-wise) | GET | enterprise/app/mileage/trips?period=&date=&limit= |
| Log/replace a day | POST | enterprise/app/mileage/trip |

> The per-vehicle admin rollup and rate/unit/currency settings are admin (marketplace)
> concerns, not part of the employee app.
