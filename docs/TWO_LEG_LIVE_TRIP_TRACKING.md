# Two-Leg Live Trip Tracking

## Leg selection

- **Leg 1 — Driver to pickup:** active for assignment/en-route statuses, including `CUSTOMER_ACCEPTED`, `ASSIGNED`, `DRIVER_ASSIGNED`, and `PICKUP_STARTED`.
- **Leg 2 — Driver to hospital:** active after patient pickup, including `PATIENT_PICKED_UP`, `IN_TRANSIT`, and `ARRIVED`.
- The Customer Active Trip screen chooses the destination from the active leg: `pickup_lat/pickup_lng` for Leg 1, `destination_lat/destination_lng` for Leg 2.

## Live route calculation

The customer app calls the authenticated `calculate-route` Supabase Edge Function using the driver's latest `geo_lat/geo_lng` as the route origin and the active leg target as the destination. The function uses OSRM/OSM and now optionally returns GeoJSON road geometry when `include_geometry: true` is passed. The customer screen refreshes route data no more often than every 30 seconds per active leg, and immediately when the leg changes.

## Deploy after updating the project

```powershell
supabase functions deploy calculate-route
flutter pub get
flutter analyze
flutter test
```

The edge function must be deployed for live road distance, ETA, and route geometry. If routing fails, the UI reports route unavailable rather than substituting the original booking distance as remaining distance.
