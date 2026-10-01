# Phase 15 — Driver Eligibility / Duty-State Fix

## Root cause

`StaffStatus.fromString()` did not contain `ON_DUTY`, so an actual database status of `ON_DUTY` silently fell through to `AVAILABLE` in the Admin UI. The registration RPC then correctly rejected the driver because it only accepted `AVAILABLE`.

This made the UI show Marvy as AVAILABLE while Supabase reported `ON_DUTY`.

## Fix

- Added `StaffStatus.onDuty`.
- Admin Fleet registration accepts operational driver states `AVAILABLE` and `ON_DUTY` when the driver has no assigned ambulance and no assigned booking.
- Admin UI now explicitly shows `ON DUTY`.
- Fleet registration also checks `assignedMission` so a driver with an active booking cannot be paired.
- Added a read-only SQL consistency check for existing ECHO-99/ECHO-21 assignment anomalies.

## Existing ECHO-99 issue

The current registration RPC does not assign an ambulance to Vishnu or move an existing ambulance between drivers. If ECHO-99 is currently shown under Vishnu, that relationship came from an earlier database/UI state or older registration logic. Run `PHASE_15_DRIVER_ASSIGNMENT_CONSISTENCY_CHECK.sql` before repairing it.
