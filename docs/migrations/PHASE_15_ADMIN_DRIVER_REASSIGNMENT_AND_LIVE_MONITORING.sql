-- Persist Admin reassignment of an active booking and its paired driver/unit.
-- Apply after PHASE_15_DRIVER_ARRIVAL_COMPLETION_AND_RESOURCE_RELEASE.sql.

BEGIN;

ALTER TABLE public.bookings
    ADD COLUMN IF NOT EXISTS driver_name text,
    ADD COLUMN IF NOT EXISTS driver_phone text,
    ADD COLUMN IF NOT EXISTS ambulance_vehicle_number text,
    ADD COLUMN IF NOT EXISTS ambulance_name text,
    ADD COLUMN IF NOT EXISTS doctor_name text,
    ADD COLUMN IF NOT EXISTS emt_name text,
    ADD COLUMN IF NOT EXISTS geo_lat numeric,
    ADD COLUMN IF NOT EXISTS geo_lng numeric,
    ADD COLUMN IF NOT EXISTS geo_speed_kmh numeric NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS geo_heading numeric NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS geo_last_ping timestamptz;

UPDATE public.bookings b
SET driver_name = COALESCE(
        NULLIF(b.driver_name, ''),
        (SELECT COALESCE(
            to_jsonb(d)->>'name',
            to_jsonb(d)->>'full_name',
            to_jsonb(d)->>'display_name'
        ) FROM public.drivers d WHERE d.id = b.assigned_driver_id)
    ),
    driver_phone = COALESCE(
        NULLIF(b.driver_phone, ''),
        (SELECT COALESCE(
            to_jsonb(d)->>'phone',
            to_jsonb(d)->>'mobile',
            to_jsonb(d)->>'phone_number'
        ) FROM public.drivers d WHERE d.id = b.assigned_driver_id)
    ),
    ambulance_vehicle_number = COALESCE(
        NULLIF(b.ambulance_vehicle_number, ''),
        (SELECT a.vehicle_number FROM public.ambulances a WHERE a.id = b.assigned_ambulance_id)
    ),
    ambulance_name = COALESCE(
        NULLIF(b.ambulance_name, ''),
        (SELECT COALESCE(
            to_jsonb(a)->>'name',
            to_jsonb(a)->>'call_sign',
            to_jsonb(a)->>'vehicle_name'
        ) FROM public.ambulances a WHERE a.id = b.assigned_ambulance_id)
    ),
    doctor_name = COALESCE(
        NULLIF(b.doctor_name, ''),
        (SELECT COALESCE(
            to_jsonb(doc)->>'name',
            to_jsonb(doc)->>'full_name',
            to_jsonb(doc)->>'display_name'
        ) FROM public.doctors doc WHERE doc.id = b.assigned_doctor_id)
    )
