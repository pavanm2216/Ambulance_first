/// Customer-facing domain model. The Flutter app is intentionally local/in-memory
/// for now, but this shape mirrors the richer Customer workflow from the React app.
class Booking {
  Booking({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.date,
    required this.time,
    required this.ambulanceType,
    this.transportMode = 'ROAD_AMBULANCE',
    this.serviceCategory = 'ROAD',
    this.serviceSubtype,
    this.pickupCity = '',
    this.destinationCity = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.estimatedDurationMins = 0,
    required this.status,
    this._patientOnboardConfirmed = false,
    required this.amount,
    this.basicFare = 0,
    this.assignedAmbulanceId,
    this.assignedDriverId,
    this.assignedMedicalCrewId,
    this.assignedDoctorId,
    this.customerName = '',
    this.mobileNumber = '',
    this.email = '',
    this.alternatePhone = '',
    this.relationshipToPatient = 'Self',
    this.patientName = '',
    this.patientAge = 0,
    this.patientGender = 'Other',
    this.patientWeightKg,
    this.currentCondition = 'Stable',
    this.medicalSummary = '',
    this.isEmergency = false,
    this.isAdmittedInHospital = 'Not Sure',
    this.isConscious = true,
    this.currentHospital = '',
    this.destinationHospital = '',
    this.oxygenRequired = false,
    this.oxygenFlowLpm,
    this.icuRequired = false,
    this.ventilatorRequired = false,
    this.ventilatorMode = '',
    this.cardiacMonitorRequired = false,
    this.stretcherRequired = false,
    this.wheelchairRequired = false,
    this.pediatricPatient = false,
    this.doctorRequired = false,
    this.doctorSpecialization,
    this.emtRequired = true,
    this.medicalAttendantRequired = false,
    this.additionalEquipment = const [],
    this.specialInstructions = '',
    this.trainDetails,
    this.airDetails,
    this.deadBodyDetails,
    this.priority = 'NORMAL',
    this.customerCareStatus = 'Pending',
    this.customerCareNotes = '',
    this.customerId = '',
    this.driverName = '',
    this.driverPhone = '',
    this.emtName = '',
    this.emtPhone = '',
    this.doctorName = '',
    this.doctorPhone = '',
    this.assignedEquipment = const [],
    this.vehicleNumber = '',
    this.ambulanceDisplayName = '',
    this.isImmediate = false,
    this.etaMinutes = 0,
    this.driverLatitude,
    this.driverLongitude,
    this.driverSpeedKmh = 0,
    this.driverHeading = 0,
    this.driverLocationAccuracyMeters = 0,
    this.driverLocationUpdatedAt,
    this.driverLocationSharing = false,
    this.distanceKm = 0,
    this.quotation,
    this.invoice,
    this.cancellationReason = '',
    this.paymentStatus = 'Unpaid',
    this.vitals = const [],
    this.tripMilestone = '',
    this.isHomeService = false,
    this.homeServiceCategory = '',
    this.homeServiceName = '',
    this.visitCharge = 0,
    this.hourlyRate = 0,
    this.serviceHours = 0,
    this.serviceCondition = 'Not assessed yet',
    this.homeServiceBillingStatus = 'Visit scheduled',
  });

  final String id;
  final String pickup;
  final String destination;
  final String date;
  final String time;
  final String ambulanceType;
  final String transportMode;
  final String serviceCategory;
  final String? serviceSubtype;
  final String pickupCity;
  final String destinationCity;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int estimatedDurationMins;
  String status;
  double amount;

  /// Server-calculated basic fare before Team Lead quotation.
  final double basicFare;
  final String? assignedAmbulanceId;
  final String? assignedDriverId;
  final String? assignedMedicalCrewId;
  final String? assignedDoctorId;

  final String customerName;
  final String mobileNumber;
  final String email;
  final String alternatePhone;
  final String relationshipToPatient;

