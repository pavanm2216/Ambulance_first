import 'package:flutter/material.dart';

import '../../../core/services/admin_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../models/admin_models.dart';

class AdminStore extends ChangeNotifier {
  AdminStore({AdminRepository? repository})
    : _repository = repository ?? AdminRepository() {
    _setNeutralPricing();
  }

  final AdminRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Domain Collections
  final List<AdminBooking> _bookings = [];
  final List<AdminAmbulance> _ambulances = [];
  final List<AdminStaff> _staff = [];
  final List<AdminAuditEntry> _auditLogs = [];

  late AdminPricingRateCard activePricing;
  late AdminPricingRateCard draftPricing;

  List<AdminBooking> get bookings => List.unmodifiable(_bookings);
  List<AdminAmbulance> get ambulances => List.unmodifiable(_ambulances);
  List<AdminStaff> get staff => List.unmodifiable(_staff);
  List<AdminAuditEntry> get auditLogs => List.unmodifiable(_auditLogs);

  // Sub-rosters
  List<AdminStaff> get drivers =>
      _staff.where((s) => s.role == 'DRIVER').toList();
  List<AdminStaff> get emts => _staff.where((s) => s.role == 'EMT').toList();
  List<AdminStaff> get doctors =>
      _staff.where((s) => s.role == 'DOCTOR').toList();
  List<AdminStaff> get customerCare =>
      _staff.where((s) => s.role == 'CUSTOMER_CARE').toList();
  List<AdminStaff> get teamLeads =>
      _staff.where((s) => s.role == 'TEAM_LEAD').toList();

  // Dynamic Operational KPIs
  int get totalBookingsCount => _bookings.length;

  int get activeTripsCount => _bookings
      .where(
        (b) =>
            b.status == BookingStatus.assigned ||
            b.status == BookingStatus.driverAssigned ||
            b.status == BookingStatus.pickupStarted ||
            b.status == BookingStatus.patientPickedUp ||
            b.status == BookingStatus.inTransit ||
            b.status == BookingStatus.arrived,
      )
      .length;

  int get inTransitCount =>
      _bookings.where((b) => b.status == BookingStatus.inTransit).length;
  int get pickupStartedCount =>
      _bookings.where((b) => b.status == BookingStatus.pickupStarted).length;
  int get patientPickedUpCount =>
      _bookings.where((b) => b.status == BookingStatus.patientPickedUp).length;

  int get availableAmbulancesCount =>
      _ambulances.where((a) => a.status == FleetStatus.available).length;

  int get totalAmbulancesCount => _ambulances.length;

  double get fleetAvailabilityPercentage => totalAmbulancesCount > 0
      ? (availableAmbulancesCount / totalAmbulancesCount) * 100
      : 0.0;

  int get activeMissionAmbulancesCount => _ambulances
      .where(
        (a) =>
            a.status == FleetStatus.activeMission ||
            a.status == FleetStatus.inTransit,
      )
      .length;

  int get maintenanceAmbulancesCount =>
      _ambulances.where((a) => a.status == FleetStatus.maintenance).length;

  // Financial Metrics
  double get quotedPipelineTotal => _bookings
      .where(
        (b) =>
            b.quotationTotal > 0 &&
            !{
              'REJECTED',
              'CUSTOMER_REJECTED',
              'EXPIRED',
            }.contains(b.quotationStatus.toUpperCase()),
      )
      .fold(0.0, (sum, b) => sum + b.quotationTotal);

  double get acceptedOrdersTotal => _bookings
      .where(
        (b) => {
          'ACCEPTED',
          'CUSTOMER_ACCEPTED',
        }.contains(b.quotationStatus.toUpperCase()),
      )
      .fold(0.0, (sum, b) => sum + b.quotationTotal);

  double get paidRecognizedTotal => _bookings
      .where(
        (b) => {
          'PAID',
          'COMPLETED',
          'SUCCESS',
        }.contains(b.paymentStatus.toUpperCase()),
      )
      .fold(0.0, (sum, b) => sum + b.quotationTotal);

  double get outstandingCollectionsTotal => _bookings
      .where(
        (b) =>
            {
              'ACCEPTED',
              'CUSTOMER_ACCEPTED',
            }.contains(b.quotationStatus.toUpperCase()) &&
            !{
              'PAID',
              'COMPLETED',
              'SUCCESS',
            }.contains(b.paymentStatus.toUpperCase()),
      )
      .fold(0.0, (sum, b) => sum + b.quotationTotal);

  void _setNeutralPricing() {
    activePricing = _pricingFromRow(null, active: true);
    draftPricing = _pricingFromRow(null, active: false);
  }

