-- PHASE 5 SECURITY FOUNDATION
-- SAFE FOUNDATION ONLY.
-- This script creates role lookup helpers and does NOT change table RLS policies.
-- Review in Supabase SQL Editor before applying.
-- NEVER put a service-role key in Flutter.

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid()
  limit 1;
$$;

create or replace function public.is_app_role(expected_role text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select upper(coalesce(public.current_app_role(), '')) = upper(coalesce(expected_role, ''));
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_app_role('ADMIN');
$$;

revoke all on function public.current_app_role() from public;
revoke all on function public.is_app_role(text) from public;
revoke all on function public.is_admin() from public;

grant execute on function public.current_app_role() to authenticated;
grant execute on function public.is_app_role(text) to authenticated;
grant execute on function public.is_admin() to authenticated;
