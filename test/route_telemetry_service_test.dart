import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/core/services/route_telemetry_service.dart';

void main() {
  test('calculates zero distance for identical coordinates', () {
    expect(
      RouteTelemetryService.distanceKm(
        fromLatitude: 12.9716,
        fromLongitude: 77.5946,
        toLatitude: 12.9716,
        toLongitude: 77.5946,
      ),
      closeTo(0, 0.0001),
    );
  });


  test('identical driver and pickup coordinates count as arrived', () {
    expect(
      RouteTelemetryService.withinArrivalThreshold(
        fromLatitude: 12.9716,
        fromLongitude: 77.5946,
        toLatitude: 12.9716,
        toLongitude: 77.5946,
      ),
      isTrue,
    );
  });

  test('points within configured pickup radius count as arrived', () {
    expect(
      RouteTelemetryService.withinArrivalThreshold(
        fromLatitude: 12.9716,
        fromLongitude: 77.5946,
        toLatitude: 12.9720,
        toLongitude: 77.5946,
        thresholdMeters: 150,
      ),
      isTrue,
    );
  });

  test('points outside pickup radius are not marked arrived', () {
    expect(
      RouteTelemetryService.withinArrivalThreshold(
        fromLatitude: 12.9716,
        fromLongitude: 77.5946,
        toLatitude: 12.9816,
        toLongitude: 77.5946,
        thresholdMeters: 150,
      ),
      isFalse,
    );
  });

  test('calculates ETA from live speed', () {
    expect(
      RouteTelemetryService.etaMinutes(distanceKm: 14, speedKmh: 42),
      20,
    );
  });

  test('uses fallback speed when vehicle is stationary', () {
    expect(
      RouteTelemetryService.etaMinutes(distanceKm: 14, speedKmh: 0),
      30,
    );
  });
}
