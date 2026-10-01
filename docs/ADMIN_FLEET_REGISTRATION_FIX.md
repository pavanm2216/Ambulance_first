# Admin Fleet Registration Persistence Fix

## Problem fixed

The Admin Fleet registration screen previously updated only the Flutter `AdminStore` in memory. The ambulance therefore appeared immediately after registration, but disappeared after logout/re-login and was not visible to the Team Lead portal.

## New flow

Admin Fleet registration -> Supabase `public.ambulances` -> Team Lead backend hydration -> Allocation workspace.

The registration RPC creates the ambulance as `AVAILABLE` and persists its category/capabilities. The existing Admin staff provisioning service is also used to persist the credentialed driver entered in the registration form.

## SQL

If the full `FIX_CUSTOMER_QUOTATION_ACCEPTANCE_AND_DRIVER_DISPATCH.sql` migration is being rerun, the Admin fleet RPC is already included.

If that migration was already applied successfully, run:

`docs/migrations/ADMIN_FLEET_REGISTRATION_FIX.sql`

## Verification

After registering an ambulance, verify in Supabase:

```sql
select
  id,
  vehicle_number,
  name,
  category,
  subtype,
  model,
  base_station,
  status,
  has_oxygen,
  has_icu,
  has_ventilator,
  has_pediatric_icu,
  has_cardiac_monitor,
  has_stretcher,
  assigned_booking_id
from public.ambulances
order by created_at desc;
```

The new vehicle should have `status = 'AVAILABLE'` and `assigned_booking_id IS NULL`.

The Team Lead allocation workspace now refreshes canonical ambulance/driver data when it opens, so a newly registered available ambulance can be selected without requiring a full application restart.
