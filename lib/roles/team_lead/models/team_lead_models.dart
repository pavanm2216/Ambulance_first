enum TelemetryState { live, stale, unavailable }

class LiveTelemetry {
  const LiveTelemetry({
    required this.callsign,
    required this.speedKmh,
    required this.etaMinutes,
    required this.lastUpdatedSecondsAgo,
    required this.state,
    this.latitude,
    this.longitude,
    this.heading,
  });

  final String callsign;
  final int speedKmh;
  final int etaMinutes;
  final int lastUpdatedSecondsAgo;
  final TelemetryState state;
  final double? latitude;
  final double? longitude;
  final double? heading;

  bool get isLive => state == TelemetryState.live;
  bool get isStale => state == TelemetryState.stale;
  bool get isUnavailable => state == TelemetryState.unavailable;
}

class AmbulanceUnit {
  AmbulanceUnit({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.model,
    required this.category,
    this.subtype = 'Standard',
    required this.baseStation,
    required this.status,
    required this.capabilities,
    this.assignedBookingId,
    this.lastInspectionDate = '2026-09-01',
    this.serviceDate = '2026-08-15',
    this.notes = '',
  });

  final String id;
  String name;
  String registrationNumber;
  String model;
  String category;
  String subtype;
  String baseStation;
  String status; // AVAILABLE, ASSIGNED, IN_TRANSIT, MAINTENANCE, OFFLINE
  Set<String> capabilities;
  String? assignedBookingId;
  String lastInspectionDate;
  String serviceDate;
  String notes;

  bool get isAvailable => status == 'AVAILABLE' || status == 'READY';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isInTransit => status == 'IN_TRANSIT';
  bool get isMaintenance => status == 'MAINTENANCE';
  bool get isOffline => status == 'OFFLINE';

  bool hasCapability(String cap) => capabilities.contains(cap.toUpperCase());
}

class DriverRosterItem {
  DriverRosterItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.experienceYears,
    required this.supportedCategories,
    required this.status, // AVAILABLE, ASSIGNED, ON_TRIP, OFF_DUTY
    required this.depot,
    this.assignedBookingId,
    this.assignedAmbulanceNumber,
    this.completedTrips = 0,
  });

  final String id;
  String name;
  String phone;
  String email;
  String licenseNumber;
  String licenseExpiry;
  int experienceYears;
  List<String> supportedCategories;
  String status;
  String depot;
  String? assignedBookingId;
  String? assignedAmbulanceNumber;
  int completedTrips;

  bool get isAvailable => status == 'AVAILABLE' || status == 'ON_DUTY';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isOnTrip => status == 'ON_TRIP';
  bool get isOffDuty => status == 'OFF_DUTY';
}

class EmtRosterItem {
  EmtRosterItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.qualification,
    required this.experienceYears,
    required this.certifications,
    required this.hasPediatricCapability,
    required this.status, // AVAILABLE, ASSIGNED, ON_TRIP, OFF_DUTY
    required this.depot,
    this.assignedBookingId,
  });

  final String id;
  String name;
  String phone;
  String email;
  String qualification;
  int experienceYears;
  Set<String> certifications; // BLS, ACLS, PALS
  bool hasPediatricCapability;
  String status;
  String depot;
  String? assignedBookingId;

  bool get isAvailable => status == 'AVAILABLE';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isOnTrip => status == 'ON_TRIP';
  bool get isOffDuty => status == 'OFF_DUTY';
}

class DoctorRosterItem {
  DoctorRosterItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.specialization,
    required this.hospital,
    required this.experienceYears,
    required this.hasPediatricCapability,
    required this.medicalLicense,
    required this.licenseExpiry,
    required this.status, // AVAILABLE, ASSIGNED, ON_TRIP, ON_CALL, OFF_DUTY
    required this.depot,
    this.assignedBookingId,
  });

  final String id;
  String name;
  String phone;
  String email;
  String specialization;
  String hospital;
  int experienceYears;
  bool hasPediatricCapability;
  String medicalLicense;
  String licenseExpiry;
  String status;
  String depot;
  String? assignedBookingId;

  bool get isAvailable => status == 'AVAILABLE' || status == 'ON_CALL';
  bool get isAssigned => status == 'ASSIGNED';
  bool get isOnTrip => status == 'ON_TRIP';
  bool get isOffDuty => status == 'OFF_DUTY';
}

