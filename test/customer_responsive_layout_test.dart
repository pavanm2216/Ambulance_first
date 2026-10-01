import 'package:ambulance_first/core/models/auth_user.dart';
import 'package:ambulance_first/core/models/booking.dart';
import 'package:ambulance_first/core/services/shared_booking_store.dart';
import 'package:ambulance_first/roles/customer/screens/customer_active_trip_screen.dart';
import 'package:ambulance_first/roles/customer/screens/customer_bookings_screen.dart';
import 'package:ambulance_first/roles/customer/screens/customer_dashboard_screen.dart';
import 'package:ambulance_first/roles/customer/screens/customer_history_screen.dart';
import 'package:ambulance_first/roles/customer/screens/customer_quotations_screen.dart';
import 'package:ambulance_first/roles/customer/screens/home_services_screen.dart';
import 'package:ambulance_first/roles/customer/screens/customer_shell.dart';
import 'package:ambulance_first/roles/customer/theme/ambulance_first_theme.dart';
import 'package:ambulance_first/roles/customer/screens/book_ambulance_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = AuthUser(
    id: 'customer-responsive-test',
    name: 'Customer Test',
    email: 'customer@example.com',
    phone: '9876543210',
    role: 'CUSTOMER',
  );

  final viewports = [
    const Size(320, 568),
    const Size(360, 780),
    const Size(375, 498),
    const Size(440, 956),
    const Size(768, 1024),
    const Size(1280, 800),
  ];
  final pages = <String, Widget Function()>{
    'Dashboard': () => CustomerDashboardScreen(
      user: user,
      onBookNewAmbulance: () {},
      onNavigateToSection: (_) {},
    ),
    'Bookings': () => CustomerBookingsScreen(
      user: user,
      onBookNewAmbulance: () {},
    ),
    'Active Trips': () => CustomerActiveTripScreen(
      user: user,
      onBookNewAmbulance: () {},
    ),
    'Quotations': () => CustomerQuotationsScreen(
      user: user,
      onBookNewAmbulance: () {},
    ),
    'History': () => CustomerHistoryScreen(
      user: user,
      onBookNewAmbulance: () {},
    ),
    'Home Services': () => HomeServicesScreen(
      user: user,
      onBookingCreated: (_) {},
    ),
    'Customer Shell': () => const CustomerShell(user: user),
    'Booking wizard': () => BookAmbulanceWizardScreen(
      user: user,
      onBookingCreated: (_) {},
      onCancel: () {},
    ),
  };
  final originalBookings = List<Booking>.of(SharedBookingStore.bookings);

  setUp(() {
    SharedBookingStore.bookings
      ..clear()
      ..addAll([
        _booking(id: 'BK-2026-000000000001', status: 'IN_TRANSIT'),
        _booking(
          id: 'BK-2026-000000000002',
          status: 'QUOTATION_SENT',
          quotation: Quotation(
            id: 'QT-2026-000000000002',
            status: 'SENT',
            baseAmbulanceCharge: 4500,
            distanceCharge: 1200,
            doctorCharge: 900,
            emtCharge: 600,
            oxygenCharge: 250,
            icuCharge: 800,
            ventilatorCharge: 500,
            equipmentCharge: 300,
            attendantCharge: 200,
            additionalCharges: 100,
            discount: 0,
            taxPercent: 5,
            paymentTerms: 'Due on arrival',
            validUntil: 'Tomorrow',
          ),
        ),
        _booking(
          id: 'BK-2026-000000000003',
          status: 'SERVICE_COMPLETED',
          invoice: Invoice(
            id: 'INV-2026-000000000003',
            bookingId: 'BK-2026-000000000003',
            quotationId: 'QT-2026-000000000003',
            serviceDetails: 'Advanced life support transfer',
            total: 14800,
            paymentStatus: 'Paid',
            invoiceDate: '29 Sep 2026',
          ),
        ),
        _booking(id: 'BK-2026-000000000004', status: 'CANCELLED'),
      ]);
  });

  tearDown(() {
    SharedBookingStore.bookings
      ..clear()
      ..addAll(originalBookings);
  });

  testWidgets('customer pages and booking wizard fit responsive viewports', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      for (final page in pages.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AmbulanceFirstTheme.lightTheme(),
            home: Scaffold(body: page.value()),
          ),
        );
        await tester.pumpAndSettle();
        _expectNoLayoutException(tester, viewport, page.key);
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AmbulanceFirstTheme.lightTheme(),
          home: Scaffold(
            body: BookAmbulanceWizardScreen(
              user: user,
              onBookingCreated: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, viewport, 'Wizard service step');

      await _continueWizard(tester);
      _expectNoLayoutException(tester, viewport, 'Wizard contact step');
      await _continueWizard(tester);
      _expectNoLayoutException(tester, viewport, 'Wizard patient step');

      final textFields = find.byType(TextFormField);
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.first, 'Alexandria Patient');
      await tester.enterText(textFields.last, '42');
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.first);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Current Medical Condition'), findsOneWidget);
      expect(dropdowns, findsNWidgets(2));
      await tester.ensureVisible(find.text('Current Medical Condition'));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stable / Routine').last);
      await tester.pumpAndSettle();
      await _continueWizard(tester);
      expect(find.textContaining('Step 4 of 7'), findsOneWidget);
      _expectNoLayoutException(tester, viewport, 'Wizard medical step');
      final categoryDropdown = find.byType(DropdownButtonFormField<String>);
      expect(categoryDropdown, findsOneWidget);
      await tester.ensureVisible(categoryDropdown);
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oxygen Ambulance (BLS)').last);
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, viewport, 'Wizard medical step');
      await _continueWizard(tester);
      _expectNoLayoutException(tester, viewport, 'Wizard route step');

      final routeFields = find.byType(TextFormField);
      await tester.ensureVisible(routeFields.first);
      await tester.enterText(routeFields.first, 'Long hospital pickup address');
      await tester.enterText(routeFields.at(1), 'Long destination hospital address');
      await _continueWizard(tester);
      _expectNoLayoutException(tester, viewport, 'Wizard schedule step');
      await tester.ensureVisible(find.text('Scheduled'));
      await tester.tap(find.text('Scheduled'));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, viewport, 'Wizard scheduled date/time');
    }
  });
}

