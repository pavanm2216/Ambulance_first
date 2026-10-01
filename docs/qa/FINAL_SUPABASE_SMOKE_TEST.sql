-- READ-ONLY smoke/inspection queries. Do not use this file to replace RLS policies.

-- 1. Required controlled functions.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'app_role',
    'create_customer_booking',
    'transition_booking_status',
    'submit_doctor_assessment',
    'prepare_booking_quotation',
    'respond_to_quotation',
    'allocate_booking',
    'record_booking_vitals'
  )
order by p.proname;

-- 2. Required tables.
select table_name
from information_schema.tables
where table_schema='public'
  and table_name in (
    'profiles','bookings','ambulances','drivers','doctors','customer_care',
    'booking_status_history','booking_vitals','booking_doctor_assessments',
    'notifications','audit_logs','pricing_settings'
  )
order by table_name;

-- 3. Current RLS policy inventory. Run before and after the final RLS cutover.
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname='public'
order by tablename, policyname;

-- 4. Confirm active profile role population.
select role, count(*) as profile_count
from public.profiles
group by role
order by role;

-- 5. Confirm operational resource identity alignment.
select 'drivers' as resource, count(*) as rows,
       count(*) filter (where id in (select id from public.profiles)) as profile_linked
from public.drivers
union all
select 'doctors', count(*),
       count(*) filter (where id in (select id from public.profiles))
from public.doctors
union all
select 'customer_care', count(*),
       count(*) filter (where id in (select id from public.profiles))
from public.customer_care;
