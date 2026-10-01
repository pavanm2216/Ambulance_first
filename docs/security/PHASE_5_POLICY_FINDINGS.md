# Phase 5 — Supabase RLS Policy Findings

## Verified from the supplied Supabase policy inventory

RLS is enabled on:

- ambulances
- audit_logs
- booking_doctor_assessments
- booking_status_history
- booking_vitals
- bookings
- customer_care
- doctors
- drivers
- notifications
- profiles

`FORCE ROW LEVEL SECURITY` is false for all of the above.

## Critical finding

Several tables still have permissive `public` / `ALL` policies with `USING true` and `WITH CHECK true`:

- ambulances_open
- audit_logs_open
- assessments_open
- status_history_open
- vitals_open
- bookings_open
- customer_care_open
- doctors_open
- drivers_open
- notifications_open
- profiles_open

Because these policies are `PERMISSIVE`, adding a narrower policy does **not** secure the table while the open policy remains. The open policy must be removed/replaced only after the replacement policy is validated.

## Additional policy conflicts

`doctors`, `drivers`, and `customer_care` contain authenticated read/insert policies in addition to their open policies. These are currently redundant while the open policy exists.

`doctors_write` and `drivers_write` allow ADMIN/TEAM_LEAD through a profile lookup, but are also ineffective as a security boundary while the corresponding `*_open` policy remains.

`profiles` currently has both:

- own-profile SELECT/UPDATE policies
- `profiles_read_all`
- `profiles_open`
- `profiles_insert_service` with `WITH CHECK true`

This means profile data is currently broadly readable/writable through the permissive policy set.

## Role population verified

- ADMIN: 3
- CUSTOMER: 5
- CUSTOMER_CARE: 1
- DOCTOR: 1
- DRIVER: 2
- TEAM_LEAD: 1

No `EMT` profile role was returned.

## Why the destructive migration is intentionally not generated yet

The policy predicates for `bookings`, `booking_status_history`, `booking_vitals`, `booking_doctor_assessments`, `notifications`, and `ambulances` depend on exact foreign-key/linkage columns and the existing workflow write paths.

Only one booking ownership field is confirmed from the Flutter repository: `bookings.customer_id`.

The following must be confirmed before replacing the open policies:

1. Exact columns and foreign keys for bookings and clinical/history tables.
2. How driver/doctor/team-lead/customer-care identities map to profiles.
3. Whether assigned booking IDs are the authoritative allocation link.
4. Existing website write operations that must continue to work.
5. Whether the pricing_settings migration has been applied.

Do **not** drop the `*_open` policies until these items are verified.
