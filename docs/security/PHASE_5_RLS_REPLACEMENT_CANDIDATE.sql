-- PHASE 5 RLS REPLACEMENT CANDIDATE
-- Generated from the audited policy inventory + verified foreign keys.
-- STATUS: REVIEW / DO NOT APPLY UNTIL BACKUP + compatibility verification.
--
-- This script deliberately does NOT create broad client UPDATE policies for
-- bookings, audit logs, status history, vitals, or assessments. Those writes
-- should move behind controlled workflow operations after the existing React
-- write paths are verified.
--
-- IMPORTANT: PostgreSQL PERMISSIVE policies are OR'ed. Therefore the existing
-- *_open policies must be removed in the same transaction as their replacements.
-- Do not execute piecemeal.

begin;

-- ---------------------------------------------------------------------------
-- 0. Role helpers
-- ---------------------------------------------------------------------------

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role from public.profiles p where p.id = auth.uid() limit 1;
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

-- ---------------------------------------------------------------------------
-- 1. Remove only the audited broad/open policies.
-- ---------------------------------------------------------------------------

drop policy if exists ambulances_open on public.ambulances;
drop policy if exists audit_logs_open on public.audit_logs;
drop policy if exists assessments_open on public.booking_doctor_assessments;
drop policy if exists status_history_open on public.booking_status_history;
drop policy if exists vitals_open on public.booking_vitals;
drop policy if exists bookings_open on public.bookings;
drop policy if exists customer_care_open on public.customer_care;
drop policy if exists doctors_open on public.doctors;
drop policy if exists drivers_open on public.drivers;
drop policy if exists notifications_open on public.notifications;
drop policy if exists profiles_open on public.profiles;
drop policy if exists profiles_read_all on public.profiles;

-- Remove legacy broad resource policies whose predicates were also too broad.
drop policy if exists "Allow insert for authenticated" on public.customer_care;
drop policy if exists "Allow read for authenticated" on public.customer_care;
drop policy if exists "Allow insert for authenticated" on public.doctors;
drop policy if exists "Allow read for authenticated" on public.doctors;
drop policy if exists "Allow update own row" on public.doctors;
drop policy if exists doctors_read on public.doctors;
drop policy if exists doctors_write on public.doctors;
drop policy if exists "Allow insert for authenticated" on public.drivers;
drop policy if exists "Allow read for authenticated" on public.drivers;
drop policy if exists "Allow update own row" on public.drivers;
drop policy if exists drivers_read on public.drivers;
drop policy if exists drivers_write on public.drivers;

-- ---------------------------------------------------------------------------
-- 2. Profiles
-- ---------------------------------------------------------------------------

create policy profiles_select_own_or_admin
on public.profiles for select to authenticated
using (auth.uid() = id or public.is_admin());

-- Profile UPDATE is intentionally withheld. RLS is row-level, so a generic
-- own-row UPDATE policy could also allow a user to change `role`. Use a
-- controlled backend operation for profile edits.

-- Profile creation is intentionally backend-controlled. Do not expose a
-- client INSERT policy for arbitrary role assignment.

-- ---------------------------------------------------------------------------
-- 3. Bookings
-- ---------------------------------------------------------------------------

create policy bookings_select_customer_or_operations
on public.bookings for select to authenticated
using (
  customer_id = auth.uid()
  or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
  or assigned_driver_id = auth.uid()
  or assigned_doctor_id = auth.uid()
  or assigned_emt_id = auth.uid()
);

create policy bookings_insert_customer_own
on public.bookings for insert to authenticated
with check (
  customer_id = auth.uid()
  and public.current_app_role() = 'CUSTOMER'
);

-- No general client UPDATE/DELETE policy. Workflow mutations should be
-- implemented through controlled backend operations after compatibility review.

-- ---------------------------------------------------------------------------
-- 4. Ambulances
-- ---------------------------------------------------------------------------

