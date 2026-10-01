# Phase 2.5 — Workflow / RLS Compatibility Audit

## Scope

This phase inspects the current Flutter Supabase access layer before changing
production RLS policies.

## Current Flutter Supabase operations

The connected Flutter baseline currently performs Supabase reads through:

- `supabase_booking_repository.dart` → `bookings`
- `supabase_resource_repository.dart` → `drivers`, `ambulances`, `doctors`, `customer_care`
- `supabase_auth_repository.dart` → `profiles`

The current Admin implementation added in Phase 3 is read-only and uses:

- `bookings`
- `ambulances`
- `drivers`
- `doctors`
- `customer_care`
- `profiles`
- `audit_logs`

The existing operational workflow services are still substantially local/in-memory;
they do not currently issue Supabase INSERT/UPDATE/DELETE operations for booking
transitions, allocation, notifications, or audit entries.

## Consequence for RLS migration

The database currently has `public` + `ALL` policies on several operational tables.
Those policies must eventually be replaced by role-aware policies, but doing so
immediately could break the React/website workflows if those workflows still rely
on direct client-side writes.

Therefore this phase does **not** change production RLS.

## Safe Admin implementation boundary

Admin UI is initially read-only. It does not expose:

- fleet INSERT/UPDATE/DELETE
- staff account creation
- staff DELETE
- arbitrary booking UPDATE
- quotation mutation
- audit-log mutation
- pricing persistence

These actions require a verified role-aware backend policy or secure backend
operation first.

## Required security direction

Target authorization model:

`auth.uid()` → `profiles.id` → `profiles.role`

Admin-only operations should be guarded by `profiles.role = 'ADMIN'`.

Audit logs should be readable by authorized operational/admin roles and should not
be freely writable or deletable by arbitrary public clients.

## EMT

The booking schema contains `assigned_emt_id → profiles.id`, but the audited
profile role values did not confirm EMT as an active profile role. No EMT table is
introduced and no EMT role is invented in Flutter.

## Pricing

No persistent pricing/settings table was found in the audited schema. The Admin
Pricing screen therefore remains an explicit placeholder rather than pretending
that local UI state is persisted.
