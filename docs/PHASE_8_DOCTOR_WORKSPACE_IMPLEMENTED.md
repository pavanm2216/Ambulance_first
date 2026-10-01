# Phase 8 — Doctor Workspace Implementation

Status: **implemented as read-only clinical workspace**.

## Implemented

- Added `DoctorRepository` using the existing `doctors`, `bookings`, `booking_vitals`, and `booking_doctor_assessments` tables.
- Added Doctor role routing in `lib/main.dart`.
- Added Doctor workspace with:
  - clinical overview
  - assigned patient list
  - patient demographics and route
  - latest vitals
  - assessment history
  - explicit empty/error/loading states
- Existing backend resources are reused; no `emts` table or new Doctor table is created.

## Identity bridge

The audited `doctors` schema does not contain a confirmed `profile_id`/`user_id` column. The workspace therefore locates the Doctor resource using the authenticated profile email against `doctors.email`.

This is an integration bridge, not a claim that the database has a formal foreign-key identity relationship.

## Clinical writes

Clinical submission is intentionally disabled until Phase 5 role-aware RLS is verified. The UI does not insert or update:

- `booking_vitals`
- `booking_doctor_assessments`
- `bookings`
- `audit_logs`

This prevents the Flutter client from bypassing an unverified clinical authorization boundary.

## Required future write policy

A Doctor may read/write only the clinical records for bookings where the authenticated Doctor is the assigned Doctor. The final policy must resolve:

`auth.uid() -> profiles.id -> doctor resource identity -> bookings.assigned_doctor_id`

without relying on a client-supplied doctor ID as an authorization decision.
