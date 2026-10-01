# Ambulance First — Admin Role Implementation Plan

Status: Phase 0 + Phase 1 completed. Phase 2 is blocked pending authoritative Supabase schema/RLS inspection.

## Goal
Add the ADMIN portal to the current Flutter application without replacing the existing Customer, Customer Care, Team Lead, Driver, authentication, Supabase connectivity, or shared booking workflow.

## Source of truth hierarchy
1. Existing Supabase schema, constraints, RLS policies and persisted data.
2. Existing Flutter/Supabase-connected project.
3. React Admin portal as functional/UI reference.
4. React local/demo state only as reference, never as production backend truth.

## React Admin scope captured
- Master Operations dashboard
- All Bookings registry
- Ambulance Fleet
- Medical Staff & Drivers
- Budgets & Quotations
- Analytics & Reports
- Audit Trail & Compliance
- Pricing & System Settings
- Public Website View/navigation convenience

## Known React/backend mismatches to resolve before implementation
- React uses local state/localStorage for much of the operational workflow.
- React pricing settings are UI state; persistence is not established.
- React reports contain hardcoded/demo benchmark values; Flutter must calculate production metrics from real data.
- React labels audit capability as immutable/cryptographic without establishing a cryptographic backend chain.
- React has an EMT role/profile path, but the current confirmed Flutter/Supabase role set does not establish EMT as a valid profiles.role.
- React staff creation uses client-side Supabase Auth signup patterns that must not be copied into Flutter as a privileged-account creation mechanism.

## Phase 0 — Baseline protection
- Preserve the current Supabase-connected ZIP as the baseline.
- Work from a separate Admin development copy.
- Do not change existing role screens while Admin is being designed.
- Do not add duplicate database tables.
- Do not add service-role credentials to Flutter.

## Phase 1 — Admin requirements freeze
### Navigation
- Dashboard
- All Bookings
- Ambulance Fleet
- Medical Staff & Drivers
- Budgets & Quotations
- Analytics & Reports
- Audit Trail & Compliance
- Pricing & System Settings
- Optional public website navigation

### Booking capabilities
- Read all bookings permitted by RLS.
- Search by booking ID, patient, customer, pickup and destination.
- Filter by booking status and service category.
- Open shared booking detail view.
- Open booking audit trail.

### Fleet capabilities
- List/search/filter ambulances.
- View capabilities and operational status.
- Add/update/status changes only after schema/RLS verification.
- Preserve compatibility with Team Lead allocation.

### Staff capabilities
- Drivers
- Doctors
- Customer Care
- Team Leads
- EMT only if backend schema/role is authoritatively confirmed.
- View/edit/suspend/restore/delete only after backend authorization is verified.
- Staff account creation must use a secure backend mechanism; never a service-role key in Flutter.

### Quotations
- Read quotations from the same booking/quotation source used by Team Lead and Customer.
- Do not create a second quotation model or duplicate quotation store.

### Reports
- Calculate from real persisted data.
- No hardcoded demo percentages/timings/revenue.
- Use status history/timestamps where available.

### Audit
- Read audit logs.
- Filter by actor/action/booking where supported by schema.
- Privileged mutations should be audited by a trusted backend path where possible.

### Pricing
- UI can be designed first.
- Persistence is blocked until a real pricing configuration contract is verified.
- Team Lead quotation calculation must consume the same persisted configuration.

## Phase 2 — Supabase contract audit (BLOCKING GATE)
Inspect:
- profiles
- ambulances
- drivers
- doctors
- customer_care
- bookings
- booking_status_history
- booking_vitals
- booking_doctor_assessments
- notifications
- audit_logs

For each table verify:
- columns and data types
- primary keys
- foreign keys
- nullable/default values
- unique constraints
- check constraints/enums
- created_at/updated_at behavior
- RLS enabled/disabled
- SELECT/INSERT/UPDATE/DELETE policies
- role checks
- ownership checks

Do not implement a write until the exact target columns and authorization path are known.

## Phase 3 — Admin authentication/routing
Replace the current ADMIN unsupported-role screen with AdminShell.
Keep unknown-role blocking behavior.
Keep non-admin routing unchanged.

## Phase 4 — Admin shell
Add:
lib/roles/admin/screens/admin_shell.dart
lib/roles/admin/screens/admin_dashboard_screen.dart
lib/roles/admin/screens/admin_bookings_screen.dart
lib/roles/admin/screens/admin_fleet_screen.dart
lib/roles/admin/screens/admin_staff_screen.dart
lib/roles/admin/screens/admin_quotations_screen.dart
lib/roles/admin/screens/admin_reports_screen.dart
lib/roles/admin/screens/admin_audit_screen.dart
lib/roles/admin/screens/admin_pricing_screen.dart

Shared backend access remains in core/services.

## Phase 5 — Read-only Admin
Implement in this order:
1. Dashboard
2. Bookings
3. Fleet
4. Staff
5. Quotations
6. Audit
7. Reports

## Phase 6 — Fleet management
Implement only against verified ambulances schema/RLS.

## Phase 7 — Staff management
Implement secure profile/resource updates and privileged account creation.

## Phase 8 — Quotations
Expose the same quotation state used by Team Lead/Customer.

## Phase 9 — Persistent pricing
Only after pricing storage is verified/approved.

## Phase 10 — Real reports
Use persisted operational data and historical timestamps.

## Phase 11 — Audit/compliance
Connect to real audit_logs and trusted mutation auditing.

## Phase 12 — Regression gate
Verify all role workflows after every Admin milestone:
- Customer
- Customer Care
- Team Lead
- Driver
- Admin

## Non-negotiable safety rules
- Never route ADMIN to Customer.
- Never use a Supabase service-role key in Flutter.
- Never invent database columns.
- Never create duplicate resource tables to compensate for schema uncertainty.
- Never replace shared Booking with an Admin-specific booking model.
- Never overwrite working role screens merely to simplify Admin implementation.
- Never represent empty backend tables with fake production data.
- Never claim persistence when a value only lives in widget/local state.
