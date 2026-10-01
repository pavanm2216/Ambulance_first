-- Driver-to-customer live-tracking repair
--
-- Apply this AFTER TEAM_LEAD_LIVE_OPERATIONS_AND_AUTO_TRIP.sql and AFTER
-- FIX_DRIVER_PORTAL_CANONICAL_ID_CONTRACT.sql. It deliberately replaces their
-- overlapping Driver RPCs: earlier versions referenced columns that are not
-- present in this production schema (notably drivers.total_trips and
-- drivers.assigned_booking_id).
--
-- Required, verified schema contract:
--   bookings.assigned_driver_id = drivers.id
--   drivers.profile_id          = auth.uid()
--   bookings.geo_*              = canonical public live telemetry

BEGIN;

-- Fail before replacing functions if a required canonical column is absent.
DO $$
DECLARE
  v_missing text;
BEGIN
  SELECT string_agg(format('%s.%s', required.table_name, required.column_name), ', ')
  INTO v_missing
  FROM (VALUES
    ('drivers', 'id'), ('drivers', 'profile_id'), ('drivers', 'status'),
    ('bookings', 'id'), ('bookings', 'assigned_driver_id'),
    ('bookings', 'status'), ('bookings', 'geo_lat'), ('bookings', 'geo_lng'),
    ('bookings', 'geo_speed_kmh'), ('bookings', 'geo_heading'),
    ('bookings', 'geo_last_ping'), ('bookings', 'updated_at'),
    ('bookings', 'pickup_lat'), ('bookings', 'pickup_lng'),
    ('bookings', 'destination_lat'), ('bookings', 'destination_lng'),
    ('bookings', 'trip_started_at'), ('bookings', 'patient_picked_up_at'),
    ('bookings', 'in_transit_at'), ('bookings', 'arrived_at'),
    ('bookings', 'completed_at')
  ) AS required(table_name, column_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.table_name = required.table_name
      AND c.column_name = required.column_name
  );

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Cannot install Driver tracking RPCs. Missing required columns: %', v_missing;
  END IF;
END;
$$;