  final String patientName;
  final int patientAge;
  final String patientGender;
  final double? patientWeightKg;
  final String currentCondition;
  final String medicalSummary;
  final bool isEmergency;
  final String isAdmittedInHospital;
  final bool isConscious;
  final String currentHospital;
  final String destinationHospital;

  final bool oxygenRequired;
  final double? oxygenFlowLpm;
  final bool icuRequired;
  final bool ventilatorRequired;
  final String ventilatorMode;
  final bool cardiacMonitorRequired;
  final bool stretcherRequired;
  final bool wheelchairRequired;
  final bool pediatricPatient;
  final bool doctorRequired;
  final String? doctorSpecialization;
  final bool emtRequired;
  final bool medicalAttendantRequired;
  final List<String> additionalEquipment;
  final String specialInstructions;
  final RailwayTransferDetails? trainDetails;
  final AirTransferDetails? airDetails;
  final DeadBodyTransferDetails? deadBodyDetails;

  String priority;
  String customerCareStatus;
  String customerCareNotes;
  final String customerId;

  String driverName;
  String driverPhone;
  String emtName;
  String emtPhone;
  String doctorName;
  String doctorPhone;
  List<String> assignedEquipment;
  String vehicleNumber;
  final String ambulanceDisplayName;
  final bool isImmediate;
  int etaMinutes;

  // Live driver telemetry. These fields are mutable so the driver app can
  // update the same booking object while the customer watches the trip.
  double? driverLatitude;
  double? driverLongitude;
  double driverSpeedKmh;
  double driverHeading;
  double driverLocationAccuracyMeters;
  DateTime? driverLocationUpdatedAt;
  bool driverLocationSharing;
  final double distanceKm;

  Quotation? quotation;
  Invoice? invoice;
  String cancellationReason;
  String paymentStatus;
  final List<VitalSign> vitals;
  String tripMilestone;
  bool? _patientOnboardConfirmed;

  bool get patientOnboardConfirmed => _patientOnboardConfirmed == true;

  set patientOnboardConfirmed(bool? value) => _patientOnboardConfirmed = value;

  // Home-service billing
  final bool isHomeService;
  final String homeServiceCategory;
  final String homeServiceName;
  final double visitCharge;
  final double hourlyRate;
  double serviceHours;
  String serviceCondition;
  String homeServiceBillingStatus;

  double get homeServiceAdditionalAmount {
    if (!isHomeService || serviceHours <= 1 || hourlyRate <= 0) {
      return 0;
    }
    return (serviceHours - 1) * hourlyRate;
  }

  double get homeServiceCalculatedTotal {
    if (!isHomeService) return amount;
    return visitCharge + homeServiceAdditionalAmount;
  }

  bool get isCompleted =>
      status == 'SERVICE_COMPLETED' ||
      status == 'INVOICE_GENERATED' ||
      status == 'Completed' ||
      status == 'HOME_SERVICE_COMPLETED';
  bool get isCancelled => status == 'CANCELLED' || status == 'Cancelled';
  bool get isActive => const {
    'CUSTOMER_ACCEPTED',
    'ASSIGNED',
    'DRIVER_ASSIGNED',
    'EMT_ASSIGNED',
    'DOCTOR_ASSIGNED',
    'PICKUP_STARTED',
    'PATIENT_PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED',
    'On the Way',
    'HOME_SERVICE_IN_PROGRESS',
  }.contains(status);
  bool get canTrack =>
      !isCompleted &&
      !isCancelled &&
      const {
        'CUSTOMER_ACCEPTED',
        'ASSIGNED',
        'DRIVER_ASSIGNED',
        'EMT_ASSIGNED',
        'DOCTOR_ASSIGNED',
        'PICKUP_STARTED',
        'PATIENT_PICKED_UP',
        'IN_TRANSIT',
        'ARRIVED',
      }.contains(status);
  bool get canCancel => const {
    'NEW',
    'CUSTOMER_CARE_CONTACT_PENDING',
    'CUSTOMER_CARE_CONTACTED',
    'VERIFICATION_PENDING',
    'VERIFIED',
    'SENT_TO_TEAM_LEAD',
    'ALLOCATION_PENDING',
    'BUDGET_PENDING',
    'QUOTATION_SENT',
    'Pending',
    'Upcoming',
    'HOME_SERVICE_BOOKED',
  }.contains(status);
  bool get hasPendingQuotation =>
      quotation?.status == 'SENT' || quotation?.status == 'CUSTOMER_VIEWED';

  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';

