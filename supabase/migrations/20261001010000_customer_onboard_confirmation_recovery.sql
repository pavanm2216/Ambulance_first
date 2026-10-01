BEGIN;

ALTER TABLE public.bookings
    ADD COLUMN IF NOT EXISTS patient_onboard_confirmed_at timestamptz;

UPDATE public.bookings
SET patient_onboard_confirmed_at = COALESCE(
    patient_onboard_confirmed_at,
    patient_picked_up_at,
    in_transit_at,
    arrived_at,
    updated_at,
    now()
)
WHERE status::text IN (
    'IN_TRANSIT',
    'ARRIVED',
    'SERVICE_COMPLETED',
    'INVOICE_GENERATED',
    'COMPLETED'
);

CREATE OR REPLACE FUNCTION public.enforce_patient_onboard_before_transit()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF OLD.status::text = 'PATIENT_PICKED_UP'
       AND NEW.status::text = 'IN_TRANSIT'
       AND NEW.patient_onboard_confirmed_at IS NULL THEN
        RAISE EXCEPTION 'Customer must confirm patient onboard before transit';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS bookings_require_patient_onboard_before_transit
    ON public.bookings;

CREATE TRIGGER bookings_require_patient_onboard_before_transit
    BEFORE UPDATE OF status ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_patient_onboard_before_transit();

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

    IF upper(b.status::text) NOT IN (
        'PATIENT_PICKED_UP',
        'IN_TRANSIT',
        'ARRIVED'
    ) THEN
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
GRANT EXECUTE ON FUNCTION public.customer_confirm_patient_onboard(text)
    TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;