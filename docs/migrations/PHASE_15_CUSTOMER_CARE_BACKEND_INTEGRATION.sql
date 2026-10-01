-- AeroMed / Ambulance First — Phase 15 Customer Care backend integration
-- Apply after the controlled workflow migrations.
-- This closes the gap between the Customer Care UI and the authoritative bookings workflow.

begin;

create or replace function public.customer_care_verify_and_handoff(
  p_booking_id text,
  p_notes text default '',
  p_priority text default 'NORMAL'
)
returns public.bookings
language plpgsql security definer set search_path = public
as $$
declare
  b public.bookings;
  v_previous text;
begin
  if auth.uid() is null or public.app_role() not in ('CUSTOMER_CARE','ADMIN') then
    raise exception 'Only CUSTOMER_CARE or ADMIN may verify and hand off bookings';
  end if;

  select * into b from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;

  if b.status not in (
    'NEW','CUSTOMER_CARE_CONTACT_PENDING','CUSTOMER_CARE_CONTACTED',
    'VERIFICATION_PENDING','VERIFIED'
  ) then
    raise exception 'Booking is not awaiting Customer Care verification: %', b.status;
  end if;

  v_previous := b.status;

  update public.bookings
  set status = 'SENT_TO_TEAM_LEAD',
      customer_care_verified = true,
      customer_care_verified_at = now(),
      customer_care_verification_notes = nullif(trim(p_notes), ''),
      cc_verified_by_id = auth.uid(),
      cc_verified_by_name = coalesce(
        (select coalesce(p.full_name, p.email, '') from public.profiles p where p.id = auth.uid()),
        ''
      ),
      cc_verified_at = now(),
      cc_call_status = 'VERIFIED',
      cc_notes = nullif(trim(p_notes), ''),
      cc_priority = coalesce(nullif(trim(p_priority),''), priority),
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
    user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value
  )
  select
    auth.uid(), coalesce(p.full_name,p.email,''), public.app_role(),
    'Customer Care verified and handed off booking', p_booking_id, 'BOOKING',
    v_previous, 'SENT_TO_TEAM_LEAD'
  from public.profiles p where p.id = auth.uid();

  return b;
end;
$$;

revoke all on function public.customer_care_verify_and_handoff(text,text,text) from public;
grant execute on function public.customer_care_verify_and_handoff(text,text,text) to authenticated;

commit;
