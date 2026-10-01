# Phase 15 — Customer Booking Location + Live Schema Fix v3

## Root cause

The Customer booking RPC uses `jsonb_populate_record(null::public.bookings, v_payload)`. PostgreSQL does not apply the table column defaults to omitted keys during this record population. The live `bookings` table has several NOT NULL workflow fields, so omitting them produced errors such as:

- `customer_care_verified` violates not-null constraint
- subsequent NOT NULL workflow fields could fail in the same way

The live schema does **not** contain the legacy `customer_verified` column.

## Fix

`create_customer_booking(jsonb)` now:

- strips server-controlled workflow, verification, assignment, quotation, and trip fields from the customer payload; route calculation metadata is retained after the authenticated route calculation step;
- explicitly initializes every live NOT NULL booking workflow field;
- sets `status = NEW`;
- sets `customer_care_verified = false`;
- sets `quotation_revision = 0`;
- initializes all six `cc_check_*` fields to `false`;
- sets `customer_id = auth.uid()`;
- retains normal customer request fields including pickup GPS/location source.

No `customer_verified` column is added or referenced.

## SQL to run

Run:

`docs/migrations/PHASE_15_CUSTOMER_BOOKING_LOCATION_AND_CREATE_FIX.sql`

Then test a new customer booking.

## QA

Use:

`docs/migrations/PHASE_15_CUSTOMER_BOOKING_LOCATION_QUERIES.sql`

The QA queries are aligned with the supplied live `public.bookings` schema.
