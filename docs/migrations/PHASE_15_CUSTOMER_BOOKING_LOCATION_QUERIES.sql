-- Read-only QA queries for Customer booking location/persistence.
-- These queries match the live public.bookings schema.

-- 1) Latest customer bookings and captured pickup GPS.
SELECT
    id,
    status,
    customer_id,
    customer_name,
    patient_name,
    pickup_address,
    pickup_city,
    pickup_lat,
    pickup_lng,
    pickup_location_source,
    patient_location_lat,
    patient_location_lng,
    patient_location_accuracy_m,
    location_captured_at,
    destination_address,
    destination_city,
    estimated_distance_km,
    estimated_duration_mins,
    customer_care_verified,
    quotation_revision,
    created_at
FROM public.bookings
ORDER BY created_at DESC
LIMIT 10;

-- 2) Verify one booking created from USE LOCATION.
-- Replace the booking id before running.
SELECT
    id,
    status,
    customer_id,
    pickup_address,
    pickup_lat,
    pickup_lng,
    pickup_location_source,
    patient_location_lat,
    patient_location_lng,
    patient_location_accuracy_m,
    location_captured_at,
    destination_address,
    destination_lat,
    destination_lng,
    customer_care_verified,
    quotation_revision
FROM public.bookings
WHERE id = 'REPLACE_BOOKING_ID';

-- 3) Confirm the current create_customer_booking RPC exists.
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'create_customer_booking';

-- 4) Verify the server-initialized NOT NULL workflow fields on one booking.
SELECT
    id,
    status,
    customer_care_verified,
    quotation_revision,
    cc_check_patient_condition,
    cc_check_oxygen_therapy,
    cc_check_ventilator_loaded,
    cc_check_doctor_designated,
    cc_check_receiving_bed_secured,
    cc_check_route_priority_cleared
FROM public.bookings
WHERE id = 'REPLACE_BOOKING_ID';


-- Real route QA
SELECT
  id,
  pickup_address, pickup_lat, pickup_lng,
  destination_address, destination_lat, destination_lng,
  estimated_distance_km, estimated_duration_mins,
  route_distance_meters, route_duration_seconds,
  route_provider, route_calculated_at
FROM public.bookings
ORDER BY created_at DESC
LIMIT 5;
