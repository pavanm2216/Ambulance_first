-- Ambulance First — Phase 7 persistent pricing configuration
-- NON-DESTRUCTIVE: creates only the new pricing_settings table.
-- Run this in Supabase SQL Editor after Phase 5 role helpers are installed.

create table if not exists public.pricing_settings (
  id text primary key default 'default',
  road_basic_oxygen_base numeric not null default 0,
  road_basic_oxygen_per_km numeric not null default 0,
  road_advanced_icu_base numeric not null default 0,
  road_advanced_icu_per_km numeric not null default 0,
  road_pediatric_icu_base numeric not null default 0,
  road_pediatric_icu_per_km numeric not null default 0,
  air_medevac_base numeric not null default 0,
  railway_base numeric not null default 0,
  dead_body_base numeric not null default 0,
  dead_body_per_km numeric not null default 0,
  doctor_escort numeric not null default 0,
  emt_escort numeric not null default 0,
  ventilator numeric not null default 0,
  incubator numeric not null default 0,
  oxygen numeric not null default 0,
  night_surcharge_percent numeric not null default 0,
  tax_percent numeric not null default 5,
  updated_by uuid null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.pricing_settings enable row level security;

-- Admins can read and maintain the shared pricing configuration.
drop policy if exists pricing_settings_admin_select on public.pricing_settings;
create policy pricing_settings_admin_select
on public.pricing_settings
for select
to authenticated
using (public.is_admin());

drop policy if exists pricing_settings_admin_insert on public.pricing_settings;
create policy pricing_settings_admin_insert
on public.pricing_settings
for insert
to authenticated
with check (public.is_admin() and updated_by = auth.uid());

drop policy if exists pricing_settings_admin_update on public.pricing_settings;
create policy pricing_settings_admin_update
on public.pricing_settings
for update
to authenticated
using (public.is_admin())
with check (public.is_admin() and updated_by = auth.uid());

-- Seed exactly one neutral configuration row. This is configuration, not operational/fake data.
insert into public.pricing_settings (id)
values ('default')
on conflict (id) do nothing;
