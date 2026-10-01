-- Customer quotation read contract
--
-- Apply this after the controlled workflow and quotation migrations.
-- A Team Lead quotation is persisted on public.bookings in the q_* columns.
-- The customer feed must return those same canonical rows; otherwise a
-- QUOTATION_SENT booking has no price or quotation ID available to review.

BEGIN;

-- PostgreSQL cannot replace a function if its existing return type differs.
-- RESTRICT is intentional: the migration stops rather than removing an
-- unexpected dependent object.
DROP FUNCTION IF EXISTS public.get_customer_bookings();

CREATE OR REPLACE FUNCTION public.get_customer_bookings()
RETURNS SETOF public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'CUSTOMER' THEN
    RAISE EXCEPTION 'Customer authentication required';
  END IF;

  RETURN QUERY
  SELECT b.*
  FROM public.bookings b
  WHERE b.customer_id = auth.uid()
  ORDER BY b.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_customer_bookings() FROM public;
GRANT EXECUTE ON FUNCTION public.get_customer_bookings() TO authenticated;

-- The app also loads this feed for its quotation tab. Returning the canonical
-- booking rows keeps the price, quotation ID, and status consistent with the
-- booking feed without exposing any other customer's records.
DROP FUNCTION IF EXISTS public.get_customer_quotations();

CREATE OR REPLACE FUNCTION public.get_customer_quotations()
RETURNS SETOF public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'CUSTOMER' THEN
    RAISE EXCEPTION 'Customer authentication required';
  END IF;

  RETURN QUERY
  SELECT b.*
  FROM public.bookings b
  WHERE b.customer_id = auth.uid()
    AND b.quotation_id IS NOT NULL
  ORDER BY b.quotation_sent_at DESC NULLS LAST, b.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_customer_quotations() FROM public;
GRANT EXECUTE ON FUNCTION public.get_customer_quotations() TO authenticated;

-- Customer decision contract used by all Customer quotation screens.
-- This exact parameter list is intentional: PostgREST resolves RPCs by their
-- named arguments, so an older overload without p_accept cannot service the
-- Flutter request.
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
  v_next_status text;
  v_quote_status text;
BEGIN
  IF auth.uid() IS NULL OR public.app_role() <> 'CUSTOMER' THEN
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

  IF b.status <> 'QUOTATION_SENT' OR b.quotation_id IS NULL THEN
    RAISE EXCEPTION 'No sent quotation is awaiting a customer response';
  END IF;

  IF NOT p_accept AND NULLIF(TRIM(COALESCE(p_reason, '')), '') IS NULL THEN
    RAISE EXCEPTION 'A rejection reason is required';
  END IF;

  v_next_status := CASE WHEN p_accept THEN 'CUSTOMER_ACCEPTED' ELSE 'CUSTOMER_REJECTED' END;
  v_quote_status := CASE WHEN p_accept THEN 'ACCEPTED' ELSE 'REJECTED' END;

  UPDATE public.bookings
  SET quotation_status = v_quote_status,
      quotation_responded_at = now(),
      quotation_rejection_reason = CASE
        WHEN p_accept THEN NULL
        ELSE NULLIF(TRIM(p_reason), '')
      END,
      status = v_next_status,
      updated_at = now()
  WHERE id = b.id
  RETURNING * INTO b;

  RETURN b;
END;
$$;

REVOKE ALL ON FUNCTION public.respond_to_quotation(text, boolean, text) FROM public;
GRANT EXECUTE ON FUNCTION public.respond_to_quotation(text, boolean, text) TO authenticated;

COMMIT;