  Future<void> loadFromDatabase() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _repository.bookings(),
        _repository.ambulances(),
        _repository.drivers(),
        _repository.doctors(),
        _repository.customerCare(),
        _repository.profiles(),
        _repository.medicalCrew(),
        _safeAuditLogs(),
        _safePricingSettings(),
      ]);

      _replaceList(
        _bookings,
        _mapBookings(results[0] as List<Map<String, dynamic>>),
      );

      _replaceList(
        _ambulances,
        _mapAmbulances(results[1] as List<Map<String, dynamic>>),
      );

      _replaceList(
        _staff,
        _mapStaff(
          drivers: results[2] as List<Map<String, dynamic>>,
          doctors: results[3] as List<Map<String, dynamic>>,
          customerCare: results[4] as List<Map<String, dynamic>>,
          profiles: results[5] as List<Map<String, dynamic>>,
          medicalCrew: results[6] as List<Map<String, dynamic>>,
        ),
      );

      _replaceList(
        _auditLogs,
        _mapAuditLogs(results[7] as List<Map<String, dynamic>>),
      );

      final pricing = results[8] as Map<String, dynamic>?;

      activePricing = _pricingFromRow(pricing, active: true);

      draftPricing = _pricingFromRow(pricing, active: false);

      _errorMessage = null;
    } catch (error) {
      // Keep previously loaded real Supabase data if one refresh fails.
      // Never replace operational data with dummy/demo data.
      _errorMessage = 'Could not refresh Admin data from Supabase: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadFromDatabase();

  AdminBooking? bookingById(String bookingId) {
    for (final booking in _bookings) {
      if (booking.id == bookingId) return booking;
    }
    return null;
  }

  Future<void> refreshBooking(String bookingId) async {
    final row = await _repository.bookingById(bookingId);
    if (row == null) return;
    final refreshed = _mapBookings([row]).firstOrNull;
    if (refreshed == null) return;
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) return;
    _bookings[index] = refreshed;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _safeAuditLogs() async {
    try {
      return await _repository.auditLogs();
    } catch (_) {
      // Audit logs are optional for the operational Admin dashboard.
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>?> _safePricingSettings() async {
    try {
      return await _repository.pricingSettings();
    } catch (_) {
      // Keep the pricing model neutral if the settings table is unavailable.
      return null;
    }
  }

  static void _replaceList<T>(List<T> target, List<T> values) {
    target
      ..clear()
      ..addAll(values);
  }

  List<AdminBooking> _mapBookings(
    List<Map<String, dynamic>> rows, {
    List<Map<String, dynamic>> quotationRows = const [],
    List<Map<String, dynamic>> invoiceRows = const [],
  }) {
    return rows
        .map(
          (row) => _bookingFromRow(
            row,
            quotation: _latestRelatedRow(row, quotationRows, 'booking_id'),
            invoice: _latestRelatedRow(row, invoiceRows, 'booking_id'),
          ),
        )
        .toList();
  }

  Map<String, dynamic>? _latestRelatedRow(
    Map<String, dynamic> bookingRow,
    List<Map<String, dynamic>> relatedRows,
    String bookingKey,
  ) {
    final bookingId = _string(bookingRow, ['id', 'booking_id']);
    final matches = relatedRows
        .where((row) => _string(row, [bookingKey]) == bookingId)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final av = _int(a, ['version_no']);
      final bv = _int(b, ['version_no']);
      if (av != bv) return bv.compareTo(av);
      final ad = _date(a, ['created_at', 'invoice_date']);
      final bd = _date(b, ['created_at', 'invoice_date']);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return matches.first;
  }

  AdminBooking _bookingFromRow(
    Map<String, dynamic> row, {
    Map<String, dynamic>? quotation,
    Map<String, dynamic>? invoice,
  }) {
    final status = BookingStatus.fromString(
      _string(row, ['status', 'booking_status'], fallback: 'NEW'),
    );
    final createdAt = _date(row, ['created_at', 'createdAt']) ?? DateTime.now();
    final patientName = _string(row, [
      'patient_name',
      'patientName',
    ], fallback: 'Patient');
    final customerName = _string(row, [
      'customer_name',
      'customerName',
      'requester_name',
    ], fallback: 'Customer');
    final quotationTotal = _double(quotation ?? row, [
      'final_amount',
      'q_final_amount',
      'quotation_final_amount',
      'amount',
    ]);
    final timeline = <TimelineStep>[
      TimelineStep(
        stage: 'Booking Created',
        time: _time(createdAt),
        completed: true,
      ),
    ];
    if (status.index >= BookingStatus.verified.index) {
      timeline.add(
        TimelineStep(
          stage: 'Verified',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status.index >= BookingStatus.sentToTeamLead.index) {
      timeline.add(
        TimelineStep(
          stage: 'Sent to Team Lead',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status.index >= BookingStatus.quotationSent.index) {
      timeline.add(
        TimelineStep(
          stage: 'Quotation Sent',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status.index >= BookingStatus.assigned.index) {
      timeline.add(
        TimelineStep(
          stage: 'Resource Allocated',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status.index >= BookingStatus.inTransit.index) {
      timeline.add(
        TimelineStep(
          stage: 'Trip Started',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status.index >= BookingStatus.patientPickedUp.index) {
      timeline.add(
        TimelineStep(
          stage: 'Patient Picked Up',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }
    if (status == BookingStatus.serviceCompleted) {
      timeline.add(
        TimelineStep(
          stage: 'Service Completed',
          time: _time(createdAt),
          completed: true,
        ),
      );
    }

    return AdminBooking(
      id: _string(row, [
        'id',
        'booking_id',
        'booking_reference',
      ], fallback: 'UNKNOWN'),
      refCode: _string(row, [
        'ref_code',
        'reference_code',
        'booking_reference',
      ], fallback: _string(row, ['id'], fallback: '')),
      createdAt: createdAt,
      status: status,
      priority: _string(row, ['priority'], fallback: 'NORMAL'),
      urgencyLevel: _string(row, [
        'urgency_level',
        'urgency',
      ], fallback: 'ROUTINE'),
      serviceCategory: _string(row, [
        'service_category',
        'serviceCategory',
        'category',
      ], fallback: 'ROAD'),
      serviceSubtype: _string(row, [
        'service_subtype',
        'serviceSubtype',
        'ambulance_type',
      ], fallback: 'ROAD AMBULANCE'),
      triageNotes: _string(row, [
        'triage_notes',
        'medical_summary',
        'special_instructions',
      ]),
      customerName: customerName,
      customerContact: _string(row, [
        'customer_contact',
        'mobile_number',
        'phone',
        'customer_phone',
      ]),
      patientName: patientName,
      patientInitials: _initials(patientName),
      patientAge: _int(row, ['patient_age', 'age']),
      patientGender: _string(row, [
        'patient_gender',
        'gender',
      ], fallback: 'Other'),
      patientCondition: _string(row, [
        'patient_condition',
        'current_condition',
        'condition',
      ], fallback: 'Not specified'),
      pickupLocation: _string(row, [
        'pickup',
        'pickup_address',
        'pickup_location',
      ], fallback: 'Pickup location unavailable'),
      destinationLocation: _string(row, [
        'destination',
        'destination_address',
        'destination_location',
      ], fallback: 'Destination unavailable'),
      distanceKm: _double(row, [
        'distance_km',
        'estimated_distance_km',
        'distance',
      ]),
      distanceRemainingKm: _double(row, ['distance_remaining_km']),
      estimatedTimeMinutes: _int(row, [
        'estimated_duration_mins',
        'estimated_time_minutes',
      ]),
      etaMinutes: _int(row, ['eta_minutes'], fallback: 0),
      currentSpeedKmH: _int(row, [
        'geo_speed_kmh',
        'driver_speed_kmh',
        'current_speed_kmh',
      ]),
      driverLatitude: _doubleOrNull(row, ['geo_lat', 'driver_latitude']),
      driverLongitude: _doubleOrNull(row, ['geo_lng', 'driver_longitude']),
      driverLocationUpdatedAt: _date(row, [
        'geo_last_ping',
        'driver_location_recorded_at',
      ]),
      heading: _string(row, ['driver_heading', 'heading'], fallback: 'N 000°'),
      ambulanceId: _nullable(row, ['assigned_ambulance_id']),
      ambulanceCad: _nullable(row, [
        'ambulance_vehicle_number',
        'ambulance_cad',
      ]),
      ambulanceModel: _nullable(row, ['ambulance_name', 'ambulance_model']),
      driverId: _nullable(row, ['assigned_driver_id']),
      driverName: _nullable(row, ['driver_name', 'assigned_driver_name']),
      driverPhone: _nullable(row, ['driver_phone']),
      emtId: _nullable(row, ['assigned_emt_id']),
      emtName: _nullable(row, ['emt_name']),
      doctorId: _nullable(row, ['assigned_doctor_id']),
      doctorName: _nullable(row, ['doctor_name']),
      doctorSpecialization: _nullable(row, ['doctor_specialization']),
      quotationId: _string(
        quotation ?? row,
        ['id', 'quotation_id'],
        fallback: quotationTotal > 0
            ? 'Q-${_string(row, ['id'], fallback: 'UNKNOWN')}'
            : '',
      ),
      quotationTotal: quotationTotal,
      quotationStatus: _string(quotation ?? row, [
        'status',
        'quotation_status',
      ], fallback: quotationTotal > 0 ? 'SENT' : 'PENDING'),
      paymentStatus: _string(invoice ?? row, [
        'payment_status',
      ], fallback: 'UNPAID'),
      baseFare: _double(quotation ?? row, [
        'base_charge',
        'q_base_charge',
        'base_fare',
      ]),
      distanceCharge: _double(quotation ?? row, [
        'distance_charge',
        'q_distance_charge',
      ]),
      doctorFee: _double(quotation ?? row, [
        'doctor_charge',
        'q_doctor_charge',
        'doctor_fee',
      ]),
      emtFee: _double(quotation ?? row, [
        'emt_charge',
        'q_emt_charge',
        'emt_fee',
      ]),
      equipmentFee: _double(quotation ?? row, [
        'equipment_charge',
        'q_equipment_charge',
        'equipment_fee',
      ]),
      nightSurcharge: _double(quotation ?? row, [
        'night_surcharge',
        'q_night_surcharge',
      ]),
      tax: _double(quotation ?? row, ['tax_amount', 'q_tax_amount', 'tax']),
      requiresOxygen: _bool(row, [
        'req_oxygen',
        'oxygen_required',
        'oxygenRequired',
      ]),
      requiresIcu: _bool(row, ['req_icu', 'icu_required', 'icuRequired']),
      requiresVentilator: _bool(row, [
        'req_ventilator',
        'ventilator_required',
        'ventilatorRequired',
      ]),
      requiresPicu: _bool(row, [
        'req_pediatric',
        'req_pediatric_icu',
        'pediatric_required',
      ]),
      requiresCardiacMonitor: _bool(row, [
        'req_cardiac_monitor',
        'cardiac_monitor_required',
      ]),
      requiresStretcher: _bool(row, ['req_stretcher', 'stretcher_required']),
      requiresWheelchair: _bool(row, ['req_wheelchair', 'wheelchair_required']),
      specialRequirements: _stringList(row, [
        'additional_equipment',
        'special_requirements',
      ]),
      timeline: timeline,
      cancellationReason: _nullable(row, [
        'cancellation_reason',
        'quotation_rejection_reason',
      ]),
    );
  }

  List<AdminAmbulance> _mapAmbulances(List<Map<String, dynamic>> rows) {
    return rows
        .map(
          (row) => AdminAmbulance(
            id: _string(row, ['id', 'ambulance_id']),
            callSign: _string(row, [
              'name',
              'call_sign',
              'callSign',
              'vehicle_number',
            ], fallback: 'AMBULANCE'),
            vehicleCadNo: _string(row, [
              'vehicle_number',
              'vehicle_cad_no',
              'cad_number',
            ], fallback: _string(row, ['id'])),
            platform: _string(row, [
              'model',
              'platform',
              'vehicle_model',
            ], fallback: 'Ambulance'),
            classification: _string(row, [
              'classification',
              'subtype',
            ], fallback: 'STANDARD'),
            category: _string(row, [
              'category',
              'service_category',
            ], fallback: 'ROAD'),
            status: FleetStatus.fromString(
              _string(row, ['status'], fallback: 'AVAILABLE'),
            ),
            stationBase: _string(row, [
              'base_station',
              'station_base',
              'station',
            ], fallback: 'Not specified'),
            currentLocation: _string(row, [
              'current_location',
              'location',
            ], fallback: 'Location unavailable'),
            activeIncidentId: _nullable(row, [
              'active_incident_id',
              'active_booking_id',
            ]),
            fuelPercent: _int(row, ['fuel_percent', 'fuel'], fallback: 0),
            oxygenPressureBar: _int(row, [
              'oxygen_pressure_bar',
              'oxygen_pressure',
            ], fallback: 0),
            serviceDate: _string(row, [
              'service_date',
              'last_service_date',
            ], fallback: ''),
            inspectionStatus: _string(row, [
              'inspection_status',
            ], fallback: 'NOT RECORDED'),
            workOrder: _nullable(row, ['work_order']),
            assignedDriver: _nullable(row, ['assigned_driver_name']),
            assignedDriverId: _nullable(row, [
              'assigned_driver_id',
              'current_driver_id',
            ]),
            assignedEmt: _nullable(row, ['assigned_emt_name']),
            assignedDoctor: _nullable(row, ['assigned_doctor_name']),
            hasOxygen: _bool(row, ['has_oxygen', 'oxygen'], fallback: false),
            hasIcu: _bool(row, ['has_icu', 'icu'], fallback: false),
            hasVentilator: _bool(row, [
              'has_ventilator',
              'ventilator',
            ], fallback: false),
            hasPicu: _bool(row, ['has_picu', 'picu'], fallback: false),
            hasIncubator: _bool(row, [
              'has_incubator',
              'incubator',
            ], fallback: false),
            hasFreezer: _bool(row, ['has_freezer', 'freezer'], fallback: false),
            hasCardiacMonitor: _bool(row, [
              'has_cardiac_monitor',
              'cardiac_monitor',
            ]),
            hasStretcher: _bool(row, ['has_stretcher', 'stretcher']),
            hasWheelchair: _bool(row, ['has_wheelchair', 'wheelchair']),
          ),
        )
        .where((a) => a.id.isNotEmpty)
        .toList();
  }

  List<AdminStaff> _mapStaff({
    required List<Map<String, dynamic>> drivers,
    required List<Map<String, dynamic>> doctors,
    required List<Map<String, dynamic>> customerCare,
    required List<Map<String, dynamic>> profiles,
    required List<Map<String, dynamic>> medicalCrew,
  }) {
    final result = <AdminStaff>[];

    result.addAll(drivers.map((r) => _staffFromRow(r, role: 'DRIVER')));
    result.addAll(doctors.map((r) => _staffFromRow(r, role: 'DOCTOR')));
    result.addAll(
      customerCare.map((r) => _staffFromRow(r, role: 'CUSTOMER_CARE')),
    );

    result.addAll(
      profiles
          .where((r) => _string(r, ['role']).toUpperCase() == 'TEAM_LEAD')
          .map((r) => _staffFromRow(r, role: 'TEAM_LEAD')),
    );

    // EMTs are operational resources in public.medical_crew.
    // The provisioning Edge Function uses the Auth user/profile UUID as the
    // medical_crew UUID, so we can merge profile identity data when present.
    for (final crew in medicalCrew) {
      final crewId = _string(crew, ['id']);
      final crewPhone = _string(crew, ['phone']);
      final matchingProfile = profiles.cast<Map<String, dynamic>?>().firstWhere(
        (profile) {
          if (profile == null) return false;
          final profileId = _string(profile, ['id', 'profile_id', 'user_id']);
          final profilePhone = _string(profile, ['phone']);
          return (crewId.isNotEmpty && profileId == crewId) ||
              (crewPhone.isNotEmpty && profilePhone == crewPhone);
        },
        orElse: () => null,
      );

      final merged = <String, dynamic>{
        ...crew,
        ...?matchingProfile,
        'id': crewId,
        'status': _string(crew, ['status'], fallback: 'AVAILABLE'),
        'role': 'EMT',
        'crew_type': _string(crew, ['crew_type'], fallback: 'EMT'),
        'certification': _nullable(crew, ['certification']),
      };

      result.add(_staffFromRow(merged, role: 'EMT'));
    }

    return result.where((s) => s.id.isNotEmpty).toList();
  }

  AdminStaff _staffFromRow(Map<String, dynamic> row, {required String role}) {
    return AdminStaff(
      id: _string(row, ['id', 'profile_id', 'user_id']),
      name: _string(row, ['name', 'full_name'], fallback: 'Unnamed staff'),
      email: _string(row, ['email']),
      phone: _string(row, ['phone']),
      role: role,
      status: StaffStatus.fromString(
        _string(row, ['status'], fallback: 'AVAILABLE'),
      ),
      licenseNumber: _nullable(row, ['license_number']),
      licenseExpiry: _nullable(row, ['license_expiry']),
      specialization: _nullable(row, ['specialization']),
      qualification: _nullable(row, ['qualification']),
      hospital: _nullable(row, ['current_hospital', 'hospital']),
      experienceYears: _int(row, ['experience_years']),
      tripCount: _int(row, ['total_trips', 'trip_count']),
      rating: _double(row, ['rating']),
      assignedVehicle: _nullable(row, [
        'assigned_ambulance_number',
        'assigned_vehicle',
      ]),
      assignedMission: _nullable(row, [
        'assigned_booking_id',
        'assigned_mission',
      ]),
      department: _nullable(row, ['department']),
      shift: _nullable(row, ['shift']),
      workload: _nullable(row, ['workload']),
      suspensionReason: _nullable(row, ['suspension_reason']),
      hasPediatricCapability: _bool(row, [
        'is_pediatric_capable',
        'has_pediatric_capability',
      ]),
    );
  }

  List<AdminAuditEntry> _mapAuditLogs(List<Map<String, dynamic>> rows) {
    return rows
        .map(
          (r) => AdminAuditEntry(
            id: _string(r, ['id'], fallback: 'AUD-${rows.indexOf(r) + 1}'),
            timestamp: _date(r, ['timestamp', 'created_at']) ?? DateTime.now(),
            actor: _string(r, [
              'user_name',
              'actor_name',
            ], fallback: 'Unknown actor'),
            role: _string(r, ['user_role', 'role'], fallback: 'UNKNOWN'),
            action: _string(r, ['action'], fallback: 'UNKNOWN'),
            entity: _string(r, ['entity_type', 'entity'], fallback: 'SYSTEM'),
            entityId: _string(r, ['booking_id', 'entity_id']),
            severity: _string(r, ['severity'], fallback: 'INFO'),
            details: _string(r, [
              'notes',
              'details',
              'action',
            ], fallback: 'Administrative event'),
            previousValue: _string(r, ['previous_value']),
            newValue: _string(r, ['new_value']),
          ),
        )
        .toList();
  }

  AdminPricingRateCard _pricingFromRow(
    Map<String, dynamic>? row, {
    required bool active,
  }) {
    final source = row ?? const <String, dynamic>{};
    final version = _string(source, [
      'version_id',
      'versionId',
    ], fallback: active ? 'DATABASE_ACTIVE' : 'DATABASE_DRAFT');
    return AdminPricingRateCard(
      versionId: version,
      currency: _string(source, ['currency'], fallback: 'INR'),
      effectiveDate: _string(source, [
        'effective_from',
        'effective_date',
        'updated_at',
      ], fallback: ''),
      createdBy: _string(source, [
        'created_by_name',
        'created_by',
        'updated_by',
      ], fallback: 'Supabase configuration'),
      approvedBy: _string(source, [
        'approved_by_name',
        'approved_by',
      ], fallback: active ? 'Configured in database' : 'Not approved'),
      isActive: active,
      roadBasicOxygenBase: _double(source, ['road_basic_oxygen_base']),
      roadBasicOxygenPerKm: _double(source, ['road_basic_oxygen_per_km']),
      roadIcuBase: _double(source, ['road_advanced_icu_base', 'road_icu_base']),
      roadIcuPerKm: _double(source, [
        'road_advanced_icu_per_km',
        'road_icu_per_km',
      ]),
      roadPicuBase: _double(source, [
        'road_pediatric_icu_base',
        'road_picu_base',
      ]),
      roadPicuPerKm: _double(source, [
        'road_pediatric_icu_per_km',
        'road_picu_per_km',
      ]),
      railwayBase: _double(source, ['railway_base']),
      airBaseRate: _double(source, ['air_medevac_base', 'air_base_rate']),
      airPerKm: _double(source, ['air_per_km']),
      deadBodyBase: _double(source, ['dead_body_base']),
      deadBodyPerKm: _double(source, ['dead_body_per_km']),
      doctorFee: _double(source, ['doctor_escort', 'doctor_fee']),
      emtFee: _double(source, ['emt_escort', 'emt_fee']),
      ventilatorFee: _double(source, ['ventilator']),
      incubatorFee: _double(source, ['incubator']),
      oxygenFlatFee: _double(source, ['oxygen']),
      nightSurchargePercent: _double(source, ['night_surcharge_percent']),
      taxPercent: _double(source, ['tax_percent'], fallback: 5),
    );
  }

  static String _string(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
    }
    return fallback;
  }

  static String? _nullable(Map<String, dynamic> row, List<String> keys) {
    final value = _string(row, keys);
    return value.isEmpty ? null : value;
  }

  static int _int(
    Map<String, dynamic> row,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double _double(
    Map<String, dynamic> row,
    List<String> keys, {
    double fallback = 0,
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double? _doubleOrNull(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _bool(
    Map<String, dynamic> row,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value is bool) return value;
      if ('$value'.toLowerCase() == 'true') return true;
      if ('$value'.toLowerCase() == 'false') return false;
    }
    return fallback;
  }

  static DateTime? _date(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is DateTime) return value;
      if (value != null) {
        final parsed = DateTime.tryParse('$value');
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }

  static String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static List<String> _stringList(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is List) return value.map((e) => '$e').toList();
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  // --- ACTIONS & WORKFLOWS ---

  // 1. Advance Booking Timeline
  void advanceBookingStage(
    String bookingId,
    String nextStageName, {
    String actor = 'Administrator',
  }) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;
    final booking = _bookings[idx];

    final stepIdx = booking.timeline.indexWhere(
      (t) => t.stage.toLowerCase() == nextStageName.toLowerCase(),
    );
    if (stepIdx != -1) {
      booking.timeline[stepIdx].completed = true;
    }

    if (nextStageName.toLowerCase().contains('picked up')) {
      booking.status = BookingStatus.patientPickedUp;
    } else if (nextStageName.toLowerCase().contains('trip started')) {
      booking.status = BookingStatus.inTransit;
    } else if (nextStageName.toLowerCase().contains('complete')) {
      booking.status = BookingStatus.serviceCompleted;
      booking.distanceRemainingKm = 0;
      booking.etaMinutes = 0;

      // Release ambulance if completed
      if (booking.ambulanceId != null) {
        final ambIdx = _ambulances.indexWhere(
          (a) => a.id == booking.ambulanceId,
        );
        if (ambIdx != -1) {
          _ambulances[ambIdx].status = FleetStatus.available;
          _ambulances[ambIdx].activeIncidentId = null;
        }
      }
    }

    _recordAudit(
      action: 'BOOKING_TIMELINE_ADVANCE',
      entity: 'BOOKING',
      entityId: booking.id,
      details: 'Advanced timeline to stage: $nextStageName by $actor',
      newValue: nextStageName,
    );

    notifyListeners();
  }

  // 2. Controlled Fleet Status Change with Safety Rules
  (bool success, String message) updateAmbulanceStatus({
    required String ambulanceId,
    required FleetStatus newStatus,
    String? supervisorPin,
    bool checklistPassed = false,
  }) {
    final idx = _ambulances.indexWhere((a) => a.id == ambulanceId);
    if (idx == -1) return (false, 'Ambulance not found.');
    final ambulance = _ambulances[idx];

    // Safety Rule 1: Active Mission cannot silently transition to Available
    if ((ambulance.status == FleetStatus.activeMission ||
            ambulance.status == FleetStatus.inTransit) &&
        newStatus == FleetStatus.available) {
      return (
        false,
        'Safety Governance Lock: ${ambulance.callSign} is currently on Active Mission #${ambulance.activeIncidentId ?? "CURRENT"}. Transition to Available is blocked until receiving hospital electronically confirms patient handover.',
      );
    }

    // Safety Rule 2: Maintenance to Available requires Supervisor PIN & Clinical Sign-off
    if (ambulance.status == FleetStatus.maintenance &&
        newStatus == FleetStatus.available) {
      if (!checklistPassed) {
        return (
          false,
          'Clinical Safety Lock: All decontamination and gas pressure checklists must be verified.',
        );
      }
      if (supervisorPin == null || supervisorPin.length < 4) {
        return (
          false,
          'Authorization Lock: Enter a valid 4-digit Supervisor PIN to clear maintenance units.',
        );
      }
    }

    final oldStatus = ambulance.status.label;
    ambulance.status = newStatus;
    if (newStatus == FleetStatus.available) {
      ambulance.activeIncidentId = null;
      ambulance.workOrder = null;
    }

    _recordAudit(
      action: 'FLEET_STATUS_MUTATION',
      entity: 'AMBULANCE',
      entityId: ambulance.callSign,
      severity: newStatus == FleetStatus.maintenance ? 'WARNING' : 'INFO',
      details:
          '${ambulance.callSign} operational status transitioned from $oldStatus to ${newStatus.label}',
      previousValue: oldStatus,
      newValue: newStatus.label,
    );

    notifyListeners();
    return (
      true,
      '${ambulance.callSign} status successfully updated to ${newStatus.label}.',
    );
  }

  Future<(bool success, String message)> updateAmbulanceStatusAsync({
    required String ambulanceId,
    required FleetStatus newStatus,
    String? supervisorPin,
    bool checklistPassed = false,
  }) async {
    final idx = _ambulances.indexWhere((a) => a.id == ambulanceId);
    if (idx == -1) return (false, 'Ambulance not found.');
    final ambulance = _ambulances[idx];

    if ((ambulance.status == FleetStatus.activeMission ||
            ambulance.status == FleetStatus.inTransit) &&
        newStatus == FleetStatus.available) {
      return (
        false,
        'Safety Governance Lock: active mission units cannot be returned to Available from Admin.',
      );
    }
    if (ambulance.status == FleetStatus.maintenance &&
        newStatus == FleetStatus.available) {
      if (!checklistPassed) {
        return (
          false,
          'Clinical Safety Lock: maintenance checklist must be verified.',
        );
      }
      if (supervisorPin == null || supervisorPin.length < 4) {
        return (
          false,
          'Authorization Lock: valid supervisor authorization is required.',
        );
      }
    }

    try {
      await _repository.fleetStatus(
        ambulance.id,
        newStatus.name == 'activeMission' ? 'ACTIVE_MISSION' : newStatus.label,
      );
      await loadFromDatabase();
      return (
        true,
        '${ambulance.callSign} status updated to ${newStatus.label}.',
      );
    } catch (error) {
      return (false, 'Fleet status update failed: $error');
    }
  }

  // 3. Register New Ambulance Transactional Workflow (Step 1-5)
  //
  // IMPORTANT: fleet registration is now server-backed. The previous version
  // only inserted the new ambulance/driver into this in-memory store, so the
  // record disappeared after logout/re-login and Team Lead could not see it.
  Future<(bool success, String message)> registerAmbulance({
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
    required int fuelPercent,
    required int oxygenPressureBar,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String driverEmail,
    required String driverLicense,
    required int driverExperience,
  }) async {
    // ------------------------------------------------------------------------
    // Client-side validation
    // ------------------------------------------------------------------------
    if (callSign.trim().isEmpty || vehicleCadNo.trim().isEmpty) {
      return (false, 'Call Sign and CAD Number are required fields.');
    }

    if (_ambulances.any(
      (a) => a.callSign.toLowerCase() == callSign.trim().toLowerCase(),
    )) {
      return (
        false,
        'An ambulance with Call Sign $callSign already exists in CAD Fleet.',
      );
    }

    if (driverName.trim().isEmpty || driverLicense.trim().isEmpty) {
      return (
        false,
        'A credentialed driver name and license number are required.',
      );
    }

    // Revalidate the selected existing driver from the freshly hydrated
    // roster. Duty status is not the same as primary-ambulance eligibility.
    final selectedDriver = _staff.where(
      (staff) =>
          staff.id.toString() == driverId &&
          staff.role.toUpperCase() == 'DRIVER',
    );
    if (selectedDriver.isEmpty) {
      return (false, 'Select a current available driver from the roster.');
    }
    final driver = selectedDriver.first;
    if (driver.status != StaffStatus.available) {
      return (false, 'Selected driver is not available for fleet enrollment.');
    }
    if (driver.assignedVehicle?.trim().isNotEmpty == true) {
      return (
        false,
        'Selected driver ${driver.name} is already paired with ambulance '
            '${driver.assignedVehicle}. Choose an unpaired driver.',
      );
    }
    if (driver.assignedMission?.trim().isNotEmpty == true) {
      return (
        false,
        'Selected driver ${driver.name} is assigned to an active booking. '
            'Choose an unassigned driver.',
      );
    }

    if (!SupabaseService.isConfigured) {
      return (
        false,
        'Supabase is not configured. Fleet registration cannot be saved.',
      );
    }

    try {
      // ----------------------------------------------------------------------
      // 1. Persist the ambulance in the canonical public.ambulances table.
      // ----------------------------------------------------------------------
      await _repository.registerAmbulance(
        callSign: callSign.trim(),
        vehicleCadNo: vehicleCadNo.trim(),
        platform: platform.trim(),
        classification: classification,
        category: category,
        stationBase: stationBase,
        hasOxygen: hasOxygen,
        hasIcu: hasIcu,
        hasVentilator: hasVentilator,
        hasPicu: hasPicu,
        hasIncubator: hasIncubator,
        hasFreezer: hasFreezer,
        driverId: driverId,
      );

      // The selected driver already exists in the operational roster. The
      // server transaction binds that driver to this ambulance; do not create
      // a second driver account from the registration form.
      // ----------------------------------------------------------------------
      // Reload from Supabase. Never rely on local-only state.
      // ----------------------------------------------------------------------
      await loadFromDatabase();

      // ----------------------------------------------------------------------
      // 4. Audit is recorded by the backend fleet RPC. The local store is
      //    refreshed from the canonical DB state.
      // ----------------------------------------------------------------------
      return (
        true,
        'Ambulance ${callSign.trim()} successfully registered and saved. '
            'It is now AVAILABLE for Team Lead allocation, and driver $driverName '
            'has been paired with $driverName.',
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return (false, 'Ambulance registration failed: $message');
    }
  }

  // 4. Staff Lifecycle Operations (Suspend, Activate, Deactivate)
  (bool success, String message) setStaffStatus({
    required String staffId,
    required StaffStatus newStatus,
    String? reason,
  }) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx == -1) return (false, 'Staff member not found.');
    final member = _staff[idx];

    // Safety Rule: If actively assigned to an ambulance or mission, cannot suspend/deactivate
    if (member.status == StaffStatus.assigned &&
        (newStatus == StaffStatus.suspended ||
            newStatus == StaffStatus.inactive)) {
      return (
        false,
        'Active Assignment Conflict: ${member.name} is currently assigned to active duties (${member.assignedVehicle ?? member.assignedMission ?? "In Service"}). Please reassign duties before altering status to ${newStatus.label}.',
      );
    }

    final oldStatus = member.status.label;
    member.status = newStatus;
    if (newStatus == StaffStatus.suspended) {
      member.suspensionReason = reason ?? 'Administrative hold';
    } else {
      member.suspensionReason = null;
    }

    _recordAudit(
      action: newStatus == StaffStatus.suspended
          ? 'STAFF_SUSPENDED'
          : 'STAFF_STATUS_CHANGE',
      entity: 'STAFF',
      entityId: member.id,
      severity: newStatus == StaffStatus.suspended ? 'CRITICAL' : 'INFO',
      details:
          'Staff member ${member.name} (${member.role}) status changed from $oldStatus to ${newStatus.label}. Reason: ${reason ?? "Routine"}',
      previousValue: oldStatus,
      newValue: newStatus.label,
    );

    notifyListeners();
    return (true, '${member.name} status updated to ${newStatus.label}.');
  }

  Future<(bool success, String message)> provisionStaffFromDatabase({
    required String name,
    required String email,
    required String phone,
    required String role,
    String? specialization,
    String? licenseNumber,
    int experienceYears = 0,
    bool pediatricCapable = false,
    String? hospital,
    String? department,
    String? shift,
    String? certification,
    String? crewType,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      return (false, 'Name and email are required.');
    }
    const supportedRoles = {
      'DRIVER',
      'DOCTOR',
      'EMT',
      'CUSTOMER_CARE',
      'TEAM_LEAD',
    };
    if (!supportedRoles.contains(role)) {
      return (
        false,
        'This staff role is not supported for account provisioning.',
      );
    }
    try {
      await _repository.provisionStaff({
        'role': role,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'license_number': licenseNumber?.trim(),
        'experience_years': experienceYears,
        'specialization': specialization?.trim(),
        'is_pediatric_capable': pediatricCapable,
        'current_hospital': hospital?.trim(),
        'department': department?.trim(),
        'shift': shift?.trim(),
        'certification': certification?.trim(),
        'crew_type': (crewType?.trim().isNotEmpty ?? false)
            ? crewType!.trim().toUpperCase()
            : 'EMT',
      });
      await loadFromDatabase();
      return (
        true,
        '$name was provisioned successfully. An invitation was sent to $email.',
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Bad state: ', '');
      if (message.startsWith('Staff service is currently unavailable.') ||
          message.startsWith('An account already exists for this email.')) {
        return (false, message);
      }
      return (false, 'Staff provisioning failed: $message');
    }
  }

  // 5. Pricing Rate Card Operations
  void activateDraftPricing() {
    activePricing = AdminPricingRateCard(
      versionId: draftPricing.versionId.replaceAll('-DRAFT', ''),
      currency: draftPricing.currency,
      effectiveDate: DateTime.now().toIso8601String().substring(0, 10),
      createdBy: draftPricing.createdBy,
      approvedBy: 'CAD Executive Board Approved',
      isActive: true,
      roadBasicOxygenBase: draftPricing.roadBasicOxygenBase,
      roadBasicOxygenPerKm: draftPricing.roadBasicOxygenPerKm,
      roadIcuBase: draftPricing.roadIcuBase,
      roadIcuPerKm: draftPricing.roadIcuPerKm,
      roadPicuBase: draftPricing.roadPicuBase,
      roadPicuPerKm: draftPricing.roadPicuPerKm,
      railwayBase: draftPricing.railwayBase,
      airBaseRate: draftPricing.airBaseRate,
      airPerKm: draftPricing.airPerKm,
      deadBodyBase: draftPricing.deadBodyBase,
      deadBodyPerKm: draftPricing.deadBodyPerKm,
      doctorFee: draftPricing.doctorFee,
      emtFee: draftPricing.emtFee,
      ventilatorFee: draftPricing.ventilatorFee,
      incubatorFee: draftPricing.incubatorFee,
      oxygenFlatFee: draftPricing.oxygenFlatFee,
      nightSurchargePercent: draftPricing.nightSurchargePercent,
      taxPercent: draftPricing.taxPercent,
    );

    _recordAudit(
      action: 'PRICING_VERSION_ACTIVATED',
      entity: 'PRICING',
      entityId: activePricing.versionId,
      severity: 'WARNING',
      details: 'Activated pricing rate card version ${activePricing.versionId}',
      newValue: 'Effective ${activePricing.effectiveDate}',
    );

    notifyListeners();
  }

  Future<(bool success, String message)>
  activateDraftPricingFromDatabase() async {
    try {
      await _repository.savePricingSettings({
        'road_basic_oxygen_base': draftPricing.roadBasicOxygenBase,
        'road_basic_oxygen_per_km': draftPricing.roadBasicOxygenPerKm,
        'road_advanced_icu_base': draftPricing.roadIcuBase,
        'road_advanced_icu_per_km': draftPricing.roadIcuPerKm,
        'road_pediatric_icu_base': draftPricing.roadPicuBase,
        'road_pediatric_icu_per_km': draftPricing.roadPicuPerKm,
        'railway_base': draftPricing.railwayBase,
        'air_medevac_base': draftPricing.airBaseRate,
        'dead_body_base': draftPricing.deadBodyBase,
        'dead_body_per_km': draftPricing.deadBodyPerKm,
        'doctor_escort': draftPricing.doctorFee,
        'emt_escort': draftPricing.emtFee,
        'ventilator': draftPricing.ventilatorFee,
        'incubator': draftPricing.incubatorFee,
        'oxygen': draftPricing.oxygenFlatFee,
        'night_surcharge_percent': draftPricing.nightSurchargePercent,
        'tax_percent': draftPricing.taxPercent,
      });
      await loadFromDatabase();
      return (true, 'Pricing configuration saved to Supabase.');
    } catch (error) {
      return (false, 'Pricing update failed: $error');
    }
  }

  // 7. Interactive Pricing Calculator
  Map<String, double> previewQuote({
    required double distanceKm,
    required String serviceCategory,
    String subType = 'BASIC',
    bool needsDoctor = false,
    bool needsEmt = false,
    bool needsVentilator = false,
    bool needsIncubator = false,
    bool needsOxygen = false,
    bool isNight = false,
  }) {
    final p = activePricing;
    double base = 0;
    double distanceCharge = 0;

    if (serviceCategory == 'ROAD') {
      if (subType == 'PICU') {
        base = p.roadPicuBase;
        distanceCharge = distanceKm * p.roadPicuPerKm;
      } else if (subType == 'ICU') {
        base = p.roadIcuBase;
        distanceCharge = distanceKm * p.roadIcuPerKm;
      } else {
        base = p.roadBasicOxygenBase;
        distanceCharge = distanceKm * p.roadBasicOxygenPerKm;
      }
    } else if (serviceCategory == 'RAILWAY') {
      base = p.railwayBase;
      distanceCharge = distanceKm * 3.20;
    } else if (serviceCategory == 'AIR') {
      base = p.airBaseRate;
      distanceCharge = distanceKm * p.airPerKm;
    } else if (serviceCategory == 'DEAD_BODY') {
      base = p.deadBodyBase;
      distanceCharge = distanceKm * p.deadBodyPerKm;
    }

    final doctorFee = needsDoctor ? p.doctorFee : 0.0;
    final emtFee = needsEmt ? p.emtFee : 0.0;
    final staffFees = doctorFee + emtFee;

    double equipmentFees = 0.0;
    if (needsVentilator) equipmentFees += p.ventilatorFee;
    if (needsIncubator) equipmentFees += p.incubatorFee;
    if (needsOxygen) equipmentFees += p.oxygenFlatFee;

    final subtotal = base + distanceCharge + staffFees + equipmentFees;
    final nightSurcharge = isNight
        ? (subtotal * (p.nightSurchargePercent / 100))
        : 0.0;
    final preTax = subtotal + nightSurcharge;
    final tax = preTax * (p.taxPercent / 100);
    final total = preTax + tax;

    return {
      'baseFare': base,
      'distanceCharge': distanceCharge,
      'doctorFee': doctorFee,
      'emtFee': emtFee,
      'equipmentFees': equipmentFees,
      'nightSurcharge': nightSurcharge,
      'tax': tax,
      'total': total,
    };
  }

  // 8. Reallocate Resources to Booking
  Future<void> reallocateBooking({
    required String bookingId,
    required String ambulanceId,
    required String driverId,
    String? emtId,
    String? doctorId,
  }) async {
    final bIdx = _bookings.indexWhere((b) => b.id == bookingId);
    if (bIdx == -1) throw StateError('Booking is not loaded in Admin.');
    final b = _bookings[bIdx];

    final amb = _ambulances.firstWhere((a) => a.id == ambulanceId);
    final drv = _staff.firstWhere((s) => s.id == driverId);
    final emt = emtId != null ? _staff.firstWhere((s) => s.id == emtId) : null;
    final doc = doctorId != null
        ? _staff.firstWhere((s) => s.id == doctorId)
        : null;

    await _repository.reassignBookingResources(
      bookingId: bookingId,
      ambulanceId: ambulanceId,
      driverId: driverId,
    );

    b.ambulanceId = amb.id;
    b.ambulanceCad = amb.vehicleCadNo;
    b.ambulanceModel = amb.platform;
    b.driverId = drv.id;
    b.driverName = drv.name;
    b.driverPhone = drv.phone;
    if (emt != null) {
      b.emtId = emt.id;
      b.emtName = emt.name;
    }
    if (doc != null) {
      b.doctorId = doc.id;
      b.doctorName = doc.name;
      b.doctorSpecialization = doc.specialization;
    }

    _recordAudit(
      action: 'RESOURCE_REALLOCATION',
      entity: 'BOOKING',
      entityId: b.id,
      details:
          'Reallocated to unit ${amb.callSign}, Driver ${drv.name}, Doctor ${doc?.name ?? "None"}',
      newValue: 'Ambulance: ${amb.callSign}',
    );

    await loadFromDatabase();
    notifyListeners();
  }

  void _recordAudit({
    required String action,
    required String entity,
    required String entityId,
    required String details,
    String severity = 'INFO',
    String previousValue = '',
    String newValue = '',
  }) {
    final entry = AdminAuditEntry(
      id: 'AUD-${1000 + _auditLogs.length + 1}',
      timestamp: DateTime.now(),
      actor: 'Admin Ops Lead',
      role: 'ADMIN',
      action: action,
      entity: entity,
      entityId: entityId,
      severity: severity,
      details: details,
      previousValue: previousValue,
      newValue: newValue,
    );
    _auditLogs.insert(0, entry);
    notifyListeners();
  }

  @override
  void dispose() {
    _bookings.clear();
    _ambulances.clear();
    _staff.clear();
    _auditLogs.clear();
    super.dispose();
  }
}
