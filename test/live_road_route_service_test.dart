import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/core/services/live_road_route_service.dart';

void main() {
  group('LiveRoadRouteService.resolveLeg', () {
    test('uses pickup as the first destination before pickup confirmation', () {
      expect(
        LiveRoadRouteService.resolveLeg(status: 'DRIVER_ASSIGNED'),
        LiveTripLeg.pickup,
      );
      expect(
        LiveRoadRouteService.resolveLeg(status: 'ASSIGNED'),
        LiveTripLeg.pickup,
      );
      expect(
        LiveRoadRouteService.resolveLeg(status: 'PICKUP_STARTED'),
        LiveTripLeg.pickup,
      );
    });

    test(
      'keeps pickup as the target until customer confirms patient onboard',
      () {
        expect(
          LiveRoadRouteService.resolveLeg(status: 'PATIENT_PICKED_UP'),
          LiveTripLeg.pickup,
        );
        expect(
          LiveRoadRouteService.resolveLeg(
            status: 'PATIENT_PICKED_UP',
            patientOnboardConfirmed: true,
          ),
          LiveTripLeg.hospital,
        );
        expect(
          LiveRoadRouteService.resolveLeg(
            status: 'IN_TRANSIT',
            patientOnboardConfirmed: true,
          ),
          LiveTripLeg.hospital,
        );
        expect(
          LiveRoadRouteService.resolveLeg(
            status: 'ARRIVED',
            patientOnboardConfirmed: true,
          ),
          LiveTripLeg.hospital,
        );
      },
    );

    test('milestone can switch the route to the hospital', () {
      expect(
        LiveRoadRouteService.resolveLeg(
          status: 'PICKUP_STARTED',
          milestone: 'PATIENT_PICKED_UP',
          patientOnboardConfirmed: true,
        ),
        LiveTripLeg.hospital,
      );
    });

    test('arrival, completion, and cancellation disable active navigation', () {
      for (final status in ['ARRIVED', 'SERVICE_COMPLETED', 'CANCELLED']) {
        expect(
          LiveRoadRouteService.hasActiveNavigation(status: status),
          isFalse,
        );
      }
    });

    test('only accepts recent persisted driver telemetry', () {
      final now = DateTime(2026, 1, 1, 12);
      expect(
        LiveRoadRouteService.hasFreshDriverLocation(
          now.subtract(const Duration(seconds: 59)),
          now: now,
        ),
        isTrue,
      );
      expect(
        LiveRoadRouteService.hasFreshDriverLocation(
          now.subtract(const Duration(seconds: 61)),
          now: now,
        ),
        isFalse,
      );
      expect(
        LiveRoadRouteService.hasFreshDriverLocation(null, now: now),
        isFalse,
      );
    });
  });
}
