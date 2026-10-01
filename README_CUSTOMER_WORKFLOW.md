# AeroMed Customer Flutter App

This project is the Customer-role Flutter experience for booking and tracking ambulance services. It keeps the glass/neumorphic visual system from the starter project and mirrors the workflow analyzed from the original web application.

## Customer workflow

1. **Create a request** from the Book tab. The form captures a transport mode (Road, Railway, Air, or Dead Body Transfer), requester details, patient information, pickup and destination, preferred timing, emergency priority, and medical requirements. The initial request is deliberately **price-free**: the customer does not choose or purchase a priced ambulance package.
2. **Review and confirm** the request in the booking summary sheet before submission.
3. **Customer Care verification** begins after submission. New requests move to `CUSTOMER_CARE_CONTACT_PENDING`, with the customer-facing message that Customer Care will call to verify clinical and route details.
4. **Operations quotation** is shown in Quotations & Invoices after verification. The Team Lead determines the operational resources and dispatch cost; the customer can then review itemized ambulance, distance, clinical support, equipment, tax, payment terms, and validity.
5. **Accept or reject** the quotation. Acceptance moves the request to `CUSTOMER_ACCEPTED` and indicates that allocation is in progress. Rejection records a reason and notifies operations.
6. **Dispatch and live trip** are represented by the Active tab, with ambulance, route, ETA, crew, telemetry, milestones, and patient vitals.
7. **Cancel** eligible requests with a required reason. The request becomes `CANCELLED`.
8. **History and invoices** expose completed and cancelled case records.

## App structure

- `lib/screens/customer_shell.dart`: Customer navigation, in-memory booking state, cancellation, quotation response, and notifications.
- `lib/screens/book_ambulance_screen.dart`: Customer request form and ambulance selection.
- `lib/screens/booking_summary_sheet.dart`: Final confirmation step.
- `lib/screens/my_bookings_screen.dart`: Booking list, statuses, cancellation, and booking details.
- `lib/screens/quotations_invoices_screen.dart`: Quotation acceptance/rejection and invoices.
- `lib/screens/active_trip_screen.dart`: Active dispatch and live trip presentation.
- `lib/screens/booking_history_screen.dart`: Completed/cancelled records.
- `lib/models/booking.dart`: Customer-facing booking, quotation, vitals, and ambulance option models.
- `lib/services/customer_booking_workflow_service.dart`: Centralized mock state engine for valid transitions, quotation creation, assignment, rejection, cancellation, and invoice generation.

## Data behavior

The app is intentionally local/in-memory for this prototype. Seeded records demonstrate an active trip, a quotation awaiting customer response, an explicit post-completion invoice, and completed history. New requests remain `NEW` after submission and can be progressed through the same centralized mock workflow engine from My Bookings. Supabase or another backend can be connected later without changing the customer-facing workflow contracts.

Transport mode is stored separately from an assigned ambulance/service. A new request stores `ROAD_AMBULANCE`, `RAILWAY_AMBULANCE`, `AIR_AMBULANCE`, or `DEAD_BODY_TRANSFER`; an assigned vehicle and crew are only represented after quotation acceptance and allocation. Quotation and invoice are separate objects, and invoices are created only after service completion.

## Validation

The sandbox used for this update does not have the Flutter SDK installed, so `flutter analyze` and a device build could not be executed here. The source changes are limited to Dart files and were reviewed against the existing project APIs and test expectations.

Run locally with:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Visual direction

The app uses the supplied starter's AeroMed glass/neumorphic system: dark teal surfaces, mint action color, coral emergency actions, rounded cards, bottom navigation, tactile shadows, and restrained motion for the confirmation and live-trip moments.

## License / prototype note

This is a workflow prototype. Real emergency dispatch, payments, GPS, medical data security, and backend authorization require production integrations and clinical/compliance review before deployment.

_Created for the AeroMed Customer role workflow._