Future<void> _continueWizard(WidgetTester tester) async {
  final continueButton = find.text('CONTINUE');
  await tester.ensureVisible(continueButton);
  await tester.tap(continueButton);
  await tester.pumpAndSettle();
}

Booking _booking({
  required String id,
  required String status,
  Quotation? quotation,
  Invoice? invoice,
}) {
  return Booking(
    id: id,
    pickup:
        'St. Catherine Medical Center, North Tower, Bengaluru, Karnataka',
    destination:
        'Regional Advanced Critical Care and Specialty Hospital, Whitefield',
    date: '29 September 2026',
    time: '14:45 IST',
    ambulanceType: 'Advanced Life Support ICU Ambulance',
    status: status,
    amount: 14800,
    customerId: 'customer-responsive-test',
    customerName: 'Customer Test',
    patientName: 'Alexandria Patient With A Long Display Name',
    patientAge: 42,
    patientGender: 'Female',
    relationshipToPatient: 'Primary family caregiver and legal guardian',
    currentCondition: 'Cardiac monitoring and assisted respiratory support',
    driverName: 'Christopher Driver With A Long Name',
    emtName: 'Taylor Paramedic',
    doctorName: 'Jordan Physician',
    vehicleNumber: 'KA-01-AB-1234',
    driverLocationSharing: true,
    driverLocationUpdatedAt: DateTime.utc(2026, 9, 24, 16, 10, 12),
    quotation: quotation,
    invoice: invoice,
  );
}

void _expectNoLayoutException(
  WidgetTester tester,
  Size viewport,
  String section,
) {
  expect(
    tester.takeException(),
    isNull,
    reason: '$section raised a Flutter layout exception at $viewport',
  );
}