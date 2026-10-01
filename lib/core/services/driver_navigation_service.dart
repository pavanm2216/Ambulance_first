import 'package:geolocator/geolocator.dart';

import '../models/driver_models.dart';
import 'driver_location_service.dart';
import 'live_road_route_service.dart';

/// Builds external driving directions with an explicit ambulance origin.
///
/// This deliberately has no address fallback: opening Maps without valid
/// coordinates makes Maps substitute the handset's "Your location" value.
class DriverNavigationService {
  DriverNavigationService({DriverLocationService? locationService})
    : _locationService = locationService ?? DriverLocationService.instance;

  final DriverLocationService _locationService;

  static const Duration gpsTimeout = Duration(seconds: 15);

  static bool hasValidCoordinates(double? latitude, double? longitude) =>
      latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static Uri buildDirectionsUri({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    if (!hasValidCoordinates(originLatitude, originLongitude) ||
        !hasValidCoordinates(destinationLatitude, destinationLongitude)) {
      throw const FormatException(
        'Navigation requires valid ambulance and destination coordinates.',
      );
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '$originLatitude,$originLongitude',
      'destination': '$destinationLatitude,$destinationLongitude',
      'travelmode': 'driving',
    });
  }

  static bool canNavigate({required String status, String milestone = ''}) =>
      LiveRoadRouteService.hasActiveNavigation(
        status: status,
        milestone: milestone,
      );

  Future<Uri> directionsForBooking(DriverBooking booking) async {
    if (!canNavigate(
      status: booking.status,
      milestone: booking.tripMilestone,
    )) {
      throw StateError('Navigation is not available for this trip stage.');
    }

    final leg = LiveRoadRouteService.resolveLeg(
      status: booking.status,
      milestone: booking.tripMilestone,
      patientOnboardConfirmed: booking.patientOnboardConfirmed,
    );
    final destinationLatitude = leg == LiveTripLeg.pickup
        ? booking.pickupLatitude
        : booking.destinationLatitude;
    final destinationLongitude = leg == LiveTripLeg.pickup
        ? booking.pickupLongitude
        : booking.destinationLongitude;
    if (!hasValidCoordinates(destinationLatitude, destinationLongitude)) {
      throw const FormatException(
        'The active trip destination does not have valid coordinates.',
      );
    }

    // A navigation tap must obtain a current device fix. We intentionally do
    // not fall back to pickup/customer coordinates or an unbounded old ping.
    final Position position = await _locationService
        .getCurrentPosition()
        .timeout(
          gpsTimeout,
          onTimeout: () {
            throw const DriverLocationException(
              'GPS fix timed out. Wait for a current location and try again.',
              category: DriverLocationErrorCategory.unavailable,
            );
          },
        );
    return buildDirectionsUri(
      originLatitude: position.latitude,
      originLongitude: position.longitude,
      destinationLatitude: destinationLatitude!,
      destinationLongitude: destinationLongitude!,
    );
  }
}
