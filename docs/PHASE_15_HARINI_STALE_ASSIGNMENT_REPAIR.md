# Phase 15 — Harini Stale Doctor Assignment Repair

## Verified current state

Harini was returned as:

- `status = ASSIGNED`
- `assigned_booking_id = BK-1790061610278`

The same booking was returned as:

- `status = CUSTOMER_ACCEPTED`
- `assigned_doctor_id = 7ad0f843-cf98-4ee9-8f9d-80e46d91bde5`
- `doctor_name = harini`

The booking is not yet `ASSIGNED`, so this is a stale doctor assignment left by the previous allocation QA state.

## Repair

Run:

`docs/migrations/PHASE_15_REPAIR_HARINI_STALE_ASSIGNMENT.sql`

The transaction is scoped to Harini and `BK-1790061610278`. It clears the doctor assignment on both sides and changes Harini to `AVAILABLE` only when the booking is still `CUSTOMER_ACCEPTED`.

## Expected result

```text
Harini
status = AVAILABLE
assigned_booking_id = NULL
```

and:

```text
BK-1790061610278
status = CUSTOMER_ACCEPTED
assigned_doctor_id = NULL
doctor_name = NULL
```

## Why this is safe

The repair does not clear an already allocated booking. If the booking has moved to `ASSIGNED`, the guarded update will not execute.

After the repair, refresh the Team Lead Allocation Workspace. Harini should appear in the doctor list when the booking requires a doctor.
