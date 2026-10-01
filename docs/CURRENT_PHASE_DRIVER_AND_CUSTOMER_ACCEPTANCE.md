# Current Phase — Customer Acceptance + Driver Dispatch

## Customer quotation acceptance

Customer acceptance is persisted through `respond_to_quotation()` and updates the booking to `CUSTOMER_ACCEPTED`. The latest quotation history row is synchronized when present. Customer screens reload the booking from Supabase after the RPC succeeds, so logout/login does not restore the old `QUOTATION_SENT` state.

## Team Lead allocation

Allocation is allowed only after `CUSTOMER_ACCEPTED`. The backend validates ambulance category/capabilities, driver availability/category support, and required doctor/EMT resources. Flutter hydrates the Team Lead resource roster from Supabase when configured.

## Driver workflow

1. Driver authenticates.
2. Driver portal requires live location before entering operations.
3. GPS is published to Supabase continuously while on duty.
4. Team Lead assigns an ambulance/driver after customer acceptance.
5. Driver receives `ASSIGNED` and accepts the assignment.
6. Driver advances through `PICKUP_STARTED` → `PATIENT_PICKED_UP` → `IN_TRANSIT` → `ARRIVED` → `SERVICE_COMPLETED`.
7. GPS continues after service completion while the driver remains on duty.
8. Going `OFF_DUTY`/`LEAVE` stops location tracking and backend publishing.
9. Driver trip completion releases the driver and increments total trips.

## Important platform note

Flutter Web/Chrome foreground geolocation requires the browser tab/page to remain active and location permission to remain enabled. True background tracking after the browser/app is suspended requires a native mobile background-location implementation and platform-specific permissions.
