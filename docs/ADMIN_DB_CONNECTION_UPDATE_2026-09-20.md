# Admin Portal — Supabase Connection Update

## What changed

The existing Admin UI has been retained. The AdminStore no longer seeds operational demo bookings, fleet units, staff, audit records, or Canadian pricing as the runtime source.

On AdminShell startup it now loads:

- `bookings`
- `ambulances`
- `drivers`
- `doctors`
- `customer_care`
- `profiles`
- `audit_logs`
- `pricing_settings`

through the existing `AdminRepository` and maps the returned records into the current Admin UI models.

## Connected Admin operations

- Fleet status changes use the existing `admin_update_ambulance_status` RPC.
- Staff provisioning uses the existing `admin-provision-staff` Edge Function.
- Pricing save uses the existing `pricing_settings` table.
- Header and page refresh controls reload the Admin data from Supabase.

## UI/rendering fixes

- Admin bottom navigation items now receive equal width and truncate labels safely instead of colliding on narrow screens.
- Tooltips expose the full bottom-navigation label.
- Admin header no longer displays fabricated CAD version/readiness numbers.
- Dashboard triage ticker is derived from live active bookings instead of seeded incident messages.
- Dashboard comparison percentage was removed because no historical comparison query exists yet.
- Audit screen wording no longer claims an unsupported immutable/cryptographic chain.
- Currency display was removed from the hard-coded Canadian demo format and now uses the app's INR presentation until a currency value is explicitly provided by the persisted pricing configuration.
- Admin data loading now exposes a compact loading/error state with retry.

## Intentionally not implemented as direct client writes

Ambulance registration still requires the verified database write contract for the existing `ambulances` schema. The Flutter client does not invent columns or perform an unverified insert.

The Admin booking-create button is intentionally not wired to a new client-side insert. Booking creation must use the project's controlled booking RPC and workflow contract.

EMT is not provisioned through Auth because the project's confirmed authenticated profile roles do not include EMT.

## Runtime requirement

The bundled `.env` contains only the public Supabase publishable/anon key. The service-role key must remain in Supabase Edge Function secrets and must never be added to Flutter.

For live Admin data, the authenticated account must have `profiles.role = ADMIN` and the database RLS policies/RPCs/Edge Function referenced by this project must be deployed and authorized for that account.
