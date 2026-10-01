# Admin Fleet Registration — Available Driver Selection Fix

## Problem

Step 4 of Admin Fleet Registration displayed `No unallocated drivers are available` even when the Admin Staff screen showed drivers such as Marvy, Teja, and Rajesh as `AVAILABLE` and without an assigned ambulance.

## Root cause

`AdminStaff.status` is the canonical `StaffStatus` enum. The previous fleet registration filter converted the enum with `toString()` and compared it to the string `AVAILABLE`.

Dart formats the enum as `StaffStatus.available`, so the comparison always failed.

## Fix

`admin_fleet_register_screen.dart` now:

- imports the canonical `AdminStaff` / `StaffStatus` model;
- filters `role == DRIVER`;
- requires `status == StaffStatus.available`;
- requires `assignedVehicle` / `assigned_ambulance_number` to be empty;
- displays the canonical `driver.status.label` (`AVAILABLE`);
- preserves the selected driver while still eligible;
- clears a stale selection if the driver becomes assigned/unavailable.

## Expected result

With the same data shown by the Admin Staff screen:

- Marvy — AVAILABLE, no unit → appears in the dropdown
- Teja — AVAILABLE, no unit → appears in the dropdown
- Rajesh Kumar — AVAILABLE, no unit → appears in the dropdown
- Vishnu Vardhan — ASSIGNED, Unit NED-ICU-99 → does not appear

No database migration is required for this UI/model-filter fix, provided the existing `drivers` table/RLS already allows the Admin Staff screen to read these driver rows.

## Verification

The packaging environment does not have the Flutter SDK, so `flutter analyze` could not be executed here. Run `flutter analyze` locally after extracting the ZIP.
