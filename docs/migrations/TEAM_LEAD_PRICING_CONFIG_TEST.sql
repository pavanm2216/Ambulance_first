-- Ambulance First - DEVELOPMENT/QA pricing only.
-- Replace these values with approved company tariffs before production use.
-- This migration is intentionally non-zero so the quotation workflow can be tested end-to-end.

insert into public.pricing_settings (
  id,
  road_basic_oxygen_base,
  road_basic_oxygen_per_km,
  road_advanced_icu_base,
  road_advanced_icu_per_km,
  road_pediatric_icu_base,
  road_pediatric_icu_per_km,
  air_medevac_base,
  railway_base,
  dead_body_base,
  dead_body_per_km,
  doctor_escort,
  emt_escort,
  ventilator,
  incubator,
  oxygen,
  night_surcharge_percent,
  tax_percent,
  updated_at
) values (
  'default',
  1800, 25,
  2500, 40,
  4500, 55,
  25000,
  7000,
  2500, 30,
  1000,
  500,
  1200,
  1500,
  300,
  10,
  5,
  now()
)
on conflict (id) do update set
  road_basic_oxygen_base = excluded.road_basic_oxygen_base,
  road_basic_oxygen_per_km = excluded.road_basic_oxygen_per_km,
  road_advanced_icu_base = excluded.road_advanced_icu_base,
  road_advanced_icu_per_km = excluded.road_advanced_icu_per_km,
  road_pediatric_icu_base = excluded.road_pediatric_icu_base,
  road_pediatric_icu_per_km = excluded.road_pediatric_icu_per_km,
  air_medevac_base = excluded.air_medevac_base,
  railway_base = excluded.railway_base,
  dead_body_base = excluded.dead_body_base,
  dead_body_per_km = excluded.dead_body_per_km,
  doctor_escort = excluded.doctor_escort,
  emt_escort = excluded.emt_escort,
  ventilator = excluded.ventilator,
  incubator = excluded.incubator,
  oxygen = excluded.oxygen,
  night_surcharge_percent = excluded.night_surcharge_percent,
  tax_percent = excluded.tax_percent,
  updated_at = now();

-- Example for the current 6.32 km ALS booking:
-- base 2500 + distance 6.32*40 + doctor 1000 + EMT 500 + oxygen 300 = 4552.80
-- 5% tax = 227.64; final = 4780.44
