import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_models.dart';
import 'supabase_service.dart';

/// Canonical Team Lead resource reader.
///
/// Team Lead never owns a second in-memory roster. Every resource shown in the
/// operational pages is loaded from Supabase through controlled RPCs.
class SupabaseResourceRepository {
  SupabaseClient get _db => SupabaseService.client;

  /// Retrieves the authenticated Driver's own resource row through the
  /// controlled RPC.  This works even when RLS correctly prevents the mobile
  /// client from reading every driver in the fleet.
  Future<DriverProfile?> getCurrentDriver() async {
    final rows = await _db.rpc('get_current_driver');
    final maps = _maps(rows);
    return maps.isEmpty ? null : driverFromRow(maps.first);
  }

  /// Compatibility entry point for the existing unified app callers.  The
  /// server determines the identity; [userId] is only used by the narrow
  /// direct-query fallback before the Driver feed migration is applied.
  Future<DriverProfile?> getDriverForUser(String userId) async {
    try {
      return await getCurrentDriver();
    } catch (_) {
      if (userId.trim().isEmpty) return null;
      final row = await _db
          .from('drivers')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();
      return row == null ? null : driverFromRow(Map<String, dynamic>.from(row));
    }
  }

  Future<DriverProfile?> getDriverById(String driverId) async {
    final row = await _db
        .from('drivers')
        .select()
        .eq('id', driverId)
        .maybeSingle();
    if (row == null) return null;
    return driverFromRow(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> getAmbulances() async {
    final rows = await _db.rpc('get_team_lead_ambulances');
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> getDrivers() async {
    final rows = await _db.rpc('get_team_lead_drivers');
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final rows = await _db.rpc('get_team_lead_doctors');
    return _maps(rows);
  }

  /// EMT/paramedic records come from public.medical_crew.
  Future<List<Map<String, dynamic>>> getEmtProfiles() async {
    final rows = await _db.rpc('get_team_lead_emt_profiles');
    return _maps(rows);
  }

  /// The ambulance enum has one allocatable state. Do not infer an
  /// operational state from telemetry or incomplete profile fields.
  static bool isAmbulanceAvailable(Map<String, dynamic> row) =>
      '${row['status'] ?? ''}'.trim().toUpperCase() == 'AVAILABLE';

  DriverProfile driverFromRow(Map<String, dynamic> row) {
    return DriverProfile(
      id: '${row['id'] ?? ''}',
      name: '${row['name'] ?? row['full_name'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      email: '${row['email'] ?? ''}',
      licenseNumber: '${row['license_number'] ?? ''}',
      licenseExpiry: '${row['license_expiry'] ?? ''}',
      experienceYears: _int(row['experience_years']),
      supportedCategories: _stringList(
        row['supported_categories'] ?? row['supported_category'],
      ),
      currentLocation: '${row['current_location'] ?? ''}',
      assignedAmbulanceNumber:
          '${row['assigned_ambulance_number'] ?? ''}',
      status: '${row['status'] ?? 'AVAILABLE'}',
      totalTrips: _int(row['total_trips']),
      rating: _double(row['rating']),
      assignedBookingId: row['assigned_booking_id']?.toString(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic rows) {
    if (rows is! List) return <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => '$e').toList();
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
