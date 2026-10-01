-- Hold assigned resources after driver arrival until the booking's customer
-- confirms patient drop-off. Apply after FIX_DRIVER_PORTAL_CANONICAL_ID_CONTRACT.sql.

BEGIN;

ALTER TABLE public.bookings
    ADD COLUMN IF NOT EXISTS patient_onboard_confirmed_at timestamptz,
    ADD COLUMN IF NOT EXISTS dropoff_customer_confirmed_at timestamptz;

UPDATE public.bookings
SET patient_onboard_confirmed_at = COALESCE(
    patient_onboard_confirmed_at,
    patient_picked_up_at,
    in_transit_at,
    arrived_at,
    updated_at,
    now()
)
WHERE status IN ('IN_TRANSIT', 'ARRIVED', 'SERVICE_COMPLETED', 'INVOICE_GENERATED', 'COMPLETED');

CREATE OR REPLACE FUNCTION public.driver_advance_booking(
    p_booking_id text,
    p_next_status text
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    d public.drivers;
    v_previous text;
    v_expected text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE profile_id = auth.uid()
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver resource not found';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND assigned_driver_id = d.id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    v_previous := b.status;
    v_expected := CASE b.status
        WHEN 'DRIVER_ASSIGNED' THEN 'PICKUP_STARTED'
        WHEN 'PICKUP_STARTED' THEN 'PATIENT_PICKED_UP'
        WHEN 'PATIENT_PICKED_UP' THEN 'IN_TRANSIT'
        WHEN 'IN_TRANSIT' THEN 'ARRIVED'
        ELSE NULL
    END;

    IF v_expected IS NULL OR v_expected <> p_next_status THEN
        RAISE EXCEPTION 'Invalid driver transition from % to %', b.status, p_next_status;
    END IF;

    IF b.status = 'PATIENT_PICKED_UP'
       AND p_next_status = 'IN_TRANSIT'
       AND b.patient_onboard_confirmed_at IS NULL THEN
        RAISE EXCEPTION 'Customer must confirm patient onboard before transit';
    END IF;

    UPDATE public.bookings
    SET status = p_next_status,
        trip_started_at = CASE WHEN p_next_status = 'PICKUP_STARTED' THEN COALESCE(trip_started_at, now()) ELSE trip_started_at END,
        patient_picked_up_at = CASE WHEN p_next_status = 'PATIENT_PICKED_UP' THEN COALESCE(patient_picked_up_at, now()) ELSE patient_picked_up_at END,
        in_transit_at = CASE WHEN p_next_status = 'IN_TRANSIT' THEN COALESCE(in_transit_at, now()) ELSE in_transit_at END,
        arrived_at = CASE WHEN p_next_status = 'ARRIVED' THEN COALESCE(arrived_at, now()) ELSE arrived_at END,
        updated_at = now()
    WHERE id = b.id
    RETURNING * INTO b;

    UPDATE public.drivers SET status = 'ON_TRIP'
    WHERE id = d.id;

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id, user_name, user_role, action, booking_id, entity_type,
            previous_value, new_value
        )
        SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
               'Driver trip status changed', b.id, 'BOOKING', v_previous, p_next_status
        FROM public.profiles pr
        WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_advance_booking(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_advance_booking(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_confirm_patient_onboard(
    p_booking_id text
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'CUSTOMER' THEN
        RAISE EXCEPTION 'Customer authentication required';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND customer_id = auth.uid()
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking was not found for current customer';
    END IF;

    IF b.patient_onboard_confirmed_at IS NOT NULL THEN
        RETURN b;
    END IF;
    IF b.status <> 'PATIENT_PICKED_UP' THEN
        RAISE EXCEPTION 'Patient onboard can only be confirmed after driver pickup';
    END IF;

    UPDATE public.bookings
    SET patient_onboard_confirmed_at = now(),
        updated_at = now()
    WHERE id = b.id
    RETURNING * INTO b;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.customer_confirm_patient_onboard(text) FROM public;
GRANT EXECUTE ON FUNCTION public.customer_confirm_patient_onboard(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.customer_confirm_dropoff(
    p_booking_id text
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'CUSTOMER' THEN
        RAISE EXCEPTION 'Customer authentication required';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND customer_id = auth.uid()
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking was not found for current customer';
    END IF;

    IF b.status = 'SERVICE_COMPLETED' THEN
        RETURN b;
    END IF;
    IF b.patient_onboard_confirmed_at IS NULL THEN
        RAISE EXCEPTION 'Customer must confirm patient onboard before drop-off';
    END IF;
    IF b.status <> 'ARRIVED' THEN
        RAISE EXCEPTION 'Drop-off can only be confirmed after driver arrival';
    END IF;

    UPDATE public.bookings
    SET status = 'SERVICE_COMPLETED',
        dropoff_customer_confirmed_at = COALESCE(dropoff_customer_confirmed_at, now()),
        completed_at = COALESCE(completed_at, now()),
        updated_at = now()
    WHERE id = b.id
    RETURNING * INTO b;

    IF b.assigned_driver_id IS NOT NULL THEN
        UPDATE public.drivers SET status = 'AVAILABLE'
        WHERE id = b.assigned_driver_id;

        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'drivers'
              AND column_name = 'assigned_booking_id'
        ) THEN
            EXECUTE 'UPDATE public.drivers SET assigned_booking_id = NULL WHERE id = $1'
            USING b.assigned_driver_id;
        END IF;

        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'drivers'
              AND column_name = 'assigned_ambulance_number'
        ) THEN
            EXECUTE 'UPDATE public.drivers SET assigned_ambulance_number = NULL WHERE id = $1'
            USING b.assigned_driver_id;
        END IF;
    END IF;

    IF b.assigned_ambulance_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'ambulances'
              AND column_name = 'assigned_booking_id'
        ) THEN
            EXECUTE 'UPDATE public.ambulances
                     SET status = ''AVAILABLE'', assigned_booking_id = NULL
                     WHERE id = $1'
            USING b.assigned_ambulance_id;
        ELSE
            UPDATE public.ambulances SET status = 'AVAILABLE'
            WHERE id = b.assigned_ambulance_id;
        END IF;
    END IF;

    IF b.assigned_doctor_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'doctors'
              AND column_name = 'assigned_booking_id'
        ) THEN
            EXECUTE 'UPDATE public.doctors
                     SET status = ''AVAILABLE'', assigned_booking_id = NULL
                     WHERE id = $1'
            USING b.assigned_doctor_id;
        ELSE
            UPDATE public.doctors SET status = 'AVAILABLE'
            WHERE id = b.assigned_doctor_id;
        END IF;
    END IF;

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id, user_name, user_role, action, booking_id, entity_type,
            previous_value, new_value
        )
        SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
               'Customer confirmed patient drop-off', b.id, 'BOOKING',
               'ARRIVED', 'SERVICE_COMPLETED'
        FROM public.profiles pr
        WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.customer_confirm_dropoff(text) FROM public;
GRANT EXECUTE ON FUNCTION public.customer_confirm_dropoff(text) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;