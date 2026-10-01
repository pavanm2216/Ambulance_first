# Team Lead Live DB + Automatic Trip Monitoring

## What changed

- Accepted quotations no longer expose **Edit / Recalculate** after customer acceptance; Team Lead gets **View Case Details** and allocation access.
- Team Lead Active Trips is now fed from Supabase and refreshed every 5 seconds while the portal is open.
- Fleet, Drivers, EMTs, Doctors and booking data are loaded through controlled Team Lead RPCs rather than relying on demo/in-memory rosters.
- Active-trip cards show one card per active booking with live driver telemetry and a Google Maps route link.
- Team Lead milestone buttons/manual override controls were removed from active-trip cards.
- Driver GPS publishing automatically updates the booking milestone in PostgreSQL:
  - ASSIGNED / DRIVER_ASSIGNED → PICKUP_STARTED on first live GPS ping
  - PICKUP_STARTED → PATIENT_PICKED_UP inside a 150 m pickup geofence
  - PATIENT_PICKED_UP → IN_TRANSIT after leaving a 200 m pickup geofence
  - IN_TRANSIT → ARRIVED inside a 150 m destination geofence
- `SERVICE_COMPLETED` remains an explicit completion event rather than being inferred solely from geofence proximity.
- The migration recreates the driver assignment/advance RPCs using the confirmed booking timestamp columns only.

## SQL to run

Run:

`docs/migrations/TEAM_LEAD_LIVE_OPERATIONS_AND_AUTO_TRIP.sql`

after the previous quotation, fleet, and EMT migrations.

## Flutter setup

After replacing the project:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

The project now includes `url_launcher` so each active-trip card can open a Google Maps driving route using the live driver location when available, falling back to the pickup address.

## Important production note

The automatic milestone engine uses GPS geofences around the stored pickup/destination coordinates. It does not claim to reproduce Google's exact routed road distance or traffic-aware ETA. A production Google Routes API/Maps integration can be added later for road-route ETA and map rendering; the workflow state remains server-authoritative in Supabase.
