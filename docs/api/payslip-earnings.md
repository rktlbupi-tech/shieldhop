# Employee App API — Payslip & Earnings Screens

Read-only payroll screens. Self-scoped (login token). Only **published** payslips. Money
in org currency (₹). Base: `https://dev-api.presshop.news:5019/enterprise`.

## GET /app/payslips
Month picker, newest first. Item: `{id, period, month_label, pay_date, net_pay}`.
Show month_label; net_pay in the Net Pay card. Open a row by id. Empty = none published.

## GET /app/payslips/:id
Full payslip (own + published else 404). data:
- employee: {name, code(""), designation?, department?, location?, joined_date?} — hide null rows.
- period, pay_period{start,end}, pay_date, payment_mode.
- earnings[]: {label, amount} + total_earnings.
- deductions[]: {label, amount} (statutory + TDS + other merged; zero lines omitted) + total_deductions.
- net_pay (= total_earnings - total_deductions).

## GET /app/earnings?year=YYYY
Yearly salary + reimbursements. data:
- year, total_earnings_year (sum of months' total).
- months[] (one per published payslip month, newest first):
  - period, month_label, pay_date, total.
  - salary_components[]: {label, amount} + total_salary.
  - reimbursements[]: {label, amount} + total_reimbursements (Mileage Claims + approved expense
    claims by category). total = total_salary + total_reimbursements.

> Reimbursements are paid outside the payslip (fixed-CTC payroll), so they show on Earnings,
> not in the payslip. Computing/publishing payroll is an admin (marketplace) action.

## Quick reference
| Action | Method | Path |
| --- | --- | --- |
| Payslip month picker | GET | enterprise/app/payslips |
| Full payslip | GET | enterprise/app/payslips/:id |
| Yearly earnings | GET | enterprise/app/earnings?year=YYYY |
