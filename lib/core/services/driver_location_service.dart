import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// A small foreground GPS service used by the Driver app.
///
/// The current Flutter prototype keeps the live location in memory. When the
/// backend is introduced, the callback in [startTracking] is the integration
/// point for publishing the position through FastAPI/WebSocket/Firebase.
class DriverLocationService {
  DriverLocationService._();

  static final DriverLocationService instance = DriverLocationService._();

  StreamSubscription<Position>? _subscription;

  bool get isTracking => _subscription != null;

  Future<Position> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const DriverLocationException(
          'Location services are turned off. Please enable GPS and try again.',
          category: DriverLocationErrorCategory.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const DriverLocationException(
          'Location permission was denied. GPS is required for driver operations.',
          category: DriverLocationErrorCategory.permissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const DriverLocationException(
          'Location permission is permanently denied. Enable it from device settings.',
          category: DriverLocationErrorCategory.permissionPermanentlyDenied,
        );
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } on DriverLocationException {
      rethrow;
    } catch (e) {
      throw DriverLocationException(
        'Unable to obtain a valid GPS fix: $e',
        category: DriverLocationErrorCategory.unavailable,
      );
    }
  }

  Future<Position> startTracking({
    required void Function(Position) onPosition,
    void Function(DriverLocationException)? onError,
  }) async {
    await stopTracking();

    final initial = await getCurrentPosition();
    onPosition(initial);

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      onPosition,
      onError: (dynamic error) {
        final ex = error is DriverLocationException
            ? error
            : DriverLocationException(
                'Location stream error: $error',
                category: DriverLocationErrorCategory.unavailable,
              );
        onError?.call(ex);
      },
      cancelOnError: false,
    );

    return initial;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

enum DriverLocationErrorCategory {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class DriverLocationException implements Exception {
  const DriverLocationException(
    this.message, {
    this.category = DriverLocationErrorCategory.unavailable,
  });

  final String message;
  final DriverLocationErrorCategory category;

  @override
  String toString() => message;
}
