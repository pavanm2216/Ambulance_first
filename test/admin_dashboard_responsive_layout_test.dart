import 'package:ambulance_first/roles/admin/screens/admin_dashboard_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_fleet_screen.dart';
import 'package:ambulance_first/roles/admin/store/admin_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard lays out at 320px without exceptions', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 498);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminDashboardScreen(
            store: store,
            onOpenBookingDetail: (_) {},
            onNavigateTab: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Revenue & Quotations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin fleet lays out at 320px without exceptions', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 498);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminFleetScreen(store: store)),
      ),
    );

    expect(find.text('Fleet Command'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}