-- Ambulance First — Phase 5 compatibility gate
-- READ ONLY. Do NOT drop/replace policies from this script.
-- Run in Supabase SQL Editor and save ALL result sets.
--
-- Purpose: collect the exact live authorization/schema information required
-- before replacing the current permissive policies.

-- 1) Current RLS policy inventory.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles',
    'bookings',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs',
    'pricing_settings'
  )
order by tablename, policyname;

-- 2) RLS enabled/forced state.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'profiles',
    'bookings',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs',
    'pricing_settings'
  )
order by c.relname;

-- 3) Exact columns and nullability/defaults.
select
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'profiles',
    'bookings',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs',
    'pricing_settings'
  )
order by table_name, ordinal_position;

-- 4) Primary/unique/foreign/check constraints.
select
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name as referenced_table,
  ccu.column_name as referenced_column
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
  and tc.table_schema = kcu.table_schema
left join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
  and tc.table_schema = ccu.table_schema
where tc.table_schema = 'public'
  and tc.table_name in (
    'profiles',
    'bookings',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs',
    'pricing_settings'
  )
order by tc.table_name, tc.constraint_name, kcu.ordinal_position;

-- 5) Triggers that may already maintain history/audit/notifications.
select
  n.nspname as schema_name,
  c.relname as table_name,
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and n.nspname = 'public'
  and c.relname in (
    'profiles',
    'bookings',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs',
    'pricing_settings'
  )
order by c.relname, t.tgname;

-- 6) Public functions relevant to workflow/security.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type,
  p.prosecdef as security_definer,
  pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and (
    p.proname ilike '%booking%'
    or p.proname ilike '%audit%'
    or p.proname ilike '%role%'
    or p.proname ilike '%notification%'
    or p.proname ilike '%pricing%'
  )
order by p.proname, arguments;

-- 7) Existing role values currently stored in profiles.
select role, count(*) as profile_count
from public.profiles
group by role
order by role;
