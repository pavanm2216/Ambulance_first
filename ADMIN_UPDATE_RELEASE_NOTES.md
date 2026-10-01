# Admin Update — September 20, 2026

This package updates the Flutter Admin workspace against the senior-built React Admin feature analysis.

### Updated
- Master Operations dashboard
- All Bookings registry/search/filter/detail
- Ambulance Fleet management UI and controlled status operation
- Staff directory/provisioning entry point
- Budgets & Quotations financial view/breakdown
- Analytics & Reports with real date scoping
- Audit Trail search/event detail
- Pricing & System Settings retained on the canonical pricing table
- Admin repository centralized around canonical Supabase/RPC/Edge Function operations

### Backend gates
- Deploy `docs/migrations/PHASE_ADMIN_FLEET_CONTROLS.sql` before using fleet status mutation.
- Deploy `supabase/functions/admin-provision-staff` before staff invitation/provisioning.
- Complete the project's existing RLS replacement validation before enabling privileged mutations.

### Validation limitation
The current execution environment does not contain Flutter/Dart CLI, so this package has not been represented as having passed `flutter analyze`, `flutter test`, or a release build. Run those commands on the development machine before release.

## 2026-09-22 — Admin Fleet Persistence + Team Lead Dispatch Sync

- Fixed Admin Fleet registration so new ambulances are persisted to `public.ambulances` through `admin_register_ambulance()` instead of only living in Flutter memory.
- Admin Fleet now reloads from Supabase after successful registration, so Total Fleet / Available counts survive logout and re-login.
- Credentialed Driver details entered during ambulance registration are sent through the existing Admin staff provisioning service so the driver becomes part of the canonical driver roster when provisioning succeeds.
- Team Lead allocation workspace refreshes canonical ambulance/driver/doctor/EMT data when it opens, allowing newly registered AVAILABLE ambulances to appear without restarting the app.
- Added `docs/migrations/ADMIN_FLEET_REGISTRATION_FIX.sql` for standalone database deployment.

- Team Lead EMT loading now uses `get_team_lead_emt_profiles()` instead of a direct `profiles` SELECT, avoiding profiles RLS from hiding valid EMT resources.
- The new migration `docs/migrations/TEAM_LEAD_EMT_RESOURCE_ACCESS_FIX.sql` must be applied before testing EMT allocation.
