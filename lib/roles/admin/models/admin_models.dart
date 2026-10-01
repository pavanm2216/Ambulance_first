// ============================================================
// ADMIN DOMAIN MODELS
// Emergency Medical Fleet Operations Portal
// ============================================================

enum BookingStatus {
  newBooking,
  customerCareContactPending,
  customerCareContacted,
  verificationPending,
  verified,
  sentToTeamLead,
  allocationPending,
  quotationSent,
  customerAccepted,
  customerRejected,
  assigned,
  driverAssigned,
  pickupStarted,
  patientPickedUp,
  inTransit,
  arrived,
  serviceCompleted,
  invoiceGenerated,
  completed,
  cancelled,
  driverRejected;

  String get label {
    switch (this) {
      case BookingStatus.newBooking:
        return 'NEW';

      case BookingStatus.customerCareContactPending:
        return 'CUSTOMER_CARE_CONTACT_PENDING';

      case BookingStatus.customerCareContacted:
        return 'CUSTOMER_CARE_CONTACTED';

      case BookingStatus.verificationPending:
        return 'VERIFICATION_PENDING';

      case BookingStatus.verified:
        return 'VERIFIED';

      case BookingStatus.sentToTeamLead:
        return 'SENT_TO_TEAM_LEAD';

      case BookingStatus.allocationPending:
        return 'ALLOCATION_PENDING';

      case BookingStatus.quotationSent:
        return 'QUOTATION_SENT';

      case BookingStatus.customerAccepted:
        return 'CUSTOMER_ACCEPTED';

      case BookingStatus.customerRejected:
        return 'CUSTOMER_REJECTED';

      case BookingStatus.assigned:
        return 'ASSIGNED';

      case BookingStatus.driverAssigned:
        return 'DRIVER_ASSIGNED';

      case BookingStatus.pickupStarted:
        return 'PICKUP_STARTED';

      case BookingStatus.patientPickedUp:
        return 'PATIENT_PICKED_UP';

      case BookingStatus.inTransit:
        return 'IN_TRANSIT';

      case BookingStatus.arrived:
        return 'ARRIVED';

      case BookingStatus.serviceCompleted:
        return 'SERVICE_COMPLETED';

      case BookingStatus.invoiceGenerated:
        return 'INVOICE_GENERATED';

      case BookingStatus.completed:
        return 'COMPLETED';

      case BookingStatus.cancelled:
        return 'CANCELLED';

      case BookingStatus.driverRejected:
        return 'DRIVER_REJECTED';
    }
  }

  static BookingStatus fromString(String value) {
    final clean = value.toUpperCase().trim().replaceAll(' ', '_');

    for (final status in BookingStatus.values) {
      if (status.label == clean) {
        return status;
      }
    }

    return BookingStatus.newBooking;
  }
}

// ============================================================
// FLEET STATUS
// ============================================================

enum FleetStatus {
  available,
  assigned,
  activeMission,
  inTransit,
  maintenance,
  outOfService;

  String get label {
    switch (this) {
      case FleetStatus.available:
        return 'AVAILABLE';

      case FleetStatus.assigned:
        return 'ASSIGNED';

      case FleetStatus.activeMission:
        return 'ACTIVE MISSION';

      case FleetStatus.inTransit:
        return 'IN_TRANSIT';

      case FleetStatus.maintenance:
        return 'MAINTENANCE';

      case FleetStatus.outOfService:
        return 'OUT OF SERVICE';
    }
  }

  static FleetStatus fromString(String value) {
    final clean = value.toUpperCase().trim();

    if (clean.contains('MAINT')) {
      return FleetStatus.maintenance;
    }

    if (clean.contains('ACTIVE')) {
      return FleetStatus.activeMission;
    }

    if (clean.contains('TRANSIT')) {
      return FleetStatus.inTransit;
    }

    if (clean.contains('ASSIGN')) {
      return FleetStatus.assigned;
    }

    if (clean.contains('OUT')) {
      return FleetStatus.outOfService;
    }

    return FleetStatus.available;
  }
}

// ============================================================
// STAFF STATUS
// ============================================================

enum StaffStatus {
  available,
  assigned,
  busy,
  suspended,
  inactive,
  offDuty;

  String get label {
    switch (this) {
      case StaffStatus.available:
        return 'AVAILABLE';

      case StaffStatus.assigned:
        return 'ASSIGNED';

      case StaffStatus.busy:
        return 'BUSY';

      case StaffStatus.suspended:
        return 'SUSPENDED';

      case StaffStatus.inactive:
        return 'INACTIVE';

      case StaffStatus.offDuty:
        return 'OFF_DUTY';
    }
  }

