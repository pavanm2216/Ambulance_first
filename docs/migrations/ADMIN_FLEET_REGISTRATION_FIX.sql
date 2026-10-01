-- Ambulance First: Admin Fleet registration persistence
-- Run this standalone if the main workflow migration has already been applied.
-- It creates the server-side RPC used by the Admin Fleet registration form.

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

