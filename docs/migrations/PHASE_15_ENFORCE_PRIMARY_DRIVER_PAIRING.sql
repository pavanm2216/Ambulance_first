-- PHASE 15: ENFORCE ADMIN AMBULANCE -> PRIMARY DRIVER PAIRING
--
-- Problem fixed:
-- Team Lead allocation previously accepted any AVAILABLE driver for an
-- ambulance, even when Admin had already paired that ambulance to a primary
-- driver. This allowed a booking allocation to silently replace the paired
-- driver (e.g. ECHO-99 paired to Marvy but allocated to Vishnu).
--
-- Rules:
-- 1. If an ambulance has a primary driver (drivers.assigned_ambulance_number
--    matches ambulances.vehicle_number), that driver MUST be used.
-- 2. If the ambulance has no primary driver, the selected operational driver
--    may be used and becomes the ambulance's primary driver.
-- 3. AVAILABLE and ON_DUTY are both valid operational driver states.
-- 4. A driver with an active assigned_booking_id cannot be allocated.
-- 5. A driver already paired to a different ambulance cannot be used.
-- 6. The checks happen inside the authoritative SECURITY DEFINER RPC.

begin;

create or replace function public.allocate_booking(
    p_booking_id text,
    p_ambulance_id text,
    p_driver_id uuid,
    p_doctor_id uuid default null,
    p_emt_id uuid default null
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
    b public.bookings;
    a public.ambulances;
    d public.drivers;
    paired_driver public.drivers;
    doc public.doctors;
    v_emt_name text;
    v_tl_name text;
    v_pair_count integer;
begin
    if auth.uid() is null or public.app_role() not in ('ADMIN','TEAM_LEAD') then
        raise exception 'Only ADMIN or TEAM_LEAD may allocate';
    end if;

    select * into b
    from public.bookings
    where id = p_booking_id
    for update;
    if not found then raise exception 'Booking not found'; end if;

    if b.status <> 'CUSTOMER_ACCEPTED' then
        raise exception 'Customer must accept the quotation before allocation. Current status: %', b.status;
    end if;

    select * into a
    from public.ambulances
    where id = p_ambulance_id
    for update;
    if not found then raise exception 'Ambulance not found'; end if;

    if a.status <> 'AVAILABLE' or a.assigned_booking_id is not null then
        raise exception 'Ambulance is not available';
    end if;

    if a.category <> b.service_category then
        raise exception 'Ambulance category does not match booking';
    end if;

    if b.req_oxygen and not a.has_oxygen then raise exception 'Selected ambulance lacks oxygen'; end if;
    if b.req_icu and not a.has_icu then raise exception 'Selected ambulance lacks ICU capability'; end if;
    if b.req_ventilator and not a.has_ventilator then raise exception 'Selected ambulance lacks ventilator capability'; end if;
    if b.req_pediatric and not a.has_pediatric_icu then raise exception 'Selected ambulance lacks pediatric ICU capability'; end if;
    if b.req_cardiac_monitor and not a.has_cardiac_monitor then raise exception 'Selected ambulance lacks cardiac monitor'; end if;
    if b.req_stretcher and not a.has_stretcher then raise exception 'Selected ambulance lacks stretcher'; end if;
    if b.req_wheelchair and not a.has_wheelchair then raise exception 'Selected ambulance lacks wheelchair'; end if;
    if b.service_category = 'DEAD_BODY' and not a.has_freezer then raise exception 'Selected ambulance lacks mortuary freezer'; end if;

    -- Find the Admin-defined primary driver for this ambulance.
    select count(*) into v_pair_count
    from public.drivers
    where lower(trim(coalesce(assigned_ambulance_number,''))) = lower(trim(coalesce(a.vehicle_number,'')));

    if v_pair_count > 1 then
        raise exception 'Ambulance % has multiple primary drivers configured; resolve the driver pairing before allocation', a.vehicle_number;
    end if;

    select * into paired_driver
    from public.drivers
    where lower(trim(coalesce(assigned_ambulance_number,''))) = lower(trim(coalesce(a.vehicle_number,'')))
    for update;

    if paired_driver.id is not null and paired_driver.id <> p_driver_id then
        raise exception 'Ambulance % is paired with driver %. Team Lead cannot replace the primary driver during booking allocation.',
            a.vehicle_number, paired_driver.name;
    end if;

    select * into d
    from public.drivers
    where id = p_driver_id
    for update;
    if not found then raise exception 'Driver not found'; end if;

    if upper(coalesce(d.status,'')) not in ('AVAILABLE','ON_DUTY') or d.assigned_booking_id is not null then
        raise exception 'Driver is not available. Current status: %', d.status;
    end if;

    if nullif(trim(coalesce(d.assigned_ambulance_number,'')), '') is not null
       and lower(trim(d.assigned_ambulance_number)) <> lower(trim(a.vehicle_number)) then
        raise exception 'Driver % is already paired to ambulance %', d.name, d.assigned_ambulance_number;
    end if;

    if not (b.service_category = any(coalesce(d.supported_categories, array[]::text[]))) then
        raise exception 'Driver does not support booking category %', b.service_category;
    end if;

    if p_doctor_id is not null then
        select * into doc from public.doctors where id = p_doctor_id for update;
        if not found then raise exception 'Doctor not found'; end if;
        if doc.status <> 'AVAILABLE' or doc.assigned_booking_id is not null then raise exception 'Doctor is not available'; end if;
        if b.req_pediatric and not doc.is_pediatric_capable then raise exception 'Doctor is not pediatric capable'; end if;
        if b.req_doctor and b.req_doctor_specialization is not null and lower(doc.specialization) <> lower(b.req_doctor_specialization) then
            raise exception 'Doctor specialization does not match booking';
        end if;
    elsif b.req_doctor then
        raise exception 'Doctor is required for this booking';
    end if;

    if p_emt_id is not null then
        select full_name into v_emt_name from public.profiles where id = p_emt_id and role = 'EMT';
        if v_emt_name is null then raise exception 'EMT profile not found'; end if;
    elsif b.req_emt then
        raise exception 'EMT is required for this booking';
    end if;

    select coalesce(full_name,email,'') into v_tl_name from public.profiles where id = auth.uid();

    update public.ambulances
    set status = 'ASSIGNED', assigned_booking_id = p_booking_id
    where id = a.id;

    update public.drivers
    set status = 'ASSIGNED',
        assigned_booking_id = p_booking_id,
        assigned_ambulance_number = a.vehicle_number
    where id = d.id;

    if p_doctor_id is not null then
        update public.doctors set status='ASSIGNED', assigned_booking_id=p_booking_id where id=doc.id;
    end if;

    update public.bookings
    set assigned_ambulance_id = a.id,
        assigned_driver_id = d.id,
        assigned_doctor_id = p_doctor_id,
        assigned_emt_id = p_emt_id,
        assigned_by_tl_id = auth.uid(),
        assigned_by_tl_name = v_tl_name,
        assigned_at = now(),
        driver_name = d.name,
        driver_phone = d.phone,
        ambulance_vehicle_number = a.vehicle_number,
        ambulance_name = a.name,
        doctor_name = case when p_doctor_id is null then null else doc.name end,
        emt_name = v_emt_name,
        status = 'ASSIGNED',
        updated_at = now()
    where id = p_booking_id
    returning * into b;

    insert into public.audit_logs(user_id,user_name,user_role,action,booking_id,entity_type,previous_value,new_value)
    values(auth.uid(),v_tl_name,public.app_role(),'Booking allocated',p_booking_id,'BOOKING','CUSTOMER_ACCEPTED',
      jsonb_build_object(
        'ambulance_id',a.id,
        'ambulance_vehicle_number',a.vehicle_number,
        'driver_id',d.id,
        'driver_name',d.name,
        'driver_pairing_enforced',paired_driver.id is not null
      )::text);

    return b;
end;
$$;

revoke all on function public.allocate_booking(text,text,uuid,uuid,uuid) from public;
grant execute on function public.allocate_booking(text,text,uuid,uuid,uuid) to authenticated;

commit;
