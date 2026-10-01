# Phase 15 — Real Route Deployment Runbook

## 1. Apply the booking RPC migration

In Supabase SQL Editor run:

```text
docs/migrations/PHASE_15_ENABLE_ROUTE_METADATA_ON_CUSTOMER_BOOKING.sql
```

This keeps the existing NOT NULL booking initialization and allows the calculated route metadata to be persisted.

## 2. Deploy the route Edge Function

From the Flutter project root:

```powershell
supabase functions deploy calculate-route
```

If the CLI is not linked yet:

```powershell
supabase login
supabase link --project-ref weyftbzqfmusimqznbwr
supabase functions deploy calculate-route
```

Do not put a service-role key in Flutter or `.env`.

## 3. Run the app

```powershell
flutter pub get
flutter analyze
flutter run -d chrome
```

## 4. Test Customer booking

```text
Customer
 ↓
Book New Ambulance
 ↓
Step 4 — Route & Facility
 ↓
USE LOCATION (optional)
 ↓
Enter destination hospital
 ↓
CONTINUE
 ↓
Calculating actual road distance and travel time...
 ↓
Road route: X.X km • Y min
 ↓
Review
 ↓
Submit
```

If route calculation fails, the wizard stays on Step 4 instead of creating a booking with `0 km`.

## 5. Verify Supabase

```sql
SELECT
  id,
  pickup_address,
  pickup_lat,
  pickup_lng,
  destination_address,
  destination_lat,
  destination_lng,
  estimated_distance_km,
  estimated_duration_mins,
  route_distance_meters,
  route_duration_seconds,
  route_provider,
  route_calculated_at
FROM public.bookings
ORDER BY created_at DESC
LIMIT 5;
```

Expected for a successfully routed booking:

```text
destination_lat          NOT NULL
destination_lng          NOT NULL
estimated_distance_km    > 0
estimated_duration_mins  > 0
route_distance_meters    > 0
route_duration_seconds   > 0
route_provider           OSRM/OSM
route_calculated_at      NOT NULL
```

## Provider note

The current Edge Function uses OSRM/OSM for road routing and Nominatim for address geocoding. This is an integration/QA implementation. For production billing and high-volume traffic, move to a company-managed routing provider or self-hosted routing service.
