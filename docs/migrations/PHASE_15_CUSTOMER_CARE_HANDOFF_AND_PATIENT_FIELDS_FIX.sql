-- Phase 15: Customer Care handoff + patient identity persistence.
-- Run this migration after the existing controlled booking workflow migrations.
-- It fixes two real integration gaps:
--   1) Customer booking payload now persists age/gender/relationship from Flutter.
--   2) Customer Care handoff marks the booking as verified and sends it to the
--      Team Lead queue through the authoritative booking state.
--
-- The Flutter side of the fix is in:
--   lib/core/models/booking.dart
--   lib/core/services/supabase_booking_repository.dart
--   lib/core/services/customer_care_repository.dart
--   lib/features/customer_care/presentation/screens/call_verification_console_screen.dart
--
-- Existing public.bookings columns used here were confirmed in the project
-- schema: patient_age, patient_gender, customer_relationship_to_patient and
-- the customer-care verification/checklist fields.

begin;

create or replace function public.customer_care_verify_and_handoff(
  p_booking_id text,
  p_notes text default '',
  p_priority text default 'NORMAL'
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings;
  v_previous text;
  v_actor_name text;
begin
  if auth.uid() is null or public.app_role() not in ('CUSTOMER_CARE','ADMIN') then
    raise exception 'Only CUSTOMER_CARE or ADMIN may verify and hand off bookings';
  end if;

  select * into b
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'Booking not found: %', p_booking_id;
  end if;

  if b.status not in (
    'NEW',
    'CUSTOMER_CARE_CONTACT_PENDING',
    'CUSTOMER_CARE_CONTACTED',
    'VERIFICATION_PENDING',
    'VERIFIED'
  ) then
    raise exception 'Booking is not awaiting Customer Care verification: %', b.status;
  end if;

  v_previous := b.status;

  select coalesce(p.full_name, p.email, '')
    into v_actor_name
  from public.profiles p
  where p.id = auth.uid();

  update public.bookings
  set status = 'SENT_TO_TEAM_LEAD',
      customer_care_verified = true,
      customer_care_verified_at = now(),
      customer_care_verification_notes = nullif(trim(p_notes), ''),
      cc_verified_by_id = auth.uid(),
      cc_verified_by_name = coalesce(v_actor_name, ''),
      cc_verified_at = now(),
      cc_call_status = 'VERIFIED',
      cc_notes = nullif(trim(p_notes), ''),
      cc_priority = coalesce(nullif(trim(p_priority), ''), priority),
      priority = coalesce(nullif(trim(p_priority), ''), priority),
      cc_patient_condition_confirmed = true,
      cc_medical_req_confirmed = true,
      cc_location_confirmed = true,
      cc_datetime_confirmed = true,
      cc_check_patient_condition = true,
      cc_check_oxygen_therapy = true,
      cc_check_ventilator_loaded = true,
      cc_check_doctor_designated = true,
      cc_check_receiving_bed_secured = true,
      cc_check_route_priority_cleared = true,
      updated_at = now()
  where id = p_booking_id
  returning * into b;

  insert into public.audit_logs(
    user_id,
    user_name,
    user_role,
    action,
    booking_id,
    entity_type,
    previous_value,
    new_value
  )
  values (
    auth.uid(),
    coalesce(v_actor_name, ''),
    public.app_role(),
    'Customer Care verified and handed off booking',
    p_booking_id,
    'BOOKING',
    v_previous,
    'SENT_TO_TEAM_LEAD'
  );

  return b;
end;
$$;

revoke all on function public.customer_care_verify_and_handoff(text,text,text) from public;
grant execute on function public.customer_care_verify_and_handoff(text,text,text) to authenticated;

commit;
