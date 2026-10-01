# Phase 15 — Doctor Availability Fix

## Changes

1. Team Lead allocation now labels the Admin-paired driver as **PRIMARY DRIVER** instead of the ambiguous **PAIRED TO AMBULANCE** label. The pairing is intentional and comes from `drivers.assigned_ambulance_number`.
2. Added `docs/migrations/PHASE_15_DOCTOR_AVAILABILITY_CLEANUP.sql`. It diagnoses a doctor such as Harini and the booking holding the assignment before any repair.
3. The SQL does **not** automatically make an actively assigned doctor available. A doctor attached to an active booking must remain unavailable. If the assignment is stale (missing booking or terminal booking), the commented repair can safely clear it.

## Important

The live `allocate_booking()` RPC already protects the Admin-defined primary driver pairing. No replacement allocation RPC is added by this change.

## QA sequence

1. Run the doctor diagnostic query.
2. If Harini is attached to an active booking, do not clear her assignment.
3. If the booking is missing/terminal and the assignment is stale, use the documented repair template.
4. Refresh Team Lead allocation.
5. Harini should then appear as AVAILABLE.
