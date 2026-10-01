import 'package:flutter/foundation.dart';

class DriverLocationSnapshot {
  const DriverLocationSnapshot({
    required this.driverId,
    required this.bookingId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.heading,
    required this.updatedAt,
    required this.ambulanceUnit,
  });

  final String driverId;
  final String? bookingId;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedKmh;
  final double heading;
  final DateTime updatedAt;
  final String ambulanceUnit;
}

/// In-memory live-location bus for the current unified Flutter prototype.
///
/// Customer, Driver, Customer Care and Team Lead screens in this prototype
/// run inside the same Flutter process, so this gives the screens one shared
/// location source. Replace this store's update path with a backend stream
/// when the four roles are deployed as separate apps/devices.
class DriverLocationStore extends ChangeNotifier {
  DriverLocationStore._();

  static final DriverLocationStore instance = DriverLocationStore._();

  final Map<String, DriverLocationSnapshot> _byBooking = {};
  final Map<String, DriverLocationSnapshot> _byDriver = {};

  DriverLocationSnapshot? forBooking(String bookingId) => _byBooking[bookingId];

  DriverLocationSnapshot? forDriver(String driverId) => _byDriver[driverId];

  void update({
    required String driverId,
    required String? bookingId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required double speedKmh,
    required double heading,
    required DateTime updatedAt,
    required String ambulanceUnit,
  }) {
    final snapshot = DriverLocationSnapshot(
      driverId: driverId,
      bookingId: bookingId,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      speedKmh: speedKmh,
      heading: heading,
      updatedAt: updatedAt,
      ambulanceUnit: ambulanceUnit,
    );

    _byDriver[driverId] = snapshot;
    if (bookingId != null && bookingId.isNotEmpty) {
      _byBooking[bookingId] = snapshot;
    }
    notifyListeners();
  }

  void clearBooking(String bookingId) {
    _byBooking.remove(bookingId);
    notifyListeners();
  }

  void clearDriver(String driverId) {
    final snapshot = _byDriver.remove(driverId);
    if (snapshot?.bookingId != null) {
      _byBooking.remove(snapshot!.bookingId);
    }
    notifyListeners();
  }
}
