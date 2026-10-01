-- ============================================================================
-- Ambulance First
-- Customer quotation persistence + Driver dispatch + Live location
--
-- Apply after the existing workflow/pricing migrations.
-- Safe to run more than once.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. CUSTOMER QUOTATION RESPONSE
-- ============================================================================

CREATE OR REPLACE FUNCTION public.respond_to_quotation(
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
    v_status text;
    v_quote_status text;
    v_quote_id uuid;
BEGIN
    IF auth.uid() IS NULL
       OR public.app_role() <> 'CUSTOMER' THEN
        RAISE EXCEPTION 'Customer authentication required';
    END IF;

    SELECT *
    INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND customer_id = auth.uid()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found or not owned by customer';
    END IF;

    IF b.status <> 'QUOTATION_SENT' THEN
        RAISE EXCEPTION
            'Quotation is not awaiting customer response. Current status: %',
            b.status;
    END IF;

    v_status := CASE
        WHEN p_accept THEN 'CUSTOMER_ACCEPTED'
        ELSE 'CUSTOMER_REJECTED'
    END CASE;

    v_quote_status := CASE
        WHEN p_accept THEN 'ACCEPTED'
        ELSE 'REJECTED'
    END CASE;

    UPDATE public.bookings
    SET
        quotation_status = v_quote_status,
        quotation_responded_at = now(),
        quotation_rejection_reason = CASE
            WHEN p_accept THEN NULL
            ELSE NULLIF(TRIM(COALESCE(p_reason, '')), '')
        END,
        q_final_amount = COALESCE(
            q_final_amount,
            COALESCE(q_subtotal, 0) + COALESCE(q_tax_amount, 0)
        ),
        status = v_status,
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    IF b.quotation_id IS NOT NULL THEN
        BEGIN
            v_quote_id := b.quotation_id::uuid;

            UPDATE public.quotations
            SET
                status = v_quote_status,
                responded_at = now(),
                rejection_reason = CASE
                    WHEN p_accept THEN NULL
                    ELSE NULLIF(TRIM(COALESCE(p_reason, '')), '')
                END
            WHERE id = v_quote_id;

        EXCEPTION WHEN invalid_text_representation THEN
            UPDATE public.quotations
            SET
                status = v_quote_status,
                responded_at = now(),
                rejection_reason = CASE
                    WHEN p_accept THEN NULL
                    ELSE NULLIF(TRIM(COALESCE(p_reason, '')), '')
                END
            WHERE booking_id = p_booking_id
              AND revision_number = (
                  SELECT MAX(q2.revision_number)
                  FROM public.quotations q2
                  WHERE q2.booking_id = p_booking_id
              );
        END;
    ELSE
        UPDATE public.quotations
        SET
            status = v_quote_status,
            responded_at = now(),
            rejection_reason = CASE
                WHEN p_accept THEN NULL
                ELSE NULLIF(TRIM(COALESCE(p_reason, '')), '')
            END
        WHERE booking_id = p_booking_id
          AND revision_number = (
              SELECT MAX(q2.revision_number)
              FROM public.quotations q2
              WHERE q2.booking_id = p_booking_id
          );
    END IF;

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
            WHEN p_accept THEN 'Quotation accepted by customer'
            ELSE 'Quotation rejected by customer'
        END,
        p_booking_id,
        'QUOTATION',
        'QUOTATION_SENT',
        v_status
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.respond_to_quotation(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.respond_to_quotation(text, boolean, text) TO authenticated;


-- ============================================================================
-- 2. DRIVER LOCATION HISTORY
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.driver_location_pings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
    booking_id text REFERENCES public.bookings(id) ON DELETE SET NULL,
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    accuracy_meters numeric DEFAULT 0,
    speed_kmh numeric DEFAULT 0,
    heading numeric DEFAULT 0,
    captured_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_driver_location_pings_driver_time
ON public.driver_location_pings(driver_id, captured_at DESC);

CREATE INDEX IF NOT EXISTS idx_driver_location_pings_booking_time
ON public.driver_location_pings(booking_id, captured_at DESC);


-- ============================================================================
-- 3. DRIVER LIVE LOCATION PUBLISHER
--
-- IMPORTANT:
-- PostgreSQL cannot change the return type of an existing function using
-- CREATE OR REPLACE FUNCTION. Drop the existing same-signature function first.
-- ============================================================================

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

    IF p_latitude IS NULL OR p_longitude IS NULL THEN
        RAISE EXCEPTION 'Driver latitude and longitude are required';
    END IF;

    IF p_latitude < -90 OR p_latitude > 90 THEN
        RAISE EXCEPTION 'Invalid latitude';
    END IF;

    IF p_longitude < -180 OR p_longitude > 180 THEN
        RAISE EXCEPTION 'Invalid longitude';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    v_booking_id := COALESCE(NULLIF(TRIM(p_booking_id), ''), d.assigned_booking_id);

    IF v_booking_id IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM public.bookings
            WHERE id = v_booking_id
              AND assigned_driver_id = p_driver_id
       ) THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    UPDATE public.drivers
    SET current_location = CONCAT(
        ROUND(p_latitude::numeric, 6),
        ', ',
        ROUND(p_longitude::numeric, 6)
    )
    WHERE id = p_driver_id
    RETURNING * INTO d;

    IF v_booking_id IS NOT NULL THEN
        UPDATE public.bookings
        SET
            geo_lat = p_latitude,
            geo_lng = p_longitude,
            geo_speed_kmh = GREATEST(0, COALESCE(p_speed_kmh, 0)),
            geo_heading = COALESCE(p_heading, 0),
            geo_last_ping = now(),
            updated_at = now()
        WHERE id = v_booking_id
          AND assigned_driver_id = p_driver_id;
    END IF;

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
        GREATEST(0, COALESCE(p_accuracy_meters, 0)),
        GREATEST(0, COALESCE(p_speed_kmh, 0)),
        COALESCE(p_heading, 0),
        now()
    );

    RETURN d;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_driver_location(
    uuid, numeric, numeric, text, numeric, numeric, numeric
) FROM public;

