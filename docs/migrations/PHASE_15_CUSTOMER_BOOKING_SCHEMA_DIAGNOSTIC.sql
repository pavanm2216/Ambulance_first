-- Schema-safe diagnostics for the customer booking creation path.
-- These queries intentionally do NOT reference customer_verified because it is not
-- a confirmed column in the current public.bookings schema.

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bookings'
ORDER BY ordinal_position;

SELECT
    p.oid::regprocedure AS function_signature,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'create_customer_booking';
