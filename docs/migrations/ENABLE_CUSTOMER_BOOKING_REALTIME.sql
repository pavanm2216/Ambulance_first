-- Enables booking-row Realtime events used by the customer active-trip screen.
-- Safe to run repeatedly. This does not alter RLS policies or expose a new
-- table: Realtime delivery continues to obey the existing bookings SELECT RLS.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication
    WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'bookings'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings';
  END IF;
END;
$$;
