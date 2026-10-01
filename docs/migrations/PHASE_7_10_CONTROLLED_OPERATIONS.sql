-- Ambulance First — Phases 7-10 controlled operational RPCs
-- Apply AFTER PHASE_6_CONTROLLED_WORKFLOW.sql and the pricing migration.
-- These functions intentionally avoid direct client-side writes to protected workflow fields.

begin;

-- Shared pricing reader for trusted quotation calculation.
create or replace function public.prepare_booking_quotation(
  p_booking_id text,
  p_discount numeric default 0,
  p_payment_terms text default null
)
returns public.bookings
language plpgsql security definer set search_path = public
as $$
declare
  b public.bookings;
  p public.pricing_settings;
  v_base numeric := 0;
  v_distance numeric := 0;
  v_doctor numeric := 0;
  v_emt numeric := 0;
  v_oxygen numeric := 0;
  v_icu numeric := 0;
  v_vent numeric := 0;
  v_picu numeric := 0;
  v_equipment numeric := 0;
  v_attendant numeric := 0;
  v_air numeric := 0;
  v_rail numeric := 0;
  v_additional numeric := 0;
  v_subtotal numeric;
  v_tax numeric;
  v_final numeric;
  v_quotation_id text;
  v_tax_pct numeric;
begin
  if auth.uid() is null or public.app_role() not in ('ADMIN','TEAM_LEAD') then
    raise exception 'Only ADMIN or TEAM_LEAD may prepare quotations';
  end if;

  select * into b from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;

  select * into p from public.pricing_settings where id = 'default';
  if not found then raise exception 'Pricing configuration is missing'; end if;

  if b.service_category = 'ROAD' then
    if coalesce(b.service_subtype,'') = 'BASIC_OXYGEN' then
      v_base := p.road_basic_oxygen_base;
      v_distance := coalesce(b.estimated_distance_km,0) * p.road_basic_oxygen_per_km;
    elsif coalesce(b.service_subtype,'') = 'PEDIATRIC_ICU' then
      v_base := p.road_pediatric_icu_base;
      v_distance := coalesce(b.estimated_distance_km,0) * p.road_pediatric_icu_per_km;
    else
      v_base := p.road_advanced_icu_base;
      v_distance := coalesce(b.estimated_distance_km,0) * p.road_advanced_icu_per_km;
    end if;
  elsif b.service_category = 'AIR' then
    v_air := p.air_medevac_base;
  elsif b.service_category = 'RAILWAY' then
    v_rail := p.railway_base;
  elsif b.service_category = 'DEAD_BODY' then
    v_base := p.dead_body_base;
    v_distance := coalesce(b.estimated_distance_km,0) * p.dead_body_per_km;
  end if;

  if coalesce(b.req_doctor,false) then v_doctor := p.doctor_escort; end if;
  if coalesce(b.req_emt,false) then v_emt := p.emt_escort; end if;
  if coalesce(b.req_oxygen,false) then v_oxygen := p.oxygen; end if;
  if coalesce(b.req_icu,false) then v_icu := p.road_advanced_icu_base; end if;
  if coalesce(b.req_ventilator,false) then v_vent := p.ventilator; end if;
  if coalesce(b.req_pediatric,false) then v_picu := p.road_pediatric_icu_base; end if;
  if coalesce(b.req_attendant,false) then v_attendant := p.oxygen * 0 + p.emt_escort; end if;

  v_subtotal := greatest(0, v_base + v_distance + v_doctor + v_emt + v_oxygen + v_icu + v_vent + v_picu + v_equipment + v_attendant + v_air + v_rail + v_additional - greatest(0,p_discount));
  v_tax_pct := coalesce(p.tax_percent,5);
  v_tax := round(v_subtotal * v_tax_pct / 100, 2);
  v_final := v_subtotal + v_tax;
  v_quotation_id := coalesce(b.quotation_id, 'Q-' || b.id);

  update public.bookings
  set quotation_id = v_quotation_id,
      quotation_status = 'SENT',
      quotation_prepared_by_id = auth.uid(),
      quotation_prepared_at = now(),
      quotation_sent_at = now(),
      q_base_charge = v_base,
      q_distance_charge = v_distance,
      q_doctor_charge = v_doctor,
      q_emt_charge = v_emt,
      q_oxygen_charge = v_oxygen,
      q_icu_charge = v_icu,
      q_ventilator_charge = v_vent,
      q_pediatric_icu_charge = v_picu,
      q_equipment_charge = v_equipment,
      q_attendant_charge = v_attendant,
      q_air_charges = v_air,
      q_railway_charges = v_rail,
      q_additional_charges = v_additional,
      q_subtotal = v_subtotal,
      q_discount = greatest(0,p_discount),
      q_tax_percent = v_tax_pct,
      q_tax_amount = v_tax,
      q_final_amount = v_final,
      q_payment_terms = p_payment_terms,
      status = case when b.status in ('VERIFIED','SENT_TO_TEAM_LEAD','ALLOCATION_PENDING','BUDGET_PENDING') then 'QUOTATION_SENT' else b.status end
  where id = p_booking_id
  returning * into b;

  insert into public.audit_logs(user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value)
  select auth.uid(), coalesce(pr.full_name,pr.email,''), public.app_role(), 'Quotation prepared', b.id, 'QUOTATION', null, v_quotation_id
  from public.profiles pr where pr.id = auth.uid();

  return b;
end;
$$;

revoke all on function public.prepare_booking_quotation(text,numeric,text) from public;
grant execute on function public.prepare_booking_quotation(text,numeric,text) to authenticated;

