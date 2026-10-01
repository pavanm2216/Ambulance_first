# Phase 15 — Real Customer Pickup → Destination Road Route

## Problem

The Customer wizard previously stored the pickup GPS but did not geocode the destination or calculate a road route. `estimated_distance_km` therefore remained at its database default of `0`.

## New implementation

```text
Pickup address / Use Location
        ↓
Supabase Edge Function: calculate-route
        ↓
Geocode any missing coordinates
        ↓
OSRM driving route
        ↓
road distance + travel duration
        ↓
Customer booking payload
        ↓
public.bookings
```

The existing booking schema already has the required route columns: `pickup_lat`, `pickup_lng`, `destination_lat`, `destination_lng`, `estimated_distance_km`, `estimated_duration_mins`, `route_distance_meters`, `route_duration_seconds`, `route_provider`, and `route_calculated_at`.

## Database RPC update

After applying the earlier Customer booking migration, run:

```text
docs/migrations/PHASE_15_ENABLE_ROUTE_METADATA_ON_CUSTOMER_BOOKING.sql
```

This replaces the Customer booking RPC so the calculated route metadata is persisted instead of stripped.

## Deploy

From the project root, linked to the existing Supabase project:

```powershell
supabase functions deploy calculate-route
```

The function uses the authenticated caller's JWT and does not expose a service-role key to Flutter.

## Customer behavior

When leaving Step 4, the app now calculates the actual road route. If the route cannot be calculated, the wizard remains on Step 4 and shows the error instead of saving a fake `0 km` value.

Review shows: `Road route: X.X km • ETA Y min`.

The Customer booking details dialog no longer substitutes a fake `25 mins` duration.

## Provider

The current function uses OSRM/OSM. OSRM's route service returns the fastest driving route between the supplied coordinates, including distance and duration. This is appropriate for the current integration/QA stage. For production billing, use a company-managed routing provider or self-hosted routing service and retain the calculated distance as the billing snapshot.

## Important distinction

Booking route distance is: `Pickup → Destination Hospital`.

Live dispatch distance remains separate: `Driver current location → Pickup`.
