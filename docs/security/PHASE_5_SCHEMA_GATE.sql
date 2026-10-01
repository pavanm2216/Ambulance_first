-- PHASE 5 SCHEMA GATE
-- READ ONLY. Safe to run in Supabase SQL Editor.
-- This query is intentionally non-destructive.

-- 1) Exact columns for workflow/clinical tables.
SELECT
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.udt_name,
    c.is_nullable,
    c.column_default
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN (
      'bookings',
      'ambulances',
      'booking_status_history',
      'booking_vitals',
      'booking_doctor_assessments',
      'notifications',
      'audit_logs',
      'customer_care',
      'doctors',
      'drivers'
  )
ORDER BY c.table_name, c.ordinal_position;

-- 2) Foreign keys for the same tables.
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
      'bookings',
      'ambulances',
      'booking_status_history',
      'booking_vitals',
      'booking_doctor_assessments',
      'notifications',
      'audit_logs',
      'customer_care',
      'doctors',
      'drivers'
  )
ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position;

-- 3) Check whether the pricing table has been created.
SELECT
    to_regclass('public.pricing_settings') AS pricing_settings_table;

-- 4) List triggers that can affect workflow writes.
SELECT
    event_object_table AS table_name,
    trigger_name,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN (
      'bookings',
      'ambulances',
      'booking_status_history',
      'booking_vitals',
      'booking_doctor_assessments',
      'notifications',
      'audit_logs',
      'customer_care',
      'doctors',
      'drivers'
  )
ORDER BY event_object_table, trigger_name;