-- GPS-based state changes. Only the authenticated driver assigned to the
-- booking can invoke this routine; it does not treat a profile UUID as a
-- drivers.id value.
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
  d public.drivers;
  v_next text;
  v_pickup_distance_km numeric;
  v_destination_distance_km numeric;
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
    RAISE EXCEPTION 'Driver authentication required';
  END IF;
  IF p_latitude NOT BETWEEN -90 AND 90 OR p_longitude NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'Valid driver latitude and longitude are required';
  END IF;

  SELECT * INTO d FROM public.drivers
  WHERE profile_id = auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Driver resource not found'; END IF;

  SELECT * INTO b FROM public.bookings
  WHERE id = p_booking_id AND assigned_driver_id = d.id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Booking is not assigned to current driver'; END IF;

  v_next := b.status;
  IF b.pickup_lat IS NOT NULL AND b.pickup_lng IS NOT NULL THEN
    v_pickup_distance_km := 6371.0088 * 2 * ASIN(SQRT(
      POWER(SIN(RADIANS(p_latitude - b.pickup_lat) / 2), 2) +
      COS(RADIANS(b.pickup_lat)) * COS(RADIANS(p_latitude)) *
      POWER(SIN(RADIANS(p_longitude - b.pickup_lng) / 2), 2)
    ));
  END IF;
  IF b.destination_lat IS NOT NULL AND b.destination_lng IS NOT NULL THEN
    v_destination_distance_km := 6371.0088 * 2 * ASIN(SQRT(
      POWER(SIN(RADIANS(p_latitude - b.destination_lat) / 2), 2) +
      COS(RADIANS(b.destination_lat)) * COS(RADIANS(p_latitude)) *
      POWER(SIN(RADIANS(p_longitude - b.destination_lng) / 2), 2)
    ));
  END IF;

  -- START PICKUP EN ROUTE is an explicit Driver action. GPS must not advance
  -- ASSIGNED/DRIVER_ASSIGNED on its own and race that button.
  IF b.status = 'PICKUP_STARTED' AND v_pickup_distance_km IS NOT NULL
     AND v_pickup_distance_km <= 0.15 THEN
    v_next := 'PATIENT_PICKED_UP';
  ELSIF b.status = 'PATIENT_PICKED_UP'
     AND (v_pickup_distance_km IS NULL OR v_pickup_distance_km > 0.20) THEN
    v_next := 'IN_TRANSIT';
  ELSIF b.status = 'IN_TRANSIT' AND v_destination_distance_km IS NOT NULL
     AND v_destination_distance_km <= 0.15 THEN
    v_next := 'ARRIVED';
  END IF;

  IF v_next <> b.status THEN
    UPDATE public.bookings
    SET status = v_next,
        patient_picked_up_at = CASE WHEN v_next = 'PATIENT_PICKED_UP'
          THEN COALESCE(patient_picked_up_at, now()) ELSE patient_picked_up_at END,
        in_transit_at = CASE WHEN v_next = 'IN_TRANSIT'
          THEN COALESCE(in_transit_at, now()) ELSE in_transit_at END,
        arrived_at = CASE WHEN v_next = 'ARRIVED'
          THEN COALESCE(arrived_at, now()) ELSE arrived_at END,
        updated_at = now()
    WHERE id = b.id
    RETURNING * INTO b;
  END IF;
  RETURN b;
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
  IF p_latitude NOT BETWEEN -90 AND 90 OR p_longitude NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'Valid driver latitude and longitude are required';
  END IF;

  SELECT * INTO d FROM public.drivers
  WHERE id = p_driver_id AND profile_id = auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Driver resource does not belong to authenticated user'; END IF;

  v_booking_id := NULLIF(TRIM(p_booking_id), '');
  IF v_booking_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.bookings
    WHERE id = v_booking_id AND assigned_driver_id = d.id
  ) THEN
    RAISE EXCEPTION 'Booking is not assigned to current driver';
  END IF;

  -- This legacy convenience column is optional. Booking geo_* is mandatory
  -- and is the only telemetry source read by Customer, Team Lead and Admin.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'drivers'
      AND column_name = 'current_location'
  ) THEN
    EXECUTE 'UPDATE public.drivers SET current_location = $1 WHERE id = $2'
    USING CONCAT(ROUND(p_latitude, 6), ', ', ROUND(p_longitude, 6)), d.id;
    SELECT * INTO d FROM public.drivers WHERE id = p_driver_id;
  END IF;

  IF v_booking_id IS NOT NULL THEN
    UPDATE public.bookings
    SET geo_lat = p_latitude,
        geo_lng = p_longitude,
        geo_speed_kmh = GREATEST(0, COALESCE(p_speed_kmh, 0)),
        geo_heading = COALESCE(p_heading, 0),
        geo_last_ping = now(),
        updated_at = now()
    WHERE id = v_booking_id AND assigned_driver_id = d.id;

    PERFORM public.sync_trip_status_from_driver_location(
      v_booking_id, p_latitude, p_longitude
    );
  END IF;

  -- Location history is useful but optional: it cannot prevent canonical
  -- booking telemetry from being saved if this table has not been deployed.
  IF to_regclass('public.driver_location_pings') IS NOT NULL THEN
    BEGIN
      INSERT INTO public.driver_location_pings (
        driver_id, booking_id, latitude, longitude, accuracy_meters,
        speed_kmh, heading, captured_at
      ) VALUES (
        d.id, v_booking_id, p_latitude, p_longitude,
        GREATEST(0, COALESCE(p_accuracy_meters, 0)),
        GREATEST(0, COALESCE(p_speed_kmh, 0)), COALESCE(p_heading, 0), now()
      );
    EXCEPTION WHEN undefined_table OR undefined_column THEN
      NULL;
    END;
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
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'DRIVER' THEN
    RAISE EXCEPTION 'Driver authentication required';
  END IF;
  SELECT * INTO d FROM public.drivers WHERE profile_id = auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Driver resource not found'; END IF;
  SELECT * INTO b FROM public.bookings
  WHERE id = p_booking_id AND assigned_driver_id = d.id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Booking is not assigned to current driver'; END IF;

  IF p_accept AND b.status = 'DRIVER_ASSIGNED' THEN
    UPDATE public.drivers SET status = 'ON_TRIP' WHERE id = d.id;
    RETURN b;
  END IF;
  IF b.status <> 'ASSIGNED' THEN
    RAISE EXCEPTION 'Booking is not awaiting driver acceptance';
  END IF;

  v_next := CASE WHEN p_accept THEN 'DRIVER_ASSIGNED' ELSE 'DRIVER_REJECTED' END;
  UPDATE public.bookings SET status = v_next, updated_at = now()
  WHERE id = b.id RETURNING * INTO b;
  UPDATE public.drivers
  SET status = CASE WHEN p_accept THEN 'ON_TRIP' ELSE 'AVAILABLE' END
  WHERE id = d.id;

  BEGIN
    IF to_regclass('public.audit_logs') IS NOT NULL THEN
      INSERT INTO public.audit_logs (
        user_id, user_name, user_role, action, booking_id, entity_type,
        previous_value, new_value
      )
      SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
        CASE WHEN p_accept THEN 'Driver accepted assignment' ELSE 'Driver rejected assignment' END,
        b.id, 'BOOKING', 'ASSIGNED', v_next
      FROM public.profiles pr WHERE pr.id = auth.uid();
    END IF;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;
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
  WHERE id = p_booking_id AND assigned_driver_id = d.id FOR UPDATE;
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

  -- No total_trips, assigned_booking_id, or assigned_ambulance_number exists
  -- on the canonical drivers table.
  UPDATE public.drivers
  SET status = CASE WHEN p_next_status = 'SERVICE_COMPLETED' THEN 'AVAILABLE' ELSE 'ON_TRIP' END
  WHERE id = d.id;

  IF p_next_status = 'SERVICE_COMPLETED' AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ambulances'
      AND column_name = 'assigned_booking_id'
  ) THEN
    EXECUTE 'UPDATE public.ambulances
             SET status = ''AVAILABLE'', assigned_booking_id = NULL
             WHERE assigned_booking_id = $1'
    USING b.id;
  END IF;

  BEGIN
    IF to_regclass('public.audit_logs') IS NOT NULL THEN
      INSERT INTO public.audit_logs (
        user_id, user_name, user_role, action, booking_id, entity_type,
        previous_value, new_value
      )
      SELECT auth.uid(), COALESCE(pr.full_name, pr.email, ''), public.app_role(),
        'Driver trip status changed', b.id, 'BOOKING', v_previous, p_next_status
      FROM public.profiles pr WHERE pr.id = auth.uid();
    END IF;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;
  RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_trip_status_from_driver_location(text, numeric, numeric) FROM public;
GRANT EXECUTE ON FUNCTION public.sync_trip_status_from_driver_location(text, numeric, numeric) TO authenticated;
REVOKE ALL ON FUNCTION public.publish_driver_location(uuid, numeric, numeric, text, numeric, numeric, numeric) FROM public;
GRANT EXECUTE ON FUNCTION public.publish_driver_location(uuid, numeric, numeric, text, numeric, numeric, numeric) TO authenticated;
REVOKE ALL ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_respond_to_assignment(text, boolean, text) TO authenticated;
REVOKE ALL ON FUNCTION public.driver_advance_booking(text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.driver_advance_booking(text, text) TO authenticated;

COMMIT;