  static StaffStatus fromString(String value) {
    final clean = value.toUpperCase().trim();

    for (final status in StaffStatus.values) {
      if (status.label == clean) {
        return status;
      }
    }

    return StaffStatus.available;
  }
}

// ============================================================
// TIMELINE
// ============================================================

class TimelineStep {
  TimelineStep({
    required this.stage,
    required this.time,
    this.actor = '',
    this.desc = '',
    this.completed = false,
  });

  final String stage;
  final String time;
  final String actor;
  final String desc;

  bool completed;
}

// ============================================================
// ADMIN BOOKING
// ============================================================

class AdminBooking {
  AdminBooking({
    required this.id,
    required this.refCode,
    required this.createdAt,
    required this.status,
    required this.priority,
    required this.urgencyLevel,
    required this.serviceCategory,
    required this.serviceSubtype,
    required this.triageNotes,
    required this.customerName,
    required this.customerContact,
    required this.patientName,
    required this.patientInitials,
    required this.patientAge,
    required this.patientGender,
    required this.patientCondition,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.distanceKm,
    this.distanceRemainingKm = 0.0,
    this.estimatedTimeMinutes = 20,
    this.etaMinutes = 10,
    this.currentSpeedKmH = 0,
    this.driverLatitude,
    this.driverLongitude,
    this.driverLocationUpdatedAt,
    this.heading = 'N 000°',
    this.ambulanceId,
    this.ambulanceCad,
    this.ambulanceModel,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.emtId,
    this.emtName,
    this.doctorId,
    this.doctorName,
    this.doctorSpecialization,
    required this.quotationId,
    required this.quotationTotal,
    required this.quotationStatus,
    required this.paymentStatus,
    this.baseFare = 0.0,
    this.distanceCharge = 0.0,
    this.doctorFee = 0.0,
    this.emtFee = 0.0,
    this.equipmentFee = 0.0,
    this.nightSurcharge = 0.0,
    this.tax = 0.0,
    this.requiresOxygen = false,
    this.requiresIcu = false,
    this.requiresVentilator = false,
    this.requiresPicu = false,
    this.requiresCardiacMonitor = false,
    this.requiresStretcher = false,
    this.requiresWheelchair = false,
    this.specialRequirements = const [],
    this.timeline = const [],
    this.cancellationReason,
  });

  final String id;
  final String refCode;
  final DateTime createdAt;

  BookingStatus status;

  final String priority;
  final String urgencyLevel;
  final String serviceCategory;
  final String serviceSubtype;
  final String triageNotes;

  final String customerName;
  final String customerContact;

  final String patientName;
  final String patientInitials;
  final int patientAge;
  final String patientGender;
  final String patientCondition;

  final String pickupLocation;
  final String destinationLocation;

  final double distanceKm;

  double distanceRemainingKm;
  int estimatedTimeMinutes;
  int etaMinutes;
  int currentSpeedKmH;
  double? driverLatitude;
  double? driverLongitude;
  DateTime? driverLocationUpdatedAt;

  String heading;

  String? ambulanceId;
  String? ambulanceCad;
  String? ambulanceModel;

  String? driverId;
  String? driverName;
  String? driverPhone;

  String? emtId;
  String? emtName;

  String? doctorId;
  String? doctorName;
  String? doctorSpecialization;

  final String quotationId;

  double quotationTotal;
  String quotationStatus;
  String paymentStatus;

  double baseFare;
  double distanceCharge;
  double doctorFee;
  double emtFee;
  double equipmentFee;
  double nightSurcharge;
  double tax;
  final bool requiresOxygen;
  final bool requiresIcu;
  final bool requiresVentilator;
  final bool requiresPicu;
  final bool requiresCardiacMonitor;
  final bool requiresStretcher;
  final bool requiresWheelchair;

  final List<String> specialRequirements;

  List<TimelineStep> timeline;

  String? cancellationReason;
}

// ============================================================
// ADMIN AMBULANCE
// ============================================================

