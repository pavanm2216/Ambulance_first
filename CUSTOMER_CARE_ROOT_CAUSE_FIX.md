# Customer Care Root Cause Fix — Handoff State

## Root cause

The Customer Care dashboard was already receiving the canonical `bookings.status` correctly through `get_customer_care_bookings()` and mapping it in `CustomerCareRepository._mapCase()`.

The `Send to Team Lead (Handover)` handler then performed a second workflow-state check through `get_customer_care_booking_details()`. That details RPC does not reliably expose the canonical `bookings.status` field. The handler therefore read an empty status and displayed `Booking must be verified before handoff` even though Supabase contained `status = VERIFIED`.

The repository handoff method repeated the same invalid preflight check, so removing only the dashboard guard would not have solved the problem.

## Fix

- Dashboard handoff now uses the canonical `CustomerCareCase.status` already loaded from `get_customer_care_bookings()`.
- The dashboard no longer uses the booking-details RPC as a workflow-state gate.
- `sendCustomerCareToTeamLead()` now calls the protected `send_customer_care_to_team_lead()` RPC directly. The backend remains the authoritative authorization/state-transition check.
- After handoff, the repository reloads the canonical Customer Care booking list and verifies `bookings.status == SENT_TO_TEAM_LEAD` from the mapped case.
- Verification persistence now similarly reloads the canonical booking list instead of treating a missing status in the details RPC as a failed database write.
- The verification console no longer uses the details RPC to decide whether the booking is already verified; it uses the canonical case status.

## Expected flow

`VERIFIED` → click `Send to Team Lead` → `send_customer_care_to_team_lead()` → reload canonical booking list → `SENT_TO_TEAM_LEAD`.

The backend VERIFIED requirement is unchanged.