GRANT EXECUTE ON FUNCTION public.publish_driver_location(
    uuid, numeric, numeric, text, numeric, numeric, numeric
) TO authenticated;


-- ============================================================================
-- 4. DRIVER DUTY STATUS
-- ============================================================================

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
    IF auth.uid() IS NULL OR auth.uid() <> p_driver_id THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    IF UPPER(p_status) NOT IN ('AVAILABLE','ON_DUTY','OFF_DUTY','LEAVE','ON_TRIP') THEN
        RAISE EXCEPTION 'Invalid driver status: %', p_status;
    END IF;

    IF UPPER(p_status) IN ('OFF_DUTY','LEAVE')
       AND EXISTS (
            SELECT 1
            FROM public.bookings
            WHERE assigned_driver_id = p_driver_id
              AND status IN (
                  'ASSIGNED','DRIVER_ASSIGNED','PICKUP_STARTED',
                  'PATIENT_PICKED_UP','IN_TRANSIT','ARRIVED'
              )
       ) THEN
        RAISE EXCEPTION 'Driver cannot go off duty while an active assignment exists';
    END IF;

    UPDATE public.drivers
    SET status = UPPER(p_status)
    WHERE id = p_driver_id
    RETURNING * INTO d;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    RETURN d;
END;
$$;

REVOKE ALL ON FUNCTION public.set_driver_duty_status(uuid, text) FROM public;
GRANT EXECUTE ON FUNCTION public.set_driver_duty_status(uuid, text) TO authenticated;


-- ============================================================================
-- 5. DRIVER ACCEPTS / REJECTS ASSIGNMENT
-- ============================================================================

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
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT * INTO b
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

    IF p_accept THEN
        v_next := 'DRIVER_ASSIGNED';

        UPDATE public.bookings
        SET status = v_next, updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO b;

        UPDATE public.drivers
        SET status = 'ON_TRIP'
        WHERE id = auth.uid();
    ELSE
        v_next := 'DRIVER_REJECTED';

        UPDATE public.bookings
        SET status = v_next, updated_at = now()
        WHERE id = p_booking_id
        RETURNING * INTO b;

        UPDATE public.drivers
        SET
            status = 'AVAILABLE',
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
        CASE
            WHEN p_accept THEN 'Driver accepted assignment'
            ELSE 'Driver rejected assignment'
        END,
        p_booking_id,
        'BOOKING',
        'ASSIGNED',
        v_next
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) TO authenticated;


