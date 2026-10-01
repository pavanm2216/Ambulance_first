-- AeroMed: Driver/ambulance assignment consistency check
-- READ-ONLY diagnostics. Run this before manually repairing any existing
-- ambulance/driver pairing such as ECHO-99.

-- 1) Inspect Marvy/Vishnu/Teja by name/email.
SELECT
    id,
    name,
    email,
    status,
    assigned_ambulance_number,
    assigned_booking_id
FROM public.drivers
WHERE lower(coalesce(name, '')) IN ('marvy', 'vishnu vardhan', 'teja')
   OR lower(coalesce(email, '')) LIKE '%marvy%'
   OR lower(coalesce(email, '')) LIKE '%vishnu%'
   OR lower(coalesce(email, '')) LIKE '%teja%'
ORDER BY name;

-- 2) Inspect the ECHO-99 / ECHO-21 vehicles and their persisted driver fields.
-- If your schema has assigned_driver_id/assigned_driver_name, these will show
-- the authoritative vehicle-side pairing. If not, use the driver-side query.
SELECT *
FROM public.ambulances
WHERE upper(coalesce(id, '')) IN ('ECHO-99', 'ECHO-21')
   OR upper(coalesce(vehicle_number, '')) IN ('ECHO-99', 'ECHO-21')
   OR upper(coalesce(name, '')) IN ('ECHO-99', 'ECHO-21');

-- 3) Driver-side orphan check: a driver claims an ambulance that does not
-- exist in public.ambulances.
SELECT
    d.id,
    d.name,
    d.status,
    d.assigned_ambulance_number
FROM public.drivers d
LEFT JOIN public.ambulances a
  ON upper(trim(coalesce(a.vehicle_number, a.id, ''))) = upper(trim(d.assigned_ambulance_number))
WHERE NULLIF(trim(coalesce(d.assigned_ambulance_number, '')), '') IS NOT NULL
  AND a.id IS NULL;

-- DO NOT run UPDATE statements until the actual ECHO-99 relationship is
-- confirmed. The current registration RPC does not overwrite another
-- driver's assignment.
