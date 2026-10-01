import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_care_case.dart';
import 'supabase_service.dart';

/// Supabase-backed Customer Care access point.
class CustomerCareRepository extends ChangeNotifier {
  static final CustomerCareRepository instance =
      CustomerCareRepository._internal();
  static const _diagnosticBookingId = 'BK-0A067BDA657E';

  CustomerCareRepository._internal();

  SupabaseClient get _db => SupabaseService.client;

  List<CustomerCareCase> _cases = <CustomerCareCase>[];
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];
  List<CustomerCareCase> _activeTrips = <CustomerCareCase>[];
  RealtimeChannel? _bookingRealtimeChannel;
  Timer? _bookingRefreshTimer;
  String _lastFilter = 'ALL';
  String _lastSearch = '';
  bool isLoading = false;
  String? errorMessage;

  List<CustomerCareCase> get allCases => List.unmodifiable(_cases);
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  int get newInboundCount => _int(_dashboard['new_inbound_count']);
  int get codeRedCount => _int(_dashboard['code_red_count']);
  int get pendingCallsCount => _int(_dashboard['pending_calls_count']);
  int get verifiedCount => _int(_dashboard['verified_count']);
  int get handedOverCount => _int(_dashboard['sent_to_team_lead_count']);
  int get activeTripCount => _int(_dashboard['active_trips_count']);
  int get totalOpenCount => _int(_dashboard['total_open_count']);
  int get highPriorityCount => _cases.where((c) => c.priority == 'HIGH').length;
  int get pediatricCount => _cases.where((c) => c.pediatric).length;
  int get icuCount => _cases.where((c) => c.icu).length;

  List<CustomerCareCase> get newInboundCases => _cases
      .where(
        (c) => c.status == 'NEW' || c.status == 'CUSTOMER_CARE_CONTACT_PENDING',
      )
      .toList();
  List<CustomerCareCase> get pendingCallCases => _cases
      .where(
        (c) => const {
          'NEW',
          'CUSTOMER_CARE_CONTACT_PENDING',
          'CUSTOMER_CARE_CONTACTED',
          'VERIFICATION_PENDING',
        }.contains(c.status),
      )
      .toList();
  List<CustomerCareCase> get verifiedCases =>
      _cases.where((c) => c.status == 'VERIFIED').toList();
  List<CustomerCareCase> get handedOverCases => _cases
      .where(
        (c) => const {
          'SENT_TO_TEAM_LEAD',
          'ALLOCATION_PENDING',
          'BUDGET_PENDING',
          'QUOTATION_SENT',
          'CUSTOMER_ACCEPTED',
          'ASSIGNED',
          'DRIVER_ASSIGNED',
        }.contains(c.status),
      )
      .toList();
  List<CustomerCareCase> get activeTripCases => List.unmodifiable(_activeTrips);

  Future<void> load({String filter = 'ALL', String search = ''}) async {
    _requireSession();
    _lastFilter = filter;
    _lastSearch = search;
    _subscribeToBookingChanges();
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _db.rpc('get_customer_care_dashboard'),
        _db.rpc(
          'get_customer_care_bookings',
          params: {'p_filter': filter, 'p_search': search},
        ),
        _db.rpc('get_customer_care_notifications'),
        _db.rpc('get_customer_care_active_trips'),
      ]);
      _dashboard = _asMap(results[0], 'get_customer_care_dashboard');
      _requireDashboardKeys(_dashboard);
      final rawBookings = _asRows(results[1], 'get_customer_care_bookings');
      _cases = rawBookings.map(_mapCase).toList();
      _notifications = _asRows(results[2], 'get_customer_care_notifications');
      _activeTrips = _asRows(
        results[3],
        'get_customer_care_active_trips',
      ).map(_mapCase).toList();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToBookingChanges() {
    if (_bookingRealtimeChannel != null || !SupabaseService.isInitialized) {
      return;
    }
    _bookingRealtimeChannel = _db
        .channel('customer-care-booking-drafts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'NEW',
          ),
          callback: (_) => _queueBookingRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'VERIFIED',
          ),
          callback: (_) => _queueBookingRefresh(),
        )
        .subscribe();
  }

  void _queueBookingRefresh() {
    _bookingRefreshTimer?.cancel();
    _bookingRefreshTimer = Timer(
      const Duration(milliseconds: 300),
      () => load(filter: _lastFilter, search: _lastSearch).catchError((
        Object error,
      ) {
        debugPrint('CUSTOMER CARE REALTIME REFRESH ERROR: $error');
      }),
    );
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    final channel = _bookingRealtimeChannel;
    if (channel != null) {
      _db.removeChannel(channel);
      _bookingRealtimeChannel = null;
    }
    super.dispose();
  }

  Future<void> refresh() => load();

  CustomerCareCase? getCaseById(String id) {
    for (final item in _cases) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<Map<String, dynamic>> loadBookingDetails(String bookingId) async {
    _requireSession();
    const rpcName = 'get_customer_care_booking_details';
    debugPrint('DEBUG CC RELOAD METHOD: loadBookingDetails');
    debugPrint('DEBUG CC RELOAD RPC: $rpcName');
    final rawResult = await _db.rpc(
      rpcName,
      params: {'p_booking_id': bookingId},
    );
    debugPrint('DEBUG CC RAW REFRESH RESULT: $rawResult');
    final details = _asMap(rawResult, rpcName);
    debugPrint('DEBUG CC RAW REFRESH STATUS: ${details['status']}');
    return details;
  }

  Future<List<Map<String, dynamic>>> loadCallLogs(String bookingId) async {
    _requireSession();
    return _asRows(
      await _db.rpc(
        'get_customer_care_call_logs',
        params: {'p_booking_id': bookingId},
      ),
      'get_customer_care_call_logs',
    );
  }

  Future<List<Map<String, dynamic>>> loadBookingHistory(
    String bookingId,
  ) async {
    _requireSession();
    return _asRows(
      await _db.rpc(
        'get_customer_care_booking_history',
        params: {'p_booking_id': bookingId},
      ),
      'get_customer_care_booking_history',
    );
  }

  Future<List<CustomerCareCase>> loadActiveTrips() async {
    _requireSession();
    return _asRows(
      await _db.rpc('get_customer_care_active_trips'),
      'get_customer_care_active_trips',
    ).map(_mapCase).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    _requireSession();
    final result = await _db.rpc(
      'mark_customer_care_notification_read',
      params: {'p_notification_id': notificationId},
    );
    if (result != true) {
      throw StateError('Notification read update was not confirmed.');
    }
    final index = _notifications.indexWhere(
      (item) => item['id']?.toString() == notificationId,
    );
    if (index >= 0) {
      _notifications[index] = {
        ..._notifications[index],
        'is_read': true,
        'read': true,
      };
    }
    notifyListeners();
  }

  Future<void> saveCallLogOnly({
    required String caseId,
    required String outcome,
    required String priority,
    required String notes,
    required int callDurationSeconds,
    required bool checkPatientCondition,
    required bool checkOxygenTherapy,
    required bool checkVentilatorLoaded,
    required bool checkDoctorDesignated,
    required bool checkReceivingBedSecured,
    required bool checkRoutePriorityCleared,
  }) async {
    _requireSession();
    final now = DateTime.now().toUtc();
    await _db.rpc(
      'save_customer_care_call_log',
      params: {
        'p_call': {
          'booking_id': caseId,
          'call_started_at': now
              .subtract(Duration(seconds: callDurationSeconds))
              .toIso8601String(),
          'call_ended_at': now.toIso8601String(),
          'duration_seconds': callDurationSeconds,
          'outcome': _outcome(outcome),
          'priority': priority,
          'notes': notes,
        },
      },
    );
    await load();
  }

  Future<bool> verifyCustomerCareBooking({
    required CustomerCareVerificationPayload verification,
  }) async {
    _requireSession();
    if (!verification.isComplete) {
      throw StateError(
        'All four business confirmations and six safety checklist items are required.',
      );
    }

    final payload = verification.toJson();
    try {
      debugPrint('CUSTOMER CARE VERIFY PAYLOAD: $payload');
      final result = await _db.rpc(
        'verify_customer_care_booking',
        params: {'p_verification': payload},
      );
      debugPrint('CUSTOMER CARE VERIFY RESULT: $result');
      _assertRpcSuccess(
        result,
        expectedStatus: 'VERIFIED',
        operation: 'Verification',
      );
      await _debugDirectBookingRead(verification.bookingId);

      // The booking-details RPC is a presentation/details payload and does not
      // reliably expose the canonical workflow status. The authoritative
      // Customer Care booking list does. Reload it and validate the mapped
      // canonical status instead of interpreting a missing details field as
      // an unpersisted verification.
      await load();
      final refreshedCase = getCaseById(verification.bookingId);
      final verifiedStatus = refreshedCase?.status.trim().toUpperCase() ?? '';
      debugPrint('DEBUG CC CANONICAL STATUS AFTER VERIFY: $verifiedStatus');
      if (verifiedStatus != 'VERIFIED') {
        await _debugDirectBookingRead(verification.bookingId);
        throw StateError(
          'Verification did not persist as VERIFIED. Current status: $verifiedStatus',
        );
      }
      debugPrint('DEBUG CC REFRESHED CASE STATUS: $verifiedStatus');
      return true;
    } catch (error, stackTrace) {
      debugPrint('CUSTOMER CARE VERIFY ERROR: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<bool> sendCustomerCareToTeamLead(
    String bookingId,
    String notes,
  ) async {
    _requireSession();
    try {
      // Do not preflight the handoff through get_customer_care_booking_details.
      // That details RPC does not reliably expose bookings.status. The backend
      // handoff RPC is the authoritative authorization/state-transition check
      // and already requires the booking to be VERIFIED.
      debugPrint('CUSTOMER CARE HANDOFF BOOKING: $bookingId');
      final result = await _db.rpc(
        'send_customer_care_to_team_lead',
        params: {'p_booking_id': bookingId, 'p_notes': notes},
      );
      debugPrint('CUSTOMER CARE HANDOFF RESULT: $result');
      _assertRpcSuccess(
        result,
        expectedStatus: 'SENT_TO_TEAM_LEAD',
        operation: 'Handoff',
      );

      // Refresh the canonical Customer Care booking list and validate the
      // persisted workflow state from bookings.status.
      await load();
      final refreshedCase = getCaseById(bookingId);
      final handedOffStatus = refreshedCase?.status.trim().toUpperCase() ?? '';
      debugPrint('DEBUG CC CANONICAL STATUS AFTER HANDOFF: $handedOffStatus');
      if (handedOffStatus != 'SENT_TO_TEAM_LEAD') {
        await _debugDirectBookingRead(bookingId);
        throw StateError(
          'Handoff did not persist as SENT_TO_TEAM_LEAD. Current status: $handedOffStatus',
        );
      }
      debugPrint('DEBUG CC REFRESHED HANDOFF CASE STATUS: $handedOffStatus');
      return true;
    } catch (error, stackTrace) {
      debugPrint('CUSTOMER CARE HANDOFF FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  CustomerCareCase _mapCase(Map<String, dynamic> row) {
    final status = _string(row['status'], fallback: 'NEW');
    debugPrint('DEBUG CC MAPPED CASE STATUS: $status');
    if (row['id']?.toString() == _diagnosticBookingId ||
        row['booking_id']?.toString() == _diagnosticBookingId) {
      debugPrint('CC DASHBOARD MAPPED BK-0A067BDA657E: status=$status');
    }
    final priority = _string(
      row['cc_priority'] ?? row['priority'],
      fallback: 'NORMAL',
    );
    final isEmergency = _bool(row['is_emergency']);
    final patientConfirmed = _bool(
      row['cc_patient_condition_confirmed'] ??
          row['patient_condition_confirmed'],
    );
    return CustomerCareCase(
      id: _string(row['id'] ?? row['booking_id']),
      status: status,
      submissionStatus: _string(
        row['submission_status'],
        fallback: status == 'VERIFIED' ? 'VERIFIED' : 'PENDING_VERIFICATION',
      ),
      submittedAt: _string(row['submitted_at']),
      updatedAt: _string(
        row['updated_at'],
        fallback: _string(row['created_at']),
      ),
      source: _string(row['source'], fallback: 'CUSTOMER_APP'),
      customerName: _string(row['customer_name']),
      mobileNumber: _string(row['customer_phone'] ?? row['mobile_number']),
      email: _string(row['customer_email'] ?? row['email']),
      relationship: _string(row['relationship_to_patient']),
      patientName: _string(row['patient_name']),
      age: _int(row['patient_age']),
      gender: _string(row['patient_gender'], fallback: 'Not provided'),
      condition: _string(
        row['current_condition'] ?? row['patient_condition'],
        fallback: patientConfirmed ? 'Condition confirmed' : 'Not confirmed',
      ),
      isChild: _bool(row['pediatric_patient']),
      isEmergency: isEmergency,
      isCodeRed:
          isEmergency ||
          priority == 'CRITICAL' ||
          priority == 'CRITICAL_CODE_RED',
      serviceCategory: _string(row['service_category']),
      ambulanceCategory: _ambulanceCategoryFromRow(row),
      pickupAddress: _string(row['pickup_address']),
      destinationAddress: _string(row['destination_address']),
      destinationHospital: _string(row['destination_hospital']),
      distanceKm: _doubleOrNull(row['estimated_distance_km']) ?? 0,
      durationMins: _int(row['estimated_duration_mins']),
      preferredDate: _string(row['preferred_date'], fallback: 'Not scheduled'),
      preferredTime: _string(row['preferred_time'], fallback: 'Not scheduled'),
      oxygen: _bool(row['oxygen_required'] ?? row['req_oxygen']),
      oxygenFlow: _doubleOrNull(row['oxygen_flow_lpm']),
      icu: _bool(row['icu_required'] ?? row['req_icu']),
      ventilator: _bool(row['ventilator_required'] ?? row['req_ventilator']),
      ventilatorMode: _string(row['ventilator_mode']),
      cardiacMonitor: _bool(
        row['cardiac_monitor_required'] ?? row['req_cardiac_monitor'],
      ),
      stretcher: _bool(row['stretcher_required'] ?? row['req_stretcher']),
      wheelchair: _bool(row['wheelchair_required'] ?? row['req_wheelchair']),
      pediatric: _bool(row['pediatric_patient']),
      doctor: _bool(row['doctor_required'] ?? row['req_doctor']),
      doctorSpecialization: _string(row['doctor_specialization']),
      emt: _bool(row['emt_required'] ?? row['req_emt']),
      attendant: _bool(
        row['medical_attendant_required'] ?? row['req_attendant'],
      ),
      equipment: _strings(row['additional_equipment']),
      specialInstructions: _string(row['special_instructions']),
      callStatus: _string(
        row['cc_call_status'] ?? row['call_status'],
        fallback: 'Not contacted',
      ),
      priority: priority,
      callDurationSeconds: _int(
        row['cc_call_duration_secs'] ?? row['call_duration_seconds'],
      ),
      notes: _string(row['cc_notes'] ?? row['notes']),
      patientConfirmed: patientConfirmed,
      medicalConfirmed: _bool(
        row['cc_medical_req_confirmed'] ??
            row['medical_requirements_confirmed'],
      ),
      locationConfirmed: _bool(
        row['cc_location_confirmed'] ?? row['location_confirmed'],
      ),
      dateTimeConfirmed: _bool(
        row['cc_datetime_confirmed'] ?? row['datetime_confirmed'],
      ),
      verifiedBy: _string(
        row['cc_verified_by_name'] ?? row['verified_by_name'],
      ),
      createdAt: _string(row['created_at']),
      ambulance: _nullableString(
        row['ambulance_display_name'] ?? row['ambulance_vehicle_number'],
      ),
      vehicleNumber: _nullableString(row['ambulance_vehicle_number']),
      driverName: _nullableString(row['driver_name']),
      driverPhone: _nullableString(row['driver_phone']),
      etaMinutes: _intOrNull(row['driver_eta_minutes']),
      bloodPressure: _string(row['blood_pressure'] ?? row['bp']),
      spO2: _string(row['spo2'] ?? row['spo2_percent']),
      diagnosis: _string(row['diagnosis'] ?? row['current_condition']),
      receivingDoctor: _string(row['receiving_doctor']),
      receivingDepartment: _string(row['receiving_department']),
      doctorName: _string(row['doctor_name']),
      emtName: _string(row['emt_name']),
      liveSpeedKmh: _int(row['driver_speed_kmh']),
      currentTelemetryLocation: _string(row['driver_location_recorded_at']),
      isTelemetryStale: row['driver_location_recorded_at'] == null,
      remainingKm: _doubleOrNull(row['remaining_km']) ?? 0,
      telemetrySignalFreshness: _string(
        row['telemetry_signal_freshness'],
        fallback: 'Telemetry unavailable',
      ),
      dispatchTier: _string(row['dispatch_tier']),
      mrn: _string(row['mrn'] ?? row['medical_record_number']),
      sopTimeElapsed: _string(row['sop_time_elapsed']),
      checkPatientCondition: _bool(row['check_patient_condition']),
      checkOxygenTherapy: _bool(row['check_oxygen_therapy']),
      checkVentilatorLoaded: _bool(row['check_ventilator_loaded']),
      checkDoctorDesignated: _bool(row['check_doctor_designated']),
      checkReceivingBedSecured: _bool(row['check_receiving_bed_secured']),
      checkRoutePriorityCleared: _bool(row['check_route_priority_cleared']),
    );
  }

  String _ambulanceCategoryFromRow(Map<String, dynamic> row) {
    final explicit = _string(row['ambulance_type']);
    if (explicit.isNotEmpty) return explicit;
    switch (_string(row['service_subtype']).toUpperCase()) {
      case 'BASIC_OXYGEN':
        return 'Oxygen Ambulance (BLS)';
      case 'ADVANCED_ICU':
        return 'ICU Ambulance (ALS)';
      case 'PEDIATRIC_ICU':
        return 'NICU Ambulance (PICU/NICU)';
      default:
        return _string(row['service_category']);
    }
  }

  void _requireSession() {
    if (_db.auth.currentUser == null) {
      throw StateError('An authenticated Customer Care session is required.');
    }
  }

  Future<void> _debugDirectBookingRead(String bookingId) async {
    try {
      final result = await _db
          .from('bookings')
          .select('id,status,current_milestone')
          .eq('id', bookingId)
          .single();
      debugPrint('DEBUG CC DIRECT BOOKING READ: $result');
    } catch (error) {
      debugPrint('DEBUG CC DIRECT BOOKING READ ERROR: $error');
    }
  }

  static void _assertRpcSuccess(
    dynamic result, {
    required String expectedStatus,
    required String operation,
  }) {
    if (result == false || result == null) {
      throw StateError('$operation RPC returned no success result.');
    }
    if (result is Map) {
      final success = result['success'];
      if (success is bool && !success) {
        throw StateError('$operation RPC reported failure: $result');
      }
      final status = result['status'] ?? result['booking_status'];
      if (status != null && status.toString().toUpperCase() != expectedStatus) {
        throw StateError('$operation RPC returned status $status.');
      }
    }
  }

  List<Map<String, dynamic>> _asRows(dynamic value, String name) {
    if (value is! List) throw FormatException('$name returned malformed data.');
    return value.map((row) {
      if (row is! Map) throw FormatException('$name returned malformed data.');
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is! Map) throw FormatException('$name returned malformed data.');
    return Map<String, dynamic>.from(value);
  }

  void _requireDashboardKeys(Map<String, dynamic> value) {
    const requiredKeys = [
      'new_inbound_count',
      'code_red_count',
      'pending_calls_count',
      'verified_count',
      'sent_to_team_lead_count',
      'active_trips_count',
      'total_open_count',
    ];
    final missing = requiredKeys
        .where((key) => !value.containsKey(key))
        .toList();
    if (missing.isNotEmpty) {
      throw FormatException(
        'get_customer_care_dashboard is missing required keys: ${missing.join(', ')}',
      );
    }
  }

  static String _outcome(String value) {
    switch (value.toUpperCase()) {
      case 'NO ANSWER':
        return 'NO_ANSWER';
      case 'ANSWERED':
        return 'ANSWERED';
      case 'CALL BACK REQUESTED':
        return 'CALL_BACK_REQUESTED';
      case 'VERIFICATION IN PROGRESS':
        return 'VERIFICATION_IN_PROGRESS';
      case 'VERIFIED':
        return 'VERIFIED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'REJECTED':
        return 'REJECTED';
      default:
        return 'OTHER';
    }
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
