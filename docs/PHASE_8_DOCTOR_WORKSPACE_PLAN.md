# Phase 8 — Doctor Workspace Plan

The confirmed backend has a `DOCTOR` profile role and a `doctors` resource table.

## Workspace

Doctor Flutter routing should provide:

1. Assigned bookings
2. Patient/booking detail
3. Clinical assessment
4. Vitals view
5. Clinical notes / interventions where supported by the existing schema
6. Assessment submission
7. Completed assessment history

## Existing backend resources

Use the existing tables:

- `profiles`
- `doctors`
- `bookings`
- `booking_vitals`
- `booking_doctor_assessments`
- `notifications`
- `booking_status_history`

Do not create duplicate doctor tables.

## Assignment security

A Doctor must only access bookings assigned to that doctor. The exact RLS expression must be based on the verified relationship between:

```text
auth.uid()
→ profiles.id
→ doctors.id / operational doctor identity
→ bookings.assigned_doctor_id
```

The current schema confirms `bookings.assigned_doctor_id` is UUID and `doctors.id` is UUID. The exact policy should be validated against current foreign keys before deployment.

## Clinical writes

Doctor assessment/vitals writes should be allowed only for the assigned doctor and appropriate booking states. Do not grant blanket write access to all authenticated users.

## EMT

`EMT` remains an operational booking concept (`req_emt`, `assigned_emt_id`, `emt_name`) but is not confirmed as a `profiles.role`. Do not create an EMT authentication role without separate backend evidence.
