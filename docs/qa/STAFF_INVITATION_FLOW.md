# Staff Invitation Flow

## Production URLs

Flutter production site:

`https://mellow-longma-638c7a.netlify.app`

Staff invitation setup route:

`https://mellow-longma-638c7a.netlify.app/invite`

Add the exact setup route under:

**Supabase Dashboard -> Authentication -> URL Configuration -> Redirect URLs**

The existing Site URL remains:

`https://mellow-longma-638c7a.netlify.app`

## Flow

1. Admin provisions a Driver, Doctor, Customer Care agent, or Team Lead.
2. `admin-provision-staff` calls `inviteUserByEmail()`.
3. Supabase creates `auth.users` and the existing `on_auth_user_created` trigger creates `profiles`.
4. The Edge Function updates that profile with the approved role/details.
5. The invitation email redirects to `/invite`.
6. Supabase establishes the invitation session.
7. Flutter shows the staff account setup screen.
8. The staff member chooses a password with `auth.updateUser()`.
9. The user is taken into the role-specific portal.
10. Later, the same normal login page accepts the email/password and routes by the `profiles.role`.

## Client key

Use the public Supabase publishable key for the Flutter web build:

```text
--dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

The legacy `SUPABASE_ANON_KEY` define is still accepted by the client for compatibility.

Never place a Supabase secret/service-role key in Flutter or Netlify frontend
assets.

## Edge Function

The Edge Function prefers:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEYS`
- `SUPABASE_SECRET_KEYS`

Legacy key names are accepted as a fallback.

The optional `APP_URL` variable can override the production site URL used for
invitation redirects.