  String get transportModeLabel {
    switch (transportMode) {
      case 'AIR_AMBULANCE':
        return 'Air Ambulance';
      case 'RAIL_AMBULANCE':
        return 'Rail Ambulance';
      case 'DEAD_BODY_TRANSFER':
        return 'Dead Body Transfer';
      case 'HOME_SERVICE':
        return 'Home Medical Service';
      case 'ROAD_AMBULANCE':
      default:
        return ambulanceType.isEmpty ? 'Road Ambulance' : ambulanceType;
    }
  }

  String get customerStatusLabel {
    switch (status) {
      case 'HOME_SERVICE_BOOKED':
        return 'Home Service Booked';
      case 'HOME_SERVICE_IN_PROGRESS':
        return 'Visit In Progress';
      case 'HOME_SERVICE_COMPLETED':
        return 'Service Completed';
      case 'NEW':
        return 'Request Submitted';
      case 'CUSTOMER_CARE_CONTACT_PENDING':
        return 'Awaiting Verification';
      case 'CUSTOMER_CARE_CONTACTED':
        return 'Under Verification';
      case 'VERIFICATION_PENDING':
        return 'Under Verification';
      case 'VERIFIED':
        return 'Request Verified';
      case 'SENT_TO_TEAM_LEAD':
        return 'Under Operational Review';
      case 'ALLOCATION_PENDING':
        return 'Dispatch Planning';
      case 'BUDGET_PENDING':
        return 'Quotation Being Prepared';
      case 'QUOTATION_SENT':
        return 'Quotation Ready';
      case 'CUSTOMER_ACCEPTED':
        return 'Quotation Accepted';
      case 'CUSTOMER_REJECTED':
        return 'Quotation Rejected';
      case 'ASSIGNED':
        return 'Ambulance Assigned';
      case 'DRIVER_ASSIGNED':
        return 'Ambulance Assigned';
      case 'EMT_ASSIGNED':
        return 'Ambulance Assigned';
      case 'DOCTOR_ASSIGNED':
        return 'Ambulance Assigned';
      case 'PICKUP_STARTED':
        return 'Ambulance On The Way';
      case 'PATIENT_PICKED_UP':
        return 'Patient Onboard';
      case 'IN_TRANSIT':
        return 'Patient Onboard / In Transit';
      case 'ARRIVED':
        return 'Arrived At Destination';
      case 'SERVICE_COMPLETED':
        return 'Trip Completed';
      case 'Completed':
        return 'Trip Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class RailwayTransferDetails {
  const RailwayTransferDetails({
    this.trainNumber = '',
    this.trainName = '',
    this.coachNumber = '',
    this.pickupStation = '',
    this.destinationStation = '',
  });

  final String trainNumber;
  final String trainName;
  final String coachNumber;
  final String pickupStation;
  final String destinationStation;
}

class AirTransferDetails {
  const AirTransferDetails({
    this.flightType = 'Domestic',
    this.pickupAirport = '',
    this.destinationAirport = '',
    this.airPermitNumber,
  });

  final String flightType;
  final String pickupAirport;
  final String destinationAirport;
  final String? airPermitNumber;
}

class DeadBodyTransferDetails {
  const DeadBodyTransferDetails({
    this.deathCertificateNumber,
    this.freezerRequired = true,
    this.hospitalMorgueReleaseGranted = false,
    this.familyNOCReceived = false,
  });

  final String? deathCertificateNumber;
  final bool freezerRequired;
  final bool hospitalMorgueReleaseGranted;
  final bool familyNOCReceived;
}

class VitalSign {
  const VitalSign({
    required this.time,
    required this.heartRate,
    required this.spo2,
    required this.bp,
    required this.respiratoryRate,
    required this.temperature,
    this.glucoseMgDl,
    this.oxygenFlowLpm,
    this.ventilatorPressureCmH2O,
    this.clinicalNotes = '',
    this.recordedBy = '',
  });
  final String time;
  final int heartRate;
  final int spo2;
  final String bp;
  final int respiratoryRate;
  final double temperature;
  final double? glucoseMgDl;
  final double? oxygenFlowLpm;
  final double? ventilatorPressureCmH2O;
  final String clinicalNotes;
  final String recordedBy;
}

class Quotation {
  Quotation({
    required this.id,
    required this.status,
    required this.baseAmbulanceCharge,
    required this.distanceCharge,
    required this.doctorCharge,
    required this.emtCharge,
    required this.oxygenCharge,
    required this.icuCharge,
    required this.ventilatorCharge,
    this.pediatricIcuCharge = 0,
    required this.equipmentCharge,
    required this.attendantCharge,
    this.railwayCharges = 0,
    this.airAmbulanceCharges = 0,
    this.airportCharges = 0,
    required this.additionalCharges,
    required this.discount,
    required this.taxPercent,
    required this.paymentTerms,
    required this.validUntil,
    this.rejectionReason = '',
    this.notes = '',
    this.versionNo,
    this.preparedByName = '',
    this.preparedAt = '',
    this.sentAt = '',
    this.respondedAt = '',
    this.subtotalOverride,
    this.taxAmountOverride,
    this.finalAmountOverride,
  });

  final String id;
  String status;
  final double baseAmbulanceCharge;
  final double distanceCharge;
  final double doctorCharge;
  final double emtCharge;
  final double oxygenCharge;
  final double icuCharge;
  final double ventilatorCharge;
  final double pediatricIcuCharge;
  final double equipmentCharge;
  final double attendantCharge;
  final double railwayCharges;
  final double airAmbulanceCharges;
  final double airportCharges;
  final double additionalCharges;
  final double discount;
  final double taxPercent;
  final String paymentTerms;
  final String validUntil;
  String rejectionReason;
  final String notes;
  final int? versionNo;
  final String preparedByName;
  final String preparedAt;
  final String sentAt;
  final String respondedAt;
  final double? subtotalOverride;
  final double? taxAmountOverride;
  final double? finalAmountOverride;

  double get subtotal =>
      subtotalOverride ??
      (baseAmbulanceCharge +
          distanceCharge +
          doctorCharge +
          emtCharge +
          oxygenCharge +
          icuCharge +
          ventilatorCharge +
          pediatricIcuCharge +
          equipmentCharge +
          attendantCharge +
          railwayCharges +
          airAmbulanceCharges +
          airportCharges +
          additionalCharges -
          discount);
  double get taxAmount => taxAmountOverride ?? subtotal * taxPercent / 100;
  double get finalAmount => finalAmountOverride ?? subtotal + taxAmount;
}

class Invoice {
  Invoice({
    required this.id,
    required this.bookingId,
    required this.quotationId,
    required this.serviceDetails,
    required this.total,
    required this.paymentStatus,
    required this.invoiceDate,
    this.invoiceNumber = '',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discount = 0,
    this.paymentMethod = '',
    this.paidAt = '',
    this.pdfUrl = '',
  });
  final String id;
  final String bookingId;
  final String quotationId;
  final String serviceDetails;
  final double total;
  final String paymentStatus;
  final String invoiceDate;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final String paymentMethod;
  final String paidAt;
  final String pdfUrl;
}