WHERE b.assigned_driver_id IS NOT NULL
   OR b.assigned_doctor_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.admin_reassign_booking_resources(
    p_booking_id text,
    p_ambulance_id text,
    p_driver_id uuid
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
    old_driver_id uuid;
    old_ambulance_id text;
    v_has_driver_booking_link boolean;
    v_has_ambulance_booking_link boolean;
    v_driver_name text;
    v_driver_phone text;
    v_ambulance_name text;
    v_doctor_name text;
    v_service_category text;
    v_ambulance_category text;
    v_driver_paired_ambulance text;
    v_req_oxygen boolean;
    v_req_icu boolean;
    v_req_ventilator boolean;
    v_req_pediatric boolean;
    v_req_cardiac_monitor boolean;
    v_req_stretcher boolean;
    v_req_wheelchair boolean;
BEGIN
    IF auth.uid() IS NULL OR public.app_role() <> 'ADMIN' THEN
        RAISE EXCEPTION 'Admin authentication required';
    END IF;

    SELECT * INTO b
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found';
    END IF;
    IF b.status NOT IN (
        'ASSIGNED', 'DRIVER_ASSIGNED', 'PICKUP_STARTED',
        'PATIENT_PICKED_UP', 'IN_TRANSIT', 'ARRIVED'
    ) THEN
        RAISE EXCEPTION 'Only an active assignment can be reassigned';
    END IF;

    v_service_category := COALESCE(
        to_jsonb(b)->>'service_category',
        to_jsonb(b)->>'category',
        'ROAD'
    );
    v_req_oxygen := lower(coalesce(
        to_jsonb(b)->>'req_oxygen',
        to_jsonb(b)->>'oxygen_required',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_icu := lower(coalesce(
        to_jsonb(b)->>'req_icu',
        to_jsonb(b)->>'icu_required',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_ventilator := lower(coalesce(
        to_jsonb(b)->>'req_ventilator',
        to_jsonb(b)->>'ventilator_required',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_pediatric := lower(coalesce(
        to_jsonb(b)->>'req_pediatric',
        to_jsonb(b)->>'pediatric_required',
        to_jsonb(b)->>'req_pediatric_icu',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_cardiac_monitor := lower(coalesce(
        to_jsonb(b)->>'req_cardiac_monitor',
        to_jsonb(b)->>'cardiac_monitor_required',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_stretcher := lower(coalesce(
        to_jsonb(b)->>'req_stretcher',
        to_jsonb(b)->>'stretcher_required',
        'false'
    )) IN ('true', '1', 'yes');
    v_req_wheelchair := lower(coalesce(
        to_jsonb(b)->>'req_wheelchair',
        to_jsonb(b)->>'wheelchair_required',
        'false'
    )) IN ('true', '1', 'yes');
    old_driver_id := b.assigned_driver_id;
    old_ambulance_id := b.assigned_ambulance_id::text;

    SELECT * INTO a
    FROM public.ambulances
    WHERE id::text = p_ambulance_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ambulance not found';
    END IF;
    v_ambulance_name := COALESCE(
        to_jsonb(a)->>'name',
        to_jsonb(a)->>'call_sign',
        to_jsonb(a)->>'vehicle_name',
        a.vehicle_number
    );
    IF a.status <> 'AVAILABLE'
       AND old_ambulance_id IS DISTINCT FROM p_ambulance_id THEN
        RAISE EXCEPTION 'Selected ambulance is already assigned to another booking';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM public.bookings other_booking
        WHERE other_booking.id <> p_booking_id
          AND other_booking.assigned_ambulance_id::text = p_ambulance_id
          AND other_booking.status IN (
              'ASSIGNED', 'DRIVER_ASSIGNED', 'PICKUP_STARTED',
              'PATIENT_PICKED_UP', 'IN_TRANSIT', 'ARRIVED'
          )
    ) THEN
        RAISE EXCEPTION 'Selected ambulance is assigned to another active booking';
    END IF;
    v_ambulance_category := COALESCE(
        to_jsonb(a)->>'category',
        to_jsonb(a)->>'service_category'
    );
    IF v_ambulance_category IS NOT NULL
       AND v_ambulance_category <> v_service_category THEN
        RAISE EXCEPTION 'Ambulance category does not match booking';
    END IF;
    IF v_req_oxygen AND lower(coalesce(
        to_jsonb(a)->>'has_oxygen', to_jsonb(a)->>'oxygen', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks oxygen';
    END IF;
    IF v_req_icu AND lower(coalesce(
        to_jsonb(a)->>'has_icu', to_jsonb(a)->>'icu', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks ICU capability';
    END IF;
    IF v_req_ventilator AND lower(coalesce(
        to_jsonb(a)->>'has_ventilator', to_jsonb(a)->>'ventilator', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks ventilator capability';
    END IF;
    IF v_req_pediatric AND lower(coalesce(
        to_jsonb(a)->>'has_pediatric_icu',
        to_jsonb(a)->>'has_picu',
        to_jsonb(a)->>'picu',
        'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks pediatric ICU capability';
    END IF;
    IF v_req_cardiac_monitor AND lower(coalesce(
        to_jsonb(a)->>'has_cardiac_monitor', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks cardiac monitor';
    END IF;
    IF v_req_stretcher AND lower(coalesce(
        to_jsonb(a)->>'has_stretcher', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks stretcher';
    END IF;
    IF v_req_wheelchair AND lower(coalesce(
        to_jsonb(a)->>'has_wheelchair', 'false'
    )) NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks wheelchair';
    END IF;
    IF v_service_category = 'DEAD_BODY'
       AND lower(coalesce(to_jsonb(a)->>'has_freezer', 'false'))
           NOT IN ('true', '1', 'yes') THEN
        RAISE EXCEPTION 'Selected ambulance lacks mortuary freezer';
    END IF;

    SELECT * INTO d
    FROM public.drivers
    WHERE id = p_driver_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;
    v_driver_name := COALESCE(
        to_jsonb(d)->>'name',
        to_jsonb(d)->>'full_name',
        to_jsonb(d)->>'display_name',
        'Driver'
    );
    v_driver_phone := COALESCE(
        to_jsonb(d)->>'phone',
        to_jsonb(d)->>'mobile',
        to_jsonb(d)->>'phone_number',
        ''
    );
    IF upper(coalesce(d.status, '')) NOT IN ('AVAILABLE', 'ON_DUTY')
       AND old_driver_id IS DISTINCT FROM p_driver_id THEN
        RAISE EXCEPTION 'Selected driver is already assigned to another booking';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM public.bookings other_booking
        WHERE other_booking.id <> p_booking_id
          AND other_booking.assigned_driver_id = p_driver_id
          AND other_booking.status IN (
              'ASSIGNED', 'DRIVER_ASSIGNED', 'PICKUP_STARTED',
              'PATIENT_PICKED_UP', 'IN_TRANSIT', 'ARRIVED'
          )
    ) THEN
        RAISE EXCEPTION 'Selected driver is assigned to another active booking';
    END IF;
    IF jsonb_typeof(to_jsonb(d)->'supported_categories') = 'array'
       AND jsonb_array_length(to_jsonb(d)->'supported_categories') > 0
       AND NOT (to_jsonb(d)->'supported_categories' ? v_service_category) THEN
        RAISE EXCEPTION 'Driver does not support booking category %', v_service_category;
    END IF;
    v_driver_paired_ambulance := COALESCE(
        to_jsonb(d)->>'assigned_ambulance_number',
        to_jsonb(d)->>'assigned_vehicle'
    );
    IF nullif(trim(coalesce(v_driver_paired_ambulance, '')), '') IS NOT NULL
       AND lower(trim(v_driver_paired_ambulance)) <> lower(trim(a.vehicle_number)) THEN
        RAISE EXCEPTION 'Selected driver is paired with ambulance %, choose that ambulance',
            v_driver_paired_ambulance;
    END IF;
    IF EXISTS (
        SELECT 1
        FROM public.drivers paired
        WHERE paired.id <> p_driver_id
                    AND lower(trim(coalesce(to_jsonb(paired)->>'assigned_ambulance_number', ''))) =
              lower(trim(coalesce(a.vehicle_number, '')))
    ) THEN
        RAISE EXCEPTION 'Selected ambulance primary driver is assigned to another booking';
    END IF;

    IF old_driver_id IS NOT NULL AND old_driver_id <> p_driver_id THEN
        UPDATE public.drivers SET status = 'AVAILABLE'
        WHERE id = old_driver_id;

        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'drivers'
              AND column_name = 'assigned_booking_id'
        ) INTO v_has_driver_booking_link;
        IF v_has_driver_booking_link THEN
            EXECUTE 'UPDATE public.drivers SET assigned_booking_id = NULL
                     WHERE id = $1 AND assigned_booking_id::text = $2'
            USING old_driver_id, p_booking_id;
        END IF;

        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'drivers'
              AND column_name = 'assigned_ambulance_number'
        ) THEN
            EXECUTE 'UPDATE public.drivers SET assigned_ambulance_number = NULL
                     WHERE id = $1 AND lower(trim(assigned_ambulance_number)) = lower(trim($2))'
            USING old_driver_id, b.ambulance_vehicle_number;
        END IF;
    END IF;

    IF old_ambulance_id IS NOT NULL
       AND old_ambulance_id <> p_ambulance_id THEN
        UPDATE public.ambulances SET status = 'AVAILABLE'
        WHERE id::text = old_ambulance_id;

        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'ambulances'
              AND column_name = 'assigned_booking_id'
        ) INTO v_has_ambulance_booking_link;
        IF v_has_ambulance_booking_link THEN
            EXECUTE 'UPDATE public.ambulances SET assigned_booking_id = NULL
                     WHERE id::text = $1 AND assigned_booking_id::text = $2'
            USING old_ambulance_id, p_booking_id;
        END IF;
    END IF;

    UPDATE public.ambulances SET status = 'ASSIGNED'
    WHERE id::text = p_ambulance_id;
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'ambulances'
          AND column_name = 'assigned_booking_id'
    ) INTO v_has_ambulance_booking_link;
    IF v_has_ambulance_booking_link THEN
        EXECUTE 'UPDATE public.ambulances SET assigned_booking_id = $1 WHERE id::text = $2'
        USING p_booking_id, p_ambulance_id;
    END IF;

    UPDATE public.drivers
    SET status = CASE
            WHEN b.status IN ('ASSIGNED', 'DRIVER_ASSIGNED') THEN 'ASSIGNED'
            ELSE 'ON_TRIP'
        END
    WHERE id = p_driver_id;
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'drivers'
          AND column_name = 'assigned_booking_id'
    ) INTO v_has_driver_booking_link;
    IF v_has_driver_booking_link THEN
        EXECUTE 'UPDATE public.drivers SET assigned_booking_id = $1 WHERE id = $2'
        USING p_booking_id, p_driver_id;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'drivers'
          AND column_name = 'assigned_ambulance_number'
    ) THEN
        EXECUTE 'UPDATE public.drivers SET assigned_ambulance_number = $1 WHERE id = $2'
        USING a.vehicle_number, p_driver_id;
    END IF;

    IF b.assigned_doctor_id IS NOT NULL THEN
        SELECT * INTO doc FROM public.doctors WHERE id = b.assigned_doctor_id;
        v_doctor_name := COALESCE(
            to_jsonb(doc)->>'name',
            to_jsonb(doc)->>'full_name',
            to_jsonb(doc)->>'display_name'
        );
    END IF;

    UPDATE public.bookings
    SET assigned_ambulance_id = a.id,
        assigned_driver_id = d.id,
        driver_name = v_driver_name,
        driver_phone = v_driver_phone,
        ambulance_vehicle_number = a.vehicle_number,
        ambulance_name = v_ambulance_name,
        doctor_name = COALESCE(NULLIF(doctor_name, ''), v_doctor_name),
        geo_lat = NULL,
        geo_lng = NULL,
        geo_speed_kmh = 0,
        geo_heading = 0,
        geo_last_ping = NULL,
        updated_at = now()
    WHERE id = p_booking_id
    RETURNING * INTO b;

    IF to_regclass('public.audit_logs') IS NOT NULL THEN
        INSERT INTO public.audit_logs (
            user_id, user_name, user_role, action, booking_id, entity_type,
            previous_value, new_value
        )
        SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
               'Active booking resources reassigned', b.id, 'BOOKING',
               jsonb_build_object(
                   'driver_id', old_driver_id,
                   'ambulance_id', old_ambulance_id
               )::text,
               jsonb_build_object(
                   'driver_id', d.id,
                   'driver_name', v_driver_name,
                   'ambulance_id', a.id,
                   'ambulance_number', a.vehicle_number
               )::text
        FROM public.profiles pr
        WHERE pr.id = auth.uid();
    END IF;

    RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_reassign_booking_resources(text, text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_reassign_booking_resources(text, text, uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;