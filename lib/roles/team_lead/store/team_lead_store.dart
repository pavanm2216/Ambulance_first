import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/shared_booking_store.dart';
import '../../../core/services/team_lead_operations_service.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../models/team_lead_models.dart';

class TeamLeadStore extends ChangeNotifier {
  TeamLeadStore._();

  static final TeamLeadStore instance = TeamLeadStore._();

  final List<AmbulanceUnit> _ambulances = [];
  final List<DriverRosterItem> _drivers = [];
  final List<EmtRosterItem> _emts = [];
  final List<DoctorRosterItem> _doctors = [];
  final List<AuditEventItem> _auditLogs = [];
  final List<OperationalNotificationItem> _notifications = [];
  Timer? _liveRefreshTimer;
  bool _refreshingFromBackend = false;
  String? _bookingFeedError;
  DateTime? _lastSuccessfulBookingRefresh;

  List<AmbulanceUnit> get ambulances => List.unmodifiable(_ambulances);
  List<DriverRosterItem> get drivers => List.unmodifiable(_drivers);
  List<EmtRosterItem> get emts => List.unmodifiable(_emts);
  List<DoctorRosterItem> get doctors => List.unmodifiable(_doctors);
  List<AuditEventItem> get auditLogs => List.unmodifiable(_auditLogs);
  List<OperationalNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.read).length;

  bool get isRefreshingFromBackend => _refreshingFromBackend;
  String? get bookingFeedError => _bookingFeedError;
  DateTime? get lastSuccessfulBookingRefresh => _lastSuccessfulBookingRefresh;

  List<Booking> get allBookings => SharedBookingStore.bookings;

  Future<void> hydrateFromBackend({String? userId}) async {
    if (_refreshingFromBackend) return;
    if (!SupabaseService.isConfigured) {
      _bookingFeedError = 'Supabase is not configured.';
      notifyListeners();
      return;
    }

    _refreshingFromBackend = true;
    notifyListeners();

    try {
      final db = SupabaseService.client;
      final bookingRepo = SupabaseBookingRepository();

      // ------------------------------------------------------------
      // BOOKINGS: single Team Lead source of truth.
      // The repository unwraps the get_team_lead_bookings RPC response.
      // ------------------------------------------------------------
      List<Booking> bookings = <Booking>[];

      try {
        bookings = await bookingRepo.getBookingsForTeamLead();
        SharedBookingStore.replaceAll(bookings);
        _bookingFeedError = null;
        _lastSuccessfulBookingRefresh = DateTime.now();

        debugPrint(
          'TEAM LEAD: loaded ${bookings.length} live bookings from Supabase',
        );
      } catch (error, stackTrace) {
        _bookingFeedError = error.toString();
        bookings = SharedBookingStore.bookings;
        debugPrint('TEAM LEAD BOOKING LOAD ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        // Do not replace a previously good store with an empty list
        // when a refresh fails.
      }

      // ------------------------------------------------------------
      // RESOURCES: use the Team Lead SECURITY DEFINER RPCs.
      // This avoids direct-table RLS differences between environments.
      // ------------------------------------------------------------
      List<Map<String, dynamic>> ambulances = <Map<String, dynamic>>[];
      List<Map<String, dynamic>> drivers = <Map<String, dynamic>>[];
      List<Map<String, dynamic>> doctors = <Map<String, dynamic>>[];
      List<Map<String, dynamic>> emts = <Map<String, dynamic>>[];

      try {
        final result = await db.rpc('get_team_lead_ambulances');
        ambulances = _maps(result);
      } catch (error, stackTrace) {
        debugPrint('TEAM LEAD AMBULANCE RPC ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        final result = await db.rpc('get_team_lead_drivers');
        drivers = _maps(result);
      } catch (error, stackTrace) {
        debugPrint('TEAM LEAD DRIVER RPC ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        final result = await db.rpc('get_team_lead_doctors');
        doctors = _maps(result);
      } catch (error, stackTrace) {
        debugPrint('TEAM LEAD DOCTOR RPC ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        final result = await db.rpc('get_team_lead_emt_profiles');
        emts = _maps(result);
      } catch (error, stackTrace) {
        debugPrint('TEAM LEAD MEDICAL CREW RPC ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      // ------------------------------------------------------------
      // Resource -> active booking relationships.
      // The live schema stores assignment IDs on bookings, not on
      // ambulances/drivers/doctors/medical_crew rows.
      // ------------------------------------------------------------
      final activeBookings = bookings.where(_isActiveMission).toList();

      String? assignedBookingForResource({
        required String resourceId,
        required String type,
        String name = '',
      }) {
        final normalizedId = resourceId.trim();
        if (normalizedId.isNotEmpty) {
          for (final booking in activeBookings) {
            final assignedId = switch (type) {
              'driver' => booking.assignedDriverId,
              'doctor' => booking.assignedDoctorId,
              'emt' => booking.assignedMedicalCrewId,
              'ambulance' => booking.assignedAmbulanceId,
              _ => null,
            };
            if (assignedId == normalizedId) return booking.id;
          }
        }

        // Legacy installations may not return assignment IDs in their role RPC.
        final normalizedName = name.trim().toLowerCase();
        if (normalizedName.isEmpty) return null;
        for (final booking in activeBookings) {
          final assignedName = switch (type) {
            'driver' => booking.driverName,
            'doctor' => booking.doctorName,
            'emt' => booking.emtName,
            _ => '',
          };
          if (assignedName.trim().toLowerCase() == normalizedName) {
            return booking.id;
          }
        }
        return null;
      }

      String? assignedAmbulanceBooking(String ambulanceId) {
        if (ambulanceId.isEmpty) return null;
        final directMatch = assignedBookingForResource(
          resourceId: ambulanceId,
          type: 'ambulance',
        );
        if (directMatch != null) return directMatch;

        final ambulance = ambulances.firstWhere(
          (row) => '${row['id'] ?? ''}' == ambulanceId,
          orElse: () => <String, dynamic>{},
        );

        final vehicle = '${ambulance['vehicle_number'] ?? ''}'
            .trim()
            .toLowerCase();

        if (vehicle.isEmpty) return null;

        for (final booking in activeBookings) {
          if (booking.vehicleNumber.trim().toLowerCase() == vehicle) {
            return booking.id;
          }
        }

        return null;
      }

      // ------------------------------------------------------------
      // AMBULANCES: CURRENT LIVE SCHEMA
      // ------------------------------------------------------------
      _ambulances
        ..clear()
        ..addAll(
          ambulances.map((r) {
            final id = '${r['id'] ?? ''}';
            final vehicleNumber = '${r['vehicle_number'] ?? ''}';

            final capabilities = <String>{
              if (r['oxygen_capable'] == true) 'OXYGEN',
              if (r['icu_capable'] == true) 'ICU',
              if (r['ventilator_capable'] == true) 'VENTILATOR',
              if (r['pediatric_icu_capable'] == true) 'PICU',
              if (r['cardiac_monitor_capable'] == true) 'CARDIAC_MONITOR',
              if (r['stretcher_capable'] == true) 'STRETCHER',
              if (r['wheelchair_capable'] == true) 'WHEELCHAIR',
            };

            return AmbulanceUnit(
              id: id,
              name: '${r['display_name'] ?? vehicleNumber}',
              registrationNumber:
                  '${r['registration_number'] ?? vehicleNumber}',
              model: '',
              category: '${r['category'] ?? 'ROAD'}',
              subtype: '${r['service_subtype'] ?? ''}',
              baseStation: '',
              // A missing RPC field is unknown, not an OFFLINE state.
              status: '${r['status'] ?? 'UNKNOWN'}'.toUpperCase(),
              capabilities: capabilities,
              assignedBookingId: assignedAmbulanceBooking(id),
            );
          }),
        );

      // ------------------------------------------------------------
      // DRIVERS: CURRENT LIVE SCHEMA
      // ------------------------------------------------------------
      _drivers
        ..clear()
        ..addAll(
          drivers.map((r) {
            final id = '${r['id'] ?? ''}';
            final name = '${r['full_name'] ?? ''}';

            final supportedCategory = '${r['supported_category'] ?? ''}'.trim();

            return DriverRosterItem(
              id: id,
              name: name,
              phone: '${r['phone'] ?? ''}',
              email: '',
              licenseNumber: '${r['license_number'] ?? ''}',
              licenseExpiry: '',
              experienceYears:
                  int.tryParse('${r['experience_years'] ?? 0}') ?? 0,
              supportedCategories: supportedCategory.isEmpty
                  ? const []
                  : <String>[supportedCategory],
              status: '${r['status'] ?? 'OFF_DUTY'}'.toUpperCase(),
              depot: '',
              assignedBookingId: assignedBookingForResource(
                resourceId: id,
                type: 'driver',
                name: name,
              ),
              assignedAmbulanceNumber:
                  '${r['assigned_ambulance_number'] ?? r['assigned_vehicle'] ?? ''}',
              completedTrips: 0,
            );
          }),
        );

      // ------------------------------------------------------------
      // DOCTORS: CURRENT LIVE SCHEMA
      // ------------------------------------------------------------
      _doctors
        ..clear()
        ..addAll(
          doctors.map((r) {
            final id = '${r['id'] ?? ''}';
            final name = '${r['full_name'] ?? ''}';

            return DoctorRosterItem(
              id: id,
              name: name,
              phone: '${r['phone'] ?? ''}',
              email: '',
              specialization: '${r['specialization'] ?? ''}',
              hospital: '',
              experienceYears: 0,
              hasPediatricCapability: false,
              medicalLicense: '',
              licenseExpiry: '',
              status: '${r['status'] ?? 'OFF_DUTY'}'.toUpperCase(),
              depot: '',
              assignedBookingId: assignedBookingForResource(
                resourceId: id,
                type: 'doctor',
                name: name,
              ),
            );
          }),
        );

      // ------------------------------------------------------------
      // MEDICAL CREW / EMT: CURRENT LIVE SCHEMA VIA RPC
      // ------------------------------------------------------------
      _emts
        ..clear()
        ..addAll(
          emts.map((r) {
            final id = '${r['id'] ?? ''}';
            final name = '${r['full_name'] ?? ''}';

            return EmtRosterItem(
              id: id,
              name: name,
              phone: '${r['phone'] ?? ''}',
              email: '${r['email'] ?? ''}',
              qualification: '${r['role'] ?? 'MEDICAL_CREW'}',
              experienceYears: 0,
              certifications: <String>{},
              hasPediatricCapability: false,
              status: '${r['status'] ?? 'AVAILABLE'}'.toUpperCase(),
              depot: '',
              assignedBookingId: '${r['assigned_booking_id'] ?? ''}'.isEmpty
                  ? assignedBookingForResource(
                      resourceId: id,
                      type: 'emt',
                      name: name,
                    )
                  : '${r['assigned_booking_id']}',
            );
          }),
        );

      notifyListeners();
    } finally {
      _refreshingFromBackend = false;
      notifyListeners();
    }
  }

  bool _isActiveMission(Booking booking) => const {
    'ASSIGNED',
    'DRIVER_ASSIGNED',
    'PICKUP_STARTED',
    'PATIENT_PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED',
  }.contains(booking.status.trim().toUpperCase());

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> refreshFromBackend({String? userId}) =>
      hydrateFromBackend(userId: userId);

  void startLiveBackendSync({String? userId}) {
    if (!SupabaseService.isConfigured) return;
    _liveRefreshTimer?.cancel();

    unawaited(_hydrateWithLogging(userId: userId));

    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_hydrateWithLogging(userId: userId));
    });
  }

  Future<void> _hydrateWithLogging({String? userId}) async {
    try {
      await hydrateFromBackend(userId: userId);
    } catch (error, stackTrace) {
      debugPrint('TEAM LEAD HYDRATION ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void stopLiveBackendSync() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
  }

  @override
  void dispose() {
    stopLiveBackendSync();
    super.dispose();
  }

  // Legacy fixture data retained only for reference; never invoked in production.
  void legacyFixtureDataReference() {
    // Ambulance Fleet Initial Roster
    _ambulances.addAll([
      AmbulanceUnit(
        id: 'AF-AMB-101',
        name: 'AF-AMB-101',
        registrationNumber: 'KA-01-EA-1010',
        model: 'Force Traveller ALS-350',
        category: 'Advanced Life Support',
        subtype: 'ALS Road Ambulance',
        baseStation: 'Central Medical Command Depot',
        status: 'AVAILABLE',
        capabilities: {
          'ICU',
          'VENTILATOR',
          'OXYGEN',
          'CARDIAC_MONITOR',
          'DEFIBRILLATOR',
          'STRETCHER',
          'SUCTION',
        },
        notes: 'Equipped with Hamilton-T1 transport ventilator and multi-parameter monitor.',
      ),
      AmbulanceUnit(
        id: 'AF-AMB-102',
        name: 'AF-AMB-102',
        registrationNumber: 'KA-01-EA-1020',
        model: 'Tata Winger Critical Care',
        category: 'Advanced Life Support',
        subtype: 'ALS Road Ambulance',
        baseStation: 'South Regional Trauma Center',
        status: 'AVAILABLE',
        capabilities: {
          'ICU',
          'VENTILATOR',
          'OXYGEN',
          'CARDIAC_MONITOR',
          'DEFIBRILLATOR',
          'STRETCHER',
        },
        notes:
            'Fully certified for adult and pediatric inter-facility transport.',
      ),
      AmbulanceUnit(
        id: 'AF-AMB-105',
        name: 'AF-AMB-105',
        registrationNumber: 'KA-01-EA-1055',
        model: 'Force Traveller BLS',
        category: 'Basic Life Support',
        subtype: 'BLS Patient Transfer',
        baseStation: 'North Dispatch Station',
        status: 'AVAILABLE',
        capabilities: {'OXYGEN', 'STRETCHER', 'WHEELCHAIR', 'SUCTION'},
        notes: 'Dedicated to non-critical hospital discharges and inter-clinic transfers.',
      ),
      AmbulanceUnit(
        id: 'AF-AMB-108',
        name: 'AF-AMB-108',
        registrationNumber: 'KA-01-EA-1088',
        model: 'Force Citiline Neonatal-Mobile',
        category: 'Pediatric / Neonatal',
        subtype: 'PICU / NICU Specialized',
        baseStation: 'Children Health Institute Depot',
        status: 'AVAILABLE',
        capabilities: {
          'ICU',
          'VENTILATOR',
          'OXYGEN',
          'PICU',
          'INCUBATOR',
          'CARDIAC_MONITOR',
          'DEFIBRILLATOR',
          'STRETCHER',
        },
        notes: 'Equipped with Dräger Isolette incubator and neonatal nitric oxide delivery.',
      ),
      AmbulanceUnit(
        id: 'AF-AMB-112',
        name: 'AF-AMB-112',
        registrationNumber: 'KA-01-EA-1122',
        model: 'Force Custom Mortuary Van',
        category: 'Mortuary Transfer',
        subtype: 'Dead Body Transportation',
        baseStation: 'Central Medical Command Depot',
        status: 'AVAILABLE',
        capabilities: {'FREEZER', 'STRETCHER'},
        notes: 'Thermoregulated cryo-chamber at -4C for dignified deceased transfers.',
      ),
      AmbulanceUnit(
        id: 'AF-AMB-119',
        name: 'AF-AMB-119',
        registrationNumber: 'KA-01-EA-1199',
        model: 'Mahindra Bolero Neo ALS',
        category: 'Advanced Life Support',
        subtype: 'Rapid Response Unit',
        baseStation: 'Airport Terminal 2 Bay',
        status: 'MAINTENANCE',
        capabilities: {
          'ICU',
          'VENTILATOR',
          'OXYGEN',
          'CARDIAC_MONITOR',
          'STRETCHER',
        },
        notes: 'Undergoing routine 25,000 km braking system overhaul.',
      ),
    ]);

    // Drivers Initial Roster
    _drivers.addAll([
      DriverRosterItem(
        id: 'DRV-01',
        name: 'Rajesh Kumar',
        phone: '+91 98450 11001',
        email: 'rajesh.kumar@ambulancefirst.com',
        licenseNumber: 'KA-01-2015-004589',
        licenseExpiry: '2028-11-20',
        experienceYears: 9,
        supportedCategories: [
          'Advanced Life Support',
          'Basic Life Support',
          'Mortuary Transfer',
        ],
        status: 'AVAILABLE',
        depot: 'Central Medical Command Depot',
        completedTrips: 184,
      ),
      DriverRosterItem(
        id: 'DRV-02',
        name: 'Vikramjit Singh',
        phone: '+91 98450 11002',
        email: 'vikram.singh@ambulancefirst.com',
        licenseNumber: 'KA-01-2017-009122',
        licenseExpiry: '2029-04-14',
        experienceYears: 7,
        supportedCategories: [
          'Advanced Life Support',
          'Pediatric / Neonatal',
          'Air Evacuation Corridor',
        ],
        status: 'AVAILABLE',
        depot: 'South Regional Trauma Center',
        completedTrips: 142,
      ),
      DriverRosterItem(
        id: 'DRV-03',
        name: 'Kiran Mohan Rao',
        phone: '+91 98450 11003',
        email: 'kiran.rao@ambulancefirst.com',
        licenseNumber: 'KA-05-2019-001233',
        licenseExpiry: '2027-08-30',
        experienceYears: 5,
        supportedCategories: ['Basic Life Support', 'Mortuary Transfer'],
        status: 'AVAILABLE',
        depot: 'North Dispatch Station',
        completedTrips: 98,
      ),
      DriverRosterItem(
        id: 'DRV-04',
        name: 'Arun Dev',
        phone: '+91 98450 11004',
        email: 'arun.dev@ambulancefirst.com',
        licenseNumber: 'KA-04-2014-007811',
        licenseExpiry: '2029-01-10',
        experienceYears: 10,
        supportedCategories: ['Advanced Life Support', 'Basic Life Support'],
        status: 'OFF_DUTY',
        depot: 'Central Medical Command Depot',
        completedTrips: 210,
      ),
    ]);

    // EMTs Initial Roster
    _emts.addAll([
      EmtRosterItem(
        id: 'EMT-01',
        name: 'Anita Sharma',
        phone: '+91 98450 22001',
        email: 'anita.sharma@ambulancefirst.com',
        qualification: 'B.Sc. Paramedical & Emergency Care',
        experienceYears: 6,
        certifications: {'BLS', 'ACLS', 'PALS'},
        hasPediatricCapability: true,
        status: 'AVAILABLE',
        depot: 'Central Medical Command Depot',
      ),
      EmtRosterItem(
        id: 'EMT-02',
        name: 'Suresh Babu',
        phone: '+91 98450 22002',
        email: 'suresh.babu@ambulancefirst.com',
        qualification: 'Diploma in Emergency Medical Technology',
        experienceYears: 4,
        certifications: {'BLS', 'ACLS'},
        hasPediatricCapability: false,
        status: 'AVAILABLE',
        depot: 'South Regional Trauma Center',
      ),
      EmtRosterItem(
        id: 'EMT-03',
        name: 'Deepa Varghese',
        phone: '+91 98450 22003',
        email: 'deepa.varghese@ambulancefirst.com',
        qualification: 'Critical Care Paramedic Certified',
        experienceYears: 8,
        certifications: {'BLS', 'ACLS', 'PALS'},
        hasPediatricCapability: true,
        status: 'AVAILABLE',
        depot: 'Children Health Institute Depot',
      ),
      EmtRosterItem(
        id: 'EMT-04',
        name: 'Praveen Gowda',
        phone: '+91 98450 22004',
        email: 'praveen.gowda@ambulancefirst.com',
        qualification: 'Advanced EMT Trainee',
        experienceYears: 2,
        certifications: {'BLS'},
        hasPediatricCapability: false,
        status: 'OFF_DUTY',
        depot: 'North Dispatch Station',
      ),
    ]);

    // Doctors Initial Roster
    _doctors.addAll([
      DoctorRosterItem(
        id: 'DOC-01',
        name: 'Dr. Arjun Mehta',
        phone: '+91 98450 33001',
        email: 'dr.mehta@ambulancefirst.com',
        specialization: 'Emergency Medicine & Critical Care',
        hospital: 'Manipal Emergency Center',
        experienceYears: 12,
        hasPediatricCapability: false,
        medicalLicense: 'KMC-84920-MD',
        licenseExpiry: '2030-05-15',
        status: 'AVAILABLE',
        depot: 'Central Medical Command Depot',
      ),
      DoctorRosterItem(
        id: 'DOC-02',
        name: 'Dr. Kavya Menon',
        phone: '+91 98450 33002',
        email: 'dr.menon@ambulancefirst.com',
        specialization: 'Pediatric Intensive Care & Neonatology',
        hospital: 'Rainbow Children Hospital',
        experienceYears: 9,
        hasPediatricCapability: true,
        medicalLicense: 'KMC-99124-PICU',
        licenseExpiry: '2031-09-22',
        status: 'AVAILABLE',
        depot: 'Children Health Institute Depot',
      ),
      DoctorRosterItem(
        id: 'DOC-03',
        name: 'Dr. Naveen Joseph',
        phone: '+91 98450 33003',
        email: 'dr.joseph@ambulancefirst.com',
        specialization: 'Cardiology & Interventional Resuscitation',
        hospital: 'Narayana Health City',
        experienceYears: 14,
        hasPediatricCapability: false,
        medicalLicense: 'KMC-73019-DM',
        licenseExpiry: '2029-12-10',
        status: 'ON_CALL',
        depot: 'South Regional Trauma Center',
      ),
      DoctorRosterItem(
        id: 'DOC-04',
        name: 'Dr. Sana Qureshi',
        phone: '+91 98450 33004',
        email: 'dr.qureshi@ambulancefirst.com',
        specialization: 'Trauma Surgery & Acute Care',
        hospital: 'St. John Medical College Hospital',
        experienceYears: 8,
        hasPediatricCapability: false,
        medicalLicense: 'KMC-88301-MS',
        licenseExpiry: '2030-02-18',
        status: 'OFF_DUTY',
        depot: 'Central Medical Command Depot',
      ),
    ]);

    // Initial Notifications
    _notifications.addAll([
      OperationalNotificationItem(
        id: 'NOTIF-01',
        title: 'New Emergency Case Verified',
        message: 'Customer Care handed over verified case BK-1092 requiring ALS allocation.',
        severity: 'CRITICAL',
        bookingId: 'BK-1092',
      ),
      OperationalNotificationItem(
        id: 'NOTIF-02',
        title: 'Customer Accepted Quotation',
        message: 'Booking BK-1088 quotation accepted. Awaiting final crew dispatch confirmation.',
        severity: 'INFO',
        bookingId: 'BK-1088',
      ),
      OperationalNotificationItem(
        id: 'NOTIF-03',
        title: 'Vehicle Service Due',
        message: 'Ambulance AF-AMB-119 is currently scheduled for scheduled maintenance inspection.',
        severity: 'WARNING',
      ),
    ]);

    // Initial Audit logs
    _auditLogs.addAll([
      AuditEventItem(
        id: 'AUD-01',
        actor: 'Team Lead Ops',
        role: 'Team Lead',
        bookingId: 'BK-1088',
        action: 'Quotation sent to customer for review',
        previousState: 'BUDGET_PENDING',
        newState: 'QUOTATION_SENT',
      ),
      AuditEventItem(
        id: 'AUD-02',
        actor: 'Customer Care Lead',
        role: 'Customer Care',
        bookingId: 'BK-1092',
        action: 'Case clinically verified and transferred to Team Lead',
        previousState: 'INTAKE',
        newState: 'SENT_TO_TEAM_LEAD',
      ),
    ]);
  }

  // Capability matching helper for Ambulances
  bool checkAmbulanceCompatibility(AmbulanceUnit ambulance, Booking booking) {
    if (booking.transportMode == 'DEAD_BODY_TRANSFER' &&
        !ambulance.hasCapability('FREEZER')) {
      return false;
    }
    if (booking.icuRequired && !ambulance.hasCapability('ICU')) return false;
    if (booking.ventilatorRequired && !ambulance.hasCapability('VENTILATOR')) {
      return false;
    }
    if (booking.oxygenRequired && !ambulance.hasCapability('OXYGEN')) {
      return false;
    }
    if (booking.cardiacMonitorRequired &&
        !ambulance.hasCapability('CARDIAC_MONITOR')) {
      return false;
    }
    if (booking.stretcherRequired && !ambulance.hasCapability('STRETCHER')) {
      return false;
    }
    if (booking.wheelchairRequired && !ambulance.hasCapability('WHEELCHAIR')) {
      return false;
    }
    if (booking.pediatricPatient &&
        !ambulance.hasCapability('PICU') &&
        !ambulance.hasCapability('PEDIATRIC')) {
      return false;
    }
    return true;
  }

  List<AmbulanceUnit> getCompatibleAmbulances(Booking booking) {
    return _ambulances
        .where((a) => a.isAvailable && checkAmbulanceCompatibility(a, booking))
        .toList();
  }

  List<DriverRosterItem> getAvailableDrivers() {
    return _drivers.where((d) => d.isAvailable).toList();
  }

  List<EmtRosterItem> getAvailableEmts(Booking booking) {
    return _emts.where((e) {
      if (!e.isAvailable) return false;
      if (booking.pediatricPatient && !e.hasPediatricCapability) return false;
      return true;
    }).toList();
  }

  List<DoctorRosterItem> getAvailableDoctors(Booking booking) {
    return _doctors
        .where(
          (d) =>
              d.isAvailable &&
              (!booking.pediatricPatient || d.hasPediatricCapability),
        )
        .toList();
  }

  /// Atomic allocation workflow
  bool allocateResources({
    required Booking booking,
    required AmbulanceUnit ambulance,
    required DriverRosterItem driver,
    EmtRosterItem? emt,
    DoctorRosterItem? doctor,
    List<String> equipment = const [],
  }) {
    if (!ambulance.isAvailable || !driver.isAvailable) {
      return false;
    }
    if (!checkAmbulanceCompatibility(ambulance, booking)) {
      return false;
    }
    if (booking.pediatricPatient &&
        emt != null &&
        !emt.hasPediatricCapability) {
      return false;
    }
    if (booking.pediatricPatient &&
        doctor != null &&
        !doctor.hasPediatricCapability) {
      return false;
    }

    // Release previously assigned resources for this booking if reassigning
    releaseBookingResources(booking.id);

    // Update resource statuses
    ambulance.status = 'ASSIGNED';
    ambulance.assignedBookingId = booking.id;

    driver.status = 'ASSIGNED';
    driver.assignedBookingId = booking.id;

    if (emt != null) {
      emt.status = 'ASSIGNED';
      emt.assignedBookingId = booking.id;
    }

    if (doctor != null) {
      doctor.status = 'ASSIGNED';
      doctor.assignedBookingId = booking.id;
    }

    // Update booking object
    final previousState = booking.status;
    booking.vehicleNumber = ambulance.name;
    booking.driverName = driver.name;
    booking.driverPhone = driver.phone;
    booking.emtName = emt?.name ?? '';
    booking.doctorName = doctor?.name ?? '';
    booking.assignedEquipment = List<String>.from(equipment);
    booking.status = 'ASSIGNED';
    booking.tripMilestone = 'Ambulance and crew assigned';

    // Synchronize with core service for cross-role compatibility
    TeamLeadOperationsService.instance.allocate(
      booking,
      ambulanceId: ambulance.id,
      driverId: driver.id,
      emtId: emt?.id,
      doctorId: doctor?.id,
      equipment: equipment,
    );

    // Record audit event
    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: booking.id,
      action:
          'Assigned Ambulance (${ambulance.name}), Driver (${driver.name})${emt != null ? ', EMT (${emt.name})' : ''}${doctor != null ? ', Doctor (${doctor.name})' : ''}',
      previousState: previousState,
      newState: 'ASSIGNED',
    );

    // Push notification
    _addNotification(
      title: 'Allocation Complete: ${booking.id}',
      message:
          'Ambulance ${ambulance.name} and crew assigned to patient ${booking.patientName.isNotEmpty ? booking.patientName : 'Emergency'}.',
      severity: 'INFO',
      bookingId: booking.id,
    );

    notifyListeners();
    return true;
  }

  void releaseBookingResources(String bookingId) {
    for (final a in _ambulances) {
      if (a.assignedBookingId == bookingId) {
        a.assignedBookingId = null;
        a.status = 'AVAILABLE';
      }
    }
    for (final d in _drivers) {
      if (d.assignedBookingId == bookingId) {
        d.assignedBookingId = null;
        d.status = 'AVAILABLE';
      }
    }
    for (final e in _emts) {
      if (e.assignedBookingId == bookingId) {
        e.assignedBookingId = null;
        e.status = 'AVAILABLE';
      }
    }
    for (final doc in _doctors) {
      if (doc.assignedBookingId == bookingId) {
        doc.assignedBookingId = null;
        doc.status = 'AVAILABLE';
      }
    }
  }

  /// Milestone transitions
  bool advanceMilestone(
    Booking booking,
    String nextMilestone, {
    String? overrideReason,
  }) {
    const validTransitions = <String, Set<String>>{
      'ASSIGNED': {'PICKUP_STARTED'},
      'DRIVER_ASSIGNED': {'PICKUP_STARTED'},
      'PICKUP_STARTED': {'PATIENT_PICKED_UP'},
      'PATIENT_PICKED_UP': {'IN_TRANSIT'},
      'IN_TRANSIT': {'ARRIVED'},
      'ARRIVED': {'SERVICE_COMPLETED'},
    };

    final isStandardValid =
        validTransitions[booking.status]?.contains(nextMilestone) ?? false;
    final isOverride =
        overrideReason != null && overrideReason.trim().isNotEmpty;

    if (!isStandardValid && !isOverride) {
      return false;
    }

    final previousState = booking.status;
    booking.status = nextMilestone;
    booking.tripMilestone = _milestoneLabel(nextMilestone);

    // Update fleet & personnel status to IN_TRANSIT or ON_TRIP when moving
    if (nextMilestone == 'PICKUP_STARTED' || nextMilestone == 'IN_TRANSIT') {
      for (final a in _ambulances) {
        if (a.assignedBookingId == booking.id) a.status = 'IN_TRANSIT';
      }
      for (final d in _drivers) {
        if (d.assignedBookingId == booking.id) d.status = 'ON_TRIP';
      }
    }

    // Complete trip
    if (nextMilestone == 'SERVICE_COMPLETED') {
      releaseBookingResources(booking.id);
      booking.invoice = Invoice(
        id: 'INV-${booking.id.replaceAll(RegExp(r'[^0-9]'), '')}',
        bookingId: booking.id,
        quotationId: booking.quotation?.id ?? 'N/A',
        serviceDetails:
            '${booking.transportModeLabel} • ${booking.pickup} → ${booking.destination}',
        total: booking.amount,
        paymentStatus: 'Paid',
        invoiceDate: DateTime.now().toIso8601String(),
      );
    }

    TeamLeadOperationsService.instance.transition(booking, nextMilestone);

    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: booking.id,
      action: isOverride
          ? 'Manual Team Lead Override to $nextMilestone: $overrideReason'
          : 'Mission milestone advanced to $nextMilestone',
      previousState: previousState,
      newState: nextMilestone,
      reason: overrideReason,
    );

    notifyListeners();
    return true;
  }

  String _milestoneLabel(String status) => switch (status) {
    'PICKUP_STARTED' => 'En route to pickup location',
    'PATIENT_PICKED_UP' => 'Patient securely onboard',
    'IN_TRANSIT' => 'In transit to receiving facility',
    'ARRIVED' => 'Arrived at receiving facility',
    'SERVICE_COMPLETED' => 'Mission complete & patient handed over',
    _ => status,
  };

  LiveTelemetry getTelemetryForBooking(Booking booking) {
    final hasDriverLocation =
        booking.driverLatitude != null && booking.driverLongitude != null;
    final isTripActive = booking.isActive;

    if (!isTripActive && booking.status != 'ASSIGNED') {
      return LiveTelemetry(
        callsign: booking.vehicleNumber.isNotEmpty
            ? booking.vehicleNumber
            : 'AF-AMB-UNASSIGNED',
        speedKmh: 0,
        etaMinutes: 0,
        lastUpdatedSecondsAgo: 0,
        state: TelemetryState.unavailable,
      );
    }

    if (hasDriverLocation) {
      final ageSeconds = booking.driverLocationUpdatedAt == null
          ? 0
          : DateTime.now()
                .difference(booking.driverLocationUpdatedAt!)
                .inSeconds
                .clamp(0, 86400);
      return LiveTelemetry(
        callsign: booking.vehicleNumber.isNotEmpty
            ? booking.vehicleNumber
            : 'AF-AMB-UNASSIGNED',
        speedKmh: booking.driverSpeedKmh.toInt().clamp(0, 160),
        etaMinutes: booking.etaMinutes.clamp(0, 180),
        lastUpdatedSecondsAgo: ageSeconds,
        state: ageSeconds <= 30 ? TelemetryState.live : TelemetryState.stale,
        latitude: booking.driverLatitude,
        longitude: booking.driverLongitude,
        heading: booking.driverHeading,
      );
    }

    // Never invent live telemetry. Until the driver's first GPS ping arrives,
    // Team Lead sees the mission as waiting for a real location update.
    if (booking.isActive ||
        booking.status == 'ASSIGNED' ||
        booking.status == 'DRIVER_ASSIGNED') {
      return LiveTelemetry(
        callsign: booking.vehicleNumber.isNotEmpty
            ? booking.vehicleNumber
            : 'AF-AMB-UNASSIGNED',
        speedKmh: 0,
        etaMinutes: booking.etaMinutes.clamp(0, 180),
        lastUpdatedSecondsAgo: 0,
        state: TelemetryState.unavailable,
      );
    }

    return LiveTelemetry(
      callsign: booking.vehicleNumber.isNotEmpty
          ? booking.vehicleNumber
          : 'AF-AMB-101',
      speedKmh: 0,
      etaMinutes: 0,
      lastUpdatedSecondsAgo: 320,
      state: TelemetryState.stale,
    );
  }

  // Quotation Management
  void saveQuotation({
    required Booking booking,
    required QuotationComputation computation,
    String paymentTerms = 'Payment before dispatch',
    String validUntil = 'Valid for 24 hours',
    String notes = 'Prepared by Ambulance First Team Lead Operations.',
  }) {
    final quotation = Quotation(
      id: 'QT-${booking.id.replaceAll(RegExp(r'[^0-9]'), '')}',
      status: 'DRAFT',
      baseAmbulanceCharge: computation.baseCharge,
      distanceCharge: computation.distanceCharge,
      doctorCharge: computation.doctorCharge,
      emtCharge: computation.emtCharge,
      attendantCharge: computation.attendantCharge,
      oxygenCharge: computation.oxygenCharge,
      icuCharge: computation.icuCharge,
      ventilatorCharge: computation.ventilatorCharge,
      pediatricIcuCharge: computation.pediatricCharge,
      equipmentCharge: computation.equipmentCharge,
      additionalCharges:
          computation.logisticsCharge + computation.specialTransportCharge,
      discount: computation.discount,
      taxPercent: computation.taxPercent,
      paymentTerms: paymentTerms,
      validUntil: validUntil,
      notes: notes,
    );

    booking.quotation = quotation;
    booking.amount = quotation.finalAmount;
    booking.status = 'BUDGET_PENDING';

    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: booking.id,
      action:
          'Quotation draft calculated for INR ${quotation.finalAmount.toStringAsFixed(0)}',
      previousState: null,
      newState: 'BUDGET_PENDING',
    );

    notifyListeners();
  }

  void sendQuotationToCustomer(Booking booking) {
    if (booking.quotation == null) return;
    booking.quotation!.status = 'SENT';
    final previousState = booking.status;
    booking.status = 'QUOTATION_SENT';
    booking.tripMilestone = 'Quotation sent to customer for review';

    TeamLeadOperationsService.instance.sendQuotation(booking);

    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: booking.id,
      action:
          'Quotation ${booking.quotation!.id} sent to customer (${booking.customerName})',
      previousState: previousState,
      newState: 'QUOTATION_SENT',
    );

    _addNotification(
      title: 'Quotation Dispatched: ${booking.id}',
      message:
          'Quotation sent to ${booking.customerName}. Awaiting customer response.',
      severity: 'INFO',
      bookingId: booking.id,
    );

    notifyListeners();
  }

  // Fleet management actions
  void registerAmbulance(AmbulanceUnit unit) {
    _ambulances.insert(0, unit);
    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: 'SYSTEM',
      action:
          'Registered new vehicle ${unit.name} (${unit.registrationNumber})',
      previousState: null,
      newState: unit.status,
    );
    notifyListeners();
  }

  void setAmbulanceStatus(String ambulanceId, String newStatus) {
    final idx = _ambulances.indexWhere((a) => a.id == ambulanceId);
    if (idx != -1) {
      final old = _ambulances[idx].status;
      _ambulances[idx].status = newStatus;
      _addAudit(
        actor: 'Team Lead',
        role: 'Team Lead',
        bookingId: 'FLEET',
        action:
            'Ambulance ${_ambulances[idx].name} status changed to $newStatus',
        previousState: old,
        newState: newStatus,
      );
      notifyListeners();
    }
  }

  // Driver actions
  void addDriver(DriverRosterItem item) {
    _drivers.insert(0, item);
    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: 'ROSTER',
      action: 'Added driver ${item.name} (${item.licenseNumber})',
      previousState: null,
      newState: item.status,
    );
    notifyListeners();
  }

  void setDriverStatus(String driverId, String status) {
    final idx = _drivers.indexWhere((d) => d.id == driverId);
    if (idx != -1) {
      _drivers[idx].status = status;
      notifyListeners();
    }
  }

  // EMT actions
  void addEmt(EmtRosterItem item) {
    _emts.insert(0, item);
    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: 'ROSTER',
      action: 'Added EMT ${item.name} (${item.qualification})',
      previousState: null,
      newState: item.status,
    );
    notifyListeners();
  }

  void setEmtStatus(String emtId, String status) {
    final idx = _emts.indexWhere((e) => e.id == emtId);
    if (idx != -1) {
      _emts[idx].status = status;
      notifyListeners();
    }
  }

  // Doctor actions
  void addDoctor(DoctorRosterItem item) {
    _doctors.insert(0, item);
    _addAudit(
      actor: 'Team Lead',
      role: 'Team Lead',
      bookingId: 'ROSTER',
      action: 'Added Doctor ${item.name} (${item.specialization})',
      previousState: null,
      newState: item.status,
    );
    notifyListeners();
  }

  void setDoctorStatus(String doctorId, String status) {
    final idx = _doctors.indexWhere((d) => d.id == doctorId);
    if (idx != -1) {
      _doctors[idx].status = status;
      notifyListeners();
    }
  }

  // Notification actions
  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].read = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void _addAudit({
    required String actor,
    required String role,
    required String bookingId,
    required String action,
    String? previousState,
    String? newState,
    String? reason,
  }) {
    _auditLogs.insert(
      0,
      AuditEventItem(
        id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
        actor: actor,
        role: role,
        bookingId: bookingId,
        action: action,
        previousState: previousState,
        newState: newState,
        reason: reason,
      ),
    );
  }

  void _addNotification({
    required String title,
    required String message,
    required String severity,
    String? bookingId,
  }) {
    _notifications.insert(
      0,
      OperationalNotificationItem(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        severity: severity,
        bookingId: bookingId,
      ),
    );
  }
}
