# Team Lead EMT Requirement Fix

The database uses `bookings.req_emt` and `bookings.req_doctor` as the authoritative clinical requirement flags.

The Flutter booking mapper previously looked only for `emt_required` / `doctor_required`. As a result, a booking with `req_emt = true` could appear in the Team Lead allocation modal as EMT Optional even though the backend correctly rejected allocation without an EMT.

The mapper now accepts both naming conventions and prioritizes the existing `req_*` database columns as fallbacks.

For booking `BK-1790061610278`, the Team Lead allocation workspace should therefore show:

- `Assign EMT / Paramedic (Required)` when `req_emt = true`
- `Assign Doctor / Physician (Required)` when `req_doctor = true`

The Confirm Resource Allocation action remains protected by both Flutter validation and the Supabase `allocate_booking()` RPC.
