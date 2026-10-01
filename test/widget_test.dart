import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/main.dart';
import 'package:ambulance_first/roles/admin/widgets/stitch_header.dart';
import 'package:ambulance_first/roles/customer/widgets/ambulance_first_button.dart';

void main() {
  testWidgets('Ambulance First unified app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AmbulanceFirstUnifiedApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome to Ambulance First'), findsOneWidget);
    expect(find.text('Enter workspace'), findsOneWidget);
  });

  testWidgets('Admin profile button opens profile sheet with sign out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchHeader(
            title: 'Dashboard',
            subtitle: 'Supabase Live',
            userName: 'Central Command Admin',
            userEmail: 'admin@ambulancefirst.com',
            onSignOut: () {},
            onOpenDrawer: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Admin profile'));
    await tester.pumpAndSettle();

    expect(find.text('Central Command Admin'), findsOneWidget);
    expect(find.text('admin@ambulancefirst.com'), findsWidgets);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('Long customer action text fits within a compact mobile width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 118,
              child: AmbulanceFirstButton(
                label: 'REVIEW & AUTHORIZE',
                onPressed: () {},
                variant: AmbulanceFirstButtonVariant.primary,
                icon: Icons.verified_rounded,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