-- ============================================================================
-- 6. DRIVER TRIP MILESTONES
-- Uses the confirmed booking timestamp fields only.
-- ============================================================================

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
    v_previous_status text;
    v_expected text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
        RAISE EXCEPTION 'Driver authentication required';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
      AND assigned_driver_id = auth.uid()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking is not assigned to current driver';
    END IF;

    v_previous_status := b.status;

    v_expected := CASE b.status
        WHEN 'DRIVER_ASSIGNED' THEN 'PICKUP_STARTED'
        WHEN 'PICKUP_STARTED' THEN 'PATIENT_PICKED_UP'
        WHEN 'PATIENT_PICKED_UP' THEN 'IN_TRANSIT'
        WHEN 'IN_TRANSIT' THEN 'ARRIVED'
        WHEN 'ARRIVED' THEN 'SERVICE_COMPLETED'
        ELSE NULL
    END;

    IF v_expected IS NULL OR v_expected <> p_next_status THEN
        RAISE EXCEPTION
            'Invalid driver transition from % to %',
            b.status,
            p_next_status;
    END IF;

    UPDATE public.bookings
    SET
        status = p_next_status,
        trip_started_at = CASE
            WHEN p_next_status = 'PICKUP_STARTED'
                THEN COALESCE(trip_started_at, now())
            ELSE trip_started_at
        END,
        patient_picked_up_at = CASE
            WHEN p_next_status = 'PATIENT_PICKED_UP'
                THEN COALESCE(patient_picked_up_at, now())
            ELSE patient_picked_up_at
        END,
        in_transit_at = CASE
            WHEN p_next_status = 'IN_TRANSIT'
                THEN COALESCE(in_transit_at, now())
            ELSE in_transit_at
        END,
        arrived_at = CASE
            WHEN p_next_status = 'ARRIVED'
                THEN COALESCE(arrived_at, now())
            ELSE arrived_at
        END,
        completed_at = CASE
            WHEN p_next_status = 'SERVICE_COMPLETED'
                THEN COALESCE(completed_at, now())
            ELSE completed_at
        END,
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    IF p_next_status = 'SERVICE_COMPLETED' THEN
        UPDATE public.drivers
        SET
            status = 'AVAILABLE',
            assigned_booking_id = NULL,
            assigned_ambulance_number = NULL,
            total_trips = COALESCE(total_trips, 0) + 1
        WHERE id = auth.uid();
    ELSE
        UPDATE public.drivers
        SET status = 'ON_TRIP'
        WHERE id = auth.uid();
    END IF;

    INSERT INTO public.audit_logs (
        user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value
    )
    SELECT
        auth.uid(),
        COALESCE(pr.full_name, pr.email, ''),
        public.app_role(),
        'Driver trip status changed',
        p_booking_id,
        'BOOKING',
        v_previous_status,
        p_next_status
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.driver_advance_booking(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_advance_booking(text, text) TO authenticated;


-- ============================================================================
-- 7. TEAM LEAD ALLOCATION
-- Customer acceptance is mandatory before allocation.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.allocate_booking(
    p_booking_id text,
    p_ambulance_id text,
    p_driver_id uuid,
    p_doctor_id uuid DEFAULT NULL,
    p_emt_id uuid DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    b public.bookings;
    a public.ambulances;
    d public.drivers;
    doc public.doctors;
    v_emt_name text;
BEGIN
    IF auth.uid() IS NULL
       OR public.app_role() NOT IN ('ADMIN','TEAM_LEAD') THEN
        RAISE EXCEPTION 'Only ADMIN or TEAM_LEAD may allocate';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found';
    END IF;

    IF b.status <> 'CUSTOMER_ACCEPTED' THEN
        RAISE EXCEPTION
            'Customer must accept the quotation before allocation. Current status: %',
            b.status;
    END IF;

    SELECT * INTO a
    FROM public.ambulances
    WHERE id = p_ambulance_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ambulance not found';
    END IF;

    IF a.status <> 'AVAILABLE' OR a.assigned_booking_id IS NOT NULL THEN
        RAISE EXCEPTION 'Ambulance is not available';
    END IF;

    IF a.category <> b.service_category THEN
        RAISE EXCEPTION 'Ambulance category does not match booking';
    END IF;

    IF b.req_oxygen AND NOT a.has_oxygen THEN
        RAISE EXCEPTION 'Selected ambulance lacks oxygen';
    END IF;

    IF b.req_icu AND NOT a.has_icu THEN
        RAISE EXCEPTION 'Selected ambulance lacks ICU capability';
    END IF;

    IF b.req_ventilator AND NOT a.has_ventilator THEN
        RAISE EXCEPTION 'Selected ambulance lacks ventilator capability';
    END IF;

    IF b.req_pediatric AND NOT a.has_pediatric_icu THEN
        RAISE EXCEPTION 'Selected ambulance lacks pediatric ICU capability';
    END IF;

    IF b.req_cardiac_monitor AND NOT a.has_cardiac_monitor THEN
        RAISE EXCEPTION 'Selected ambulance lacks cardiac monitor';
    END IF;

    IF b.req_stretcher AND NOT a.has_stretcher THEN
        RAISE EXCEPTION 'Selected ambulance lacks stretcher';
    END IF;

    IF b.req_wheelchair AND NOT a.has_wheelchair THEN
        RAISE EXCEPTION 'Selected ambulance lacks wheelchair';
    END IF;

    IF b.service_category = 'DEAD_BODY' AND NOT a.has_freezer THEN
        RAISE EXCEPTION 'Selected ambulance lacks mortuary freezer';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    IF d.status <> 'AVAILABLE' OR d.assigned_booking_id IS NOT NULL THEN
        RAISE EXCEPTION 'Driver is not available';
    END IF;

    IF NOT (
        b.service_category = ANY(
            COALESCE(d.supported_categories, ARRAY[]::text[])
        )
    ) THEN
        RAISE EXCEPTION
            'Driver does not support booking category %',
            b.service_category;
    END IF;

    IF p_doctor_id IS NOT NULL THEN
        SELECT * INTO doc
        FROM public.doctors
        WHERE id = p_doctor_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Doctor not found';
        END IF;

        IF doc.status <> 'AVAILABLE' OR doc.assigned_booking_id IS NOT NULL THEN
            RAISE EXCEPTION 'Doctor is not available';
        END IF;

        IF b.req_pediatric AND NOT doc.is_pediatric_capable THEN
            RAISE EXCEPTION 'Doctor is not pediatric capable';
        END IF;

        IF b.req_doctor
           AND b.req_doctor_specialization IS NOT NULL
           AND LOWER(doc.specialization) <> LOWER(b.req_doctor_specialization) THEN
            RAISE EXCEPTION 'Doctor specialization does not match booking';
        END IF;
    ELSIF b.req_doctor THEN
        RAISE EXCEPTION 'Doctor is required for this booking';
    END IF;

    IF p_emt_id IS NOT NULL THEN
        SELECT full_name INTO v_emt_name
        FROM public.profiles
        WHERE id = p_emt_id
          AND role = 'EMT';

        IF v_emt_name IS NULL THEN
            RAISE EXCEPTION 'EMT profile not found';
        END IF;
    ELSIF b.req_emt THEN
        RAISE EXCEPTION 'EMT is required for this booking';
    END IF;

    UPDATE public.ambulances
    SET
        status = 'ASSIGNED',
        assigned_booking_id = p_booking_id
    WHERE id = p_ambulance_id;

    UPDATE public.drivers
    SET
        status = 'ASSIGNED',
        assigned_booking_id = p_booking_id,
        assigned_ambulance_number = a.vehicle_number
    WHERE id = p_driver_id;

    IF p_doctor_id IS NOT NULL THEN
        UPDATE public.doctors
        SET
            status = 'ASSIGNED',
            assigned_booking_id = p_booking_id
        WHERE id = p_doctor_id;
    END IF;

    UPDATE public.bookings
    SET
        assigned_ambulance_id = p_ambulance_id,
        assigned_driver_id = p_driver_id,
        assigned_doctor_id = p_doctor_id,
        assigned_emt_id = p_emt_id,
        assigned_by_tl_id = auth.uid(),
        assigned_by_tl_name = (
            SELECT COALESCE(full_name, email, '')
            FROM public.profiles
            WHERE id = auth.uid()
        ),
        assigned_at = now(),
        driver_name = d.name,
        driver_phone = d.phone,
        ambulance_vehicle_number = a.vehicle_number,
        ambulance_name = a.name,
        doctor_name = CASE
            WHEN p_doctor_id IS NOT NULL THEN doc.name
            ELSE NULL
        END,
        emt_name = v_emt_name,
        status = 'ASSIGNED',
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    INSERT INTO public.audit_logs (
        user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value
    )
    SELECT
        auth.uid(),
        COALESCE(pr.full_name, pr.email, ''),
        public.app_role(),
        'Booking allocated',
        p_booking_id,
        'BOOKING',
        'CUSTOMER_ACCEPTED',
        JSONB_BUILD_OBJECT(
            'ambulance_id', p_ambulance_id,
            'driver_id', p_driver_id,
            'doctor_id', p_doctor_id,
            'emt_id', p_emt_id
        )::text
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.allocate_booking(text, text, uuid, uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.allocate_booking(text, text, uuid, uuid, uuid) TO authenticated;


-- ============================================================================
-- 8. ADMIN FLEET REGISTRATION
--
-- The Admin Fleet screen must write new ambulances to the canonical
-- public.ambulances table. Previously registration only modified the
-- in-memory AdminStore, so the fleet returned to zero after logout/re-login.
--
-- This RPC persists the ambulance in the canonical fleet table and makes the
-- new AVAILABLE vehicle visible to Team Lead hydration/dispatch.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.admin_register_ambulance(
    p_call_sign text,
    p_vehicle_number text,
    p_model text,
    p_subtype text,
    p_category text DEFAULT 'ROAD',
    p_base_station text DEFAULT NULL,
    p_has_oxygen boolean DEFAULT false,
    p_has_icu boolean DEFAULT false,
    p_has_ventilator boolean DEFAULT false,
    p_has_pediatric_icu boolean DEFAULT false,
    p_has_incubator boolean DEFAULT false,
    p_has_freezer boolean DEFAULT false,
    p_has_cardiac_monitor boolean DEFAULT true,
    p_has_stretcher boolean DEFAULT true
)
RETURNS public.ambulances
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ambulance public.ambulances;
    v_category text;
BEGIN

    IF auth.uid() IS NULL
       OR public.app_role() <> 'ADMIN' THEN
        RAISE EXCEPTION 'Only ADMIN may register ambulances';
    END IF;

    IF NULLIF(TRIM(COALESCE(p_call_sign, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Call Sign is required';
    END IF;

    IF NULLIF(TRIM(COALESCE(p_vehicle_number, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Vehicle/CAD Number is required';
    END IF;

    IF NULLIF(TRIM(COALESCE(p_model, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Vehicle model/platform is required';
    END IF;

    v_category := UPPER(TRIM(COALESCE(p_category, 'ROAD')));

    IF v_category NOT IN (
        'ROAD',
        'RAILWAY',
        'AIR',
        'DEAD_BODY'
    ) THEN
        RAISE EXCEPTION 'Invalid ambulance category: %', v_category;
    END IF;

    INSERT INTO public.ambulances (
        id,
        vehicle_number,
        name,
        category,
        subtype,
        model,
        base_station,
        status,
        has_oxygen,
        has_icu,
        has_ventilator,
        has_pediatric_icu,
        has_incubator,
        has_cardiac_monitor,
        has_stretcher,
        has_freezer,
        assigned_booking_id
    )
    VALUES (
        TRIM(p_call_sign),
        TRIM(p_vehicle_number),
        TRIM(p_call_sign),
        v_category,
        NULLIF(TRIM(COALESCE(p_subtype, '')), ''),
        NULLIF(TRIM(COALESCE(p_model, '')), ''),
        COALESCE(NULLIF(TRIM(COALESCE(p_base_station, '')), ''), 'UNASSIGNED'),
        COALESCE(NULLIF(TRIM(COALESCE(p_base_station, '')), ''), 'UNASSIGNED'),
        'AVAILABLE',
        COALESCE(p_has_oxygen, false),
        COALESCE(p_has_icu, false),
        COALESCE(p_has_ventilator, false),
        COALESCE(p_has_pediatric_icu, false),
        COALESCE(p_has_incubator, false),
        COALESCE(p_has_cardiac_monitor, true),
        COALESCE(p_has_stretcher, true),
        COALESCE(p_has_freezer, false),
        NULL
    )
    RETURNING *
    INTO v_ambulance;

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
        'Ambulance registered by Admin',
        NULL,
        'AMBULANCE',
        NULL,
        JSONB_BUILD_OBJECT(
            'ambulance_id', v_ambulance.id,
            'vehicle_number', v_ambulance.vehicle_number,
            'category', v_ambulance.category,
            'status', v_ambulance.status
        )::text
    FROM public.profiles pr
    WHERE pr.id = auth.uid();

    RETURN v_ambulance;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION
            'An ambulance with this Call Sign or Vehicle/CAD Number already exists';
END;
$$;

REVOKE ALL ON FUNCTION public.admin_register_ambulance(
    text,
    text,
    text,
    text,
    text,
    text,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean
) FROM public;

GRANT EXECUTE ON FUNCTION public.admin_register_ambulance(
    text,
    text,
    text,
    text,
    text,
    text,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean,
    boolean
) TO authenticated;

COMMIT;
