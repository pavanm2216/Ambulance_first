import 'package:ambulance_first/core/models/auth_user.dart';
import 'package:ambulance_first/features/customer_care/presentation/shell/customer_care_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final List<String> _renderErrors = [];

void main() {
  const user = AuthUser(
    id: 'customer-care-responsive-test',
    name: 'Customer Care Agent With An Exceptionally Long Name',
    email: 'care@example.com',
    phone: '9876543210',
    role: 'CUSTOMER CARE',
  );

  const viewports = [
    Size(320, 640),
    Size(375, 498),
    Size(440, 956),
    Size(768, 1024),
    Size(1280, 800),
  ];

  testWidgets('Customer Care shell fits and navigates responsive viewports', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _renderErrors.add(details.toString());
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    tester.view.devicePixelRatio = 1;

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      _renderErrors.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerCareShell(key: ValueKey(viewport), user: user),
        ),
      );
      await tester.pumpAndSettle();
      _expectNoException(tester, viewport, 'Dashboard');

      final destinations = viewport.width >= 840
          ? const [
              ('New Requests', 'Urgent Intake Queue'),
              ('Pending Calls', 'No pending Customer Care calls.'),
              ('Handoff Monitor', 'Team Lead Handover Monitor'),
              ('Active Trips', 'Active Ambulance Mission Monitoring'),
              ('All Bookings Archive', 'Master Bookings Archive'),
            ]
          : const [
              ('New', 'Urgent Intake Queue'),
              ('Pending', 'No pending Customer Care calls.'),
              ('Handoff', 'Team Lead Handover Monitor'),
              ('Active', 'Active Ambulance Mission Monitoring'),
            ];

      for (final destination in destinations) {
        _renderErrors.clear();
        final destinationText = find.text(destination.$1).last;
        final tappable = viewport.width >= 840
            ? find.ancestor(
                of: destinationText,
                matching: find.byType(ListTile),
              )
            : find.ancestor(
                of: destinationText,
                matching: find.byType(InkWell),
              );
        await tester.tap(tappable.first);
        await tester.pumpAndSettle();
        _expectNoException(tester, viewport, destination.$1);
        expect(
          find.textContaining(destination.$2),
          findsOneWidget,
          reason: '${destination.$1} did not open at $viewport',
        );
      }

      if (viewport.width < 840) {
        _renderErrors.clear();
        await tester.tap(find.byTooltip('Open Operations Hub'));
        await tester.pumpAndSettle();
        _expectNoException(tester, viewport, 'Operations drawer');
        expect(find.text('All Bookings Archive'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
      }
    }
  });
}

void _expectNoException(
  WidgetTester tester,
  Size viewport,
  String section,
) {
  final exception = tester.takeException();
  final details = _renderErrors.join('\n');
  _renderErrors.clear();
  expect(
    exception,
    isNull,
    reason: '$section raised a Flutter layout exception at $viewport\n$details',
  );
}
