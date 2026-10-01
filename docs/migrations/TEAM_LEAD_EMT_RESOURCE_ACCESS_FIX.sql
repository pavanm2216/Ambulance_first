-- ============================================================================
-- Ambulance First
-- TEAM LEAD EMT RESOURCE ACCESS FIX
--
-- Problem:
--   Team Lead allocation reads EMTs directly from public.profiles.
--   profiles commonly has restrictive RLS because it contains authentication
--   profile data. Therefore a Team Lead can see the booking/doctor/driver
--   resources but receive zero EMT rows even though an EMT profile exists.
--
-- Fix:
--   Expose only the minimum EMT resource fields through a SECURITY DEFINER
--   RPC. The RPC is available only to ADMIN and TEAM_LEAD users.
--
-- Apply this migration in Supabase SQL Editor before testing Team Lead EMT
-- allocation.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_team_lead_emt_profiles()
RETURNS TABLE (
    id uuid,
    full_name text,
    email text,
    phone text,
    role text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id,
        COALESCE(p.full_name, '')::text AS full_name,
        COALESCE(p.email, '')::text AS email,
        COALESCE(p.phone, '')::text AS phone,
        p.role::text AS role
    FROM public.profiles p
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
      AND UPPER(COALESCE(p.role::text, '')) = 'EMT'
    ORDER BY COALESCE(p.full_name, p.email, '');
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_emt_profiles() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_emt_profiles() TO authenticated;

COMMIT;
