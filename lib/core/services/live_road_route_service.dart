import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

enum LiveTripLeg { pickup, hospital }

class RoutePoint {
  const RoutePoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LiveRoadRoute {
  const LiveRoadRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.provider,
    required this.geometry,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.legKey,
  });

  final int distanceMeters;
  final int durationSeconds;
  final String provider;
  final List<RoutePoint> geometry;
  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String legKey;

  double get distanceKm => distanceMeters / 1000;
  int get etaMinutes => (durationSeconds / 60).ceil();
}

/// Requests a driving route from the authenticated Supabase Edge Function.
/// The route origin is the driver's current GPS; the destination is the active
/// leg target (pickup before patient pickup, hospital after patient pickup).
class LiveRoadRouteService {
  LiveRoadRouteService({this._client});

  static LiveTripLeg resolveLeg({
    required String status,
    String milestone = '',
    bool patientOnboardConfirmed = false,
  }) {
    return patientOnboardConfirmed ? LiveTripLeg.hospital : LiveTripLeg.pickup;
  }

  /// Arrival is still associated with the hospital for display, but a route
  /// must not remain actionable once the hospital arrival is confirmed.
  static bool hasActiveNavigation({
    required String status,
    String milestone = '',
  }) {
    final normalizedStatus = status.trim().toUpperCase();
    final normalizedMilestone = milestone.trim().toUpperCase();
    const inactive = {
      'ARRIVED',
      'SERVICE_COMPLETED',
      'INVOICE_GENERATED',
      'COMPLETED',
      'CANCELLED',
      'CANCELED',
    };
    return !inactive.contains(normalizedStatus) &&
        !inactive.contains(normalizedMilestone);
  }

  /// Persisted telemetry is only eligible for live routing while recent.
  /// A missing timestamp is not treated as a live ambulance position.
  static bool hasFreshDriverLocation(
    DateTime? updatedAt, {
    DateTime? now,
    Duration maxAge = const Duration(seconds: 60),
  }) {
    if (updatedAt == null) return false;
    final age = (now ?? DateTime.now()).difference(updatedAt);
    return age >= const Duration(minutes: -2) && age <= maxAge;
  }

  final SupabaseClient? _client;
  SupabaseClient get client => _client ?? SupabaseService.client;

  Future<LiveRoadRoute> calculate({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String originAddress,
    required String destinationAddress,
    required String legKey,
    bool includeGeometry = true,
  }) async {
    final response = await client.functions.invoke(
      'calculate-route',
      body: {
        'pickup_address': originAddress,
        'destination_address': destinationAddress,
        'pickup_lat': originLatitude,
        'pickup_lng': originLongitude,
        'destination_lat': destinationLatitude,
        'destination_lng': destinationLongitude,
        'include_geometry': includeGeometry,
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException(
        'Route service returned an invalid response.',
      );
    }
    final map = Map<String, dynamic>.from(data);
    if (map['error'] != null) {
      throw StateError(map['error'].toString());
    }

    final distance = _asInt(map['distance_meters']);
    final duration = _asInt(map['duration_seconds']);
    if (distance == null || distance < 0 || duration == null || duration < 0) {
      throw const FormatException(
        'Route service returned invalid distance or ETA.',
      );
    }

    final points = <RoutePoint>[];
    final rawGeometry = map['route_geometry'];
    if (rawGeometry is Map && rawGeometry['coordinates'] is List) {
      for (final item in rawGeometry['coordinates'] as List) {
        if (item is List && item.length >= 2) {
          final longitude = _asDouble(item[0]);
          final latitude = _asDouble(item[1]);
          if (latitude != null && longitude != null) {
            points.add(RoutePoint(latitude: latitude, longitude: longitude));
          }
        }
      }
    }

    return LiveRoadRoute(
      distanceMeters: distance,
      durationSeconds: duration,
      provider: (map['provider'] ?? 'Road routing').toString(),
      geometry: List.unmodifiable(points),
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      legKey: legKey,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is num && value.isFinite) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
