# Admin Feature Parity — Flutter Implementation

## Purpose

This update brings the Flutter Admin workspace closer to the existing senior-built React Admin feature set without copying its known prototype weaknesses.

## Implemented in Flutter

- Executive Admin dashboard using canonical Supabase records.
- Booking registry search across booking/patient/customer/route fields.
- Booking status and service-category filters.
- Booking assignment and quotation visibility.
- Booking detail modal.
- Fleet metrics, search, category/status filters and capability presentation.
- Fleet maintenance/availability control through a controlled Admin RPC.
- Staff directory tabs for Driver, Doctor, Customer Care and Team Lead.
- Staff search and server-side Edge Function provisioning entry point.
- Quotation metrics, search and itemized quotation breakdown.
- Reports with 7D/30D/90D/YTD date scoping and service mix.
- Audit search and event detail view using canonical audit fields.
- Persistent pricing editor remains connected to `pricing_settings`.
- Shared premium healthcare Admin visual language and honest loading/empty/error states.

## Intentionally not copied from React

- Browser localStorage as operational truth.
- Hard-coded KPI values.
- Unsupported cryptographic audit claims.
- Client-side privileged Auth creation.
- An invented EMT authentication role.

## Backend deployment gate

The new fleet status UI calls `admin_update_ambulance_status`. Deploy `docs/migrations/PHASE_ADMIN_FLEET_CONTROLS.sql` only after the project's existing RLS review has been completed.

The staff screen calls the existing `admin-provision-staff` Edge Function. That function must be deployed with server-side secrets before staff invitations work.

## Remaining production gates

- Deploy/test controlled Admin fleet RPC.
- Deploy/test staff provisioning Edge Function.
- Validate final role-aware RLS and replace permissive policies only after controlled writes work.
- Run `flutter analyze`, `flutter test`, and `flutter build web --release` in a Flutter-enabled environment.
- Perform real end-to-end Admin + operational workflow testing against the target Supabase project.
