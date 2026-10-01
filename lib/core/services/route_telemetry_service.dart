import 'dart:math' as math;

/// Lightweight real-time GPS distance/ETA calculations shared by Driver and
/// Team Lead. Distance is geodesic (GPS-to-GPS) distance; a road-routing
/// provider is required if exact turn-by-turn road distance is needed.
class RouteTelemetryService {
  RouteTelemetryService._();

  static double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusKm = 6371.0088;
    final dLat = _radians(toLatitude - fromLatitude);
    final dLon = _radians(toLongitude - fromLongitude);
    final lat1 = _radians(fromLatitude);
    final lat2 = _radians(toLatitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final clamped = a.clamp(0.0, 1.0).toDouble();
    return earthRadiusKm * 2 * math.atan2(math.sqrt(clamped), math.sqrt(1 - clamped));
  }

  /// Returns true when two valid GPS points are within the operational
  /// arrival radius. Default radius is 150 m; identical driver/pickup points
  /// are a valid arrival, not a GPS error.
  static bool withinArrivalThreshold({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    double thresholdMeters = 150,
  }) {
    if (!thresholdMeters.isFinite || thresholdMeters < 0) return false;
    return distanceKm(
          fromLatitude: fromLatitude,
          fromLongitude: fromLongitude,
          toLatitude: toLatitude,
          toLongitude: toLongitude,
        ) * 1000 <= thresholdMeters;
  }

  /// ETA to the pickup point. Uses the live GPS speed when moving; otherwise
  /// uses a conservative urban fallback so the UI does not display infinity.
  static int etaMinutes({
    required double distanceKm,
    required double speedKmh,
    double fallbackSpeedKmh = 28,
  }) {
    if (!distanceKm.isFinite || distanceKm <= 0.05) return 0;
    final effectiveSpeed = speedKmh >= 8 ? speedKmh : fallbackSpeedKmh;
    return math.max(1, (distanceKm / effectiveSpeed * 60).ceil());
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