-- Customer quotation response.
create or replace function public.respond_to_quotation(p_booking_id text, p_accept boolean, p_reason text default null)
returns public.bookings
language plpgsql security definer set search_path = public
as $$
declare b public.bookings; v_status text;
begin
  if auth.uid() is null or public.app_role() <> 'CUSTOMER' then raise exception 'Customer authentication required'; end if;
  select * into b from public.bookings where id=p_booking_id and customer_id=auth.uid() for update;
  if not found then raise exception 'Booking not found or not owned by customer'; end if;
  if b.status <> 'QUOTATION_SENT' then raise exception 'Quotation is not awaiting customer response'; end if;
  v_status := case when p_accept then 'CUSTOMER_ACCEPTED' else 'CUSTOMER_REJECTED' end;
  update public.bookings set quotation_status=case when p_accept then 'ACCEPTED' else 'REJECTED' end,
      quotation_responded_at=now(), quotation_rejection_reason=case when p_accept then null else p_reason end,
      status=v_status
    where id=p_booking_id returning * into b;
  insert into public.audit_logs(user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value)
    select auth.uid(),coalesce(pr.full_name,pr.email,''),public.app_role(),'Quotation response',p_booking_id,'QUOTATION','SENT',v_status
    from public.profiles pr where pr.id=auth.uid();
  return b;
end;
$$;
revoke all on function public.respond_to_quotation(text,boolean,text) from public;
grant execute on function public.respond_to_quotation(text,boolean,text) to authenticated;

-- Team Lead allocation. Resource IDs are authoritative; denormalized names are copied server-side.
create or replace function public.allocate_booking(
  p_booking_id text,
  p_ambulance_id text,
  p_driver_id uuid,
  p_doctor_id uuid default null,
  p_emt_id uuid default null
)
returns public.bookings
language plpgsql security definer set search_path = public
as $$
declare b public.bookings; d public.drivers; doc public.doctors; a_name text; a_vehicle text; emt_name text;
begin
  if auth.uid() is null or public.app_role() not in ('ADMIN','TEAM_LEAD') then raise exception 'Only ADMIN or TEAM_LEAD may allocate'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if b.status not in ('CUSTOMER_ACCEPTED','SENT_TO_TEAM_LEAD','VERIFIED','ALLOCATION_PENDING','QUOTATION_SENT') then raise exception 'Booking is not allocatable in status %', b.status; end if;
  select * into d from public.drivers where id=p_driver_id;
  if not found then raise exception 'Driver not found'; end if;
  if p_doctor_id is not null then select * into doc from public.doctors where id=p_doctor_id; if not found then raise exception 'Doctor not found'; end if; end if;
  select vehicle_number,name into a_vehicle,a_name from public.ambulances where id=p_ambulance_id;
  if a_vehicle is null then raise exception 'Ambulance not found'; end if;
  if p_emt_id is not null then select full_name into emt_name from public.profiles where id=p_emt_id and role='EMT'; if emt_name is null then raise exception 'EMT profile not found'; end if; end if;
  update public.bookings set assigned_ambulance_id=p_ambulance_id, assigned_driver_id=p_driver_id,
      assigned_doctor_id=p_doctor_id, assigned_emt_id=p_emt_id, assigned_by_tl_id=auth.uid(),
      assigned_by_tl_name=(select coalesce(full_name,email,'') from public.profiles where id=auth.uid()),
      assigned_at=now(), driver_name=d.name, driver_phone=d.phone, ambulance_vehicle_number=a_vehicle,
      ambulance_name=a_name, doctor_name=doc.name, emt_name=emt_name, status='ASSIGNED'
    where id=p_booking_id returning * into b;
  insert into public.audit_logs(user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value)
    select auth.uid(),coalesce(pr.full_name,pr.email,''),public.app_role(),'Booking allocated',p_booking_id,'BOOKING',null,
      jsonb_build_object('ambulance_id',p_ambulance_id,'driver_id',p_driver_id,'doctor_id',p_doctor_id)::text
    from public.profiles pr where pr.id=auth.uid();
  return b;
end;
$$;
revoke all on function public.allocate_booking(text,text,uuid,uuid,uuid) from public;
grant execute on function public.allocate_booking(text,text,uuid,uuid,uuid) to authenticated;

-- Doctor vitals write. Uses only audited columns already confirmed in booking_vitals.
create or replace function public.record_booking_vitals(
  p_booking_id text,
  p_heart_rate_bpm numeric default null,
  p_bp_systolic numeric default null,
  p_bp_diastolic numeric default null,
  p_spo2_percent numeric default null,
  p_respiratory_rate numeric default null,
  p_temperature_celsius numeric default null,
  p_glucose_mg_dl numeric default null,
  p_oxygen_flow_lpm numeric default null,
  p_ventilator_pressure numeric default null,
  p_clinical_notes text default null
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null or public.app_role() <> 'DOCTOR' then raise exception 'Only authenticated DOCTOR users may record vitals'; end if;
  if not exists(select 1 from public.bookings where id=p_booking_id and assigned_doctor_id=auth.uid()) then raise exception 'Booking is not assigned to current doctor'; end if;
  insert into public.booking_vitals(booking_id,heart_rate_bpm,bp_systolic,bp_diastolic,spo2_percent,respiratory_rate,temperature_celsius,glucose_mg_dl,oxygen_flow_lpm,ventilator_pressure,clinical_notes)
  values(p_booking_id,p_heart_rate_bpm,p_bp_systolic,p_bp_diastolic,p_spo2_percent,p_respiratory_rate,p_temperature_celsius,p_glucose_mg_dl,p_oxygen_flow_lpm,p_ventilator_pressure,p_clinical_notes)
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.record_booking_vitals(text,numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,text) from public;
grant execute on function public.record_booking_vitals(text,numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,numeric,text) to authenticated;

commit;
