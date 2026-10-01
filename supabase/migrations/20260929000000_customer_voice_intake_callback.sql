-- Persist partial customer voice intake as a NEW booking for Customer Care.
-- Apply after PHASE_15_CUSTOMER_BOOKING_LOCATION_AND_CREATE_FIX.sql.

begin;

create or replace function public.mark_voice_booking_for_customer_care()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.booking_source = 'VOICE_INTAKE' and new.status = 'NEW' then
    if coalesce(new.cc_notes, '') not like '%VOICE INTAKE CALLBACK REQUEST%' then
      new.cc_notes := concat_ws(
        E'\n',
        nullif(trim(new.cc_notes), ''),
        'VOICE INTAKE CALLBACK REQUEST: request is incomplete; Customer Care should call the customer.'
      );
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists bookings_mark_voice_intake_for_customer_care
  on public.bookings;
create trigger bookings_mark_voice_intake_for_customer_care
before insert or update on public.bookings
for each row execute function public.mark_voice_booking_for_customer_care();

create or replace function public.save_customer_voice_booking_draft(
  p_booking_id text,
  p_booking jsonb
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings;
  v_patch public.bookings;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may save voice bookings';
  end if;
  if nullif(trim(p_booking_id), '') is null then
    raise exception 'Voice booking id is required';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and customer_id = auth.uid()
  for update;

  if not found then
    perform public.create_customer_booking(
      p_booking || jsonb_build_object(
        'id', p_booking_id,
        'booking_source', 'VOICE_INTAKE'
      )
    );
    return p_booking_id;
  end if;

  if v_booking.status <> 'NEW' or v_booking.booking_source <> 'VOICE_INTAKE' then
    raise exception 'Only an open voice intake can be updated';
  end if;

  v_patch := jsonb_populate_record(v_booking, p_booking);

  update public.bookings
  set booking_source = 'VOICE_INTAKE',
      service_category = v_patch.service_category,
      service_subtype = v_patch.service_subtype,
      transport_mode = v_patch.transport_mode,
      ambulance_type = v_patch.ambulance_type,
      pickup_address = v_patch.pickup_address,
      pickup_city = v_patch.pickup_city,
      pickup_lat = v_patch.pickup_lat,
      pickup_lng = v_patch.pickup_lng,
      destination_address = v_patch.destination_address,
      current_hospital = v_patch.current_hospital,
      destination_hospital = v_patch.destination_hospital,
      preferred_date = v_patch.preferred_date,
      preferred_time = v_patch.preferred_time,
      customer_name = v_patch.customer_name,
      customer_phone = v_patch.customer_phone,
      customer_email = v_patch.customer_email,
      relationship_to_patient = v_patch.relationship_to_patient,
      patient_name = v_patch.patient_name,
      patient_age = v_patch.patient_age,
      patient_gender = v_patch.patient_gender,
      current_condition = v_patch.current_condition,
      medical_summary = v_patch.medical_summary,
      is_emergency = v_patch.is_emergency,
      is_immediate = v_patch.is_immediate,
      oxygen_required = v_patch.oxygen_required,
      icu_required = v_patch.icu_required,
      ventilator_required = v_patch.ventilator_required,
      cardiac_monitor_required = v_patch.cardiac_monitor_required,
      pediatric_patient = v_patch.pediatric_patient,
      doctor_required = v_patch.doctor_required,
      emt_required = v_patch.emt_required,
      stretcher_required = v_patch.stretcher_required,
      wheelchair_required = v_patch.wheelchair_required,
      additional_equipment = v_patch.additional_equipment,
      priority = v_patch.priority,
      updated_at = now()
  where id = p_booking_id and customer_id = auth.uid() and status = 'NEW';

  return p_booking_id;
end;
$$;

revoke all on function public.mark_voice_booking_for_customer_care() from public;
revoke all on function public.save_customer_voice_booking_draft(text, jsonb) from public;
grant execute on function public.save_customer_voice_booking_draft(text, jsonb) to authenticated;

commit;