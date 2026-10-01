-- QA / diagnostic queries for Phase 15 live pickup telemetry.
-- Read-only: these do not modify data.

-- 1) Booking pickup coordinates + current driver telemetry.
SELECT
    b.id,
    b.status,
    b.pickup_address,
    b.pickup_lat,
    b.pickup_lng,
    b.assigned_driver_id,
    b.driver_name,
    b.ambulance_vehicle_number,
    b.geo_lat AS driver_lat,
    b.geo_lng AS driver_lng,
    b.geo_speed_kmh,
    b.geo_heading,
    b.geo_last_ping
FROM public.bookings b
WHERE b.id = 'BK-1790061610278';

-- 2) Latest raw GPS ping for the assigned driver/booking.
SELECT
    p.driver_id,
    p.booking_id,
    p.latitude,
    p.longitude,
    p.speed_kmh,
    p.heading,
    p.accuracy_meters,
    p.captured_at
FROM public.driver_location_pings p
WHERE p.booking_id = 'BK-1790061610278'
ORDER BY p.captured_at DESC
LIMIT 1;

-- 3) Read-only assigned work for Team Lead.
SELECT
    b.id AS booking_id,
    b.status,
    b.patient_name,
    b.ambulance_vehicle_number,
    b.ambulance_name,
    b.assigned_driver_id,
    b.driver_name,
    b.driver_phone,
    b.assigned_doctor_id,
    b.doctor_name,
    b.assigned_emt_id,
    b.emt_name,
    b.assigned_at
FROM public.bookings b
WHERE b.status IN ('ASSIGNED','DRIVER_ASSIGNED','PICKUP_STARTED','PATIENT_PICKED_UP','IN_TRANSIT','ARRIVED')
ORDER BY b.assigned_at DESC NULLS LAST;

-- 4) Doctor availability sanity check.
SELECT
    d.id,
    d.name,
    d.status,
    d.assigned_booking_id
FROM public.doctors d
ORDER BY d.status, d.name;
