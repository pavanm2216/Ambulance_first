-- Ambulance First — Phase 6 controlled workflow write layer
-- STATUS: APPLY AFTER BACKUP. This moves core booking mutations behind
-- SECURITY DEFINER RPCs instead of broad client UPDATE policies.
-- Service-role credentials are NOT required by Flutter.

begin;

create or replace function public.app_role()
returns text
language sql stable security definer set search_path = public
as $$ select upper(coalesce((select role from public.profiles where id = auth.uid()), '')) $$;

revoke all on function public.app_role() from public;
grant execute on function public.app_role() to authenticated;

-- Customer booking creation. Protected operational fields are stripped before
-- the row is inserted; customer_id and status are server-controlled.
create or replace function public.create_customer_booking(p_booking jsonb)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_id text;
  v_payload jsonb;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then
    raise exception 'Only authenticated CUSTOMER users may create bookings';
  end if;

  v_id := nullif(trim(p_booking->>'id'), '');
  if v_id is null then
    raise exception 'Booking id is required';
  end if;

  v_payload := p_booking
    - ARRAY[
      'status','customer_id','created_at','updated_at',
      'cc_verified_by_id','cc_verified_by_name','cc_verified_at',
      'assigned_ambulance_id','assigned_driver_id','assigned_emt_id',
      'assigned_doctor_id','assigned_by_tl_id','assigned_by_tl_name','assigned_at',
      'quotation_id','quotation_status','quotation_prepared_by_id',
      'quotation_prepared_by_name','quotation_prepared_at','quotation_sent_at',
      'quotation_responded_at','quotation_rejection_reason',
      'q_base_charge','q_distance_charge','q_doctor_charge','q_emt_charge',
      'q_oxygen_charge','q_icu_charge','q_ventilator_charge',
      'q_pediatric_icu_charge','q_equipment_charge','q_attendant_charge',
      'q_air_charges','q_railway_charges','q_additional_charges',
      'q_subtotal','q_discount','q_tax_percent','q_tax_amount','q_final_amount',
      'q_payment_terms'
    ]
    || jsonb_build_object('customer_id', auth.uid(), 'status', 'NEW');

  insert into public.bookings
  select (jsonb_populate_record(null::public.bookings, v_payload)).*;

  return v_id;
end;
$$;

revoke all on function public.create_customer_booking(jsonb) from public;
grant execute on function public.create_customer_booking(jsonb) to authenticated;

-- Controlled status transition. Assignment/quotation/clinical fields are not
-- modified by this RPC. They get dedicated operations in later phases.
create or replace function public.transition_booking_status(
  p_booking_id text,
  p_next_status text
)
returns public.bookings
language plpgsql security definer set search_path = public
as $$
declare
  v_current text;
  v_role text := public.app_role();
  v_allowed boolean := false;
  v_row public.bookings;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;

  select status into v_current from public.bookings
  where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;

  -- Ownership/assignment is checked before role transition rules.
  if v_role = 'CUSTOMER' then
    if not exists (select 1 from public.bookings where id=p_booking_id and customer_id=auth.uid()) then
      raise exception 'Booking is not owned by current customer';
    end if;
    v_allowed := (v_current='QUOTATION_SENT' and p_next_status in ('CUSTOMER_ACCEPTED','CUSTOMER_REJECTED'));
  elsif v_role in ('ADMIN','CUSTOMER_CARE') then
    v_allowed := (v_current,p_next_status) in (
      ('NEW','CUSTOMER_CARE_CONTACT_PENDING'),
      ('CUSTOMER_CARE_CONTACT_PENDING','CUSTOMER_CARE_CONTACTED'),
      ('CUSTOMER_CARE_CONTACTED','VERIFICATION_PENDING'),
      ('VERIFICATION_PENDING','VERIFIED')
    );
  elsif v_role = 'TEAM_LEAD' then
    v_allowed := (v_current,p_next_status) in (
      ('VERIFIED','SENT_TO_TEAM_LEAD'),
      ('SENT_TO_TEAM_LEAD','ALLOCATION_PENDING'),
      ('CUSTOMER_ACCEPTED','ASSIGNED')
    );
  elsif v_role = 'DRIVER' then
    if not exists (select 1 from public.bookings where id=p_booking_id and assigned_driver_id=auth.uid()) then
      raise exception 'Booking is not assigned to current driver';
    end if;
    v_allowed := (v_current,p_next_status) in (
      ('ASSIGNED','PICKUP_STARTED'),
      ('PICKUP_STARTED','PATIENT_PICKED_UP'),
      ('PATIENT_PICKED_UP','IN_TRANSIT'),
      ('IN_TRANSIT','ARRIVED')
    );
  elsif v_role = 'DOCTOR' then
    if not exists (select 1 from public.bookings where id=p_booking_id and assigned_doctor_id=auth.uid()) then
      raise exception 'Booking is not assigned to current doctor';
    end if;
    v_allowed := (v_current,p_next_status) in (('ARRIVED','SERVICE_COMPLETED'));
  end if;

  if not v_allowed then
    raise exception 'Transition % -> % is not permitted for role %', v_current, p_next_status, v_role;
  end if;

  update public.bookings set status=p_next_status where id=p_booking_id returning * into v_row;

  -- Audit is trusted and generated server-side.
  insert into public.audit_logs(user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value)
  select auth.uid(), coalesce(p.full_name,p.email,''), v_role,
         'Booking status changed', p_booking_id, 'BOOKING', v_current, p_next_status
  from public.profiles p where p.id=auth.uid();

  return v_row;
end;
$$;

revoke all on function public.transition_booking_status(text,text) from public;
grant execute on function public.transition_booking_status(text,text) to authenticated;

-- Doctor clinical assessment write.
create or replace function public.submit_doctor_assessment(
  p_booking_id text,
  p_diagnosis text,
  p_patient_condition text,
  p_medications text[] default '{}',
  p_interventions text[] default '{}',
  p_notes text default ''
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null or public.app_role() <> 'DOCTOR' then
    raise exception 'Only authenticated DOCTOR users may submit assessments';
  end if;
  if not exists (select 1 from public.bookings where id=p_booking_id and assigned_doctor_id=auth.uid()) then
    raise exception 'Booking is not assigned to current doctor';
  end if;
  insert into public.booking_doctor_assessments
    (booking_id,doctor_id,doctor_name,diagnosis,patient_condition,medications_administered,interventions,notes)
  select p_booking_id, d.id, d.name, p_diagnosis, p_patient_condition,
         coalesce(p_medications,'{}'), coalesce(p_interventions,'{}'), p_notes
  from public.doctors d where d.id=auth.uid()
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_doctor_assessment(text,text,text,text[],text[],text) from public;
grant execute on function public.submit_doctor_assessment(text,text,text,text[],text[],text) to authenticated;

commit;
