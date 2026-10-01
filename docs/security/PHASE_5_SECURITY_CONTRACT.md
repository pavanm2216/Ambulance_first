# Phase 5 — Backend Security & RLS Contract

## Status

**Phase 5 foundation prepared; production RLS policy replacement is intentionally not applied yet.**

The existing Supabase database has RLS enabled on the audited operational tables, but several tables currently expose permissive `ALL` policies. Replacing those policies without the exact current policy output and a verified write matrix could break the existing React website.

This phase therefore separates the work into:

1. **Safe foundation** — role lookup helpers that do not change table access.
2. **Compatibility verification** — capture exact policies and client-side writes.
3. **Policy replacement** — only after the compatibility matrix is approved.
4. **Controlled Admin writes** — after role-aware RLS/backend operations are validated.

## Canonical authorization model

```text
auth.uid()
    ↓
public.profiles.id
    ↓
public.profiles.role
    ↓
role-aware table policy
```

Confirmed application roles:

- CUSTOMER
- ADMIN
- DOCTOR
- DRIVER
- TEAM_LEAD
- CUSTOMER_CARE

EMT is not added as a profile role because the current backend evidence does not confirm it.

## Required access direction

| Table | Customer | Customer Care | Team Lead | Driver | Doctor | Admin |
|---|---|---|---|---|---|---|
| profiles | own row | operationally scoped | operationally scoped | own row | own row | read/manage as approved |
| bookings | own bookings | workflow scope | workflow scope | assigned scope | assigned scope | read |
| ambulances | none | read/scoped | operational scope | assigned scope | none | read/manage |
| drivers | none | read/scoped | operational scope | own resource | none | read/manage |
| doctors | none | read/scoped | operational scope | none | own resource | read/manage |
| customer_care | none | own resource | operational scope | none | none | read/manage |
| booking_status_history | own booking | workflow scope | workflow scope | assigned booking | assigned booking | read |
| booking_vitals | own booking where product permits | clinical workflow | clinical workflow | assigned booking | assigned booking | read |
| booking_doctor_assessments | own booking where product permits | workflow scope | workflow scope | assigned booking | assigned booking | read |
| notifications | own notifications | own notifications | own notifications | own notifications | own notifications | read as required |
| audit_logs | none | authorized read | authorized read | authorized read | authorized read | read |

**Important:** the exact row predicates must be derived from the actual foreign keys/columns and existing workflow code. Do not implement a predicate merely because a UI model contains a similarly named field.

## Current Flutter boundary

The Flutter Admin repository remains read-only until the policy/backend contract is verified. This is deliberate. Client-side role checks are useful for UX but are not a substitute for Supabase RLS.

## Staff account creation

Do not copy the React browser pattern that calls `supabase.auth.signUp()` from an Admin session for privileged staff creation. That can replace the active auth session and is not an appropriate privileged-account provisioning boundary.

Preferred production flow:

```text
Admin Flutter
   ↓
secure authenticated backend operation / Edge Function
   ↓
create Auth user
   ↓
create profile + operational resource
   ↓
write audit event
   ↓
return non-secret result
```

The service-role key must remain server-side.

## Audit logs

Admin/operational clients must not be allowed to freely insert, update, or delete audit history. Audit creation should occur from trusted backend operations or narrowly scoped server-side functions.

## Pricing

No verified persistent pricing/settings table exists in the audited contract. Do not create pricing RLS policies until the persistent pricing design is approved.
