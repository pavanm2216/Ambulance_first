# Ambulance First — Phase Status

## Completed / prepared
- Supabase connection foundation
- Customer workflow/UI baseline
- Admin read-only workspace
- Doctor read-only workspace
- Supabase schema/role/RLS audit
- Verified identity foreign keys
- RLS replacement candidate
- Phase 6 controlled booking/status/audit RPCs
- Phase 7 persistent pricing migration + Admin pricing UI
- Phase 7 quotation preparation RPC
- Phase 8 Doctor assessment RPC + vitals RPC
- Phase 9 allocation RPC
- Phase 10 quotation response + shared mutation repository

## Current deployment gate
The project now has a controlled server-side mutation layer for the core operational path. Production activation still requires Supabase SQL deployment and smoke testing.

## Remaining work
- Deploy and smoke-test migrations/RPCs
- Verify exact booking_status_history write contract
- Add notification generation/read acknowledgement contract
- Deploy secure staff provisioning Edge Function
- Add Admin fleet/staff UI mutation flows after backend verification
- Wire remaining role screens away from local-only mutations
- Replace permissive `*_open` policies only after RPC smoke tests
- Run Flutter analyze/test/build on a machine with Flutter SDK
- Final end-to-end QA and release preparation
