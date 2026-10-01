-- Run these read-only queries in the Supabase SQL Editor before and after
-- FIX_DRIVER_LIVE_TRACKING_SCHEMA_SAFE.sql. They inspect the deployed schema;
-- they do not rely on the files in this repository.

-- 1. Actual columns (look especially for the absent legacy driver fields).
SELECT table_name, column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('drivers', 'bookings', 'ambulances', 'doctors', 'driver_location_pings')
ORDER BY table_name, ordinal_position;

-- 2. Deployed definitions, including every overload and its argument types.
SELECT
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS arguments,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'publish_driver_location',
    'driver_respond_to_assignment',
    'driver_advance_booking',
    'sync_trip_status_from_driver_location',
    'get_customer_bookings'
  )
ORDER BY p.proname, pg_get_function_identity_arguments(p.oid);

-- 3. Search the deployed Driver function bodies for stale columns. This must
-- return zero rows after the repair (comments may still mention the names).
SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'publish_driver_location', 'driver_respond_to_assignment',
    'driver_advance_booking', 'sync_trip_status_from_driver_location'
  )
  AND pg_get_functiondef(p.oid) ~
    '(SET[[:space:]]+total_trips|SET[[:space:]]+assigned_booking_id|SET[[:space:]]+assigned_ambulance_number)';

-- 4. Confirm the canonical identity relationship for a known booking.
-- Replace the value with the booking under test.
SELECT
  b.id AS booking_id,
  b.status,
  b.assigned_driver_id,
  d.profile_id AS driver_auth_user_id,
  b.geo_lat, b.geo_lng, b.geo_speed_kmh, b.geo_heading, b.geo_last_ping
FROM public.bookings b
LEFT JOIN public.drivers d ON d.id = b.assigned_driver_id
WHERE b.id = '<BOOKING_ID>';

-- 5. After the Driver publishes a location, geo_lat, geo_lng and
-- geo_last_ping must be non-null and advance with each point.
SELECT id, status, geo_lat, geo_lng, geo_speed_kmh, geo_heading, geo_last_ping
FROM public.bookings
WHERE id = '<BOOKING_ID>';
