# Phase 5 — Production RLS Review Gate

Updated: 2026-09-19

This gate must be completed before enabling operational writes in Flutter.

## What is already implemented

- Role helper SQL is prepared in `docs/security/PHASE_5_ROLE_HELPERS.sql`.
- Policy replacement template is prepared in `docs/security/PHASE_5_POLICY_REPLACEMENT_TEMPLATE.sql`.
- Flutter Admin/Doctor write paths remain gated.
- No service-role secret is present in the Flutter project.
- Staff provisioning Edge Function scaffold is present under `supabase/functions/admin-provision-staff/` but is not wired/deployed.

## Required live Supabase evidence

Run the read-only audit script:

`docs/PHASE_5_NEXT_ACTION.sql`

The result must be reviewed for:

1. Every existing policy on audited tables.
2. Every `*_open`/publicly permissive policy.
3. Foreign keys used to establish ownership/assignment predicates.
4. Exact booking assignment columns.
5. Any triggers/functions that already write history, notifications, or audit logs.
6. Any constraints that make an apparently valid Flutter write fail.

## Tables in scope

- profiles
- bookings
- ambulances
- drivers
- doctors
- customer_care
- booking_status_history
- booking_vitals
- booking_doctor_assessments
- notifications
- audit_logs
- pricing_settings

## Approval rules

- Do not simply add a restrictive policy while a permissive `ALL` policy remains; PostgreSQL permissive policies are combined with OR semantics.
- Do not grant clients direct audit-history mutation.
- Do not infer a role/resource relationship from the UI alone.
- Do not add an EMT profile role without backend evidence.
- Do not put a service-role key in Flutter.

## After the audit

The next implementation sequence is:

1. Replace only audited permissive policies with role-aware policies.
2. Apply and test `pricing_settings` migration/RLS.
3. Deploy and test the staff provisioning Edge Function.
4. Enable Doctor clinical writes.
5. Enable Admin fleet/staff controlled writes.
6. Move booking/status/notification/audit transitions from local-only stores to the verified shared Supabase workflow.
7. Run local Flutter analyze/test/build on the target development machine.

## Current blocking items

The implementation cannot honestly mark Phase 5 complete until the live policy/constraint output is supplied and reviewed. This is a backend verification dependency, not a Flutter UI dependency.
