-- ============================================================================
-- PHASE 15: DOCTOR AVAILABILITY / STALE ASSIGNMENT QA
--
-- Purpose:
--   Diagnose why a doctor is shown as ASSIGNED and therefore excluded from
--   Team Lead allocation. Do NOT make an actively assigned doctor AVAILABLE.
--
-- This script is intentionally safe: inspect first, then run the repair only
-- when the doctor is not attached to an active booking.
-- ============================================================================

-- 1. Inspect Harini and the booking currently holding the assignment.
SELECT
    d.id,
    d.name,
    d.status,
    d.assigned_booking_id,
    b.status AS booking_status,
    b.id AS booking_id,
    b.patient_name,
    b.assigned_doctor_id,
    b.doctor_name
FROM public.doctors d
LEFT JOIN public.bookings b
    ON b.id = d.assigned_booking_id
WHERE lower(d.name) LIKE '%harini%'
ORDER BY d.name;

-- 2. Inspect ALL assigned doctors before changing anything.
SELECT
    d.id,
    d.name,
    d.status,
    d.assigned_booking_id,
    b.status AS booking_status,
    b.id AS booking_id,
    b.patient_name
FROM public.doctors d
LEFT JOIN public.bookings b
    ON b.id = d.assigned_booking_id
WHERE upper(coalesce(d.status, '')) = 'ASSIGNED'
ORDER BY d.name;

-- 3. SAFE REPAIR TEMPLATE.
-- Replace the doctor UUID below only after step 1 confirms that the linked
-- booking is missing or is in a terminal/non-active state.
--
-- UPDATE public.doctors
-- SET status = 'AVAILABLE',
--     assigned_booking_id = NULL
-- WHERE id = '<HARINI_DOCTOR_UUID>'
--   AND status = 'ASSIGNED'
--   AND (
--       assigned_booking_id IS NULL
--       OR NOT EXISTS (
--           SELECT 1
--           FROM public.bookings b
--           WHERE b.id = public.doctors.assigned_booking_id
--             AND upper(coalesce(b.status, '')) IN (
--                 'NEW',
--                 'CUSTOMER_CARE_CONTACTED',
--                 'VERIFICATION_PENDING',
--                 'VERIFIED',
--                 'SENT_TO_TEAM_LEAD',
--                 'ALLOCATION_PENDING',
--                 'QUOTATION_SENT',
--                 'CUSTOMER_ACCEPTED',
--                 'ASSIGNED',
--                 'DRIVER_ASSIGNED',
--                 'PICKUP_STARTED',
--                 'DRIVER_PICKUP_STARTED',
--                 'PATIENT_PICKED_UP',
--                 'IN_TRANSIT',
--                 'ARRIVED'
--             )
--       )
--   );

-- 4. Verify the repaired doctor.
-- SELECT id, name, status, assigned_booking_id
-- FROM public.doctors
-- WHERE id = '<HARINI_DOCTOR_UUID>';
