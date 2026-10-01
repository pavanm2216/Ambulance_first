# Phase 15 — Live Pickup Telemetry + Read-Only Assigned Work

## Changes

- Driver HUD now calculates live GPS distance from the driver to the patient pickup coordinates.
- Driver ETA to pickup uses live speed when moving, with a conservative 28 km/h fallback while stationary.
- Team Lead telemetry now shows live distance and ETA to pickup from the latest driver GPS ping.
- Team Lead allocation queue shows assigned vehicle/driver/doctor as read-only and removes allocation/reallocation controls for assigned work.
- Budget & Quotations hides **Allocate Ambulance** after a booking is already assigned.
- Driver assignment acceptance is idempotent: a retry after `ASSIGNED -> DRIVER_ASSIGNED` returns the authoritative booking instead of failing.

## Distance limitation

The Flutter calculation is GPS/geodesic distance between the driver's latest coordinates and the pickup coordinates. Exact road-network distance and traffic-aware ETA require a routing provider such as Google Routes or Mapbox. This release does not claim to provide that road-routing calculation.

## SQL

Apply:

`docs/migrations/PHASE_15_DRIVER_ACCEPTANCE_IDEMPOTENCY_AND_LIVE_PICKUP_TELEMETRY.sql`

The SQL changes only the existing driver acceptance RPC; it does not create a new resource table or change the existing allocation contract.