class QuotationComputation {
  const QuotationComputation({
    required this.baseCharge,
    required this.distanceCharge,
    required this.doctorCharge,
    required this.emtCharge,
    required this.attendantCharge,
    required this.oxygenCharge,
    required this.icuCharge,
    required this.ventilatorCharge,
    required this.pediatricCharge,
    required this.equipmentCharge,
    required this.logisticsCharge,
    required this.specialTransportCharge,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.finalAmount,
  });

  final double baseCharge;
  final double distanceCharge;
  final double doctorCharge;
  final double emtCharge;
  final double attendantCharge;
  final double oxygenCharge;
  final double icuCharge;
  final double ventilatorCharge;
  final double pediatricCharge;
  final double equipmentCharge;
  final double logisticsCharge;
  final double specialTransportCharge;
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final double taxPercent;
  final double taxAmount;
  final double finalAmount;

  static QuotationComputation calculate({
    required double baseCharge,
    required double distanceCharge,
    double doctorCharge = 0,
    double emtCharge = 0,
    double attendantCharge = 0,
    double oxygenCharge = 0,
    double icuCharge = 0,
    double ventilatorCharge = 0,
    double pediatricCharge = 0,
    double equipmentCharge = 0,
    double logisticsCharge = 0,
    double specialTransportCharge = 0,
    double discount = 0,
    double taxPercent = 5.0,
  }) {
    final sub = (baseCharge < 0 ? 0.0 : baseCharge) +
        (distanceCharge < 0 ? 0.0 : distanceCharge) +
        (doctorCharge < 0 ? 0.0 : doctorCharge) +
        (emtCharge < 0 ? 0.0 : emtCharge) +
        (attendantCharge < 0 ? 0.0 : attendantCharge) +
        (oxygenCharge < 0 ? 0.0 : oxygenCharge) +
        (icuCharge < 0 ? 0.0 : icuCharge) +
        (ventilatorCharge < 0 ? 0.0 : ventilatorCharge) +
        (pediatricCharge < 0 ? 0.0 : pediatricCharge) +
        (equipmentCharge < 0 ? 0.0 : equipmentCharge) +
        (logisticsCharge < 0 ? 0.0 : logisticsCharge) +
        (specialTransportCharge < 0 ? 0.0 : specialTransportCharge);

    final safeDiscount = discount.clamp(0.0, sub);
    final taxable = sub - safeDiscount;
    final safeTaxPercent = taxPercent.clamp(0.0, 100.0);
    final tax = taxable * (safeTaxPercent / 100.0);
    final total = taxable + tax;

    return QuotationComputation(
      baseCharge: baseCharge,
      distanceCharge: distanceCharge,
      doctorCharge: doctorCharge,
      emtCharge: emtCharge,
      attendantCharge: attendantCharge,
      oxygenCharge: oxygenCharge,
      icuCharge: icuCharge,
      ventilatorCharge: ventilatorCharge,
      pediatricCharge: pediatricCharge,
      equipmentCharge: equipmentCharge,
      logisticsCharge: logisticsCharge,
      specialTransportCharge: specialTransportCharge,
      subtotal: sub,
      discount: safeDiscount,
      taxableAmount: taxable,
      taxPercent: safeTaxPercent,
      taxAmount: tax,
      finalAmount: total,
    );
  }
}

class AuditEventItem {
  AuditEventItem({
    required this.id,
    required this.actor,
    required this.role,
    required this.bookingId,
    required this.action,
    this.previousState,
    this.newState,
    this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String actor;
  final String role;
  final String bookingId;
  final String action;
  final String? previousState;
  final String? newState;
  final String? reason;
  final DateTime timestamp;
}

class OperationalNotificationItem {
  OperationalNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity, // CRITICAL, WARNING, INFO
    this.bookingId,
    this.read = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String title;
  final String message;
  final String severity;
  final String? bookingId;
  bool read;
  final DateTime timestamp;
}
