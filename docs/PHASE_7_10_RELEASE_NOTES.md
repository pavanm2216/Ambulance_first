# Phase 7–10 Release Notes

This package moves Ambulance First from read-only/partially local workflows toward controlled Supabase-backed operations.

## Main additions
- Shared pricing-backed quotation calculation.
- Customer quotation acceptance/rejection RPC.
- Team Lead/Admin resource allocation RPC.
- Doctor vitals RPC.
- Existing Doctor assessment RPC retained.
- Flutter repository methods for all new RPCs.
- Phase status and deployment runbook updated.

## Safety
Do not expose a Supabase service-role key in Flutter.
Do not remove `*_open` policies until the controlled RPC smoke tests pass.
Do not claim production persistence until the SQL migrations have been executed successfully in Supabase.
