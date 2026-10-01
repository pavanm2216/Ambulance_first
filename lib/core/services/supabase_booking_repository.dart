import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/driver_models.dart';
import 'customer_portal_cache.dart';
import 'supabase_service.dart';

/// Read adapter for the existing `bookings` table.
///
/// This adapter intentionally uses `select()` rather than inventing a column
/// list. The uploaded project did not include the authoritative SQL definition
/// of the existing bookings table, so the adapter maps only fields that are
/// present in a returned row.
class SupabaseBookingRepository {
  SupabaseClient get _db => SupabaseService.client;

  Future<List<Booking>> getCustomerBookings() async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc('get_customer_bookings');
    final rows = _asRows(result, 'get_customer_bookings');

    // Some customer booking feeds intentionally return booking data without
    // the quotation join. Merge the separately authorized quotation feed
    // before mapping so every customer surface sees the same sent quote.
    List<Map<String, dynamic>> quotations = <Map<String, dynamic>>[];
    try {
      quotations = await getCustomerQuotations();
    } catch (error, stackTrace) {
      // A booking remains viewable if the supplementary quotation feed fails.
      // Never fabricate a price from the basic fare in that case.
      debugPrint('CUSTOMER QUOTATION LOAD ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return rows
        .map((row) => _mapCustomerBooking(_attachQuotation(row, quotations)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCustomerQuotations() async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc('get_customer_quotations');
    return _asRows(result, 'get_customer_quotations');
  }

  Future<Map<String, dynamic>> getCustomerProfile() async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc('get_customer_profile');
    return _asMap(result, 'get_customer_profile');
  }

  Future<List<Map<String, dynamic>>> getCustomerNotifications() async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc('get_customer_notifications');
    return _asRows(result, 'get_customer_notifications');
  }

  Future<bool> markCustomerNotificationRead(String notificationId) async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc(
      'mark_customer_notification_read',
      params: {'p_notification_id': notificationId},
    );
    if (result is bool) {
      if (result) CustomerPortalCache.markNotificationRead(notificationId);
      return result;
    }
    throw StateError(
      'mark_customer_notification_read returned malformed data.',
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerBookingHistory(
    String bookingId,
  ) async {
    _requireAuthenticatedCustomer();
    final result = await _db.rpc(
      'get_customer_booking_history',
      params: {'p_booking_id': bookingId},
    );
    return _asRows(result, 'get_customer_booking_history');
  }

  Future<List<Booking>> getBookingsForUser({
    required String userId,
    required String role,
  }) async {
    late final List<dynamic> rows;

    if (role == 'CUSTOMER') {
      return getCustomerBookings();
    } else {
      rows = await _db.from('bookings').select();
    }

    final result = <Booking>[];

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      if (!_visibleToUser(row, userId: userId, role: role)) continue;

      final booking = _tryMap(row);
      if (booking != null) result.add(booking);
    }

    return result;
  }

  Future<Booking?> getBookingById(String bookingId) async {
    final rows = await _db
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .limit(1);
    if (rows.isEmpty) return null;
    return _tryMap(Map<String, dynamic>.from(rows.first));
  }

  /// Operational booking feed for Team Lead. Pass both filters explicitly so
  /// PostgREST can disambiguate deployments that retain both RPC overloads.
  Future<List<Booking>> getBookingsForTeamLead() async {
    final result = await _db.rpc(
      'get_team_lead_bookings',
      params: {'p_filter': 'ALL', 'p_search': ''},
    );
    final rows = _asRows(result, 'get_team_lead_bookings');

    final bookings = <Booking>[];
    for (final raw in rows) {
      final booking = _tryMapTeamLeadBooking(raw);
      if (booking != null) {
        bookings.add(booking);
      }
    }
    return bookings;
  }

  /// Maps the Team Lead RPC wrapper into the canonical Booking model.
  ///
  /// Important: never pass the wrapper itself to `_tryMap()`. The actual
  /// booking columns are under `raw['booking']`.
  Booking? _tryMapTeamLeadBooking(Map<String, dynamic> raw) {
    try {
      final nestedBooking = raw['booking'];
      final bookingRaw = nestedBooking is Map
          ? Map<String, dynamic>.from(nestedBooking)
          : Map<String, dynamic>.from(raw);

      // Start with the real booking row. Wrapper fields are added only when
      // they do not overwrite an existing booking column.
      final row = <String, dynamic>{...bookingRaw};

      final latestQuotation = raw['latest_quotation'];
      if (latestQuotation is Map) {
        row.putIfAbsent(
          'latest_quotation',
          () => Map<String, dynamic>.from(latestQuotation),
        );
      }

      final assignment = raw['assignment'];
      if (assignment is Map) {
        final assignmentRaw = Map<String, dynamic>.from(assignment);

        _putIfAbsentFrom(row, 'driver_name', assignmentRaw, [
          'driver_name',
          'driver_full_name',
          'driverName',
        ]);
        _putIfAbsentFrom(row, 'driver_phone', assignmentRaw, [
          'driver_phone',
          'driver_mobile',
          'driverPhone',
        ]);
        _putIfAbsentFrom(row, 'vehicle_number', assignmentRaw, [
          'vehicle_number',
          'ambulance_vehicle_number',
          'registration_number',
          'vehicleNumber',
        ]);
        _putIfAbsentFrom(row, 'doctor_name', assignmentRaw, [
          'doctor_name',
          'doctor_full_name',
          'doctorName',
        ]);
        _putIfAbsentFrom(row, 'emt_name', assignmentRaw, [
          'emt_name',
          'emt_full_name',
          'medical_crew_name',
          'emtName',
        ]);
      }

      final currentMilestone = raw['current_milestone'];
      if (currentMilestone != null) {
        row.putIfAbsent('current_milestone', () => currentMilestone);
      }

      // Reuse the existing nested-row expansion logic for quotation,
      // ambulance, driver, doctor, crew, invoice and location data.
      final expanded = _expandCustomerRow(row);
      final booking = _tryMap(expanded);

      if (booking == null) {
        debugPrint(
          'TEAM LEAD MAPPING DROPPED ROW: '
          'id=${bookingRaw['id'] ?? bookingRaw['booking_id'] ?? bookingRaw['booking_reference']}',
        );
        return null;
      }

      final milestone = _string(
        raw['current_milestone'] ?? expanded['current_milestone'],
      );
      if (milestone.isNotEmpty) {
        booking.tripMilestone = milestone;
      }

      return booking;
    } catch (error, stackTrace) {
      debugPrint('TEAM LEAD RPC RESPONSE MAPPING ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  void _putIfAbsentFrom(
    Map<String, dynamic> target,
    String targetKey,
    Map<String, dynamic> source,
    List<String> candidates,
  ) {
    if (target[targetKey] != null) return;

    for (final candidate in candidates) {
      final value = source[candidate];
      if (value != null) {
        target[targetKey] = value;
        return;
      }
    }
  }

  Future<List<DriverBooking>> getBookingsForDriver({
    required String driverId,
  }) async {
    final rows = await _db
        .from('bookings')
        .select()
        .eq('assigned_driver_id', driverId)
        .order('created_at', ascending: false);
    return rows
        .map((raw) => _tryMapDriverBooking(Map<String, dynamic>.from(raw)))
        .whereType<DriverBooking>()
        .toList();
  }

  /// Authenticated Driver feed. The database maps auth.uid() to
  /// drivers.profile_id and then uses canonical drivers.id for bookings.
  Future<List<DriverBooking>> getCurrentDriverBookings({
    String? fallbackDriverId,
  }) async {
    try {
      final rows = await _db.rpc('get_current_driver_bookings');
      if (rows is! List) return <DriverBooking>[];
      return rows
          .whereType<Map>()
          .map((raw) => _tryMapDriverBooking(Map<String, dynamic>.from(raw)))
          .whereType<DriverBooking>()
          .toList();
    } catch (_) {
      final driverId = fallbackDriverId?.trim() ?? '';
      if (driverId.isEmpty) rethrow;
      return getBookingsForDriver(driverId: driverId);
    }
  }

  bool _visibleToUser(
    Map<String, dynamic> row, {
    required String userId,
    required String role,
  }) {
    if (role != 'CUSTOMER') return true;

    final possibleOwners = <String?>[
      row['customer_id']?.toString(),
      row['customerId']?.toString(),
      row['user_id']?.toString(),
      row['userId']?.toString(),
      row['profile_id']?.toString(),
    ];

    // If the schema exposes an ownership column, enforce it client-side in
    // addition to the backend RLS policy. If no ownership column is present,
    // do not guess; return the row because RLS remains the security boundary.
    final hasOwnerColumn = possibleOwners.any((value) => value != null);
    if (!hasOwnerColumn) return true;

    return possibleOwners.any((value) => value == userId);
  }

  Booking? _tryMap(Map<String, dynamic> row) {
    try {
      final id = _string(
        row['id'] ?? row['booking_id'] ?? row['booking_reference'],
      );
      if (id.isEmpty) return null;

      final serviceCategory = _string(
        row['service_category'] ?? row['serviceCategory'] ?? row['category'],
        fallback: 'ROAD',
      );

      final status = _string(
        row['status'] ?? row['booking_status'],
        fallback: 'NEW',
      );

      final quotationId = _string(row['quotation_id']);
      final quotationStatus = _string(row['quotation_status']);
      final hasQuotation =
          quotationId.isNotEmpty ||
          row['q_final_amount'] != null ||
          quotationStatus.isNotEmpty;
      final quotation = hasQuotation
          ? Quotation(
              id: quotationId.isNotEmpty ? quotationId : 'Q-$id',
              status: quotationStatus.isNotEmpty ? quotationStatus : 'SENT',
              baseAmbulanceCharge: _double(row['q_base_charge']),
              distanceCharge: _double(row['q_distance_charge']),
              doctorCharge: _double(row['q_doctor_charge']),
              emtCharge: _double(row['q_emt_charge']),
              oxygenCharge: _double(row['q_oxygen_charge']),
              icuCharge: _double(row['q_icu_charge']),
              ventilatorCharge: _double(row['q_ventilator_charge']),
              pediatricIcuCharge: _double(row['q_pediatric_icu_charge']),
              equipmentCharge: _double(row['q_equipment_charge']),
              attendantCharge: _double(row['q_attendant_charge']),
              railwayCharges: _double(row['q_railway_charges']),
              airAmbulanceCharges: _double(row['q_air_charges']),
              additionalCharges: _double(row['q_additional_charges']),
              discount: _double(row['q_discount']),
              taxPercent: _double(row['q_tax_percent']),
              paymentTerms: _string(row['q_payment_terms']),
              validUntil: _string(row['q_valid_until']),
              rejectionReason: _string(row['quotation_rejection_reason']),
              notes: _string(row['q_notes']),
              versionNo: _intOrNull(row['quotation_version_no']),
              preparedByName: _string(row['quotation_prepared_by_name']),
              preparedAt: _string(row['quotation_prepared_at']),
              sentAt: _string(row['quotation_sent_at']),
              respondedAt: _string(row['quotation_responded_at']),
              subtotalOverride: _doubleOrNull(row['q_subtotal']),
              taxAmountOverride: _doubleOrNull(row['q_tax_amount']),
              finalAmountOverride: _doubleOrNull(row['q_final_amount']),
            )
          : null;

      return Booking(
        id: id,
        pickup: _string(
          row['pickup'] ?? row['pickup_address'] ?? row['pickupAddress'],
        ),
        destination: _string(
          row['destination'] ??
              row['destination_address'] ??
              row['destinationAddress'],
        ),
        date: _string(
          row['date'] ?? row['preferred_date'] ?? row['preferredDate'],
        ),
        time: _string(
          row['time'] ?? row['preferred_time'] ?? row['preferredTime'],
        ),
        ambulanceType: _string(
          row['ambulance_type'] ??
              row['ambulanceType'] ??
              row['service_subtype'],
          fallback: 'Road Ambulance',
        ),
        transportMode: _string(
          row['transport_mode'] ?? row['transportMode'],
          fallback: 'ROAD_AMBULANCE',
        ),
        serviceCategory: serviceCategory,
        serviceSubtype: _nullableString(
          row['service_subtype'] ?? row['serviceSubtype'],
        ),
        pickupCity: _string(row['pickup_city'] ?? row['pickupCity']),
        destinationCity: _string(
          row['destination_city'] ?? row['destinationCity'],
        ),
        pickupLatitude: _doubleOrNull(
          row['pickup_lat'] ?? row['pickup_latitude'] ?? row['pickupLatitude'],
        ),
        pickupLongitude: _doubleOrNull(
          row['pickup_lng'] ??
              row['pickup_longitude'] ??
              row['pickupLongitude'],
        ),
        destinationLatitude: _doubleOrNull(
          row['destination_lat'] ??
              row['destination_latitude'] ??
              row['destinationLatitude'],
        ),
        destinationLongitude: _doubleOrNull(
          row['destination_lng'] ??
              row['destination_longitude'] ??
              row['destinationLongitude'],
        ),
        estimatedDurationMins: _int(
          row['estimated_duration_mins'] ?? row['estimatedDurationMins'],
        ),
        status: status,
        patientOnboardConfirmed: row['patient_onboard_confirmed_at'] != null,
        amount: _double(
          row['q_final_amount'] ??
              row['final_amount'] ??
              row['finalAmount'] ??
              row['amount'] ??
              row['estimated_amount'],
        ),
        basicFare: _double(
          row['basic_fare'] ??
              row['basicFare'] ??
              row['base_fare'] ??
              row['estimated_amount'],
        ),
        assignedAmbulanceId: _nullableString(
          row['assigned_ambulance_id'] ?? row['assignedAmbulanceId'],
        ),
        assignedDriverId: _nullableString(
          row['assigned_driver_id'] ?? row['assignedDriverId'],
        ),
        assignedMedicalCrewId: _nullableString(
          row['assigned_emt_id'] ??
              row['assigned_medical_crew_id'] ??
              row['assignedMedicalCrewId'],
        ),
        assignedDoctorId: _nullableString(
          row['assigned_doctor_id'] ?? row['assignedDoctorId'],
        ),
        customerName: _string(row['customer_name'] ?? row['customerName']),
        mobileNumber: _string(
          row['customer_phone'] ?? row['mobile_number'] ?? row['mobileNumber'],
        ),
        email: _string(
          row['email'] ?? row['customer_email'] ?? row['customerEmail'],
        ),
        alternatePhone: _string(
          row['alternate_phone'] ?? row['alternatePhone'],
        ),
        relationshipToPatient: _string(
          row['relationship_to_patient'] ?? row['relationshipToPatient'],
          fallback: 'Self',
        ),
        patientName: _string(row['patient_name'] ?? row['patientName']),
        patientAge: _int(row['patient_age'] ?? row['patientAge']),
        patientGender: _string(
          row['patient_gender'] ?? row['patientGender'],
          fallback: 'Other',
        ),
        patientWeightKg: _doubleOrNull(row['patient_weight_kg']),
        currentCondition: _string(
          row['current_condition'] ?? row['currentCondition'],
          fallback: 'Not provided',
        ),
        medicalSummary: _string(row['medical_summary']),
        isConscious: _bool(row['is_conscious'], fallback: true),
        currentHospital: _string(
          row['current_hospital'] ?? row['currentHospital'],
        ),
        destinationHospital: _string(
          row['destination_hospital'] ?? row['destinationHospital'],
        ),
        oxygenRequired: _bool(
          row['oxygen_required'] ?? row['oxygenRequired'] ?? row['req_oxygen'],
        ),
        oxygenFlowLpm: _doubleOrNull(
          row['oxygen_flow_lpm'] ??
              row['oxygenFlowLpm'] ??
              row['req_oxygen_flow_lpm'],
        ),
        icuRequired: _bool(
          row['icu_required'] ?? row['icuRequired'] ?? row['req_icu'],
        ),
        ventilatorRequired: _bool(
          row['ventilator_required'] ??
              row['ventilatorRequired'] ??
              row['req_ventilator'],
        ),
        ventilatorMode: _string(
          row['ventilator_mode'] ??
              row['ventilatorMode'] ??
              row['req_ventilator_mode'],
        ),
        cardiacMonitorRequired: _bool(
          row['cardiac_monitor_required'] ??
              row['cardiacMonitorRequired'] ??
              row['req_cardiac_monitor'],
        ),
        stretcherRequired: _bool(
          row['stretcher_required'] ??
              row['stretcherRequired'] ??
              row['req_stretcher'],
        ),
        wheelchairRequired: _bool(
          row['wheelchair_required'] ??
              row['wheelchairRequired'] ??
              row['req_wheelchair'],
        ),
        pediatricPatient: _bool(
          row['pediatric_patient'] ??
              row['pediatricPatient'] ??
              row['req_pediatric'],
        ),
        doctorRequired: _bool(
          row['doctor_required'] ?? row['doctorRequired'] ?? row['req_doctor'],
        ),
        doctorSpecialization: _nullableString(
          row['doctor_specialization'] ??
              row['doctorSpecialization'] ??
              row['req_doctor_specialization'],
        ),
        emtRequired: _bool(
          row['emt_required'] ?? row['emtRequired'] ?? row['req_emt'],
          fallback: false,
        ),
        medicalAttendantRequired: _bool(
          row['medical_attendant_required'] ??
              row['medicalAttendantRequired'] ??
              row['req_attendant'],
        ),
        additionalEquipment: _strings(row['additional_equipment']),
        specialInstructions: _string(
          row['special_instructions'] ?? row['specialInstructions'],
        ),
        isHomeService: _bool(row['is_home_service'] ?? row['isHomeService']),
        homeServiceCategory: _string(
          row['home_service_category'] ?? row['homeServiceCategory'],
        ),
        homeServiceName: _string(
          row['home_service_name'] ?? row['homeServiceName'],
        ),
        visitCharge: _double(row['visit_charge'] ?? row['visitCharge']),
        hourlyRate: _double(row['hourly_rate'] ?? row['hourlyRate']),
        serviceHours: _double(row['service_hours'] ?? row['serviceHours']),
        serviceCondition: _string(
          row['service_condition'] ?? row['serviceCondition'],
          fallback: 'Not assessed yet',
        ),
        homeServiceBillingStatus: _string(
          row['home_service_billing_status'] ?? row['homeServiceBillingStatus'],
          fallback: 'Visit scheduled',
        ),
        priority: _string(row['priority'], fallback: 'NORMAL'),
        customerCareStatus: _string(
          row['customer_care_status'] ?? row['customerCareStatus'],
          fallback: 'Pending',
        ),
        customerCareNotes: _string(
          row['customer_care_notes'] ?? row['customerCareNotes'],
        ),
        customerId: _string(row['customer_id'] ?? row['customerId']),
        driverName: _string(row['driver_name'] ?? row['driverName']),
        driverPhone: _string(row['driver_phone'] ?? row['driverPhone']),
        emtName: _string(
          row['medical_crew_name'] ?? row['emt_name'] ?? row['emtName'],
        ),
        emtPhone: _string(row['medical_crew_phone']),
        doctorName: _string(row['doctor_name'] ?? row['doctorName']),
        doctorPhone: _string(row['doctor_phone']),
        vehicleNumber: _string(
          row['vehicle_number'] ??
              row['vehicleNumber'] ??
              row['ambulance_vehicle_number'],
        ),
        ambulanceDisplayName: _string(row['ambulance_display_name']),
        isImmediate: _bool(row['is_immediate']),
        etaMinutes: _int(
          row['driver_eta_minutes'] ??
              row['geo_eta_mins'] ??
              row['eta_minutes'] ??
              row['etaMinutes'],
        ),
        driverLatitude: _doubleOrNull(
          row['driver_latitude'] ?? row['geo_lat'] ?? row['driverLatitude'],
        ),
        driverLongitude: _doubleOrNull(
          row['driver_longitude'] ?? row['geo_lng'] ?? row['driverLongitude'],
        ),
        driverSpeedKmh: _double(
          row['driver_speed_kmh'] ??
              row['geo_speed_kmh'] ??
              row['driverSpeedKmh'],
        ),
        driverHeading: _double(
          row['driver_heading'] ?? row['geo_heading'] ?? row['driverHeading'],
        ),
        driverLocationSharing:
            row['driver_location_recorded_at'] != null ||
            row['geo_last_ping'] != null ||
            row['driver_location_sharing'] == true,
        driverLocationAccuracyMeters: _double(
          row['driver_accuracy_meters'] ??
              row['driver_location_accuracy_meters'],
        ),
        driverLocationUpdatedAt: _dateTimeOrNull(
          row['driver_location_recorded_at'] ??
              row['geo_last_ping'] ??
              row['driver_location_updated_at'],
        ),
        distanceKm: _double(
          row['distance_km'] ??
              row['distanceKm'] ??
              row['estimated_distance_km'],
        ),
        quotation: quotation,
        invoice: _mapInvoice(row),
        vitals: _mapVitals(row),
      );
    } catch (_) {
      return null;
    }
  }

  Booking _mapCustomerBooking(Map<String, dynamic> raw) {
    final expanded = _expandCustomerRow(raw);
    expanded['customer_id'] ??= _db.auth.currentUser!.id;
    final booking = _tryMap(expanded);
    if (booking == null) {
      throw FormatException('Customer booking data is malformed.');
    }
    booking.tripMilestone = _string(
      expanded['current_milestone'] ?? expanded['trip_milestone'],
    );
    return booking;
  }

  Map<String, dynamic> _attachQuotation(
    Map<String, dynamic> booking,
    List<Map<String, dynamic>> quotations,
  ) {
    if (booking['quotation'] is Map || booking['latest_quotation'] is Map) {
      return booking;
    }

    final bookingId = _string(
      booking['id'] ?? booking['booking_id'] ?? booking['booking_reference'],
    );
    if (bookingId.isEmpty) return booking;

    Map<String, dynamic>? latest;
    for (final quotation in quotations) {
      final quotationBookingId = _string(
        quotation['booking_id'] ??
            quotation['bookingId'] ??
            quotation['booking_reference'] ??
            quotation['bookingReference'],
      );
      if (quotationBookingId == bookingId) {
        latest = quotation;
      }
    }

    return latest == null
        ? booking
        : <String, dynamic>{...booking, 'latest_quotation': latest};
  }

  Map<String, dynamic> _expandCustomerRow(Map<String, dynamic> raw) {
    final row = <String, dynamic>{...raw};
    for (final key in [
      'ambulance',
      'driver',
      'doctor',
      'medical_crew',
      'medicalCrew',
      'quotation',
      'latest_quotation',
      'latestQuotation',
      'driver_location',
      'latest_driver_location',
      'latestDriverLocation',
      'latest_vitals',
      'latestVitals',
      'latest_invoice',
      'latestInvoice',
    ]) {
      final nested = row[key];
      if (nested is Map) {
        final nestedValues = Map<String, dynamic>.from(nested);
        final isQuotation =
            key == 'quotation' ||
            key == 'latest_quotation' ||
            key == 'latestQuotation';
        final isInvoice = key == 'latest_invoice' || key == 'latestInvoice';
        for (final entry in nestedValues.entries) {
          final target = isQuotation
              ? 'q_${entry.key}'
              : isInvoice
              ? 'invoice_${entry.key}'
              : entry.key;
          row.putIfAbsent(target, () => entry.value);
        }
      }
    }

    final ambulance = _nestedMap(row, ['ambulance']);
    if (ambulance != null) {
      row['vehicle_number'] ??=
          ambulance['vehicle_number'] ??
          ambulance['registration_number'] ??
          ambulance['vehicle_no'];
    }
    final driver = _nestedMap(row, ['driver']);
    if (driver != null) {
      row['driver_name'] ??= driver['full_name'] ?? driver['name'];
      row['driver_phone'] ??= driver['phone'] ?? driver['mobile'];
    }
    final doctor = _nestedMap(row, ['doctor']);
    if (doctor != null) {
      row['doctor_name'] ??= doctor['full_name'] ?? doctor['name'];
    }
    final crew = _nestedMap(row, ['medical_crew', 'medicalCrew']);
    if (crew != null) {
      row['emt_name'] ??=
          crew['medical_crew_name'] ?? crew['full_name'] ?? crew['name'];
    }

    _copyAlias(row, 'quotation_id', ['id', 'quotation_id'], prefix: 'q_');
    // Quotation data supplied by the role RPCs is nested. It has already
    // been expanded above with a `q_` prefix, so read aliases from that
    // namespace rather than the booking's own status/amount fields.
    _copyAlias(row, 'quotation_status', [
      'status',
      'quotation_status',
    ], prefix: 'q_');
    _copyAlias(row, 'q_final_amount', [
      'final_amount',
      'total_amount',
      'amount',
    ], prefix: 'q_');
    for (final entry in {
      'q_base_charge': ['base_ambulance_charge', 'base_charge'],
      'q_distance_charge': ['distance_charge'],
      'q_doctor_charge': ['doctor_charge'],
      'q_emt_charge': ['emt_charge'],
      'q_oxygen_charge': ['oxygen_charge'],
      'q_icu_charge': ['icu_charge'],
      'q_ventilator_charge': ['ventilator_charge'],
      'q_pediatric_icu_charge': ['pediatric_icu_charge'],
      'q_equipment_charge': ['equipment_charge'],
      'q_attendant_charge': ['attendant_charge'],
      'q_railway_charges': ['railway_charges'],
      'q_air_charges': ['air_ambulance_charges', 'air_charges'],
      'q_additional_charges': ['additional_charges'],
      'q_discount': ['discount'],
      'q_tax_percent': ['tax_percent'],
      'q_payment_terms': ['payment_terms'],
      'q_valid_until': ['valid_until'],
      'q_notes': ['notes'],
      'quotation_rejection_reason': ['rejection_reason'],
    }.entries) {
      _copyAlias(row, entry.key, entry.value, prefix: 'q_');
    }
    _copyAlias(row, 'geo_lat', ['latitude', 'lat']);
    _copyAlias(row, 'geo_lng', ['longitude', 'lng', 'lon']);
    _copyAlias(row, 'geo_speed_kmh', ['speed_kmh', 'speed']);
    _copyAlias(row, 'geo_heading', ['heading']);
    _copyAlias(row, 'geo_last_ping', [
      'recorded_at',
      'created_at',
      'updated_at',
    ]);
    _copyAlias(row, 'invoice_id', ['invoice_id', 'id'], prefix: 'invoice_');
    _copyAlias(row, 'payment_status', ['payment_status']);
    return row;
  }

  Map<String, dynamic>? _nestedMap(
    Map<String, dynamic> row,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = row[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Invoice? _mapInvoice(Map<String, dynamic> row) {
    final nested = _nestedMap(row, ['latest_invoice', 'latestInvoice']);
    if (nested == null && row['invoice_id'] == null) return null;
    final source = nested ?? row;
    final id = _string(source['invoice_id'] ?? source['id']);
    if (id.isEmpty) return null;
    return Invoice(
      id: id,
      bookingId: _string(source['booking_id'], fallback: _string(row['id'])),
      quotationId: _string(source['quotation_id']),
      serviceDetails: _string(
        source['service_details'] ?? source['description'],
      ),
      total: _double(
        source['invoice_total_amount'] ??
            source['total'] ??
            source['total_amount'] ??
            source['amount'],
      ),
      paymentStatus: _string(
        source['invoice_payment_status'] ?? source['payment_status'],
        fallback: 'Unpaid',
      ),
      invoiceDate: _string(source['invoice_date'] ?? source['created_at']),
      invoiceNumber: _string(source['invoice_number']),
      subtotal: _double(source['invoice_subtotal']),
      taxAmount: _double(source['invoice_tax_amount']),
      discount: _double(source['invoice_discount']),
      paymentMethod: _string(source['invoice_payment_method']),
      paidAt: _string(source['invoice_paid_at']),
      pdfUrl: _string(source['invoice_pdf_url']),
    );
  }

  List<VitalSign> _mapVitals(Map<String, dynamic> row) {
    final raw = row['latest_vitals'] ?? row['latestVitals'] ?? row['vitals'];
    final values = raw is List
        ? raw
        : raw is Map
        ? [raw]
        : _hasFlattenedVitals(row)
        ? [row]
        : const [];
    return values.whereType<Map>().map((value) {
      final vital = Map<String, dynamic>.from(value);
      final systolic = vital['bp_systolic'];
      final diastolic = vital['bp_diastolic'];
      final bloodPressure = systolic != null || diastolic != null
          ? '${systolic ?? ''}/${diastolic ?? ''}'
          : vital['blood_pressure'] ?? vital['bp'];
      return VitalSign(
        time: _string(
          vital['vitals_recorded_at'] ??
              vital['time'] ??
              vital['recorded_at'] ??
              vital['created_at'],
        ),
        heartRate: _int(vital['heart_rate_bpm'] ?? vital['heart_rate']),
        spo2: _int(vital['spo2_percent'] ?? vital['spo2']),
        bp: _string(bloodPressure),
        respiratoryRate: _int(vital['respiratory_rate']),
        temperature: _double(
          vital['temperature_celsius'] ?? vital['temperature'],
        ),
        glucoseMgDl: _doubleOrNull(vital['glucose_mg_dl'] ?? vital['glucose']),
        oxygenFlowLpm: _doubleOrNull(
          vital['oxygen_flow_lpm_current'] ?? vital['oxygen_flow_lpm'],
        ),
        ventilatorPressureCmH2O: _doubleOrNull(vital['ventilator_pressure']),
        clinicalNotes: _string(vital['clinical_notes']),
        recordedBy: _string(vital['recorded_by']),
      );
    }).toList();
  }

  bool _hasFlattenedVitals(Map<String, dynamic> row) {
    return row['heart_rate_bpm'] != null ||
        row['spo2_percent'] != null ||
        row['bp_systolic'] != null ||
        row['bp_diastolic'] != null ||
        row['respiratory_rate'] != null ||
        row['temperature_celsius'] != null ||
        row['glucose_mg_dl'] != null ||
        row['oxygen_flow_lpm_current'] != null ||
        row['ventilator_pressure'] != null ||
        row['clinical_notes'] != null ||
        row['vitals_recorded_at'] != null;
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  void _copyAlias(
    Map<String, dynamic> row,
    String target,
    List<String> candidates, {
    String? prefix,
  }) {
    if (row[target] != null) return;
    for (final candidate in candidates) {
      final key = prefix == null ? candidate : '$prefix$candidate';
      if (row[key] != null) {
        row[target] = row[key];
        return;
      }
    }
  }

  List<Map<String, dynamic>> _asRows(dynamic value, String rpcName) {
    if (value is! List) {
      throw FormatException('$rpcName returned malformed data.');
    }
    return value.map((row) {
      if (row is! Map) {
        throw FormatException('$rpcName returned malformed data.');
      }
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Map<String, dynamic> _asMap(dynamic value, String rpcName) {
    if (value is! Map) {
      throw FormatException('$rpcName returned malformed data.');
    }
    return Map<String, dynamic>.from(value);
  }

  void _requireAuthenticatedCustomer() {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated Customer session is required.');
    }
  }

  DriverBooking? _tryMapDriverBooking(Map<String, dynamic> row) {
    try {
      final id = _string(row['id']);
      if (id.isEmpty) return null;

      return DriverBooking(
        // ----------------------------------------------------------
        // BOOKING
        // ----------------------------------------------------------
        id: id,
        status: _string(row['status'], fallback: 'ASSIGNED'),
        patientOnboardConfirmed: row['patient_onboard_confirmed_at'] != null,
        tripMilestone: _string(
          row['current_milestone'] ?? row['trip_milestone'],
        ),
        serviceCategory: _string(row['service_category'], fallback: 'ROAD'),

        // ----------------------------------------------------------
        // PATIENT
        // ----------------------------------------------------------
        patientName: _string(row['patient_name'], fallback: 'Patient'),
        patientAge: _int(row['patient_age']),
        patientGender: _string(row['patient_gender'], fallback: 'Other'),
        currentCondition: _string(row['patient_current_condition']),
        medicalConditionSummary: _string(
          row['patient_medical_summary'],
          fallback: _string(row['patient_current_condition']),
        ),
        currentHospital: _string(row['patient_current_hospital']),
        destinationHospital: _string(row['patient_destination_hospital']),

        // ----------------------------------------------------------
        // PICKUP
        // ----------------------------------------------------------
        pickupAddress: _string(row['pickup_address']),
        pickupCity: _string(row['pickup_city']),

        // ----------------------------------------------------------
        // DESTINATION
        // ----------------------------------------------------------
        destinationAddress: _string(row['destination_address']),
        destinationCity: _string(row['destination_city']),

        // ----------------------------------------------------------
        // SCHEDULE
        // ----------------------------------------------------------
        preferredDate: _string(row['preferred_date']),
        preferredTime: _string(row['preferred_time']),

        // ----------------------------------------------------------
        // GOOGLE ROUTE
        // ----------------------------------------------------------
        estimatedDistanceKm: _double(row['estimated_distance_km']),
        estimatedDurationMins: _int(row['estimated_duration_mins']),
        routeDistanceMeters: _int(row['route_distance_meters']),
        routeDurationSeconds: _int(row['route_duration_seconds']),
        routeProvider: _string(row['route_provider']),
        routeCalculatedAt: _dateTimeOrNull(row['route_calculated_at']),

        // ----------------------------------------------------------
        // PICKUP COORDINATES
        // ----------------------------------------------------------
        pickupLatitude: _doubleOrNull(row['pickup_lat']),
        pickupLongitude: _doubleOrNull(row['pickup_lng']),

        // ----------------------------------------------------------
        // DESTINATION COORDINATES
        // ----------------------------------------------------------
        destinationLatitude: _doubleOrNull(row['destination_lat']),
        destinationLongitude: _doubleOrNull(row['destination_lng']),

        // ----------------------------------------------------------
        // CUSTOMER
        // ----------------------------------------------------------
        customerName: _string(row['customer_name']),
        customerMobile: _string(row['customer_phone']),

        // ----------------------------------------------------------
        // AMBULANCE
        // ----------------------------------------------------------
        vehicleNumber: _string(row['ambulance_vehicle_number']),

        // ----------------------------------------------------------
        // DOCTOR
        // ----------------------------------------------------------
        doctorName: _string(row['doctor_name']),
        doctorPhone: _string(row['doctor_phone']),

        // ----------------------------------------------------------
        // EMT
        // ----------------------------------------------------------
        emtName: _string(row['emt_name']),
        emtPhone: _string(row['emt_phone']),

        // ----------------------------------------------------------
        // LIVE DRIVER TELEMETRY
        // ----------------------------------------------------------
        speedKmh: _double(row['geo_speed_kmh']),
        etaMinutes: _int(row['geo_eta_mins']),

        // ----------------------------------------------------------
        // MEDICAL REQUIREMENTS
        // ----------------------------------------------------------
        oxygenRequired: _bool(row['req_oxygen']),
        stretcherRequired: _bool(row['req_stretcher']),
        doctorRequired: _bool(row['req_doctor']),
        icuRequired: _bool(row['req_icu']),
        ventilatorRequired: _bool(row['req_ventilator']),
        cardiacMonitorRequired: _bool(row['req_cardiac_monitor']),
        specialInstructions: _string(row['req_special_instructions']),
      );
    } catch (error, stackTrace) {
      debugPrint('DRIVER BOOKING MAPPING ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty ? fallback : valueText;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static DateTime? _dateTimeOrNull(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return fallback;
  }
}
