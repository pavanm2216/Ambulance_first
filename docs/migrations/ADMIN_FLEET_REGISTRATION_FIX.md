# Admin Fleet Registration Fix — current_location NOT NULL

The `public.ambulances.current_location` column is NOT NULL in the current database schema.
The previous Admin registration RPC did not populate it, causing PostgreSQL error 23502 during
ambulance registration.

The corrected `ADMIN_FLEET_REGISTRATION_FIX.sql` now writes the selected Base Station into both
`base_station` and `current_location`. If Base Station is blank, `UNASSIGNED` is used so the
NOT NULL constraint is always satisfied.

Run the SQL migration in Supabase SQL Editor, then restart/reload the Flutter app.
