import 'package:ambulance_first/core/services/driver_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverNavigationService.buildDirectionsUri', () {
    test('uses explicit ambulance origin for pickup navigation', () {
      final uri = DriverNavigationService.buildDirectionsUri(
        originLatitude: 17.472768,
        originLongitude: 78.364485,
        destinationLatitude: 17.470000,
        destinationLongitude: 78.360000,
      );

      expect(uri.queryParameters['origin'], '17.472768,78.364485');
      expect(uri.queryParameters['destination'], '17.47,78.36');
      expect(uri.queryParameters['travelmode'], 'driving');
      expect(uri.toString(), isNot(contains('Your%20location')));
    });

    test('uses explicit ambulance origin for hospital navigation', () {
      final uri = DriverNavigationService.buildDirectionsUri(
        originLatitude: 17.472768,
        originLongitude: 78.364485,
        destinationLatitude: 17.467961,
        destinationLongitude: 78.365904,
      );

      expect(uri.queryParameters['origin'], '17.472768,78.364485');
      expect(uri.queryParameters['destination'], '17.467961,78.365904');
    });

    test('rejects invalid or missing coordinates', () {
      expect(
        () => DriverNavigationService.buildDirectionsUri(
          originLatitude: 91,
          originLongitude: 78,
          destinationLatitude: 17,
          destinationLongitude: 78,
        ),
        throwsFormatException,
      );
      expect(DriverNavigationService.hasValidCoordinates(null, 78), isFalse);
    });
  });
}
