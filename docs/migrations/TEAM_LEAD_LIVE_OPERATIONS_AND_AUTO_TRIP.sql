-- ============================================================================
-- Ambulance First
-- TEAM LEAD LIVE OPERATIONS + DATABASE RESOURCE FEED + AUTO TRIP STATUS
--
-- Apply AFTER:
--   FIX_CUSTOMER_QUOTATION_ACCEPTANCE_AND_DRIVER_DISPATCH.sql
--   ADMIN_FLEET_REGISTRATION_FIX.sql
--   TEAM_LEAD_EMT_RESOURCE_ACCESS_FIX.sql
--
-- Purpose:
--   1. Give Team Lead a controlled DB-backed feed for bookings, ambulances,
--      drivers and doctors (avoids direct-table RLS gaps).
--   2. Keep EMTs available through the existing controlled EMT RPC.
--   3. Automatically advance the trip milestone from driver GPS location:
--        ASSIGNED / DRIVER_ASSIGNED
--          -> PICKUP_STARTED
--          -> PATIENT_PICKED_UP
--          -> IN_TRANSIT
--          -> ARRIVED
--      No Team Lead manual milestone buttons are required.
--   4. Keep booking geo telemetry synchronized for Team Lead monitoring.
--
-- Location thresholds are intentionally conservative and are based on GPS
-- coordinates stored on the booking. Google Maps can still be opened for the
-- route from the Team Lead UI, but the workflow state is authoritative in the
-- database and does not depend on a browser map click.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Controlled Team Lead booking feed
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_team_lead_bookings()
RETURNS SETOF public.bookings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT b.*
    FROM public.bookings b
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
    ORDER BY b.created_at DESC NULLS LAST, b.updated_at DESC NULLS LAST;
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_bookings() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_bookings() TO authenticated;


-- ---------------------------------------------------------------------------
-- 2. Controlled Team Lead fleet feed
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_team_lead_ambulances()
RETURNS SETOF public.ambulances
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT a.*
    FROM public.ambulances a
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
    ORDER BY a.status, a.vehicle_number;
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_ambulances() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_ambulances() TO authenticated;


-- ---------------------------------------------------------------------------
-- 3. Controlled Team Lead driver feed
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_team_lead_drivers()
RETURNS SETOF public.drivers
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT d.*
    FROM public.drivers d
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
    ORDER BY d.status, d.id;
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_drivers() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_drivers() TO authenticated;


-- ---------------------------------------------------------------------------
-- 4. Controlled Team Lead doctor feed
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_team_lead_doctors()
RETURNS SETOF public.doctors
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT d.*
    FROM public.doctors d
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
    ORDER BY d.status, d.id;
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_doctors() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_doctors() TO authenticated;


