# AeroMed Unified Flutter App

This build combines the three supplied Flutter role applications into one
AeroMed domain with a shared Customer-style authentication and registration
screen.

## Roles

- **Customer** — customer booking, active trip, booking history, quotations,
  invoices and public services.
- **Customer Care** — inbound booking queue, triage, verification, handover
  and active-trip operations.
- **Driver** — driver dashboard, assignments, active trip, patient/crew details
  and trip status progression.
- **Team Lead** — operational dashboard, allocation, quotations, fleet/crew and
  trip operations.
- **Doctor** — recognized by backend authentication, but a Doctor workspace is
  not present in the uploaded Flutter project yet.
- **Admin** — recognized by backend authentication only; Admin Flutter UI is
  intentionally out of scope.

## Authentication

There is one shared `WelcomeScreen` for all roles. Demo credentials are resolved
by email/ID and password, so the correct role opens automatically.

| Role | Email / ID | Password |
|---|---|---|
| Customer | `customer@aeromed.com` | `Customer@123` |
| Customer Care | `care@aeromed.com` | `Care@123` |
| Driver | `driver@aeromed.com` | `Driver@123` |

Legacy demo credentials are also accepted for compatibility with the supplied
role projects: `customer@aeromed.org` / `Customer@123`, `CC001` / `CC@12345`,
and `driver@aeromed.org` / `DRIVER@123`.

Registration remains available from the same screen. New accounts are local
demo accounts until the FastAPI authentication service is connected.

## Role workflow

The three supplied datasets use the same booking IDs where applicable. For
example, `AMB-2026-1048` appears in the Customer and Driver workflows and is
also represented in the Customer Care dataset. The role shells remain
separate UI surfaces while living inside the same Flutter application.

## Project entry point

```text
lib/main.dart
```

The original role screens, models, services, theme and widgets are retained
under `lib/` so the existing UI/UX can continue to be refined independently.

## Run

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter build web
```


## Supabase connection

This version is wired to the existing Ambulance First Supabase project.

The project URL is configured as:

```text
https://weyftbzqfmusimqznbwr.supabase.co
```

The public anon/publishable key is intentionally **not committed to source code**.
Run the application with the public key supplied at build/run time:

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
```

The app now uses Supabase Auth when the key is configured. Authentication is
followed by a lookup in the existing `profiles` table, and the role returned by
the backend is authoritative.

Confirmed backend profile roles:

```text
CUSTOMER
ADMIN
DOCTOR
DRIVER
TEAM_LEAD
CUSTOMER_CARE
```

`ADMIN` is recognized by the Flutter authentication layer but intentionally
does **not** open an Admin portal. The user is shown an explicit unsupported-role
screen instead of being silently routed to Customer.

`DOCTOR` is also recognized. The uploaded project does not currently contain a
Doctor workspace, so Doctor users are not incorrectly routed to Customer.

`EMT` is not treated as a `profiles.role` because it is not present in the
confirmed backend role set.

### Empty Supabase tables

The following tables already exist and may currently contain zero rows:

```text
ambulances
drivers
doctors
customer_care
bookings
booking_status_history
booking_vitals
booking_doctor_assessments
notifications
audit_logs
```

Zero rows are treated as legitimate empty-data states. The Flutter application
must not create fake production records simply because a resource table is
empty.

### Important integration boundary

This update establishes the real Supabase connection, authentication/profile
role resolution, and existing resource-table adapters. Booking/quotation/
clinical persistence must be mapped to the actual columns and constraints of
the existing `bookings` and related tables before writing production records.
Do not invent columns or duplicate tables to make those workflows work.
