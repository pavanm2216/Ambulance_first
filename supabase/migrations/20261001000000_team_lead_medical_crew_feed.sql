BEGIN;

DROP FUNCTION IF EXISTS public.get_team_lead_emt_profiles();

CREATE FUNCTION public.get_team_lead_emt_profiles()
RETURNS TABLE (
    id uuid,
    full_name text,
    phone text,
    crew_type text,
    certification text,
    status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        crew.id,
        COALESCE(crew.full_name, '')::text,
        COALESCE(crew.phone, '')::text,
        COALESCE(crew.crew_type, '')::text,
        COALESCE(crew.certification, '')::text,
        COALESCE(crew.status::text, '')::text
    FROM public.medical_crew AS crew
    WHERE public.app_role() IN ('ADMIN', 'TEAM_LEAD')
    ORDER BY crew.status, crew.full_name;
$$;

REVOKE ALL ON FUNCTION public.get_team_lead_emt_profiles() FROM public;
GRANT EXECUTE ON FUNCTION public.get_team_lead_emt_profiles() TO authenticated;

COMMIT;