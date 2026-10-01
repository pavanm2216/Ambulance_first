import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// All operational mutations go through Supabase RPCs.
///
/// This repository is the Flutter-side contract for the operational
/// Supabase RPCs used by Customer, Customer Care, Team Lead and Driver.
class SupabaseWorkflowRepository {
  SupabaseClient get _db => SupabaseService.client;

  // ---------------------------------------------------------------------------
  // CUSTOMER BOOKING
  // ---------------------------------------------------------------------------

  /// Calls the route Edge Function.
  ///
  /// The Edge Function calculates the route and updates the booking's
  /// estimated distance/duration. The database trigger then persists
  /// the basic fare.
  Future<void> calculateBookingRoute(String bookingId) async {
    final response = await _db.functions.invoke(
      'calculate-booking-route',
      body: {'bookingId': bookingId},
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        'Route calculation failed with status ${response.status}.',
      );
    }
  }

  /// Explicitly calculates and persists the booking's basic fare.
  ///
  /// Supabase RPC:
  /// calculate_booking_basic_fare(p_booking_id text)
  Future<Map<String, dynamic>> calculateBasicFare(String bookingId) async {
    final result = await _db.rpc(
      'calculate_booking_basic_fare',
      params: {'p_booking_id': bookingId},
    );

    return _map(result);
  }

  /// Creates a customer booking through the database RPC.
  Future<String> createCustomerBooking(Map<String, dynamic> booking) async {
    final result = await _db.rpc(
      'create_customer_booking',
      params: {'p_booking': booking},
    );

    return result.toString();
  }

  /// Creates or updates the authenticated customer's single active draft.
  Future<Map<String, dynamic>?> getCustomerBookingDraft() async {
    final result = await _db.rpc('get_customer_booking_draft');
    if (result == null) return null;
    return _map(result);
  }

  /// Creates or updates the authenticated customer's single active draft.
  Future<String> saveCustomerBookingDraft(Map<String, dynamic> booking) async {
    final result = await _db.rpc(
      'save_customer_booking_draft',
      params: {'p_booking': booking},
    );
    return result.toString();
  }

  /// Saves the latest values and marks the active draft ready for Care review.
  Future<String> submitCustomerBookingDraft({
    required String bookingId,
    required Map<String, dynamic> booking,
  }) async {
    final result = await _db.rpc(
      'submit_customer_booking_draft',
      params: {'p_booking_id': bookingId, 'p_booking': booking},
    );
    return result.toString();
  }

  /// Creates or updates a voice-intake booking that Customer Care can call back.
  Future<String> saveCustomerVoiceBookingDraft({
    required String bookingId,
    required Map<String, dynamic> booking,
  }) async {
    final result = await _db.rpc(
      'save_customer_voice_booking_draft',
      params: {
        'p_booking_id': bookingId,
        'p_booking': {
          ...booking,
          'id': bookingId,
          'booking_source': 'VOICE_INTAKE',
        },
      },
    );
    return result.toString();
  }

  // ---------------------------------------------------------------------------
  // GENERIC BOOKING STATUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> transitionBookingStatus({
    required String bookingId,
    required String nextStatus,
  }) async {
    final result = await _db.rpc(
      'transition_booking_status',
      params: {'p_booking_id': bookingId, 'p_next_status': nextStatus},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // DOCTOR ASSESSMENT
  // ---------------------------------------------------------------------------

  Future<String> submitDoctorAssessment({
    required String bookingId,
    required String diagnosis,
    required String patientCondition,
    List<String> medications = const [],
    List<String> interventions = const [],
    String notes = '',
  }) async {
    final result = await _db.rpc(
      'submit_doctor_assessment',
      params: {
        'p_booking_id': bookingId,
        'p_diagnosis': diagnosis,
        'p_patient_condition': patientCondition,
        'p_medications': medications,
        'p_interventions': interventions,
        'p_notes': notes,
      },
    );

    return result.toString();
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - QUOTATION
  // ---------------------------------------------------------------------------

  /// Creates/sends an exact quotation for the booking.
  ///
  /// Supabase RPC:
  /// prepare_booking_quotation(
  ///   p_booking_id,
  ///   p_discount,
  ///   p_payment_terms
  /// )
  Future<Map<String, dynamic>> prepareQuotation({
    required String bookingId,
    num discount = 0,
    String? paymentTerms,
  }) async {
    final result = await _db.rpc(
      'prepare_booking_quotation',
      params: {
        'p_booking_id': bookingId,
        'p_discount': discount,
        'p_payment_terms': paymentTerms,
      },
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER - QUOTATION RESPONSE
  // ---------------------------------------------------------------------------

  /// Accepts or rejects a quotation.
  ///
  /// Supabase RPC:
  /// respond_to_quotation(
  ///   p_booking_id text,
  ///   p_accept boolean,
  ///   p_reason text
  /// )
  Future<Map<String, dynamic>> respondToQuotation({
    required String bookingId,
    required bool accept,
    String? reason,
  }) async {
    final result = await _db.rpc(
      'respond_to_quotation',
      params: {
        'p_booking_id': bookingId,
        'p_accept': accept,
        'p_reason': reason,
      },
    );

    return _map(result);
  }

  /// Confirms that the patient was dropped at the booked destination.
  /// Resource release is performed atomically by the customer-authorized RPC.
  Future<Map<String, dynamic>> confirmCustomerDropoff({
    required String bookingId,
  }) async {
    final result = await _db.rpc(
      'customer_confirm_dropoff',
      params: {'p_booking_id': bookingId},
    );

    return _map(result);
  }

  Future<Map<String, dynamic>> confirmCustomerPatientOnboard({
    required String bookingId,
  }) async {
    final result = await _db.rpc(
      'customer_confirm_patient_onboard',
      params: {'p_booking_id': bookingId},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - RESOURCE ALLOCATION
  // ---------------------------------------------------------------------------

  /// Allocates the ambulance, driver, doctor and medical crew.
  ///
  /// IMPORTANT:
  /// The database itself checks that the booking is in
  /// CUSTOMER_ACCEPTED state before allowing allocation.
  ///
  /// Supabase RPC:
  /// allocate_booking(
  ///   p_booking_id text,
  ///   p_ambulance_id uuid,
  ///   p_driver_id uuid,
  ///   p_doctor_id uuid,
  ///   p_medical_crew_id uuid
  /// )
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

        // The database relationship is:
        // bookings.assigned_medical_crew_id
        //
        // Flutter may still call this resource "EMT" because that is
        // the terminology currently used by the UI.
        'p_medical_crew_id': emtId,
      },
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // DRIVER - ASSIGNMENT RESPONSE
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> driverRespondToAssignment({
    required String bookingId,
    required bool accept,
    String? reason,
  }) async {
    final result = await _db.rpc(
      'driver_respond_to_assignment',
      params: {
        'p_booking_id': bookingId,
        'p_accept': accept,
        'p_reason': reason,
      },
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // DRIVER - BOOKING PROGRESSION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> driverAdvanceBooking({
    required String bookingId,
    required String nextStatus,
  }) async {
    final result = await _db.rpc(
      'driver_advance_booking',
      params: {'p_booking_id': bookingId, 'p_next_status': nextStatus},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // DRIVER - LIVE LOCATION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> publishDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    String? bookingId,
    double accuracyMeters = 0,
    double speedKmh = 0,
    double heading = 0,
  }) async {
    final result = await _db.rpc(
      'publish_driver_location',
      params: {
        'p_driver_id': driverId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_booking_id': bookingId,
        'p_accuracy_meters': accuracyMeters,
        'p_speed_kmh': speedKmh,
        'p_heading': heading,
      },
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // DRIVER - DUTY STATUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> setDriverDutyStatus({
    required String driverId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'set_driver_duty_status',
      params: {'p_driver_id': driverId, 'p_status': status},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - AMBULANCE STATUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> setTeamLeadAmbulanceStatus({
    required String ambulanceId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'team_lead_update_ambulance_status',
      params: {'p_ambulance_id': ambulanceId, 'p_status': status},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - DRIVER STATUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> setTeamLeadDriverStatus({
    required String driverId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'team_lead_update_driver_status',
      params: {'p_driver_id': driverId, 'p_status': status},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - MEDICAL CREW / EMT STATUS
  // ---------------------------------------------------------------------------

  /// The UI currently calls this resource "EMT".
  ///
  /// In the actual database the resource is stored in:
  /// public.medical_crew
  ///
  /// The RPC parameter remains p_emt_id for compatibility with the
  /// database function contract.
  Future<Map<String, dynamic>> setTeamLeadEmtStatus({
    required String emtId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'team_lead_update_emt_status',
      params: {'p_emt_id': emtId, 'p_status': status},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // TEAM LEAD - DOCTOR STATUS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> setTeamLeadDoctorStatus({
    required String doctorId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'team_lead_update_doctor_status',
      params: {'p_doctor_id': doctorId, 'p_status': status},
    );

    return _map(result);
  }

  // ---------------------------------------------------------------------------
  // VITALS
  // ---------------------------------------------------------------------------

  Future<String> recordVitals({
    required String bookingId,
    num? heartRate,
    num? bpSystolic,
    num? bpDiastolic,
    num? spo2,
    num? respiratoryRate,
    num? temperature,
    num? glucose,
    num? oxygenFlow,
    num? ventilatorPressure,
    String? clinicalNotes,
  }) async {
    final result = await _db.rpc(
      'record_booking_vitals',
      params: {
        'p_booking_id': bookingId,
        'p_heart_rate_bpm': heartRate,
        'p_bp_systolic': bpSystolic,
        'p_bp_diastolic': bpDiastolic,
        'p_spo2_percent': spo2,
        'p_respiratory_rate': respiratoryRate,
        'p_temperature_celsius': temperature,
        'p_glucose_mg_dl': glucose,
        'p_oxygen_flow_lpm': oxygenFlow,
        'p_ventilator_pressure': ventilatorPressure,
        'p_clinical_notes': clinicalNotes,
      },
    );

    return result.toString();
  }

  // ---------------------------------------------------------------------------
  // INTERNAL RESPONSE CONVERSION
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{'result': value};
  }
}
