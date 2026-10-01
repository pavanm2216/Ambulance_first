# Phase 6 — Admin Controlled Operations Contract

## Scope

Admin controlled writes are deliberately split into two categories.

### Direct role-aware database writes

These are candidates for normal authenticated Supabase writes once Phase 5 RLS is verified:

- approved fleet metadata/status updates
- approved non-auth operational resource updates
- pricing configuration (Phase 7)

### Privileged backend operations

These must not be implemented by putting a service-role key in Flutter:

- creating an Auth user for a Driver/Doctor/Customer Care account
- changing `profiles.role`
- disabling/deleting a staff Auth account
- creating a staff resource together with its Auth profile as one operation
- privileged audit events

Recommended implementation: Supabase Edge Functions using server-side service-role credentials, with the caller verified as `ADMIN` through the authenticated user's profile.

## Staff creation contract

A future `admin-create-staff` operation should accept only the minimum required fields:

```text
role: DRIVER | DOCTOR | CUSTOMER_CARE
email
full_name
phone
resource-specific fields
```

Server sequence:

```text
verify JWT
  ↓
lookup profiles by auth.uid()
  ↓
require role ADMIN
  ↓
validate requested role
  ↓
create Auth user
  ↓
create profiles row
  ↓
create matching drivers/doctors/customer_care row
  ↓
write audit_logs
  ↓
return safe public result
```

If any step fails, the server must return an explicit error. Flutter must not claim that the staff account was created.

## Fleet writes

Use the existing `ambulances` table. Do not create another fleet table.

Before implementing CRUD, verify the exact ambulance columns and constraints from the current database schema. The Admin UI must map to those columns rather than inventing fields.

## Deletion

Do not expose historical staff deletion in the first Admin write release. Prefer status/suspension changes where the existing schema supports them.

## Audit

Audit records must be generated server-side for privileged operations. Flutter must not fabricate `user_id`, role, timestamps, or audit history.
