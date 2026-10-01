import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Read-only Doctor data adapter.
///
/// Clinical writes are intentionally not exposed until the Phase 5 RLS
/// contract has been applied and verified. The identity bridge uses the
/// authenticated profile email to locate the existing doctors resource;
/// there is no confirmed profile_id column on doctors in the audited schema.
class DoctorRepository {
  SupabaseClient get _db => SupabaseService.client;

  Future<Map<String, dynamic>?> doctorForUser({
    required String userId,
    required String email,
  }) async {
    if (email.trim().isEmpty) return null;
    final rows = await _db
        .from('doctors')
        .select()
        .eq('email', email.trim())
        .limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> assignedBookings(String doctorId) async {
    if (doctorId.trim().isEmpty) return const [];
    final rows = await _db
        .from('bookings')
        .select()
        .eq('assigned_doctor_id', doctorId)
        .order('updated_at', ascending: false);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> vitals(String bookingId) async {
    final rows = await _db
        .from('booking_vitals')
        .select()
        .eq('booking_id', bookingId)
        .order('recorded_at', ascending: false);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> assessments(String bookingId) async {
    final rows = await _db
        .from('booking_doctor_assessments')
        .select()
        .eq('booking_id', bookingId)
        .order('timestamp', ascending: false);
    return _maps(rows);
  }

  static List<Map<String, dynamic>> _maps(List<dynamic> rows) =>
      rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}
