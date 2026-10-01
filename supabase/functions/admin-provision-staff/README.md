# Admin Staff Provisioning Edge Function

Provisions an operational staff Auth user from an authenticated Admin session,
creates the matching operational resource, and sends a Supabase invitation.

## Provisioning workflow

```text
Admin Portal
   |
   v
admin-provision-staff
   |
   +--> Supabase Auth inviteUserByEmail()
   |       |
   |       +--> invitation email
   |       +--> redirect to Flutter /invite
   |
   +--> auth.users
   |       |
   |       +--> existing on_auth_user_created trigger
   |               |
   |               +--> profiles row
   |
   +--> UPDATE profiles with approved role/details
   |
   +--> DRIVER / DOCTOR / CUSTOMER_CARE resource
   |
   +--> audit_logs
```

The `profiles` table is **updated**, not inserted, because the live database
already has an `on_auth_user_created` trigger that creates the profile row.

## Roles

- `DRIVER` -> `drivers`
- `DOCTOR` -> `doctors`
- `CUSTOMER_CARE` -> `customer_care`
- `TEAM_LEAD` -> `profiles` only (no dedicated table is currently confirmed)

## Edge Function secrets

The function prefers the current Supabase secret names:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEYS`
- `SUPABASE_SECRET_KEYS`

It also supports the legacy names while a project is being migrated:

- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Never put the secret/service-role key in Flutter, `.env`, Netlify frontend
variables, or the web bundle.

## Optional configuration

`APP_URL` can be supplied as a non-secret Edge Function environment variable.

If omitted, the function uses the current production Flutter site:

```text
https://mellow-longma-638c7a.netlify.app
```

The invitation redirect is:

```text
https://mellow-longma-638c7a.netlify.app/invite
```

That URL must be present in Supabase Authentication > URL Configuration >
Redirect URLs.

## Request shape

```json
{
  "role": "DOCTOR",
  "name": "Dr Example",
  "email": "doctor@example.com",
  "phone": "+91...",
  "specialization": "Emergency Medicine",
  "experience_years": 5,
  "license_number": "...",
  "is_pediatric_capable": true,
  "current_hospital": "..."
}
```

For a driver, use `license_number`, `license_expiry`, `experience_years`,
`supported_categories`, and `current_location` as applicable.

For Customer Care, use `department` and `shift` as applicable.
