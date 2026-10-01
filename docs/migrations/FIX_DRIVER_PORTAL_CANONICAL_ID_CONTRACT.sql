-- Driver portal canonical-ID contract
--
-- Team Lead allocation persists public.drivers.id in
-- bookings.assigned_driver_id.  Driver authentication uses
-- public.drivers.profile_id (= auth.uid()).  Older Driver RPCs compared the
-- two IDs directly, which made a correctly allocated booking visible but
-- impossible to acknowledge, advance, publish GPS for, or update duty on.
--
-- Apply after the controlled workflow, Team Lead allocation, and live-trip
-- migrations.

BEGIN;

-- Controlled Driver feeds.  These avoid relying on broad direct-table SELECT
-- policies from the mobile client and always resolve the current Driver by
-- drivers.profile_id = auth.uid().
CREATE OR REPLACE FUNCTION public.get_current_driver()
RETURNS SETOF public.drivers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    RETURN QUERY
    SELECT d.*
    FROM public.drivers d
    WHERE d.profile_id = auth.uid()
    LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_current_driver_bookings()
RETURNS SETOF public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    RETURN QUERY
    SELECT b.*
    FROM public.bookings b
    INNER JOIN public.drivers d ON d.id = b.assigned_driver_id
    WHERE d.profile_id = auth.uid()
    ORDER BY b.created_at DESC NULLS LAST;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_driver_duty_status(
    p_driver_id uuid,
    p_status text
)
RETURNS public.drivers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    d public.drivers;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE id = p_driver_id
      AND profile_id = auth.uid()
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver resource does not belong to the authenticated user';
    END IF;

    IF UPPER(p_status) NOT IN ('AVAILABLE', 'OFF_DUTY', 'LEAVE', 'ON_TRIP') THEN
        RAISE EXCEPTION 'Invalid driver status: %', p_status;
    END IF;

    IF UPPER(p_status) IN ('OFF_DUTY', 'LEAVE') AND EXISTS (
        SELECT 1 FROM public.bookings
        WHERE assigned_driver_id = d.id
          AND status IN ('ASSIGNED', 'DRIVER_ASSIGNED', 'PICKUP_STARTED',
                         'PATIENT_PICKED_UP', 'IN_TRANSIT', 'ARRIVED')
    ) THEN
        RAISE EXCEPTION 'Driver cannot go off duty while an active assignment exists';
    END IF;

    UPDATE public.drivers
    SET status = UPPER(p_status)
    WHERE id = d.id
    RETURNING * INTO d;

    RETURN d;
END;
$$;


CREATE OR REPLACE FUNCTION public.publish_driver_location(
    p_driver_id uuid,
    p_latitude numeric,
    p_longitude numeric,
    p_booking_id text DEFAULT NULL,
    p_accuracy_meters numeric DEFAULT 0,
    p_speed_kmh numeric DEFAULT 0,
    p_heading numeric DEFAULT 0
)
RETURNS public.drivers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    d public.drivers;
    v_booking_id text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;
    IF p_latitude IS NULL OR p_longitude IS NULL
       OR p_latitude NOT BETWEEN -90 AND 90
       OR p_longitude NOT BETWEEN -180 AND 180 THEN
        RAISE EXCEPTION 'Valid driver latitude and longitude are required';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE id = p_driver_id
      AND profile_id = auth.uid()
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver resource does not belong to the authenticated user';
    END IF;

    -- The confirmed drivers schema has no assigned_booking_id column. The
    -- app supplies the active booking explicitly with every GPS ping.
    v_booking_id := NULLIF(TRIM(p_booking_id), '');
    IF v_booking_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.bookings
        WHERE id = v_booking_id AND assigned_driver_id = d.id
    ) THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    UPDATE public.drivers
    SET current_location = CONCAT(ROUND(p_latitude, 6), ', ', ROUND(p_longitude, 6))
    WHERE id = d.id
    RETURNING * INTO d;

    IF v_booking_id IS NOT NULL THEN
        UPDATE public.bookings
        SET geo_lat = p_latitude,
            geo_lng = p_longitude,
            geo_speed_kmh = GREATEST(0, COALESCE(p_speed_kmh, 0)),
            geo_heading = COALESCE(p_heading, 0),
            geo_last_ping = now(),
            updated_at = now()
        WHERE id = v_booking_id AND assigned_driver_id = d.id;
    END IF;

    INSERT INTO public.driver_location_pings (
        driver_id, booking_id, latitude, longitude, accuracy_meters,
        speed_kmh, heading, captured_at
    ) VALUES (
        d.id, v_booking_id, p_latitude, p_longitude,
        GREATEST(0, COALESCE(p_accuracy_meters, 0)),
        GREATEST(0, COALESCE(p_speed_kmh, 0)), COALESCE(p_heading, 0), now()
    );

    IF v_booking_id IS NOT NULL THEN
        PERFORM public.sync_trip_status_from_driver_location(
            v_booking_id, p_latitude, p_longitude
        );
    END IF;

    RETURN d;
