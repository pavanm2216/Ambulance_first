# Phase 6 — Controlled Workflow Write Layer

## Implemented preparation

This phase adds a server-side write boundary for the most important workflow mutations:

- Customer booking creation
- Role-scoped booking status transitions
- Server-generated audit entries
- Doctor assessment submission

The Flutter client calls RPCs through the normal authenticated Supabase session. No service-role key is placed in Flutter.

## Intentionally deferred

- quotation calculation/persistence
- Team Lead resource allocation
- ambulance CRUD
- staff account creation deployment
- vitals write RPC (the exact complete `booking_vitals` schema was not included in the returned audit output)
- status-history insertion (the returned audit output did not include the complete status-history column list)

Those operations should be added after their exact table contracts are confirmed.

## Deployment order

1. Back up the database.
2. Apply the Phase 7 pricing migration if `pricing_settings` does not yet exist.
3. Apply this Phase 6 RPC migration.
4. Test each RPC with representative role accounts.
5. Only then apply the Phase 5 RLS replacement candidate.
6. Remove direct client-side write paths once RPC calls are wired into the role UIs.
