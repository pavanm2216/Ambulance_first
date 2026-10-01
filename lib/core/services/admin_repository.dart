import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Admin data/workflow adapter. Reads use canonical tables; sensitive writes
/// use audited RPCs or the server-side staff provisioning Edge Function.
class AdminRepository {
  SupabaseClient get _db => SupabaseService.client;

  Future<List<Map<String, dynamic>>> bookings() async => _maps(
    await _db.from('bookings').select().order('created_at', ascending: false),
  );
  Future<Map<String, dynamic>?> bookingById(String bookingId) async {
    final rows = _maps(
      await _db.from('bookings').select().eq('id', bookingId).limit(1),
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> ambulances() async => _maps(
    await _db.from('ambulances').select().order('created_at', ascending: false),
  );
  Future<List<Map<String, dynamic>>> drivers() async => _maps(
    await _db.from('drivers').select().order('created_at', ascending: false),
  );

  Future<List<Map<String, dynamic>>> availableDrivers() async {
    final rows = await _db
        .from('drivers')
        .select()
        .order('created_at', ascending: false);
    final maps = _maps(rows);
    final assignedRows = await _db
        .from('ambulances')
        .select('current_driver_id')
        .not('current_driver_id', 'is', null);
    final assignedIds = <String>{
      for (final row in assignedRows)
        (row['current_driver_id'] ?? '').toString(),
    };

    final eligible = maps.where((row) {
      final driverId = (row['id'] ?? '').toString();
      final status = (row['status'] ?? '').toString().toUpperCase();
      final license = (row['license_number'] ?? '').toString().trim();
      // The primary ambulance relationship is stored on the driver record.
      // A driver can be AVAILABLE for duty while still being paired with a
      // vehicle, so status alone is not sufficient for fleet enrollment.
      final assignedAmbulance = (row['assigned_ambulance_number'] ?? '')
          .toString()
          .trim();
      final assignedBooking = (row['assigned_booking_id'] ?? '')
          .toString()
          .trim();
      return driverId.isNotEmpty &&
          status == 'AVAILABLE' &&
          license.isNotEmpty &&
          assignedAmbulance.isEmpty &&
          assignedBooking.isEmpty &&
          !assignedIds.contains(driverId);
    }).toList();

    debugPrint(
      'ADMIN AVAILABLE DRIVERS: rows=${maps.length}; eligible=${eligible.length}; '
      'ids=${eligible.map((row) => row['id']).toList()}; '
      'names=${eligible.map((row) => row['full_name'] ?? row['name'] ?? '').toList()}; '
      'statuses=${eligible.map((row) => row['status'] ?? '').toList()}; '
      'licenses=${eligible.map((row) => (row['license_number'] ?? '').toString().isNotEmpty).toList()}; '
      'assigned=${assignedIds.toList()}',
    );

    return eligible;
  }

  Future<List<Map<String, dynamic>>> doctors() async => _maps(
    await _db.from('doctors').select().order('created_at', ascending: false),
  );
  Future<List<Map<String, dynamic>>> medicalCrew() async => _maps(
    await _db
        .from('medical_crew')
        .select()
        .order('created_at', ascending: false),
  );
  Future<List<Map<String, dynamic>>> customerCare() async => _maps(
    await _db
        // Customer Care operational records are not stored in the legacy
        // `customer_care` relation.  The canonical resource table is
        // `customer_care_agents` and links to Auth/profile via profile_id.
        .from('customer_care_agents')
        .select()
        .order('created_at', ascending: false),
  );
  Future<List<Map<String, dynamic>>> profiles() async => _maps(
    await _db.from('profiles').select().order('created_at', ascending: false),
  );
  // ============================================================
  // AUDIT LOGS
  // ============================================================
  //
  // The current production schema does not expose a confirmed
  // public.audit_logs table. Keep this method available because
  // AdminStore uses it during refresh, but return an empty list
  // so the entire Admin dashboard is not broken by an optional
  // audit source.
  //
  // Operational booking history is available separately through
  // reportStatusHistory().
  // ============================================================

  Future<List<Map<String, dynamic>>> auditLogs() async {
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> pricingSettings() async {
    final rows = await _db
        .from('pricing_settings')
        .select()
        .order('updated_at', ascending: false)
        .limit(20);
    final maps = _maps(rows);
    if (maps.isEmpty) return null;

    final defaultRow = maps.firstWhere(
      (row) => (row['id'] ?? '').toString() == 'default',
      orElse: () => maps.first,
    );
    return defaultRow;
  }

  Future<void> savePricingSettings(Map<String, dynamic> values) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('An authenticated Admin session is required.');
    }

    final rows = await _db
        .from('pricing_settings')
        .select('id')
        .order('updated_at', ascending: false)
        .limit(20);
    final maps = _maps(rows);
    final currentId = maps
        .map((row) => (row['id'] ?? '').toString())
        .firstWhere(
          (id) => id == 'default',
          orElse: () => maps.isNotEmpty
              ? (maps.first['id'] ?? 'default').toString()
              : 'default',
        );

    final row = {
      'id': currentId,
      ...values,
      'updated_by': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _db.from('pricing_settings').upsert(row, onConflict: 'id');
  }

  Future<Map<String, dynamic>> prepareQuotation({
    required String bookingId,
    required double additionalCharge,
    String? paymentTerms,
  }) async {
    final result = await _db.rpc(
      'prepare_booking_quotation',
      params: {
        'p_booking_id': bookingId,
        'p_discount': additionalCharge,
        'p_payment_terms': paymentTerms,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> allocateBooking({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
    String? doctorId,
    String? emtId,
  }) async {
    final result = await _db.rpc(
      'allocate_booking',
      params: {
        'p_booking_id': bookingId,
        'p_ambulance_id': ambulanceId,
        'p_driver_id': driverId,
        'p_doctor_id': doctorId,
        'p_medical_crew_id': emtId,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> reassignBookingResources({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
  }) async {
    final result = await _db.rpc(
      'admin_reassign_booking_resources',
      params: {
        'p_booking_id': bookingId,
        'p_ambulance_id': ambulanceId,
        'p_driver_id': driverId,
      },
    );
    if (result is! Map) {
      throw const FormatException(
        'admin_reassign_booking_resources returned malformed data.',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> transitionBookingStatus(
    String bookingId,
    String status,
  ) async {
    final result = await _db.rpc(
      'transition_booking_status',
      params: {'p_booking_id': bookingId, 'p_next_status': status},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> provisionStaff(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _db.functions.invoke(
        'admin-provision-staff',
        body: payload,
      );
      if (response.status >= 400) {
        final detail = _functionError(response.data);
        debugPrint(
          'ADMIN STAFF PROVISION ERROR: HTTP ${response.status}; '
          'response=${response.data}',
        );
        throw StateError(
          detail ?? 'Staff provisioning failed (HTTP ${response.status}).',
        );
      }
      if (response.data is Map && response.data['error'] != null) {
        final detail = _functionError(response.data);
        debugPrint('ADMIN STAFF PROVISION ERROR: response=${response.data}');
        throw StateError(detail ?? 'Staff provisioning failed.');
      }
      if (response.data is! Map) {
        throw StateError('Staff provisioning returned an invalid response.');
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on StateError {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('ADMIN STAFF PROVISION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      final message = error.toString().toLowerCase();
      if (message.contains('failed to fetch') ||
          message.contains('status: 0')) {
        throw StateError(
          'Staff service is currently unavailable. Please verify the Supabase staff-provisioning service.',
        );
      }
      // Keep the server/PostgREST message intact. It identifies schema,
      // authorization, and constraint failures that must not be masked as a
      // generic provisioning failure.
      throw StateError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  static String? _functionError(dynamic body) {
    if (body is! Map) return null;
    final fields = <String>[
      for (final key in const ['error', 'message', 'code', 'details', 'hint'])
        if (body[key] != null && body[key].toString().trim().isNotEmpty)
          '$key: ${body[key]}',
    ];
    return fields.isEmpty ? null : fields.join(' | ');
  }

  Future<Map<String, dynamic>> registerAmbulance({
    required String callSign,
    required String vehicleCadNo,
    required String platform,
    required String classification,
    required String category,
    required String stationBase,
    required bool hasOxygen,
    required bool hasIcu,
    required bool hasVentilator,
    required bool hasPicu,
    required bool hasIncubator,
    required bool hasFreezer,
    required String driverId,
  }) async {
    final result = await _db.rpc(
      'admin_register_ambulance_with_driver',
      params: {
        'p_call_sign': callSign,
        'p_vehicle_number': vehicleCadNo,
        'p_model': platform,
        'p_subtype': classification,
        'p_category': category,
        'p_base_station': stationBase,
        'p_has_oxygen': hasOxygen,
        'p_has_icu': hasIcu,
        'p_has_ventilator': hasVentilator,
        'p_has_pediatric_icu': hasPicu,
        'p_has_incubator': hasIncubator,
        'p_has_freezer': hasFreezer,
        // ALS/mobile ICU registrations should be dispatchable for the
        // common cardiac-monitor + stretcher requirements used by allocation.
        'p_has_cardiac_monitor': true,
        'p_has_stretcher': true,
        'p_driver_id': driverId,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> fleetStatus(
    String ambulanceId,
    String status,
  ) async {
    final result = await _db.rpc(
      'admin_update_ambulance_status',
      params: {'p_ambulance_id': ambulanceId, 'p_status': status},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> createMedicalCrew({
    required String name,
    required String phone,
    required String crewType,
    required String certification,
  }) async {
    final result = await _db
        .from('medical_crew')
        .insert({
          'full_name': name,
          'phone': phone,
          'crew_type': crewType,
          'certification': certification,
          'status': 'AVAILABLE',
        })
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> reportStatusHistory() async => _maps(
    await _db
        .from('booking_status_history')
        .select()
        .order('changed_at', ascending: false),
  );

  static List<Map<String, dynamic>> _maps(List<dynamic> rows) =>
      rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}
