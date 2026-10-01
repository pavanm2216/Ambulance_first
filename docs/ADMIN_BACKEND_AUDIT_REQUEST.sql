-- Run in the Supabase SQL Editor and send the result back.
-- This is READ-ONLY metadata inspection. It does not modify your database.

-- 1) Columns, types, defaults and nullability
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
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'bookings',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs'
  )
order by table_name, ordinal_position;

-- 2) Primary/unique/foreign/check constraints
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
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'bookings',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs'
  )
order by tc.table_name, tc.constraint_type, tc.constraint_name, kcu.ordinal_position;

-- 3) RLS status
select
  schemaname,
  tablename,
  rowsecurity,
  forcerowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles',
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'bookings',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs'
  )
order by tablename;

-- 4) RLS policies
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
    'ambulances',
    'drivers',
    'doctors',
    'customer_care',
    'bookings',
    'booking_status_history',
    'booking_vitals',
    'booking_doctor_assessments',
    'notifications',
    'audit_logs'
  )
order by tablename, policyname;
