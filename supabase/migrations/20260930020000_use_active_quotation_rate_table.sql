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
  v_category_rates text;
begin
  if auth.uid() is null or public.app_role() not in ('ADMIN', 'TEAM_LEAD') then
    raise exception 'Only ADMIN or TEAM_LEAD may preview quotations';
  end if;

  select * into b from public.bookings where id = p_booking_id;
  if not found then raise exception 'Booking not found'; end if;

  select rate.* into v_rate
  from public.p as rate
  where upper(trim(coalesce(rate.service_category, ''))) =
        upper(trim(coalesce(b.service_category, '')))
    and (
      nullif(trim(rate.service_subtype), '') is null
      or upper(trim(rate.service_subtype)) =
         upper(trim(coalesce(b.service_subtype, '')))
    )
    and coalesce(rate.is_active, false)
    and (rate.effective_from is null or rate.effective_from <= now())
    and (rate.effective_until is null or rate.effective_until > now())
  order by (nullif(trim(rate.service_subtype), '') is not null) desc,
           rate.effective_from desc nulls last,
           rate.updated_at desc nulls last
  limit 1;
  if not found then
    select string_agg(
      format(
        'subtype=%s active=%s from=%s until=%s',
        coalesce(nullif(trim(rate.service_subtype), ''), '<generic>'),
        coalesce(rate.is_active, false),
        coalesce(rate.effective_from::text, 'null'),
        coalesce(rate.effective_until::text, 'null')
      ),
      '; '
    ) into v_category_rates
    from public.p as rate
    where upper(trim(coalesce(rate.service_category, ''))) =
          upper(trim(coalesce(b.service_category, '')));
    raise exception 'No active quotation rate found for service category % and subtype %; category rows: %',
      b.service_category, b.service_subtype, coalesce(v_category_rates, 'none visible');
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

notify pgrst, 'reload schema';
commit;