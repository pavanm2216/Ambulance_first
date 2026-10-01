# Phase 5 — RLS Replacement Review

## Current state

The live audit confirmed RLS is enabled on the operational tables, but several permissive `*_open` policies use `USING (true)` / `WITH CHECK (true)`. Because these policies are PERMISSIVE, they override the intended security boundary through OR semantics.

The foreign-key audit also confirmed the important identity relationships:

- `bookings.customer_id -> profiles.id`
- `bookings.assigned_driver_id -> drivers.id`
- `bookings.assigned_doctor_id -> doctors.id`
- `bookings.assigned_emt_id -> profiles.id`
- `bookings.assigned_by_tl_id -> profiles.id`
- `bookings.cc_verified_by_id -> profiles.id`
- `bookings.quotation_prepared_by_id -> profiles.id`
- `drivers.id -> profiles.id`
- `doctors.id -> profiles.id`
- `customer_care.id -> profiles.id`
- clinical/status tables link back to bookings and profiles.

Therefore `drivers.id = auth.uid()`, `doctors.id = auth.uid()`, and `customer_care.id = auth.uid()` are now supported by the database foreign keys rather than being assumptions.

## Candidate migration

`PHASE_5_RLS_REPLACEMENT_CANDIDATE.sql` contains the first concrete policy replacement candidate.

It intentionally:

- removes the audited broad/open policies;
- preserves customer ownership for bookings;
- gives operational read access according to role/assignment;
- prevents arbitrary client creation of profiles/staff records;
- prevents arbitrary client mutation of booking status history, vitals, assessments, notifications, and audit history;
- leaves privileged booking/fleet/staff/clinical writes for controlled backend operations.

## Important compatibility note

The candidate is **not yet approved for production execution** because the existing React application still contains client-side workflow behavior that must be checked against the new write boundary. In particular, any direct React writes to bookings, status history, vitals, assessments, notifications, or audit logs need to be migrated to trusted workflow operations before those client writes are blocked.

## Pricing

`pricing_settings` was not present in the supplied RLS inventory. Do not add pricing policies until the Phase 7 migration is confirmed as applied.

## Booking trigger

The database has:

- `bookings_updated_at`
- BEFORE UPDATE
- `set_updated_at()`

The RLS migration does not modify this trigger.
