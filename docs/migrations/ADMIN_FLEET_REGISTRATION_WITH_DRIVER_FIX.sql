-- ============================================================================
-- Ambulance First: Admin Fleet Registration + Primary Driver Pairing
--
-- Purpose:
--   1. Register an ambulance in public.ambulances.
--   2. Require selection of an existing AVAILABLE driver who is not already
--      paired with another ambulance.
--   3. Pair that driver to the new ambulance using
--      drivers.assigned_ambulance_number.
--   4. Initialize ambulances.current_location from base_station.
--   5. Keep the entire operation atomic: if driver validation or ambulance
--      insertion fails, neither resource is partially changed.
--
-- Apply after the existing Ambulance First workflow migrations.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Correct the legacy registration RPC so it no longer has an INSERT
--    target/value mismatch and satisfies current_location NOT NULL.
-- ---------------------------------------------------------------------------
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
    v_location text;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'ADMIN' THEN
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

    IF v_category NOT IN ('ROAD', 'RAILWAY', 'AIR', 'DEAD_BODY') THEN
        RAISE EXCEPTION 'Invalid ambulance category: %', v_category;
    END IF;

    v_location := COALESCE(
        NULLIF(TRIM(COALESCE(p_base_station, '')), ''),
        'UNASSIGNED'
    );

    INSERT INTO public.ambulances (
        id,
        vehicle_number,
        name,
        category,
        subtype,
        model,
        current_location,
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
        v_location,
        v_location,
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
    RETURNING * INTO v_ambulance;

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
        jsonb_build_object(
            'ambulance_id', v_ambulance.id,
            'vehicle_number', v_ambulance.vehicle_number,
            'category', v_ambulance.category,
            'current_location', v_ambulance.current_location,
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
    text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean
) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_register_ambulance(
    text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean
) TO authenticated;


-- ---------------------------------------------------------------------------
-- 2. Atomic Admin registration that pairs an EXISTING driver.
--
-- IMPORTANT:
--   This does NOT create another Driver account.
--   Step 4 of the Admin registration UI now selects an existing unallocated
--   driver from public.drivers.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_register_ambulance_with_driver(
    p_call_sign text,
    p_vehicle_number text,
    p_model text,
    p_subtype text,
    p_category text,
    p_base_station text,
    p_has_oxygen boolean,
    p_has_icu boolean,
    p_has_ventilator boolean,
    p_has_pediatric_icu boolean,
    p_has_incubator boolean,
    p_has_freezer boolean,
    p_has_cardiac_monitor boolean,
    p_has_stretcher boolean,
    p_driver_id uuid
)
RETURNS public.ambulances
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ambulance public.ambulances;
    v_driver public.drivers;
    v_category text;
    v_location text;
    v_admin_name text;
BEGIN
    -- -----------------------------------------------------------------------
    -- Admin authorization
    -- -----------------------------------------------------------------------
    IF auth.uid() IS NULL OR public.app_role() <> 'ADMIN' THEN
        RAISE EXCEPTION 'Only ADMIN may register and pair ambulances';
    END IF;

    -- -----------------------------------------------------------------------
    -- Basic validation
    -- -----------------------------------------------------------------------
    IF NULLIF(TRIM(COALESCE(p_call_sign, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Call Sign is required';
    END IF;

    IF NULLIF(TRIM(COALESCE(p_vehicle_number, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Vehicle/CAD Number is required';
    END IF;

    IF NULLIF(TRIM(COALESCE(p_model, '')), '') IS NULL THEN
        RAISE EXCEPTION 'Vehicle model/platform is required';
    END IF;

    IF p_driver_id IS NULL THEN
        RAISE EXCEPTION 'An available driver must be selected';
    END IF;

    v_category := UPPER(TRIM(COALESCE(p_category, 'ROAD')));

    IF v_category NOT IN ('ROAD', 'RAILWAY', 'AIR', 'DEAD_BODY') THEN
        RAISE EXCEPTION 'Invalid ambulance category: %', v_category;
    END IF;

    v_location := COALESCE(
        NULLIF(TRIM(COALESCE(p_base_station, '')), ''),
        'UNASSIGNED'
    );

    -- -----------------------------------------------------------------------
    -- Lock the driver so two Admin sessions cannot pair the same driver at
    -- the same time.
    -- -----------------------------------------------------------------------
    SELECT *
    INTO v_driver
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected driver was not found';
    END IF;

    IF UPPER(COALESCE(v_driver.status, '')) <> 'AVAILABLE' THEN
        RAISE EXCEPTION
            'Selected driver is not available. Current status: %',
            v_driver.status;
    END IF;

    IF NULLIF(TRIM(COALESCE(v_driver.assigned_ambulance_number, '')), '') IS NOT NULL THEN
        RAISE EXCEPTION
            'Selected driver is already allocated to ambulance %',
            v_driver.assigned_ambulance_number;
    END IF;

    -- -----------------------------------------------------------------------
    -- Insert the ambulance. current_location is required by the live schema.
    -- -----------------------------------------------------------------------
    INSERT INTO public.ambulances (
        id,
        vehicle_number,
        name,
        category,
        subtype,
        model,
        current_location,
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
        v_location,
        v_location,
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
    RETURNING * INTO v_ambulance;

    -- -----------------------------------------------------------------------
    -- Pair the existing driver with the newly registered ambulance.
    -- This is the source used by the Driver portal and Team Lead allocation
    -- workspace to identify the driver's primary ambulance.
    -- -----------------------------------------------------------------------
    UPDATE public.drivers
    SET assigned_ambulance_number = v_ambulance.vehicle_number
    WHERE id = p_driver_id;

    SELECT COALESCE(full_name, email, '')
    INTO v_admin_name
    FROM public.profiles
    WHERE id = auth.uid();

    -- -----------------------------------------------------------------------
    -- Audit both resources in one event.
    -- -----------------------------------------------------------------------
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
    VALUES (
        auth.uid(),
        COALESCE(v_admin_name, ''),
        'ADMIN',
        'Ambulance registered and primary driver paired',
        NULL,
        'AMBULANCE',
        NULL,
        jsonb_build_object(
            'ambulance_id', v_ambulance.id,
            'vehicle_number', v_ambulance.vehicle_number,
            'driver_id', v_driver.id,
            'driver_name', v_driver.name,
            'category', v_ambulance.category,
            'status', v_ambulance.status,
            'base_station', v_ambulance.base_station
        )::text
    );

    RETURN v_ambulance;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION
            'An ambulance with this Call Sign or Vehicle/CAD Number already exists';
END;
$$;

REVOKE ALL ON FUNCTION public.admin_register_ambulance_with_driver(
    text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,uuid
) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_register_ambulance_with_driver(
    text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,uuid
) TO authenticated;

COMMIT;
