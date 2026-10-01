-- READ-ONLY PHASE 5 COMPATIBILITY AUDIT
-- Run this in Supabase SQL Editor and save the output before changing RLS.

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
order by tc.table_name, tc.constraint_name, kcu.ordinal_position;