class AdminAmbulance {
  AdminAmbulance({
    required this.id,
    required this.callSign,
    required this.vehicleCadNo,
    required this.platform,
    required this.classification,
    required this.category,
    required this.status,
    required this.stationBase,
    required this.currentLocation,
    this.activeIncidentId,
    this.fuelPercent = 0,
    this.oxygenPressureBar = 0,
    required this.serviceDate,
    required this.inspectionStatus,
    this.workOrder,
    this.assignedDriver,
    this.assignedDriverId,
    this.assignedEmt,
    this.assignedDoctor,
    this.hasOxygen = false,
    this.hasIcu = false,
    this.hasVentilator = false,
    this.hasPicu = false,
    this.hasIncubator = false,
    this.hasFreezer = false,
    this.hasCardiacMonitor = false,
    this.hasStretcher = false,
    this.hasWheelchair = false,
  });

  final String id;

  String callSign;
  String vehicleCadNo;
  String platform;
  String classification;
  String category;

  FleetStatus status;

  String stationBase;
  String currentLocation;

  String? activeIncidentId;

  int fuelPercent;
  int oxygenPressureBar;

  String serviceDate;
  String inspectionStatus;

  String? workOrder;

  String? assignedDriver;
  String? assignedDriverId;

  String? assignedEmt;
  String? assignedDoctor;

  bool hasOxygen;
  bool hasIcu;
  bool hasVentilator;
  bool hasPicu;
  bool hasIncubator;
  bool hasFreezer;
  bool hasCardiacMonitor;
  bool hasStretcher;
  bool hasWheelchair;
}

// ============================================================
// ADMIN STAFF
//
// IMPORTANT:
// No fake business defaults.
// Values are zero/empty unless Supabase actually provides them.
// ============================================================

class AdminStaff {
  AdminStaff({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,

    this.licenseNumber,
    this.licenseExpiry,
    this.specialization,
    this.qualification,
    this.hospital,

    this.experienceYears = 0,
    this.tripCount = 0,
    this.rating = 0.0,

    this.assignedVehicle,
    this.assignedMission,

    this.department,
    this.shift,
    this.workload,

    this.suspensionReason,

    this.hasPediatricCapability = false,
  });

  final String id;

  String name;
  String email;
  String phone;

  /// DRIVER
  /// EMT
  /// DOCTOR
  /// CUSTOMER_CARE
  /// TEAM_LEAD
  final String role;

  StaffStatus status;

  String? licenseNumber;
  String? licenseExpiry;

  String? specialization;
  String? qualification;
  String? hospital;

  int experienceYears;
  int tripCount;
  double rating;

  String? assignedVehicle;
  String? assignedMission;

  String? department;
  String? shift;
  String? workload;

  String? suspensionReason;

  bool hasPediatricCapability;
}

// ============================================================
// PRICING
// ============================================================

class AdminPricingRateCard {
  AdminPricingRateCard({
    required this.versionId,
    required this.currency,
    required this.effectiveDate,
    required this.createdBy,
    required this.approvedBy,
    required this.isActive,
    this.roadBasicOxygenBase = 350.0,
    this.roadBasicOxygenPerKm = 4.50,
    this.roadIcuBase = 650.0,
    this.roadIcuPerKm = 7.20,
    this.roadPicuBase = 850.0,
    this.roadPicuPerKm = 8.50,
    this.railwayBase = 1200.0,
    this.airBaseRate = 4500.0,
    this.airPerKm = 3.50,
    this.deadBodyBase = 450.0,
    this.deadBodyPerKm = 3.80,
    this.doctorFee = 450.0,
    this.emtFee = 220.0,
    this.ventilatorFee = 180.0,
    this.incubatorFee = 250.0,
    this.oxygenFlatFee = 80.0,
    this.nightSurchargePercent = 20.0,
    this.taxPercent = 5.0,
  });

  final String versionId;
  final String currency;
  final String effectiveDate;
  final String createdBy;

  String approvedBy;
  bool isActive;

  double roadBasicOxygenBase;
  double roadBasicOxygenPerKm;

  double roadIcuBase;
  double roadIcuPerKm;

  double roadPicuBase;
  double roadPicuPerKm;

  double railwayBase;

  double airBaseRate;
  double airPerKm;

  double deadBodyBase;
  double deadBodyPerKm;

  double doctorFee;
  double emtFee;

  double ventilatorFee;
  double incubatorFee;
  double oxygenFlatFee;

  double nightSurchargePercent;
  double taxPercent;
}

// ============================================================
// AUDIT
// ============================================================

class AdminAuditEntry {
  AdminAuditEntry({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.role,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.severity,
    required this.details,
    this.previousValue = '',
    this.newValue = '',
  });

  final String id;
  final DateTime timestamp;

  final String actor;
  final String role;

  final String action;

  final String entity;
  final String entityId;

  final String severity;
  final String details;

  final String previousValue;
  final String newValue;
}
