begin;

alter table public.bookings
  add column if not exists submission_status text not null default 'PENDING_VERIFICATION',
  add column if not exists submitted_at timestamptz;

drop trigger if exists bookings_mark_voice_intake_for_customer_care
  on public.bookings;
drop function if exists public.mark_voice_booking_for_customer_care();

update public.bookings
set submission_status = 'VERIFIED'
where status in (
  'VERIFIED', 'SENT_TO_TEAM_LEAD', 'ALLOCATION_PENDING', 'BUDGET_PENDING',
  'QUOTATION_SENT', 'CUSTOMER_ACCEPTED', 'ASSIGNED', 'DRIVER_ASSIGNED',
  'PICKUP_STARTED', 'PATIENT_PICKED_UP', 'IN_TRANSIT', 'ARRIVED',
  'SERVICE_COMPLETED'
);

update public.bookings
set submitted_at = coalesce(submitted_at, created_at)
where submission_status in ('PENDING_VERIFICATION', 'VERIFIED');

alter table public.bookings
  drop constraint if exists bookings_submission_status_check;
alter table public.bookings
  add constraint bookings_submission_status_check
  check (submission_status in ('DRAFT', 'PENDING_VERIFICATION', 'VERIFIED'));

create unique index if not exists bookings_one_active_customer_draft
  on public.bookings (customer_id)
  where submission_status = 'DRAFT' and status = 'NEW';

grant select on public.bookings to authenticated;
drop policy if exists bookings_customer_care_read on public.bookings;
create policy bookings_customer_care_read
  on public.bookings
  for select
  to authenticated
  using (public.is_customer_care_user());

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'bookings'
  ) then
    alter publication supabase_realtime add table public.bookings;
  end if;
end;
$$;

create or replace function public.sync_customer_booking_submission_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.submission_status = 'DRAFT' then
      new.submitted_at := null;
      new.current_milestone := 'Customer filling draft';
    else
      new.submission_status := 'PENDING_VERIFICATION';
      new.submitted_at := coalesce(new.submitted_at, now());
    end if;
    return new;
  end if;

  if new.status = 'VERIFIED' then
    if old.submission_status = 'DRAFT' then
      raise exception 'A draft booking cannot be verified before customer submission';
    end if;
    new.submission_status := 'VERIFIED';
    new.submitted_at := coalesce(old.submitted_at, new.submitted_at, now());
    return new;
  end if;

  if old.submission_status = 'DRAFT' then
    if new.status <> 'NEW' then
      raise exception 'A draft booking must be submitted before workflow status changes';
    end if;
    if new.submission_status not in ('DRAFT', 'PENDING_VERIFICATION') then
      raise exception 'A draft can only be submitted for verification';
    end if;
    if new.submission_status = 'DRAFT' then
      new.submitted_at := null;
      new.current_milestone := 'Customer filling draft';
    else
      new.submitted_at := coalesce(new.submitted_at, now());
      new.current_milestone := 'Booking submitted pending verification';
    end if;
  elsif new.submission_status = 'DRAFT' then
    if old.status <> 'NEW' or old.submitted_at is not null then
      raise exception 'Only an unsubmitted new booking can become a draft';
    end if;
    new.submitted_at := null;
    new.current_milestone := 'Customer filling draft';
  elsif new.submission_status = 'PENDING_VERIFICATION' then
    new.submitted_at := coalesce(new.submitted_at, old.submitted_at, now());
  end if;

  if new.submission_status = 'DRAFT' and new.status = 'NEW' then
    if coalesce(new.cc_notes, '') not like '%DRAFT: CUSTOMER IS FILLING DETAILS%' then
      new.cc_notes := concat_ws(
        E'\n',
        nullif(trim(new.cc_notes), ''),
        'DRAFT: CUSTOMER IS FILLING DETAILS. Call the customer; do not verify until submitted.'
      );
    end if;
  else
    new.cc_notes := nullif(
      trim(
        replace(
          coalesce(new.cc_notes, ''),
          'DRAFT: CUSTOMER IS FILLING DETAILS. Call the customer; do not verify until submitted.',
          ''
        )
      ),
      ''
    );
  end if;

  return new;
end;
$$;

drop trigger if exists bookings_sync_submission_state on public.bookings;
create trigger bookings_sync_submission_state
before insert or update on public.bookings
for each row execute function public.sync_customer_booking_submission_state();

