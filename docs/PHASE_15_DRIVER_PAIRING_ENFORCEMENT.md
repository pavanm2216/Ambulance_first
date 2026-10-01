# Phase 15 — Primary Driver Pairing Enforcement

## Root cause found

Admin fleet registration is intended to pair an existing driver to an ambulance through `drivers.assigned_ambulance_number`. The previous Team Lead `allocate_booking` RPC did not enforce that pairing. It accepted any eligible driver and then overwrote the driver's `assigned_ambulance_number` with the selected ambulance vehicle number.

That allowed an ambulance registered with one driver to later be allocated to another driver. The observed ECHO-99 case is an example: the booking row was assigned to `vishn vardhan` even though the Admin workflow had selected Marvy.

## Fix

1. Added `docs/migrations/PHASE_15_ENFORCE_PRIMARY_DRIVER_PAIRING.sql`.
2. The authoritative allocation RPC now:
   - locks the ambulance and booking;
   - finds the primary driver paired through `drivers.assigned_ambulance_number`;
   - rejects any different driver when a primary pairing exists;
   - accepts `AVAILABLE` and `ON_DUTY` drivers when they have no active booking;
   - rejects drivers paired to a different ambulance;
   - preserves the ambulance-to-driver pairing during allocation;
   - records the enforced pairing in the audit event.
3. Flutter Team Lead driver selection now treats `ON_DUTY` as operationally selectable when unassigned.
4. When an ambulance has a primary paired driver, the allocation UI only permits that paired driver.

## Required deployment action

Run the new migration in Supabase SQL Editor before testing the Team Lead allocation workflow. Do not manually edit ECHO-99 first; validate the migration and then repair any stale data separately if needed.
