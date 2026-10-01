# Ambulance First — Supabase Connection

## Backend

The Flutter application is configured for the existing Ambulance First Supabase project:

`https://weyftbzqfmusimqznbwr.supabase.co`

The public anon/publishable key can be loaded from the bundled local `.env` file for development, or supplied at runtime with `--dart-define`. The service-role/secret key must never be stored in the Flutter app.

## Run

```bash
flutter pub get
flutter run -d chrome
```

For CI/CD or a machine where `.env` should not be used, inject the public key explicitly:

```bash
flutter run -d chrome --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
```

`--dart-define` takes priority over `.env`.

## Authentication

When `SUPABASE_ANON_KEY` is present:

```text
Supabase Auth
    ↓
profiles
    ↓
role
    ↓
Flutter role routing
```

The profile role is authoritative. The login UI cannot grant itself a role.

## Confirmed backend roles

```text
CUSTOMER
ADMIN
DOCTOR
DRIVER
TEAM_LEAD
CUSTOMER_CARE
```

Admin is implemented as the read-only Flutter Admin workspace in the current Phase 2–3 build.

Doctor is recognized by authentication, but the uploaded project does not yet
contain a Doctor workspace.

EMT is not assumed to be a profile role.

## Existing tables

The application reuses the existing schema:

- ambulances
- audit_logs
- booking_doctor_assessments
- booking_status_history
- booking_vitals
- bookings
- customer_care
- doctors
- drivers
- notifications
- profiles

Do not create duplicate tables.

## Empty data

The current database may have rows only in `profiles`. Other tables can be empty.

An empty result is handled as application state, not as a schema failure.

## Booking persistence boundary

Before implementing inserts/updates for `bookings`, `booking_status_history`,
`booking_vitals`, or `booking_doctor_assessments`, inspect the actual Supabase
columns, constraints and RLS policies. The Flutter models contain richer website
workflow fields than can safely be assumed to match every database column.

Never invent a database column to make an insert compile.

## Security

Never use the Supabase service-role key in Flutter.

Only use the public anon/publishable client key.

## Phase 5 security note

The Flutter client does not attempt to replace production RLS. See
`docs/security/PHASE_5_SECURITY_CONTRACT.md` and the staged SQL files under
`docs/security/` before changing existing policies.