create or replace function public.create_customer_booking_draft(p_booking jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id text;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may create booking drafts';
  end if;

  insert into public.bookings (
    customer_id, customer_name, customer_phone, customer_email,
    alternate_phone, relationship_to_patient, patient_name, patient_age,
    patient_gender, current_condition, medical_summary, pickup_address,
    pickup_city, pickup_lat, pickup_lng, destination_address,
    destination_city, destination_lat, destination_lng, current_hospital,
    destination_hospital, transport_mode, service_category, service_subtype,
    is_immediate, is_emergency, priority, preferred_date, preferred_time,
    oxygen_required, oxygen_flow_lpm, icu_required, ventilator_required,
    ventilator_mode, cardiac_monitor_required, stretcher_required,
    wheelchair_required, pediatric_patient, doctor_required,
    doctor_specialization, emt_required, medical_attendant_required,
    additional_equipment, special_instructions, estimated_distance_km,
    estimated_duration_mins, status, submission_status, submitted_at,
    current_milestone
  ) values (
    auth.uid(),
    coalesce(nullif(p_booking->>'customer_name', ''), nullif((select full_name from public.profiles where id = auth.uid()), ''), 'Customer contact pending'),
    coalesce(nullif(p_booking->>'customer_phone', ''), (select phone from public.profiles where id = auth.uid())),
    coalesce(nullif(p_booking->>'customer_email', ''), (select email from public.profiles where id = auth.uid())),
    nullif(p_booking->>'alternate_phone', ''),
    coalesce(nullif(p_booking->>'relationship_to_patient', ''), 'Self'),
    coalesce(nullif(p_booking->>'patient_name', ''), 'Patient details pending'),
    nullif(p_booking->>'patient_age', '')::integer,
    nullif(p_booking->>'patient_gender', ''),
    nullif(p_booking->>'current_condition', ''),
    nullif(p_booking->>'medical_summary', ''),
    coalesce(nullif(p_booking->>'pickup_address', ''), 'Pickup address pending'),
    nullif(p_booking->>'pickup_city', ''),
    nullif(p_booking->>'pickup_lat', '')::numeric,
    nullif(p_booking->>'pickup_lng', '')::numeric,
    coalesce(nullif(p_booking->>'destination_address', ''), 'Destination address pending'),
    nullif(p_booking->>'destination_city', ''),
    nullif(p_booking->>'destination_lat', '')::numeric,
    nullif(p_booking->>'destination_lng', '')::numeric,
    nullif(p_booking->>'current_hospital', ''),
    nullif(p_booking->>'destination_hospital', ''),
    coalesce(p_booking->>'transport_mode', 'ROAD_AMBULANCE'),
    coalesce(p_booking->>'service_category', 'ROAD'),
    nullif(p_booking->>'service_subtype', ''),
    coalesce((p_booking->>'is_immediate')::boolean, true),
    coalesce((p_booking->>'is_emergency')::boolean, false),
    coalesce(p_booking->>'priority', 'NORMAL'),
    nullif(p_booking->>'preferred_date', '')::date,
    nullif(p_booking->>'preferred_time', '')::time,
    coalesce((p_booking->>'oxygen_required')::boolean, false),
    nullif(p_booking->>'oxygen_flow_lpm', '')::numeric,
    coalesce((p_booking->>'icu_required')::boolean, false),
    coalesce((p_booking->>'ventilator_required')::boolean, false),
    nullif(p_booking->>'ventilator_mode', ''),
    coalesce((p_booking->>'cardiac_monitor_required')::boolean, false),
    coalesce((p_booking->>'stretcher_required')::boolean, false),
    coalesce((p_booking->>'wheelchair_required')::boolean, false),
    coalesce((p_booking->>'pediatric_patient')::boolean, false),
    coalesce((p_booking->>'doctor_required')::boolean, false),
    nullif(p_booking->>'doctor_specialization', ''),
    coalesce((p_booking->>'emt_required')::boolean, false),
    coalesce((p_booking->>'medical_attendant_required')::boolean, false),
    coalesce(p_booking->'additional_equipment', '[]'::jsonb),
    nullif(p_booking->>'special_instructions', ''),
    coalesce(nullif(p_booking->>'estimated_distance_km', '')::numeric, 0),
    coalesce(nullif(p_booking->>'estimated_duration_mins', '')::integer, 0),
    'NEW', 'DRAFT', null, 'Customer filling draft'
  ) returning id into v_id;

  insert into public.booking_status_history (
    booking_id, previous_status, status, milestone_title,
    milestone_description, changed_by_id, changed_by_role
  ) values (
    v_id, null, 'NEW', 'Customer Draft Started',
    'Customer opened the booking form; details are being entered.',
    auth.uid(), 'CUSTOMER'
  );

  return v_id;
end;
$$;

create or replace function public.get_customer_booking_draft()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking jsonb;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may read booking drafts';
  end if;

  select to_jsonb(b) into v_booking
  from public.bookings b
  where b.customer_id = auth.uid()
    and b.status = 'NEW'
    and b.submission_status = 'DRAFT'
  order by b.updated_at desc
  limit 1;

  return v_booking;
end;
$$;

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
      ambulance_type = v_patch.ambulance_type,
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
      and nullif(trim(v_booking.ambulance_type), '') is null then
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

-- Keep older clients functional while routing them through the safe shared draft RPC.
create or replace function public.save_customer_voice_booking_draft(
  p_booking_id text,
  p_booking jsonb
)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.save_customer_booking_draft(p_booking);
end;
$$;

revoke all on function public.sync_customer_booking_submission_state() from public;
revoke all on function public.create_customer_booking_draft(jsonb) from public;
revoke all on function public.get_customer_booking_draft() from public;
revoke all on function public.save_customer_booking_draft(jsonb) from public;
revoke all on function public.submit_customer_booking_draft(text, jsonb) from public;
revoke all on function public.save_customer_voice_booking_draft(text, jsonb) from public;
grant execute on function public.save_customer_booking_draft(jsonb) to authenticated;
grant execute on function public.create_customer_booking_draft(jsonb) to authenticated;
grant execute on function public.get_customer_booking_draft() to authenticated;
grant execute on function public.submit_customer_booking_draft(text, jsonb) to authenticated;
grant execute on function public.save_customer_voice_booking_draft(text, jsonb) to authenticated;

commit;