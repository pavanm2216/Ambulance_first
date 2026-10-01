import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String city;
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. Please enable it in Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    var address = '${position.latitude}, ${position.longitude}';
    var city = '';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
          if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
          if ((place.subLocality ?? '').trim().isNotEmpty)
            place.subLocality!.trim(),
          if ((place.locality ?? '').trim().isNotEmpty)
            place.locality!.trim(),
          if ((place.administrativeArea ?? '').trim().isNotEmpty)
            place.administrativeArea!.trim(),
          if ((place.postalCode ?? '').trim().isNotEmpty)
            place.postalCode!.trim(),
        ];

        if (parts.isNotEmpty) {
          address = parts.join(', ');
        }
        city = (place.locality ?? place.subAdministrativeArea ?? '').trim();
      }
    } catch (_) {
      // Coordinates are still returned when reverse geocoding is unavailable.
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      city: city,
    );
  }
}
