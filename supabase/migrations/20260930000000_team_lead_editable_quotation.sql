begin;

create or replace function public.preview_booking_quotation(p_booking_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings;
  v_rate public.p%rowtype;
  v_base numeric := 0;
  v_distance_km numeric := 0;
  v_distance_rate numeric := 0;
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
  v_subtotal numeric;
  v_tax numeric;
  v_final numeric;
  v_tax_pct numeric;
  v_req_doctor boolean;
  v_req_emt boolean;
  v_req_oxygen boolean;
  v_req_icu boolean;
  v_req_ventilator boolean;
  v_req_pediatric boolean;
  v_req_attendant boolean;
begin
  if auth.uid() is null or public.app_role() not in ('ADMIN', 'TEAM_LEAD') then
    raise exception 'Only ADMIN or TEAM_LEAD may preview quotations';
  end if;

  select * into b from public.bookings where id = p_booking_id;
  if not found then raise exception 'Booking not found'; end if;

  select rate.* into v_rate
  from public.p as rate
  where rate.service_category = b.service_category
    and (rate.service_subtype is null or rate.service_subtype = b.service_subtype)
    and coalesce(rate.is_active, false)
    and (rate.effective_from is null or rate.effective_from <= now())
    and (rate.effective_until is null or rate.effective_until > now())
  order by (rate.service_subtype is not null) desc,
           rate.effective_from desc nulls last,
           rate.updated_at desc nulls last
  limit 1;
  if not found then
    raise exception 'No active quotation rate found for service category % and subtype %',
      b.service_category, b.service_subtype;
  end if;

  v_req_doctor := lower(coalesce(
    to_jsonb(b)->>'doctor_required', to_jsonb(b)->>'req_doctor', 'false'
  )) in ('true', '1', 'yes');
  v_req_emt := lower(coalesce(
    to_jsonb(b)->>'emt_required', to_jsonb(b)->>'req_emt', 'false'
  )) in ('true', '1', 'yes');
  v_req_oxygen := lower(coalesce(
    to_jsonb(b)->>'oxygen_required', to_jsonb(b)->>'req_oxygen', 'false'
  )) in ('true', '1', 'yes');
  v_req_icu := lower(coalesce(
    to_jsonb(b)->>'icu_required', to_jsonb(b)->>'req_icu', 'false'
  )) in ('true', '1', 'yes');
  v_req_ventilator := lower(coalesce(
    to_jsonb(b)->>'ventilator_required', to_jsonb(b)->>'req_ventilator', 'false'
  )) in ('true', '1', 'yes');
  v_req_pediatric := lower(coalesce(
    to_jsonb(b)->>'pediatric_required',
    to_jsonb(b)->>'req_pediatric',
    to_jsonb(b)->>'pediatric_patient',
    'false'
  )) in ('true', '1', 'yes');
  v_req_attendant := lower(coalesce(
    to_jsonb(b)->>'medical_attendant_required',
    to_jsonb(b)->>'req_attendant',
    'false'
  )) in ('true', '1', 'yes');

  v_distance_km := coalesce(b.estimated_distance_km, 0);
  v_base := coalesce(v_rate.base_charge, 0);
  v_distance_rate := coalesce(v_rate.per_km_charge, 0);
  v_distance := v_distance_km * v_distance_rate;
  if v_req_doctor then v_doctor := coalesce(v_rate.doctor_charge, 0); end if;
  if v_req_emt then v_emt := coalesce(v_rate.emt_charge, 0); end if;
  if v_req_oxygen then v_oxygen := coalesce(v_rate.oxygen_charge, 0); end if;
  if v_req_icu then v_icu := coalesce(v_rate.icu_charge, 0); end if;
  if v_req_ventilator then v_vent := coalesce(v_rate.ventilator_charge, 0); end if;
  if v_req_pediatric then v_picu := coalesce(v_rate.pediatric_icu_charge, 0); end if;
  if v_req_attendant then v_attendant := coalesce(v_rate.attendant_charge, 0); end if;
  if jsonb_typeof(to_jsonb(b)->'additional_equipment') = 'array' then
    if jsonb_array_length(to_jsonb(b)->'additional_equipment') > 0 then
      v_equipment := coalesce(v_rate.equipment_charge, 0);
    end if;
  end if;

  v_subtotal := greatest(
    0,
    v_base + v_distance + v_doctor + v_emt + v_oxygen + v_icu + v_vent +
      v_picu + v_equipment + v_attendant + v_air + v_rail
  );
  v_tax_pct := coalesce(v_rate.tax_percent, 5);
  v_tax := round(v_subtotal * v_tax_pct / 100, 2);
  v_final := v_subtotal + v_tax;

  return jsonb_build_object(
    'service_category', b.service_category,
    'service_subtype', b.service_subtype,
    'rate_card_effective_from', v_rate.effective_from,
    'distance_km', v_distance_km,
    'distance_rate', v_distance_rate,
    'base_charge', v_base,
    'distance_charge', v_distance,
    'doctor_charge', v_doctor,
    'emt_charge', v_emt,
    'oxygen_charge', v_oxygen,
    'icu_charge', v_icu,
    'ventilator_charge', v_vent,
    'pediatric_icu_charge', v_picu,
    'equipment_charge', v_equipment,
    'attendant_charge', v_attendant,
    'air_charge', v_air,
    'railway_charge', v_rail,
    'night_surcharge_percent', coalesce(v_rate.night_surcharge_percent, 0),
    'subtotal', v_subtotal,
    'tax_percent', v_tax_pct,
    'tax_amount', v_tax,
    'final_amount', v_final
  );
end;
$$;

revoke all on function public.preview_booking_quotation(text) from public;
grant execute on function public.preview_booking_quotation(text) to authenticated;

drop function if exists public.prepare_booking_quotation(text, numeric, text);

create or replace function public.prepare_booking_quotation(
  p_booking_id text,
  p_discount numeric default 0,
  p_payment_terms text default null,
  p_final_amount numeric default null
)
returns public.bookings
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings;
  v_preview jsonb;
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
  v_discount numeric := 0;
  v_components_total numeric;
  v_subtotal numeric;
  v_tax numeric;
  v_final numeric;
  v_quotation_id text;
  v_tax_pct numeric;
begin
  if auth.uid() is null or public.app_role() not in ('ADMIN', 'TEAM_LEAD') then
    raise exception 'Only ADMIN or TEAM_LEAD may prepare quotations';
  end if;

  if p_final_amount is not null and p_final_amount < 0 then
    raise exception 'Final quotation amount cannot be negative';
  end if;

  select * into b from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;

  v_preview := public.preview_booking_quotation(p_booking_id);
  v_base := coalesce((v_preview->>'base_charge')::numeric, 0);
  v_distance := coalesce((v_preview->>'distance_charge')::numeric, 0);
  v_doctor := coalesce((v_preview->>'doctor_charge')::numeric, 0);
  v_emt := coalesce((v_preview->>'emt_charge')::numeric, 0);
  v_oxygen := coalesce((v_preview->>'oxygen_charge')::numeric, 0);
  v_icu := coalesce((v_preview->>'icu_charge')::numeric, 0);
  v_vent := coalesce((v_preview->>'ventilator_charge')::numeric, 0);
  v_picu := coalesce((v_preview->>'pediatric_icu_charge')::numeric, 0);
  v_equipment := coalesce((v_preview->>'equipment_charge')::numeric, 0);
  v_attendant := coalesce((v_preview->>'attendant_charge')::numeric, 0);
  v_air := coalesce((v_preview->>'air_charge')::numeric, 0);
  v_rail := coalesce((v_preview->>'railway_charge')::numeric, 0);
  v_components_total := coalesce((v_preview->>'subtotal')::numeric, 0);
  v_discount := greatest(0, coalesce(p_discount, 0));
  v_subtotal := greatest(0, v_components_total - v_discount);
  v_tax_pct := coalesce((v_preview->>'tax_percent')::numeric, 5);
  v_tax := round(v_subtotal * v_tax_pct / 100, 2);
  v_final := v_subtotal + v_tax;

  if p_final_amount is not null then
    v_final := round(p_final_amount, 2);
    v_subtotal := greatest(0, round(v_final / (1 + v_tax_pct / 100), 2));
    if v_subtotal >= v_components_total then
      v_additional := v_subtotal - v_components_total;
      v_discount := 0;
    else
      v_additional := 0;
      v_discount := v_components_total - v_subtotal;
    end if;
    v_tax := v_final - v_subtotal;
  end if;

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
      q_discount = v_discount,
      q_tax_percent = v_tax_pct,
      q_tax_amount = v_tax,
      q_final_amount = v_final,
      q_payment_terms = p_payment_terms,
      status = case
        when b.status in ('VERIFIED', 'SENT_TO_TEAM_LEAD', 'ALLOCATION_PENDING', 'BUDGET_PENDING')
          then 'QUOTATION_SENT'
        else b.status
      end
  where id = p_booking_id
  returning * into b;

  insert into public.audit_logs(
    user_id, user_name, user_role, action, booking_id, entity_type, previous_value, new_value
  )
  select auth.uid(), coalesce(pr.full_name, pr.email, ''), public.app_role(),
         'Quotation prepared', b.id, 'QUOTATION', null, v_quotation_id
  from public.profiles pr where pr.id = auth.uid();

  return b;
end;
$$;

revoke all on function public.prepare_booking_quotation(text, numeric, text, numeric) from public;
grant execute on function public.prepare_booking_quotation(text, numeric, text, numeric) to authenticated;

notify pgrst, 'reload schema';
commit;