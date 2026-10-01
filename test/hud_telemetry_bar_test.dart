import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/features/driver/presentation/widgets/hud_telemetry_bar.dart';

void main() {
  testWidgets(
    'recalculates ETA when distance remains but telemetry ETA is zero',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudTelemetryBar(speedKmh: 0, etaMinutes: 0, remainingKm: 14),
          ),
        ),
      );

      expect(find.text('30'), findsOneWidget);
    },
  );

  testWidgets('shows placeholders until live route data is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HudTelemetryBar(
            speedKmh: 0,
            etaMinutes: null,
            remainingKm: null,
          ),
        ),
      ),
    );

    expect(find.text('--'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
  });
}
