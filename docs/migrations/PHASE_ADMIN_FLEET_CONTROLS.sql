-- Controlled Admin fleet status mutation.
-- Deploy only after the audited RLS policy replacement has been validated.
create or replace function public.admin_update_ambulance_status(
  p_ambulance_id text,
  p_status text
)
returns public.ambulances
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ambulance public.ambulances;
  v_old text;
  v_user_name text;
begin
  if auth.uid() is null or public.app_role() <> 'ADMIN' then
    raise exception 'Only ADMIN may change fleet status';
  end if;

  if upper(coalesce(p_status,'')) not in ('AVAILABLE','MAINTENANCE') then
    raise exception 'Admin fleet status operation only supports AVAILABLE or MAINTENANCE';
  end if;

  select status into v_old from public.ambulances where id = p_ambulance_id for update;
  if not found then raise exception 'Ambulance not found'; end if;

  -- Do not make an actively assigned/on-trip unit available through an admin shortcut.
  if upper(coalesce(v_old,'')) in ('ASSIGNED','IN_TRANSIT','ON_TRIP') and upper(p_status) = 'AVAILABLE' then
    raise exception 'Active or assigned ambulance must be released through the operational workflow';
  end if;

  update public.ambulances set status = upper(p_status) where id = p_ambulance_id returning * into v_ambulance;
  select coalesce(full_name,email,'') into v_user_name from public.profiles where id = auth.uid();

  insert into public.audit_logs(user_id,user_name,user_role,action,entity_type,previous_value,new_value,timestamp)
  values(auth.uid(),v_user_name,'ADMIN','UPDATE_FLEET_STATUS','AMBULANCE',v_old,upper(p_status),now());

  return v_ambulance;
end;
$$;
revoke all on function public.admin_update_ambulance_status(text,text) from public;
grant execute on function public.admin_update_ambulance_status(text,text) to authenticated;
