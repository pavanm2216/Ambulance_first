# Phase 6–8 Runbook

## Step 1 — Validate Phase 4 locally

```bash
flutter pub get
flutter analyze
```

Fix any remaining analyzer errors before enabling database writes.

## Step 2 — Audit current policies

Run:

`docs/PHASE_5_NEXT_ACTION.sql`

Save all result sets and review them against `docs/PHASE_5_POLICY_REVIEW_CHECKLIST.md`. Do not apply the policy replacement template until the output has been reviewed.

## Step 3 — Apply pricing migration

After the Phase 5 role helper functions are confirmed:

`docs/migrations/PHASE_7_PRICING_SETTINGS.sql`

The migration is non-destructive to the existing operational tables.

## Step 4 — Test Admin pricing

Log in with an Admin profile and verify:

- pricing row loads
- Admin can save
- non-Admin cannot save
- refreshed Admin session sees the same values

## Step 5 — Phase 6 privileged staff operations

The secure staff-provisioning Edge Function scaffold is now present at `supabase/functions/admin-provision-staff/`. Deploy/wire it only after the Phase 5 policy inventory is approved and the live audit-log contract is verified. Never put a service-role key in Flutter.

## Step 6 — Phase 8 Doctor workspace

Build the Doctor workspace against the existing resources and verify assignment-scoped RLS before clinical writes.

## Step 7 — Phase 9

Only after the above works, perform the Admin visual parity pass against the Customer design system.