-- ---------------------------------------------------------------------------
-- 5. Automatic location-driven trip status synchronizer
--
-- Thresholds:
--   PICKUP_RADIUS_KM  = 0.15 km / 150 m
--   DEPART_RADIUS_KM  = 0.20 km / 200 m
--   DEST_RADIUS_KM    = 0.15 km / 150 m
--
-- The first live GPS ping after driver acceptance starts PICKUP_STARTED.
-- Reaching pickup changes the state to PATIENT_PICKED_UP.
-- Moving away from pickup changes it to IN_TRANSIT.
-- Reaching destination changes it to ARRIVED.
-- SERVICE_COMPLETED remains an explicit operational completion event and is
-- not inferred merely from proximity to the facility.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_trip_status_from_driver_location(
    p_booking_id text,
    p_latitude numeric,
    p_longitude numeric
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    v_previous_status text;
    v_next_status text;
    v_pickup_distance_km numeric;
    v_destination_distance_km numeric;
    v_has_pickup boolean;
    v_has_destination boolean;
BEGIN
    IF p_booking_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT *
    INTO b
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    v_previous_status := b.status;
    v_next_status := b.status;
    v_has_pickup := b.pickup_lat IS NOT NULL AND b.pickup_lng IS NOT NULL;
    v_has_destination := b.destination_lat IS NOT NULL AND b.destination_lng IS NOT NULL;

    -- Haversine distance from current driver location to pickup.
    IF v_has_pickup THEN
        v_pickup_distance_km := 6371.0088 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(p_latitude - b.pickup_lat) / 2), 2) +
                COS(RADIANS(b.pickup_lat)) *
                COS(RADIANS(p_latitude)) *
                POWER(SIN(RADIANS(p_longitude - b.pickup_lng) / 2), 2)
            )
        );
    END IF;

    -- Haversine distance from current driver location to destination.
    IF v_has_destination THEN
        v_destination_distance_km := 6371.0088 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(p_latitude - b.destination_lat) / 2), 2) +
                COS(RADIANS(b.destination_lat)) *
                COS(RADIANS(p_latitude)) *
                POWER(SIN(RADIANS(p_longitude - b.destination_lng) / 2), 2)
            )
        );
    END IF;

    -- Assigned/preparing -> driver has started moving/publishing GPS.
    IF b.status IN ('ASSIGNED', 'DRIVER_ASSIGNED') THEN
        v_next_status := 'PICKUP_STARTED';

    -- Pickup reached -> patient is considered onboard for this automated
    -- operational model.
    ELSIF b.status = 'PICKUP_STARTED'
      AND v_has_pickup
      AND v_pickup_distance_km <= 0.15 THEN
        v_next_status := 'PATIENT_PICKED_UP';

    -- Once onboard, leaving the pickup geofence starts transit.
    ELSIF b.status = 'PATIENT_PICKED_UP'
      AND (
          NOT v_has_pickup
          OR v_pickup_distance_km > 0.20
      ) THEN
        v_next_status := 'IN_TRANSIT';

    -- Destination reached -> arrived at facility.
    ELSIF b.status = 'IN_TRANSIT'
      AND v_has_destination
      AND v_destination_distance_km <= 0.15 THEN
        v_next_status := 'ARRIVED';
    END IF;

    IF v_next_status <> v_previous_status THEN
        UPDATE public.bookings
        SET
            status = v_next_status,
            trip_started_at = CASE
                WHEN v_next_status = 'PICKUP_STARTED'
                THEN COALESCE(trip_started_at, now())
                ELSE trip_started_at
            END,
            patient_picked_up_at = CASE
                WHEN v_next_status = 'PATIENT_PICKED_UP'
                THEN COALESCE(patient_picked_up_at, now())
                ELSE patient_picked_up_at
            END,
            in_transit_at = CASE
                WHEN v_next_status = 'IN_TRANSIT'
                THEN COALESCE(in_transit_at, now())
                ELSE in_transit_at
            END,
            arrived_at = CASE
                WHEN v_next_status = 'ARRIVED'
                THEN COALESCE(arrived_at, now())
                ELSE arrived_at
            END,
            updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO b;

        IF to_regclass('public.audit_logs') IS NOT NULL THEN
            INSERT INTO public.audit_logs (
                user_id,
                user_name,
                user_role,
                action,
                booking_id,
                entity_type,
                previous_value,
                new_value
            )
            SELECT
                auth.uid(),
                COALESCE(pr.full_name, pr.email, 'Driver'),
                public.app_role(),
                'Automatic GPS trip milestone update',
                p_booking_id,
                'BOOKING',
                v_previous_status,
                v_next_status
            FROM public.profiles pr
            WHERE pr.id = auth.uid();
        END IF;
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_trip_status_from_driver_location(text,numeric,numeric) FROM public;
GRANT EXECUTE ON FUNCTION public.sync_trip_status_from_driver_location(text,numeric,numeric) TO authenticated;


-- ---------------------------------------------------------------------------
-- 6. Replace the location publisher so every driver GPS ping also invokes the
--    automatic trip-state synchronizer.
--
-- PostgreSQL requires DROP before recreation when changing an existing
-- function's return type/signature contract. The signature below is the one
-- used by the Flutter driver app.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.publish_driver_location(
    uuid,
    numeric,
    numeric,
    text,
    numeric,
    numeric,
    numeric
);

CREATE FUNCTION public.publish_driver_location(
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
    IF auth.uid() IS NULL OR auth.uid() <> p_driver_id THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT *
    INTO d
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    v_booking_id := COALESCE(p_booking_id, d.assigned_booking_id);

    IF v_booking_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM public.bookings
        WHERE id = v_booking_id
          AND assigned_driver_id = p_driver_id
    ) THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    UPDATE public.drivers
    SET current_location = concat(
            round(p_latitude::numeric, 6),
            ', ',
            round(p_longitude::numeric, 6)
        )
    WHERE id = p_driver_id
    RETURNING * INTO d;

    UPDATE public.bookings
    SET
        geo_lat = p_latitude,
        geo_lng = p_longitude,
        geo_speed_kmh = greatest(0, coalesce(p_speed_kmh, 0)),
        geo_heading = coalesce(p_heading, 0),
        geo_last_ping = now(),
        updated_at = now()
    WHERE id = v_booking_id
      AND assigned_driver_id = p_driver_id;

    INSERT INTO public.driver_location_pings (
        driver_id,
        booking_id,
        latitude,
        longitude,
        accuracy_meters,
        speed_kmh,
        heading,
        captured_at
    )
    VALUES (
        p_driver_id,
        v_booking_id,
        p_latitude,
        p_longitude,
        greatest(0, coalesce(p_accuracy_meters, 0)),
        greatest(0, coalesce(p_speed_kmh, 0)),
        coalesce(p_heading, 0),
        now()
    );

    IF v_booking_id IS NOT NULL THEN
        PERFORM public.sync_trip_status_from_driver_location(
            v_booking_id,
            p_latitude,
            p_longitude
        );
    END IF;

    RETURN d;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_driver_location(
    uuid,
    numeric,
    numeric,
    text,
    numeric,
    numeric,
    numeric
) FROM public;

