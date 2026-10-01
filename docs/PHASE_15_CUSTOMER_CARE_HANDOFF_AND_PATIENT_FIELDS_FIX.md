# Phase 15 — Customer Care Handoff + Patient Identity Fix

## Fixed

### Customer Care card
The Customer Care card was falling back to `Booking.patientAge = 0` and `relationshipToPatient = Self` because the Customer booking payload did not send:

- `patient_age`
- `patient_gender`
- `customer_relationship_to_patient`

The booking model now sends those real values and the Supabase repository reads the canonical database column `customer_relationship_to_patient`.

### Send to Team Lead
The Customer Care screen already called the backend RPC, but backend failures were swallowed and the UI gave no error. The handoff now:

1. Calls `customer_care_verify_and_handoff`.
2. Persists `SENT_TO_TEAM_LEAD`.
3. Persists Customer Care verification metadata.
4. Marks all six handoff checks complete in the booking.
5. Writes an audit event.
6. Reloads the booking from Supabase.
7. Surfaces the real RPC error to the operator if the mutation fails.

The Team Lead feed remains database-authoritative through `get_team_lead_bookings()`.

## SQL to run

Run:

`docs/migrations/PHASE_15_CUSTOMER_CARE_HANDOFF_AND_PATIENT_FIELDS_FIX.sql`

## Verification

After clicking **SEND TO TEAM LEAD**, run:

```sql
select
  id,
  status,
  customer_care_verified,
  customer_care_verified_at,
  cc_verified_by_name,
  cc_verified_at,
  cc_call_status,
  cc_notes,
  cc_priority,
  cc_check_patient_condition,
  cc_check_oxygen_therapy,
  cc_check_ventilator_loaded,
  cc_check_doctor_designated,
  cc_check_receiving_bed_secured,
  cc_check_route_priority_cleared,
  patient_name,
  patient_age,
  patient_gender,
  customer_relationship_to_patient
from public.bookings
where id = '<BOOKING_ID>';
```

Expected after successful handoff:

```text
status = SENT_TO_TEAM_LEAD
customer_care_verified = true
cc_check_* = true for all six checks
```

The Team Lead portal should then show the booking in its quotation queue and be able to prepare the quotation.
