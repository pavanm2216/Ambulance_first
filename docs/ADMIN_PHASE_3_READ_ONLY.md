# Admin Phase 3 — Read-only workspace

The ADMIN route now opens a dedicated `AdminShell` instead of `UnsupportedRoleScreen`.

Implemented modules:

1. Master Operations dashboard
2. All Bookings
3. Ambulance Fleet
4. Medical Staff & Drivers
5. Budgets & Quotations
6. Analytics & Reports
7. Audit Trail & Compliance
8. Pricing & System Settings

## Data source

All Admin read views use the existing Supabase tables. No duplicate Admin tables
or Admin-specific Booking model were created.

## Important limitations

- Fleet/staff/booking CRUD is intentionally not exposed yet.
- Audit logs are read-only in the Admin UI.
- Pricing is not persisted because no pricing table exists in the audited schema.
- Empty backend tables display honest empty states instead of demo records.

## Verification note

The current execution environment does not contain the Flutter CLI, so `flutter
analyze`, `flutter test`, and `flutter run` were not executed here. The ZIP should
be verified locally on the development machine with those commands before being
used as a production build.