GRANT EXECUTE ON FUNCTION public.publish_driver_location(
    uuid,
    numeric,
    numeric,
    text,
    numeric,
    numeric,
    numeric
) TO authenticated;
-- ---------------------------------------------------------------------------
-- 7. Harden the driver assignment/advance RPCs against the confirmed schema.
--    These definitions intentionally avoid optional/unconfirmed timestamp
--    columns from older prototypes.
-- ---------------------------------------------------------------------------
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

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id,
            user_name,
            user_role,
            action,
            booking_id,
            entity_type,
            previous_value,
            new_value
        )
        SELECT
            auth.uid(),
            COALESCE(pr.full_name, pr.email, ''),
            public.app_role(),
            CASE
                WHEN p_accept THEN 'Driver accepted assignment'
                ELSE 'Driver rejected assignment'
            END,
            p_booking_id,
            'BOOKING',
            v_previous,
            v_next
        FROM public.profiles pr
        WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_respond_to_assignment(text,boolean,text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_respond_to_assignment(text,boolean,text) TO authenticated;


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
    v_previous text;
    v_expected text;
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

    v_previous := b.status;

    v_expected := CASE b.status
        WHEN 'DRIVER_ASSIGNED' THEN 'PICKUP_STARTED'
        WHEN 'PICKUP_STARTED' THEN 'PATIENT_PICKED_UP'
        WHEN 'PATIENT_PICKED_UP' THEN 'IN_TRANSIT'
        WHEN 'IN_TRANSIT' THEN 'ARRIVED'
        WHEN 'ARRIVED' THEN 'SERVICE_COMPLETED'
        ELSE NULL
    END;

    -- Location automation may already have advanced the booking. In that case
    -- the driver can continue from the current authoritative state.
    IF v_expected IS NULL OR v_expected <> p_next_status THEN
        RAISE EXCEPTION 'Invalid driver transition from % to %', b.status, p_next_status;
    END IF;

    UPDATE public.bookings
    SET status = p_next_status,
        trip_started_at = CASE
            WHEN p_next_status = 'PICKUP_STARTED' THEN COALESCE(trip_started_at, now())
            ELSE trip_started_at
        END,
        patient_picked_up_at = CASE
            WHEN p_next_status = 'PATIENT_PICKED_UP' THEN COALESCE(patient_picked_up_at, now())
            ELSE patient_picked_up_at
        END,
        in_transit_at = CASE
            WHEN p_next_status = 'IN_TRANSIT' THEN COALESCE(in_transit_at, now())
            ELSE in_transit_at
        END,
        arrived_at = CASE
            WHEN p_next_status = 'ARRIVED' THEN COALESCE(arrived_at, now())
            ELSE arrived_at
        END,
        completed_at = CASE
            WHEN p_next_status = 'SERVICE_COMPLETED' THEN COALESCE(completed_at, now())
            ELSE completed_at
        END,
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    IF p_next_status = 'SERVICE_COMPLETED' THEN
        UPDATE public.drivers
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL,
            assigned_ambulance_number = NULL,
            total_trips = COALESCE(total_trips, 0) + 1
        WHERE id = auth.uid();

        UPDATE public.ambulances a
        SET status = 'AVAILABLE',
            assigned_booking_id = NULL
        WHERE a.assigned_booking_id = p_booking_id;
    ELSE
        UPDATE public.drivers
        SET status = 'ON_TRIP'
        WHERE id = auth.uid();
    END IF;

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id,
            user_name,
            user_role,
            action,
            booking_id,
            entity_type,
            previous_value,
            new_value
        )
        SELECT
            auth.uid(),
            COALESCE(pr.full_name, pr.email, ''),
            public.app_role(),
            'Driver trip status changed',
            p_booking_id,
            'BOOKING',
            v_previous,
            p_next_status
        FROM public.profiles pr
        WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_advance_booking(text,text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_advance_booking(text,text) TO authenticated;

COMMIT;
