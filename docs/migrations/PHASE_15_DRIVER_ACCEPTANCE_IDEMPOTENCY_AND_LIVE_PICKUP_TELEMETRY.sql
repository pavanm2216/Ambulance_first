-- Ambulance First
-- PHASE 15: DRIVER ACCEPTANCE IDEMPOTENCY + LIVE PICKUP TELEMETRY
--
-- Purpose:
-- 1. A retry of "START PICKUP" must not fail merely because the first request
--    already changed ASSIGNED -> DRIVER_ASSIGNED.
-- 2. Driver and Team Lead clients can safely retry while their local UI catches
--    up with the authoritative Supabase state.
--
-- Apply in Supabase SQL Editor.

BEGIN;

CREATE OR REPLACE FUNCTION public.driver_respond_to_assignment(
    p_booking_id text,
    p_accept boolean,
    p_reason text DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    v_next text;
    v_previous text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT *
    INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND assigned_driver_id = auth.uid()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    -- Idempotent retry: the first accept may have succeeded while the Flutter
    -- client still showed ASSIGNED. Return the authoritative state instead of
    -- throwing "Booking is not awaiting driver acceptance".
    IF p_accept AND b.status = 'DRIVER_ASSIGNED' THEN
        UPDATE public.drivers
        SET status = 'ON_TRIP'
        WHERE id = auth.uid();
        RETURN b;
    END IF;

    IF b.status <> 'ASSIGNED' THEN
        RAISE EXCEPTION 'Booking is not awaiting driver acceptance';
    END IF;

    v_previous := b.status;

    IF p_accept THEN
        v_next := 'DRIVER_ASSIGNED';

        UPDATE public.bookings
        SET status = v_next,
            updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO b;

        UPDATE public.drivers
        SET status = 'ON_TRIP'
        WHERE id = auth.uid();
    ELSE
        v_next := 'DRIVER_REJECTED';

        UPDATE public.bookings
        SET status = v_next,
            updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO b;

        UPDATE public.drivers
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL,
            assigned_ambulance_number = NULL
        WHERE id = auth.uid();
    END IF;

    INSERT INTO public.audit_logs (
        user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value
    )
    SELECT
        auth.uid(),
        COALESCE(pr.full_name, pr.email, ''),
        public.app_role(),
        CASE WHEN p_accept THEN 'Driver accepted assignment' ELSE 'Driver rejected assignment' END,
        p_booking_id,
        'BOOKING',
        v_previous,
        v_next
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) TO authenticated;

COMMIT;
