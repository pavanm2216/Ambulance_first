# Ambulance First — Phases 7–10 Implementation Status

## Implemented in this package

### Phase 7 — Pricing
- Persistent `pricing_settings` migration already present.
- Admin pricing screen already reads/writes the shared configuration.
- Added controlled quotation preparation RPC that consumes the shared pricing row.

### Phase 8 — Doctor
- Doctor assigned-booking workspace remains connected to real Supabase data.
- Added controlled doctor vitals RPC.
- Existing controlled doctor assessment RPC is retained.
- Clinical writes must be tested with the real DOCTOR account before enabling production RLS replacement.

### Phase 9 — Admin / Team Lead operations
- Added controlled quotation preparation.
- Added customer quotation response.
- Added Team Lead/Admin allocation RPC for existing ambulance/driver/doctor resources.
- No generic fleet/staff delete operation was introduced.
- Staff account provisioning remains an Edge Function deployment task.

### Phase 10 — Shared workflow
The controlled operations now cover the core mutation path:

Customer booking → verification/status transitions → quotation → customer response → allocation → driver status transitions → doctor assessment/vitals → completion.

The notification and booking-status-history schema still needs an exact production write contract before it is enabled. Existing open policies must not be removed until RPC smoke tests pass.

## Remaining deployment gates

1. Apply Phase 7 pricing migration if not already applied.
2. Apply Phase 6 controlled workflow migration.
3. Apply this Phase 7–10 controlled operations migration.
4. Test each RPC with the corresponding real role account.
5. Verify `booking_vitals` insert succeeds.
6. Verify quotation values and shared pricing behavior.
7. Verify allocation against real ambulance/driver/doctor records.
8. Only after successful smoke tests, replace the permissive `*_open` policies with the reviewed RLS migration.
9. Deploy secure staff-provisioning Edge Function.
10. Run Flutter analyze/test/build on a machine with Flutter SDK.

## Explicit non-claims

- No production Supabase migration was executed by this packaging environment.
- No Flutter runtime build was executed here because the Flutter SDK is unavailable.
- No EMT portal/role is invented; `assigned_emt_id` remains supported only where an existing `profiles` row with role `EMT` exists.