create policy ambulances_select_operations
on public.ambulances for select to authenticated
using (public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD','DRIVER'));

-- Writes intentionally withheld until exact ambulance constraints and the
-- secure Admin write contract are verified.

-- ---------------------------------------------------------------------------
-- 5. Drivers
-- ---------------------------------------------------------------------------

create policy drivers_select_operations_or_self
on public.drivers for select to authenticated
using (
  id = auth.uid()
  or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
);

-- Driver writes remain backend-controlled so assignment/status/rating fields
-- cannot be modified by the client simply because the row belongs to the user.

-- ---------------------------------------------------------------------------
-- 6. Doctors
-- ---------------------------------------------------------------------------

create policy doctors_select_operations_or_self
on public.doctors for select to authenticated
using (
  id = auth.uid()
  or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
);

-- Doctor writes remain backend-controlled so assignment/status/rating fields
-- cannot be modified by the client simply because the row belongs to the user.

-- ---------------------------------------------------------------------------
-- 7. Customer Care resources
-- ---------------------------------------------------------------------------

create policy customer_care_select_operations_or_self
on public.customer_care for select to authenticated
using (
  id = auth.uid()
  or public.current_app_role() in ('ADMIN','TEAM_LEAD')
);

-- Customer-care resource writes remain backend-controlled.

-- ---------------------------------------------------------------------------
-- 8. Booking status history
-- ---------------------------------------------------------------------------

create policy status_history_select_related_booking
on public.booking_status_history for select to authenticated
using (
  exists (
    select 1 from public.bookings b
    where b.id = booking_status_history.booking_id
      and (
        b.customer_id = auth.uid()
        or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
        or b.assigned_driver_id = auth.uid()
        or b.assigned_doctor_id = auth.uid()
        or b.assigned_emt_id = auth.uid()
      )
  )
);

-- History inserts are withheld until status-transition backend operations are
-- implemented. This prevents clients from forging historical events.

-- ---------------------------------------------------------------------------
-- 9. Booking vitals
-- ---------------------------------------------------------------------------

create policy vitals_select_related_booking
on public.booking_vitals for select to authenticated
using (
  exists (
    select 1 from public.bookings b
    where b.id = booking_vitals.booking_id
      and (
        b.customer_id = auth.uid()
        or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
        or b.assigned_driver_id = auth.uid()
        or b.assigned_doctor_id = auth.uid()
        or b.assigned_emt_id = auth.uid()
      )
  )
);

-- Clinical writes withheld until Doctor/Driver workflow operations are verified.

-- ---------------------------------------------------------------------------
-- 10. Doctor assessments
-- ---------------------------------------------------------------------------

create policy assessments_select_related_booking
on public.booking_doctor_assessments for select to authenticated
using (
  exists (
    select 1 from public.bookings b
    where b.id = booking_doctor_assessments.booking_id
      and (
        b.customer_id = auth.uid()
        or public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD')
        or b.assigned_driver_id = auth.uid()
        or b.assigned_doctor_id = auth.uid()
        or b.assigned_emt_id = auth.uid()
      )
  )
);

-- Assessment writes withheld until the Doctor workspace write contract is active.

-- ---------------------------------------------------------------------------
-- 11. Notifications
-- ---------------------------------------------------------------------------

create policy notifications_select_own
on public.notifications for select to authenticated
using (target_user_id = auth.uid());

-- Client notification writes are withheld. Trusted workflow operations should
-- generate notifications server-side.

-- ---------------------------------------------------------------------------
-- 12. Audit logs
-- ---------------------------------------------------------------------------

create policy audit_logs_select_authorized
on public.audit_logs for select to authenticated
using (public.current_app_role() in ('ADMIN','CUSTOMER_CARE','TEAM_LEAD','DRIVER','DOCTOR'));

-- No client INSERT/UPDATE/DELETE policy. Audit history must be trusted.

commit;

-- ---------------------------------------------------------------------------
-- POST-APPLY CHECKS (run separately)
-- ---------------------------------------------------------------------------
-- select tablename, policyname, cmd, roles, qual, with_check
-- from pg_policies
-- where schemaname='public'
-- order by tablename, policyname;
