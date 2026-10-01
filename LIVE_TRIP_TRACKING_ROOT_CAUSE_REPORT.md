# Live Trip Tracking — Root-Cause Report and Patch Notes

## Scope and verification boundary

This report is based on static inspection of the supplied project archive. No live Supabase connection or database schema snapshot was supplied, and Flutter/Dart CLI tools are not installed in this execution environment. Therefore database migrations, RLS, realtime delivery, device GPS, and full app compilation could not be exercised here. Do not treat this patch as a verified production deployment.

## Confirmed code-level defects

1. **Customer active-trip list excludes the accepted-but-not-yet-en-route state.** `Booking.isActive` omitted `CUSTOMER_ACCEPTED`, so a trip can disappear from Active Mission Tracking during the interval after acceptance and before driver movement. Added this state to the active list.
2. **Driver GPS is not attached to a booking before `PICKUP_STARTED`.** `DriverBooking.isActive` previously omitted `ASSIGNED` and `DRIVER_ASSIGNED`. DriverShell only publishes booking-scoped GPS when the active booking passes that predicate. Added both states so telemetry can be associated with the assigned trip from dispatch/assignment onward.
3. **Same-location pickup lacked a shared arrival-threshold helper.** Added `RouteTelemetryService.withinArrivalThreshold` (default 150 m) and use it in the customer tracking panel to show `AT PICKUP LOCATION` / `Arrived at pickup · Distance: 0 km` for overlapping/nearby driver and pickup coordinates.
4. **Raw backend exceptions were surfaced to drivers.** Driver GPS/action snackbars now use actionable generic copy while diagnostic details remain in debug logging.

## Canonical identity/data contract found in the project

- Authenticated driver identity: `auth.uid()` / `drivers.profile_id`.
- Canonical driver resource ID: `drivers.id`.
- Booking/trip ID: `bookings.id` (text identifier in the RPC contracts).
- Assignment link: `bookings.assigned_driver_id = drivers.id`.
- Canonical persisted location in the included safe migration: `bookings.geo_lat`, `geo_lng`, `geo_speed_kmh`, `geo_heading`, `geo_last_ping`; optional history table: `driver_location_pings`.
- Ambulance identity is the assigned ambulance resource ID, distinct from display vehicle number.

## SQL / migration findings

The archive already contains `docs/migrations/FIX_DRIVER_LIVE_TRACKING_SCHEMA_SAFE.sql`. It replaces the driver RPCs without assuming `drivers.current_location`, `drivers.total_trips`, `drivers.assigned_booking_id`, or `drivers.assigned_ambulance_number` exist, and uses the canonical driver/booking relationship. The migration explicitly requires booking `geo_*` and trip timestamp columns. Apply it **after** the controlled workflow, Team Lead live operations, and `FIX_DRIVER_PORTAL_CANONICAL_ID_CONTRACT.sql`, as its header specifies. Older SQL files still contain legacy `current_location` / `total_trips` references; do not apply an older overlapping driver RPC migration after the safe migration.

## Remaining work that requires database/environment verification

- Confirm `get_customer_bookings` returns `assigned_driver_id`, `assigned_ambulance_id`, `geo_lat`, `geo_lng`, `geo_speed_kmh`, `geo_heading`, `geo_last_ping`, and the canonical booking ID. The Dart mapper reads these values when present, but the SQL definition of the customer feed is not included in a reliable schema snapshot.
- Verify RLS and realtime publication for customer-owned active booking telemetry and authorized dispatch/team-lead access. The safe migration does not establish the full policy/publication contract.
- Current customer tracking view is a **custom-painted schematic**, not a geographic basemap or road-routing map. This patch does not claim otherwise. A production map requires an approved tile/routing provider, attribution, route API configuration, and integration tests.
- Verify ETA/distance are based on the current leg and route provider. Current fallback calculations are not a substitute for a road route.
- Run SQL smoke tests and Flutter tests on the target environment, including actual Supabase schema and device permission/background behavior.

## Changed files

- `lib/core/models/driver_models.dart` — active trip includes assigned states.
- `lib/core/models/booking.dart` — active customer booking includes `CUSTOMER_ACCEPTED`.
- `lib/core/services/route_telemetry_service.dart` — shared arrival-radius helper.
- `lib/roles/customer/screens/customer_active_trip_screen.dart` — pickup phase includes accepted state and same-location arrival messaging.
- `lib/features/driver/presentation/shell/driver_shell.dart` — user-safe GPS/action error copy.
- `test/route_telemetry_service_test.dart` — same-point/inside-radius/outside-radius tests.

## Verification status

- Static edits applied: yes.
- Automated Flutter tests: **not run** (Flutter/Dart CLI unavailable).
- SQL migration applied: **not run** (no connected Supabase environment).
- End-to-end GPS/realtime/map acceptance: **not verified**.
