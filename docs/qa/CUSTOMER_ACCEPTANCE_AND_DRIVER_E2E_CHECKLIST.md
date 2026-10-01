# Customer Acceptance + Driver E2E QA

## Database

1. Run `docs/migrations/FIX_CUSTOMER_QUOTATION_ACCEPTANCE_AND_DRIVER_DISPATCH.sql`.
2. Run `docs/migrations/TEAM_LEAD_PRICING_CONFIG_TEST.sql` in a development/QA database only.
3. Confirm `respond_to_quotation`, `allocate_booking`, `driver_respond_to_assignment`, `driver_advance_booking`, `publish_driver_location`, and `set_driver_duty_status` exist.

## Customer acceptance regression

1. Team Lead sends a quotation.
2. Customer opens Quotations → Pending Sign-off.
3. Customer selects Confirm Acceptance.
4. Confirm the UI says the acceptance was saved.
5. Refresh the browser.
6. Logout and login again.
7. The quotation must be under Accepted, not Pending Sign-off.
8. Supabase `bookings.status` must be `CUSTOMER_ACCEPTED`.
9. Supabase `bookings.quotation_status` must be `ACCEPTED`.
10. `quotation_responded_at` must be populated.
11. Latest `quotations.status` must be `ACCEPTED` when a quotation history row exists.
12. Team Lead must see the booking as `CUSTOMER_ACCEPTED` and ready for allocation.

## Team Lead allocation

1. Allocation is blocked until `CUSTOMER_ACCEPTED`.
2. Select only an AVAILABLE compatible ambulance.
3. Select an AVAILABLE compatible driver.
4. Required doctor must be AVAILABLE and match requirements.
5. EMT is selected only when a real backend EMT profile exists.
6. Backend allocation must change the booking to `ASSIGNED` and resource assignment fields must be populated.

## Driver

1. Driver logs in.
2. Location permission is requested immediately.
3. Without location permission, the operational console remains locked.
4. With permission, the driver location is published to Supabase.
5. Driver sees `ASSIGNED` booking.
6. Driver can reject or accept the assignment.
7. Accepting moves it to `DRIVER_ASSIGNED` and then pickup can start.
8. Driver advances `PICKUP_STARTED` → `PATIENT_PICKED_UP` → `IN_TRANSIT` → `ARRIVED` → `SERVICE_COMPLETED`.
9. Location continues after `SERVICE_COMPLETED` while the driver remains on duty.
10. OFF_DUTY/LEAVE stops location tracking.
11. Team Lead/Customer Care can use `geo_lat`, `geo_lng`, `geo_speed_kmh`, `geo_heading`, and `geo_last_ping` as the current telemetry.

## Platform note

Foreground GPS is supported in Flutter Web/Chrome while the page is active. True background tracking after a browser/app is suspended requires a native background-location implementation.


## Team Lead quotation filter regression fix

- Customer acceptance is authoritative as `bookings.status = CUSTOMER_ACCEPTED`.
- The `quotations.status` history row may contain `ACCEPTED`.
- Team Lead **Accepted** filter must recognize both representations.
- After the booking is `CUSTOMER_ACCEPTED`, it must appear in the Team Lead Allocation Queue and the allocation RPC must allow resource assignment.
