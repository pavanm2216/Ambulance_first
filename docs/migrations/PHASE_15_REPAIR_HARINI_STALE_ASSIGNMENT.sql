-- ============================================================================
-- PHASE 15: REPAIR HARINI'S STALE DOCTOR ASSIGNMENT
--
-- Verified QA state on 2026-09-23:
--   doctor: harini
--   doctor status: ASSIGNED
--   doctor assigned_booking_id: BK-1790061610278
--   booking status: CUSTOMER_ACCEPTED
--   booking assigned_doctor_id: Harini's UUID
--
-- The booking is NOT ASSIGNED. Therefore the doctor assignment is stale
-- from the previous allocation test. This transaction clears the stale
-- relationship on BOTH sides and makes Harini AVAILABLE.
--
-- This script is intentionally scoped to the exact QA booking and doctor.
-- It will not modify a booking that has already progressed to ASSIGNED.
-- ============================================================================

BEGIN;

-- Lock the doctor and booking rows first.
SELECT id, name, status, assigned_booking_id
FROM public.doctors
WHERE id = '7ad0f843-cf98-4ee9-8f9d-80e46d91bde5'
FOR UPDATE;

SELECT id, status, assigned_doctor_id, doctor_name
FROM public.bookings
WHERE id = 'BK-1790061610278'
FOR UPDATE;

-- Clear the stale doctor assignment only while the booking is still
-- CUSTOMER_ACCEPTED and the doctor is assigned to this exact booking.
UPDATE public.doctors
SET
    status = 'AVAILABLE',
    assigned_booking_id = NULL
WHERE id = '7ad0f843-cf98-4ee9-8f9d-80e46d91bde5'
  AND status = 'ASSIGNED'
  AND assigned_booking_id = 'BK-1790061610278'
  AND EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id = 'BK-1790061610278'
        AND b.status = 'CUSTOMER_ACCEPTED'
        AND b.assigned_doctor_id = '7ad0f843-cf98-4ee9-8f9d-80e46d91bde5'
  );

-- Clear the reverse booking-side assignment as well.
UPDATE public.bookings
SET
    assigned_doctor_id = NULL,
    doctor_name = NULL,
    updated_at = now()
WHERE id = 'BK-1790061610278'
  AND status = 'CUSTOMER_ACCEPTED'
  AND assigned_doctor_id = '7ad0f843-cf98-4ee9-8f9d-80e46d91bde5';

COMMIT;

-- Verify both sides.
SELECT
    d.id,
    d.name,
    d.status,
    d.assigned_booking_id
FROM public.doctors d
WHERE d.id = '7ad0f843-cf98-4ee9-8f9d-80e46d91bde5';

SELECT
    b.id,
    b.status,
    b.assigned_doctor_id,
    b.doctor_name
FROM public.bookings b
WHERE b.id = 'BK-1790061610278';