END;
$$;


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
    d public.drivers;
    v_next text;
    v_previous text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT * INTO d FROM public.drivers WHERE profile_id = auth.uid() FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Driver resource not found'; END IF;

    SELECT * INTO b FROM public.bookings
    WHERE id = p_booking_id AND assigned_driver_id = d.id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Booking is not assigned to current driver'; END IF;

    -- A network retry after acceptance returns the authoritative state.
    IF p_accept AND b.status = 'DRIVER_ASSIGNED' THEN
        UPDATE public.drivers SET status = 'ON_TRIP' WHERE id = d.id;
        RETURN b;
    END IF;
    IF b.status <> 'ASSIGNED' THEN
        RAISE EXCEPTION 'Booking is not awaiting driver acceptance';
    END IF;

    v_previous := b.status;
    v_next := CASE WHEN p_accept THEN 'DRIVER_ASSIGNED' ELSE 'DRIVER_REJECTED' END;
    UPDATE public.bookings SET status = v_next, updated_at = now()
    WHERE id = b.id RETURNING * INTO b;

    UPDATE public.drivers
    SET status = CASE WHEN p_accept THEN 'ON_TRIP' ELSE 'AVAILABLE' END
    WHERE id = d.id;

    -- Audit storage is optional in the current production schema. Do not
    -- roll back the authoritative driver response when that table is absent.
    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id, user_name, user_role, action, booking_id, entity_type,
            previous_value, new_value
        )
        SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
               CASE WHEN p_accept THEN 'Driver accepted assignment' ELSE 'Driver rejected assignment' END,
               b.id, 'BOOKING', v_previous, v_next
        FROM public.profiles pr WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;


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

    SELECT * INTO d FROM public.drivers WHERE profile_id = auth.uid() FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Driver resource not found'; END IF;

    SELECT * INTO b FROM public.bookings
    WHERE id = p_booking_id AND assigned_driver_id = d.id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Booking is not assigned to current driver'; END IF;

    v_previous := b.status;
    v_expected := CASE b.status
        WHEN 'DRIVER_ASSIGNED' THEN 'PICKUP_STARTED'
        WHEN 'PICKUP_STARTED' THEN 'PATIENT_PICKED_UP'
        WHEN 'PATIENT_PICKED_UP' THEN 'IN_TRANSIT'
        WHEN 'IN_TRANSIT' THEN 'ARRIVED'
        WHEN 'ARRIVED' THEN 'SERVICE_COMPLETED'
        ELSE NULL
    END;
    IF v_expected IS NULL OR v_expected <> p_next_status THEN
        RAISE EXCEPTION 'Invalid driver transition from % to %', b.status, p_next_status;
    END IF;

    UPDATE public.bookings
    SET status = p_next_status,
        trip_started_at = CASE WHEN p_next_status = 'PICKUP_STARTED' THEN COALESCE(trip_started_at, now()) ELSE trip_started_at END,
        patient_picked_up_at = CASE WHEN p_next_status = 'PATIENT_PICKED_UP' THEN COALESCE(patient_picked_up_at, now()) ELSE patient_picked_up_at END,
        in_transit_at = CASE WHEN p_next_status = 'IN_TRANSIT' THEN COALESCE(in_transit_at, now()) ELSE in_transit_at END,
        arrived_at = CASE WHEN p_next_status = 'ARRIVED' THEN COALESCE(arrived_at, now()) ELSE arrived_at END,
        completed_at = CASE WHEN p_next_status = 'SERVICE_COMPLETED' THEN COALESCE(completed_at, now()) ELSE completed_at END,
        updated_at = now()
    WHERE id = b.id RETURNING * INTO b;

    UPDATE public.drivers
    SET status = CASE WHEN p_next_status = 'SERVICE_COMPLETED' THEN 'AVAILABLE' ELSE 'ON_TRIP' END
    WHERE id = d.id;

    IF p_next_status = 'SERVICE_COMPLETED' THEN
        -- Fleet schemas created before the allocation migration may not yet
        -- have assigned_booking_id. Releasing that optional denormalized
        -- field must never roll back the completed booking transition.
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'ambulances'
              AND column_name = 'assigned_booking_id'
        ) THEN
            EXECUTE 'UPDATE public.ambulances
                     SET status = ''AVAILABLE'', assigned_booking_id = NULL
                     WHERE assigned_booking_id = $1'
            USING b.id;
        END IF;
    END IF;

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id, user_name, user_role, action, booking_id, entity_type,
            previous_value, new_value
        )
        SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
               'Driver trip status changed', b.id, 'BOOKING', v_previous, p_next_status
        FROM public.profiles pr WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.set_driver_duty_status(uuid, text) FROM public;
GRANT EXECUTE ON FUNCTION public.set_driver_duty_status(uuid, text) TO authenticated;
REVOKE ALL ON FUNCTION public.get_current_driver() FROM public;
GRANT EXECUTE ON FUNCTION public.get_current_driver() TO authenticated;
REVOKE ALL ON FUNCTION public.get_current_driver_bookings() FROM public;
GRANT EXECUTE ON FUNCTION public.get_current_driver_bookings() TO authenticated;
REVOKE ALL ON FUNCTION public.publish_driver_location(uuid, numeric, numeric, text, numeric, numeric, numeric) FROM public;
GRANT EXECUTE ON FUNCTION public.publish_driver_location(uuid, numeric, numeric, text, numeric, numeric, numeric) TO authenticated;
REVOKE ALL ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) TO authenticated;
REVOKE ALL ON FUNCTION public.driver_advance_booking(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_advance_booking(text, text) TO authenticated;

COMMIT;
