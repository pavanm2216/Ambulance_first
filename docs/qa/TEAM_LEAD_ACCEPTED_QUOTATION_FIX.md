# Team Lead Accepted Quotation Fix

## Root cause

The customer acceptance workflow correctly persisted:

- `bookings.status = CUSTOMER_ACCEPTED`
- `bookings.quotation_status = ACCEPTED`
- latest `quotations.status = ACCEPTED`

The Team Lead quotation filter was incorrectly comparing the selected `Accepted` filter against only `Booking.quotation.status == CUSTOMER_ACCEPTED`.

The backend quotation history uses `ACCEPTED`, while the booking workflow uses `CUSTOMER_ACCEPTED`.

That caused the accepted quotation to appear under **All Quotations** but disappear under **Accepted**.

## Fix

The Team Lead quotation filter now treats `bookings.status = CUSTOMER_ACCEPTED` as authoritative and also tolerates the quotation history values `ACCEPTED` and `CUSTOMER_ACCEPTED`.

The same normalization is applied for rejected and sent quotation states.

## Allocation workflow

When a quotation is accepted:

1. Customer accepts quotation.
2. `bookings.status` becomes `CUSTOMER_ACCEPTED`.
3. Team Lead **Accepted** filter displays the quotation.
4. The accepted quotation card exposes **Allocate Ambulance**.
5. Team Lead selects ambulance, driver, and required clinical resources.
6. `allocate_booking()` verifies `CUSTOMER_ACCEPTED` server-side.
7. Successful allocation changes the booking to `ASSIGNED`.
8. Driver receives the assignment and can accept/reject it.

The migration also keeps the PostgreSQL `publish_driver_location()` return-type fix by dropping the existing same-signature function before recreating it.
