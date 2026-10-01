# AeroMed / Ambulance First — Final Release Status

## Implemented in this package

1. Customer booking persistence is connected to `create_customer_booking` when Supabase is configured.
2. Customer booking payload uses the canonical `Booking` model and converts UI date/time labels to database-compatible values.
3. Customer booking identity uses the authenticated user ID locally; the database RPC remains authoritative for `customer_id`.
4. Customer Care operational cases are hydrated from the canonical `SharedBookingStore` in Supabase mode instead of demo cases.
5. Customer Care verification/handoff has a dedicated backend RPC contract and client integration.
6. Team Lead quotation sending uses `prepare_booking_quotation` in Supabase mode.
7. Existing Customer quotation acceptance/rejection, Team Lead allocation, Driver trip workflow, and Driver location implementations are preserved.
8. The old Admin Fleet Registration `StaffStatus` / `AdminStaff` blocker is not reintroduced; the current screen uses the existing Admin driver/resource model.
9. A Phase 15 Customer Care SQL migration has been added:
   `docs/migrations/PHASE_15_CUSTOMER_CARE_BACKEND_INTEGRATION.sql`
10. Phase 15 implementation notes have been added:
   `docs/PHASE_15_IMPLEMENTATION_STATUS.md`

## Release gates that require a Flutter/Supabase-enabled environment

- `flutter analyze`
- `flutter test`
- `flutter build web --release`
- Real Supabase migration execution and RLS verification
- Full multi-role E2E smoke test

The packaging environment used for this ZIP does not contain the Flutter SDK, so no Flutter command is claimed as executed here.

## Known deliberate limitations

- Driver GPS is foreground-oriented; production background tracking requires native mobile background-location support.
- Route distance is not claimed to be a production road-routing calculation; the existing project documents a future Google Routes/Mapbox integration.
- Doctor clinical writes remain gated behind backend/RLS verification.
- Demo data remains available only as the explicit non-Supabase development fallback.

## Required Supabase action before production smoke testing

Apply:

`docs/migrations/PHASE_15_CUSTOMER_CARE_BACKEND_INTEGRATION.sql`

Then run the project's existing controlled workflow/pricing migrations in their documented order if the target database does not already contain them.
