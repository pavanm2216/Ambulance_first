begin;

create or replace function public.save_customer_booking_draft(p_booking jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking_id text;
  v_booking public.bookings;
  v_patch public.bookings;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may save booking drafts';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text, 0));

  select * into v_booking
  from public.bookings
  where customer_id = auth.uid()
    and status = 'NEW'
    and submission_status = 'DRAFT'
  order by updated_at desc
  limit 1
  for update;

  if not found then
    v_booking_id := public.create_customer_booking_draft(p_booking);
    select * into v_booking
    from public.bookings
    where id = v_booking_id and customer_id = auth.uid()
    for update;
    if not found then
      raise exception 'New booking draft could not be loaded';
    end if;
  end if;

  v_booking_id := v_booking.id;
  v_patch := jsonb_populate_record(v_booking, p_booking);

  update public.bookings
  set customer_name = coalesce(nullif(trim(v_patch.customer_name), ''), 'Customer contact pending'),
      customer_phone = v_patch.customer_phone,
      customer_email = v_patch.customer_email,
      relationship_to_patient = v_patch.relationship_to_patient,
      patient_name = coalesce(nullif(trim(v_patch.patient_name), ''), 'Patient details pending'),
      patient_age = v_patch.patient_age,
      patient_gender = v_patch.patient_gender,
      current_condition = v_patch.current_condition,
      medical_summary = v_patch.medical_summary,
      service_category = v_patch.service_category,
      service_subtype = v_patch.service_subtype,
      transport_mode = v_patch.transport_mode,
      pickup_address = coalesce(nullif(trim(v_patch.pickup_address), ''), 'Pickup address pending'),
      pickup_city = v_patch.pickup_city,
      pickup_lat = v_patch.pickup_lat,
      pickup_lng = v_patch.pickup_lng,
      destination_address = coalesce(nullif(trim(v_patch.destination_address), ''), 'Destination address pending'),
      current_hospital = v_patch.current_hospital,
      destination_hospital = v_patch.destination_hospital,
      preferred_date = v_patch.preferred_date,
      preferred_time = v_patch.preferred_time,
      is_immediate = v_patch.is_immediate,
      is_emergency = v_patch.is_emergency,
      priority = v_patch.priority,
      oxygen_required = v_patch.oxygen_required,
      icu_required = v_patch.icu_required,
      ventilator_required = v_patch.ventilator_required,
      cardiac_monitor_required = v_patch.cardiac_monitor_required,
      stretcher_required = v_patch.stretcher_required,
      wheelchair_required = v_patch.wheelchair_required,
      pediatric_patient = v_patch.pediatric_patient,
      doctor_required = v_patch.doctor_required,
      emt_required = v_patch.emt_required,
      medical_attendant_required = v_patch.medical_attendant_required,
      additional_equipment = coalesce(v_patch.additional_equipment, '[]'::jsonb),
      special_instructions = v_patch.special_instructions,
      submission_status = 'DRAFT',
      submitted_at = null,
      updated_at = now()
  where id = v_booking_id
    and customer_id = auth.uid()
    and status = 'NEW'
    and submission_status = 'DRAFT';

  return v_booking_id;
end;
$$;

create or replace function public.submit_customer_booking_draft(
  p_booking_id text,
  p_booking jsonb
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking_id text;
  v_booking public.bookings;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may submit bookings';
  end if;

  v_booking_id := public.save_customer_booking_draft(p_booking);
  if v_booking_id <> p_booking_id then
    p_booking_id := v_booking_id;
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id and customer_id = auth.uid()
  for update;

  if not found or v_booking.submission_status <> 'DRAFT' or v_booking.status <> 'NEW' then
    raise exception 'No active draft booking is available to submit';
  end if;
  if nullif(trim(v_booking.customer_name), '') is null
      or v_booking.customer_name = 'Customer contact pending'
      or nullif(trim(v_booking.customer_phone), '') is null
      or nullif(trim(v_booking.patient_name), '') is null
      or v_booking.patient_name = 'Patient details pending'
      or v_booking.patient_age is null
      or nullif(trim(v_booking.patient_gender), '') is null
      or nullif(trim(v_booking.current_condition), '') is null
      or v_booking.pickup_address = 'Pickup address pending'
      or v_booking.destination_address = 'Destination address pending' then
    raise exception 'Complete required contact, patient, condition, pickup and destination details before submitting';
  end if;
  if v_booking.service_category = 'ROAD'
      and nullif(trim(v_booking.service_subtype), '') is null then
    raise exception 'Select a road ambulance category before submitting';
  end if;

  update public.bookings
  set submission_status = 'PENDING_VERIFICATION',
      submitted_at = now(),
      current_milestone = 'Booking submitted pending verification',
      updated_at = now()
  where id = p_booking_id and customer_id = auth.uid();

  update public.booking_status_history
  set milestone_title = 'Booking Submitted',
      milestone_description = 'Customer submitted the booking; Customer Care verification is pending.'
  where id = (
    select id
    from public.booking_status_history
    where booking_id = p_booking_id
    order by changed_at desc, id desc
    limit 1
  );

  return p_booking_id;
end;
$$;

revoke all on function public.save_customer_booking_draft(jsonb) from public;
revoke all on function public.submit_customer_booking_draft(text, jsonb) from public;
grant execute on function public.save_customer_booking_draft(jsonb) to authenticated;
grant execute on function public.submit_customer_booking_draft(text, jsonb) to authenticated;

commit;