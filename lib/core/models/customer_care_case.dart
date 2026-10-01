class AuditLogEntry {
  final String actor;
  final String role;
  final String action;
  final String timestamp;
  final String details;

  const AuditLogEntry({
    required this.actor,
    required this.role,
    required this.action,
    required this.timestamp,
    this.details = '',
  });
}

class CustomerCareVerificationPayload {
  const CustomerCareVerificationPayload({
    required this.bookingId,
    required this.patientConditionConfirmed,
    required this.medicalRequirementsConfirmed,
    required this.locationConfirmed,
    required this.datetimeConfirmed,
    required this.checkPatientCondition,
    required this.checkOxygenTherapy,
    required this.checkVentilatorLoaded,
    required this.checkDoctorDesignated,
    required this.checkReceivingBedSecured,
    required this.checkRoutePriorityCleared,
    required this.priority,
    required this.notes,
    this.callLogId,
    this.outcome = 'VERIFIED',
  });

  final String bookingId;
  final String? callLogId;
  final bool patientConditionConfirmed;
  final bool medicalRequirementsConfirmed;
  final bool locationConfirmed;
  final bool datetimeConfirmed;
  final bool checkPatientCondition;
  final bool checkOxygenTherapy;
  final bool checkVentilatorLoaded;
  final bool checkDoctorDesignated;
  final bool checkReceivingBedSecured;
  final bool checkRoutePriorityCleared;
  final String priority;
  final String notes;
  final String outcome;

  bool get isComplete =>
      patientConditionConfirmed &&
      medicalRequirementsConfirmed &&
      locationConfirmed &&
      datetimeConfirmed &&
      checkPatientCondition &&
      checkOxygenTherapy &&
      checkVentilatorLoaded &&
      checkDoctorDesignated &&
      checkReceivingBedSecured &&
      checkRoutePriorityCleared;

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'call_log_id': callLogId,
    'patient_condition_confirmed': patientConditionConfirmed,
    'medical_requirements_confirmed': medicalRequirementsConfirmed,
    'location_confirmed': locationConfirmed,
    'datetime_confirmed': datetimeConfirmed,
    'check_patient_condition': checkPatientCondition,
    'check_oxygen_therapy': checkOxygenTherapy,
    'check_ventilator_loaded': checkVentilatorLoaded,
    'check_doctor_designated': checkDoctorDesignated,
    'check_receiving_bed_secured': checkReceivingBedSecured,
    'check_route_priority_cleared': checkRoutePriorityCleared,
    'priority': priority,
    'notes': notes,
    'outcome': outcome,
  };
}

class CustomerCareCase {
  String id;
  String status;
  String submissionStatus;
  String submittedAt;
  String updatedAt;

  /// Origin of the request: CUSTOMER_APP or CUSTOMER_CARE_INBOUND.
  String source;
  String customerName;
  String mobileNumber;
  String email;
  String relationship;
  String patientName;
  int age;
  String gender;
  String condition;
  bool isChild;
  bool isEmergency;
  String serviceCategory;
  String ambulanceCategory;
  String pickupAddress;
  String destinationAddress;
  String destinationHospital;
  double distanceKm;
  int durationMins;
  String preferredDate;
  String preferredTime;
  bool oxygen;
  double? oxygenFlow;
  bool icu;
  bool ventilator;
  String ventilatorMode;
  bool cardiacMonitor;
  bool stretcher;
  bool wheelchair;
  bool pediatric;
  bool doctor;
  String doctorSpecialization;
  bool emt;
  bool attendant;
  List<String> equipment;
  String specialInstructions;
  String callStatus;
  String priority;
  int callDurationSeconds;
  String notes;
  bool patientConfirmed;
  bool medicalConfirmed;
  bool locationConfirmed;
  bool dateTimeConfirmed;
  String verifiedBy;
  String createdAt;
  String? ambulance;
  String? vehicleNumber;
  String? driverName;
  String? driverPhone;
  int? etaMinutes;

  // Extended clinical & telemetry fields for Stitch operations fidelity
  String bloodPressure;
  String spO2;
  String diagnosis;
  String receivingDoctor;
  String receivingDepartment;
  String doctorName;
  String emtName;
  String currentTelemetryLocation;
  int liveSpeedKmh;
  double remainingKm;
  String telemetrySignalFreshness;
  bool isTelemetryStale;
  String dispatchTier;
  String mrn;
  String sopTimeElapsed;
  bool isCodeRed;

  // 6-step Safety Handover Protocol Checklist
  bool checkPatientCondition;
  bool checkOxygenTherapy;
  bool checkVentilatorLoaded;
  bool checkDoctorDesignated;
  bool checkReceivingBedSecured;
  bool checkRoutePriorityCleared;

  List<AuditLogEntry> auditLogs;

  CustomerCareCase({
    required this.id,
    required this.status,
    this.submissionStatus = 'PENDING_VERIFICATION',
    this.submittedAt = '',
    this.updatedAt = '',
    this.source = 'CUSTOMER_APP',
    required this.customerName,
    required this.mobileNumber,
    required this.email,
    required this.relationship,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.condition,
    required this.isChild,
    required this.isEmergency,
    required this.serviceCategory,
    this.ambulanceCategory = '',
    required this.pickupAddress,
    required this.destinationAddress,
    required this.destinationHospital,
    required this.distanceKm,
    required this.durationMins,
    required this.preferredDate,
    required this.preferredTime,
    required this.oxygen,
    this.oxygenFlow,
    required this.icu,
    required this.ventilator,
    required this.ventilatorMode,
    required this.cardiacMonitor,
    required this.stretcher,
    required this.wheelchair,
    required this.pediatric,
    required this.doctor,
    required this.doctorSpecialization,
    required this.emt,
    required this.attendant,
    required this.equipment,
    required this.specialInstructions,
    required this.callStatus,
    required this.priority,
    required this.callDurationSeconds,
    required this.notes,
    required this.patientConfirmed,
    required this.medicalConfirmed,
    required this.locationConfirmed,
    required this.dateTimeConfirmed,
    required this.verifiedBy,
    required this.createdAt,
    this.ambulance,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.etaMinutes,
    this.bloodPressure = '',
    this.spO2 = '',
    this.diagnosis = '',
    this.receivingDoctor = '',
    this.receivingDepartment = '',
    this.doctorName = '',
    this.emtName = '',
    this.currentTelemetryLocation = '',
    this.liveSpeedKmh = 0,
    this.remainingKm = 0.0,
    this.telemetrySignalFreshness = 'Telemetry unavailable',
    this.isTelemetryStale = false,
    this.dispatchTier = '',
    this.mrn = '',
    this.sopTimeElapsed = '',
    this.isCodeRed = false,
    this.checkPatientCondition = false,
    this.checkOxygenTherapy = false,
    this.checkVentilatorLoaded = false,
    this.checkDoctorDesignated = false,
    this.checkReceivingBedSecured = false,
    this.checkRoutePriorityCleared = false,
    List<AuditLogEntry>? auditLogs,
  }) : auditLogs = auditLogs ?? [];

  bool get isInbound => source == 'CUSTOMER_CARE_INBOUND';
  bool get isDraft => submissionStatus.toUpperCase() == 'DRAFT';
  bool get isSubmitted =>
      submissionStatus.toUpperCase() == 'PENDING_VERIFICATION';
  bool get isSubmissionVerified =>
      submissionStatus.toUpperCase() == 'VERIFIED' || status == 'VERIFIED';

  int get checklistCompletedCount {
    int count = 0;
    if (checkPatientCondition) count++;
    if (checkOxygenTherapy) count++;
    if (checkVentilatorLoaded) count++;
    if (checkDoctorDesignated) count++;
    if (checkReceivingBedSecured) count++;
    if (checkRoutePriorityCleared) count++;
    return count;
  }

  bool get isSafetyChecklistComplete => checklistCompletedCount == 6;

  bool get allConfirmed =>
      patientConfirmed &&
      medicalConfirmed &&
      locationConfirmed &&
      dateTimeConfirmed;

  String get priorityLabel {
    switch (priority) {
      case 'CRITICAL_CODE_RED':
      case 'CODE_RED':
        return 'CRITICAL CODE RED';
      case 'HIGH':
        return 'HIGH';
      case 'LOW':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'NEW':
        return 'New Inbound';
      case 'CUSTOMER_CARE_CONTACT_PENDING':
        return 'Contact Pending';
      case 'CUSTOMER_CARE_CONTACTED':
        return 'Customer Contacted';
      case 'VERIFICATION_PENDING':
        return 'Verification Pending';
      case 'VERIFIED':
        return 'Verified Ready';
      case 'SENT_TO_TEAM_LEAD':
        return 'Sent to Team Lead';
      case 'ALLOCATION_PENDING':
        return 'Allocation Pending';
      case 'BUDGET_PENDING':
        return 'Budget Pending';
      case 'QUOTATION_SENT':
        return 'Quotation Sent';
      case 'CUSTOMER_ACCEPTED':
        return 'Customer Accepted';
      case 'ASSIGNED':
        return 'Assigned';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'PICKUP_STARTED':
        return 'Pickup Started';
      case 'PATIENT_PICKED_UP':
        return 'Patient Picked Up';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'ARRIVED':
        return 'Arrived';
      case 'SERVICE_COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  CustomerCareCase copy() => CustomerCareCase(
    id: id,
    status: status,
    submissionStatus: submissionStatus,
    submittedAt: submittedAt,
    updatedAt: updatedAt,
    source: source,
    customerName: customerName,
    mobileNumber: mobileNumber,
    email: email,
    relationship: relationship,
    patientName: patientName,
    age: age,
    gender: gender,
    condition: condition,
    isChild: isChild,
    isEmergency: isEmergency,
    serviceCategory: serviceCategory,
    ambulanceCategory: ambulanceCategory,
    pickupAddress: pickupAddress,
    destinationAddress: destinationAddress,
    destinationHospital: destinationHospital,
    distanceKm: distanceKm,
    durationMins: durationMins,
    preferredDate: preferredDate,
    preferredTime: preferredTime,
    oxygen: oxygen,
    oxygenFlow: oxygenFlow,
    icu: icu,
    ventilator: ventilator,
    ventilatorMode: ventilatorMode,
    cardiacMonitor: cardiacMonitor,
    stretcher: stretcher,
    wheelchair: wheelchair,
    pediatric: pediatric,
    doctor: doctor,
    doctorSpecialization: doctorSpecialization,
    emt: emt,
    attendant: attendant,
    equipment: List<String>.from(equipment),
    specialInstructions: specialInstructions,
    callStatus: callStatus,
    priority: priority,
    callDurationSeconds: callDurationSeconds,
    notes: notes,
    patientConfirmed: patientConfirmed,
    medicalConfirmed: medicalConfirmed,
    locationConfirmed: locationConfirmed,
    dateTimeConfirmed: dateTimeConfirmed,
    verifiedBy: verifiedBy,
    createdAt: createdAt,
    ambulance: ambulance,
    vehicleNumber: vehicleNumber,
    driverName: driverName,
    driverPhone: driverPhone,
    etaMinutes: etaMinutes,
    bloodPressure: bloodPressure,
    spO2: spO2,
    diagnosis: diagnosis,
    receivingDoctor: receivingDoctor,
    receivingDepartment: receivingDepartment,
    doctorName: doctorName,
    emtName: emtName,
    currentTelemetryLocation: currentTelemetryLocation,
    liveSpeedKmh: liveSpeedKmh,
    remainingKm: remainingKm,
    telemetrySignalFreshness: telemetrySignalFreshness,
    isTelemetryStale: isTelemetryStale,
    dispatchTier: dispatchTier,
    mrn: mrn,
    sopTimeElapsed: sopTimeElapsed,
    isCodeRed: isCodeRed,
    checkPatientCondition: checkPatientCondition,
    checkOxygenTherapy: checkOxygenTherapy,
    checkVentilatorLoaded: checkVentilatorLoaded,
    checkDoctorDesignated: checkDoctorDesignated,
    checkReceivingBedSecured: checkReceivingBedSecured,
    checkRoutePriorityCleared: checkRoutePriorityCleared,
    auditLogs: List<AuditLogEntry>.from(auditLogs),
  );
}

/// Rich demo dataset calibrated specifically from Stitch MCP Project 1449624092268908152
List<CustomerCareCase> demoCases() => [
  // Case 1: Urgent Code Red (#AM-2025-8941) - Arthur Vance
  CustomerCareCase(
    id: 'AM-2025-8941',
    status: 'NEW',
    source: 'CUSTOMER_CARE_INBOUND',
    customerName: 'David Vance',
    mobileNumber: '+1 (555) 382-9912',
    email: 'david.vance@example.com',
    relationship: 'Son / Next of Kin',
    patientName: 'Arthur Vance',
    age: 74,
    gender: 'Male',
    condition: 'Acute STEMI • Hemodynamically Unstable',
    isChild: false,
    isEmergency: true,
    isCodeRed: true,
    serviceCategory: 'ROAD',
    dispatchTier: 'Dispatch Tier 1 Primary Air/Ground',
    mrn: 'MRN-902-8812',
    pickupAddress: 'St. Jude ER (Resuscitation Bay 3)',
    destinationAddress: 'Metro Cardiac Spec • Cath Lab Rm 4',
    destinationHospital: 'Metro Cardiac Spec',
    distanceKm: 14.2,
    durationMins: 18,
    preferredDate: '21 Sep 2026',
    preferredTime: '10:45 AM',
    oxygen: true,
    oxygenFlow: 15.0,
    icu: true,
    ventilator: true,
    ventilatorMode: 'BiPAP / Transport Ready',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    pediatric: false,
    doctor: true,
    doctorSpecialization: 'Interventional Cardiology Escort',
    emt: true,
    attendant: false,
    equipment: [
      'O2: High Flow (15L)',
      'ICU Setup',
      'Doctor Escort',
      'Ventilator Ready',
    ],
    specialInstructions:
        'Direct Cath Lab handoff requested. Dr. Ross standing by.',
    callStatus: 'Pending',
    priority: 'CRITICAL_CODE_RED',
    callDurationSeconds: 277,
    notes: 'Spoke with son David Vance. Patient Arthur Vance receiving sublingual nitro and heparin at St. Jude ER. Receiving interventional cardiologist Dr. Ross confirmed in Cath Lab 2. Family escorting behind ambulance.',
    patientConfirmed: true,
    medicalConfirmed: true,
    locationConfirmed: true,
    dateTimeConfirmed: true,
    checkPatientCondition: true,
    checkOxygenTherapy: true,
    checkVentilatorLoaded: true,
    checkDoctorDesignated: true,
    checkReceivingBedSecured: true,
    checkRoutePriorityCleared: true,
    verifiedBy: 'S. Jenkins, RN',
    createdAt: '3m ago',
    bloodPressure: '82/50 (Hypotensive)',
    spO2: '88% (Desat)',
    diagnosis: 'ACUTE STEMI • Anterior',
    receivingDoctor: 'Dr. Ross (Cath Lab Rm 4)',
    receivingDepartment: 'Metro Heart Institute Cath Lab',
    doctorName: 'Dr. Kenneth Cole',
    emtName: 'A. Gomez',
    ambulance: 'Unit 04 (Mercedes Sprinter MICU)',
    vehicleNumber: 'MED-04',
    driverName: 'Michael Vance',
    driverPhone: '+1 (555) 382-9912',
    etaMinutes: 18,
    liveSpeedKmh: 74,
    remainingKm: 6.8,
    currentTelemetryLocation: 'NW HWY 101 @ MM 42',
    telemetrySignalFreshness: 'Signal 99.4% (10s ago)',
    auditLogs: [
      AuditLogEntry(
        actor: 'System Intake',
        role: 'CAD Gateway',
        action: 'Inbound incident logged from St. Jude ER Resus Bay 3',
        timestamp: '10:42 AM',
      ),
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Triage Lead',
        action: 'Direct family phone contact initiated',
        timestamp: '10:44 AM',
      ),
    ],
  ),

  // Case 2: High Urgency Pediatric (#AM-2025-8938) - Maya Rostova
  CustomerCareCase(
    id: 'AM-2025-8938',
    status: 'CUSTOMER_CARE_CONTACTED',
    source: 'CUSTOMER_APP',
    customerName: 'Elena Rostova',
    mobileNumber: '+1 (555) 721-4402',
    email: 'elena.rostova@example.com',
    relationship: 'Mother',
    patientName: 'Maya Rostova',
    age: 4,
    gender: 'Female',
    condition: 'Severe Respiratory Distress / Severe Croup Stridor',
    isChild: true,
    pediatric: true,
    isEmergency: true,
    isCodeRed: false,
    serviceCategory: 'AIR',
    dispatchTier: 'Sub-Specialty Air/Pediatric Response',
    mrn: 'PED-441-209',
    pickupAddress: 'Valley Pediatric Clinic',
    destinationAddress: "Children's Mercy Hospital",
    destinationHospital: "Children's Mercy Hospital",
    distanceKm: 22.5,
    durationMins: 25,
    preferredDate: '21 Sep 2026',
    preferredTime: '11:00 AM',
    oxygen: true,
    oxygenFlow: 6.0,
    icu: true,
    ventilator: false,
    ventilatorMode: 'Humidified O2 High Flow',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    doctor: true,
    doctorSpecialization: 'Pediatric Intensivist',
    emt: true,
    attendant: true,
    equipment: ['PICU Incubator', 'Pediatric EMT', 'O2 Humidified'],
    specialInstructions:
        'Child requires continuous humidified oxygen and stridor monitoring.',
    callStatus: 'In Progress',
    priority: 'HIGH',
    callDurationSeconds: 180,
    notes: 'Mother Elena confirmed 4yo daughter presenting with barking cough, intercostal retractions. Nebulized epinephrine given 15m ago. PICU bed assigned at Children’s Mercy.',
    patientConfirmed: true,
    medicalConfirmed: true,
    locationConfirmed: true,
    dateTimeConfirmed: false,
    checkPatientCondition: true,
    checkOxygenTherapy: true,
    checkVentilatorLoaded: false,
    checkDoctorDesignated: true,
    checkReceivingBedSecured: true,
    checkRoutePriorityCleared: false,
    verifiedBy: 'S. Jenkins, RN',
    createdAt: '11m ago',
    bloodPressure: '92/60',
    spO2: '91% (Airway compromised)',
    diagnosis: 'Acute Laryngotracheobronchitis',
    receivingDoctor: 'Dr. Alistair Finch',
    receivingDepartment: 'Pediatric ICU Bay 3',
    doctorName: 'Dr. Maya Patel',
    emtName: 'C. Bennett',
    ambulance: 'Unit 12 (NICU Van)',
    vehicleNumber: 'NICU-12',
    driverName: 'James Wilson',
    driverPhone: '+1 (555) 721-4402',
    etaMinutes: 25,
    liveSpeedKmh: 48,
    remainingKm: 14.1,
    currentTelemetryLocation: 'Metro Arterial Expressway South',
    telemetrySignalFreshness: 'Live GPS Stream: Active',
    auditLogs: [
      AuditLogEntry(
        actor: 'Elena Rostova',
        role: 'Caller',
        action: 'App booking intake submitted',
        timestamp: '10:34 AM',
      ),
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Triage Lead',
        action: 'Pediatric triage protocol activated',
        timestamp: '10:37 AM',
      ),
    ],
  ),

  // Case 3: Verified Ready For Lead (#AM-2025-8924) - Marcus Brody
  CustomerCareCase(
    id: 'AM-2025-8924',
    status: 'VERIFIED',
    source: 'CUSTOMER_CARE_INBOUND',
    customerName: 'Dr. Kenneth Cole',
    mobileNumber: '+1 (555) 901-2334',
    email: 'k.cole@trauma.org',
    relationship: 'Trauma Attending',
    patientName: 'Marcus Brody',
    age: 38,
    gender: 'Male',
    condition: 'Multiple Blunt Force Trauma • GCS 11 • Pelvic Binder',
    isChild: false,
    isEmergency: true,
    isCodeRed: false,
    serviceCategory: 'ROAD',
    dispatchTier: 'Trauma Air/Ground Critical Transport',
    mrn: 'TRM-889-102',
    pickupAddress: 'Community General Level 3 ED',
    destinationAddress: 'University Trauma Center (Resus 1)',
    destinationHospital: 'University Trauma Center',
    distanceKm: 31.0,
    durationMins: 32,
    preferredDate: '21 Sep 2026',
    preferredTime: '10:30 AM',
    oxygen: true,
    oxygenFlow: 10.0,
    icu: true,
    ventilator: true,
    ventilatorMode: 'Volume Control SIMV',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    pediatric: false,
    doctor: true,
    doctorSpecialization: 'Trauma Surgeon Escort',
    emt: true,
    attendant: true,
    equipment: ['Pelvic Binder', 'Blood Infusion Warmer', 'Transport Vent'],
    specialInstructions:
        'Massive transfusion protocol blood units accompanying patient.',
    callStatus: 'Verified',
    priority: 'HIGH',
    callDurationSeconds: 310,
    notes: 'Direct MD to MD handoff confirmed with Dr. Cole. Vitals stable post-crystalloid resuscitation. Pelvic binder placed and confirmed intact. Resus 1 prepared at University Trauma.',
    patientConfirmed: true,
    medicalConfirmed: true,
    locationConfirmed: true,
    dateTimeConfirmed: true,
    checkPatientCondition: true,
    checkOxygenTherapy: true,
    checkVentilatorLoaded: true,
    checkDoctorDesignated: true,
    checkReceivingBedSecured: true,
    checkRoutePriorityCleared: true,
    verifiedBy: 'S. Jenkins, RN',
    createdAt: '10:14 AM',
    bloodPressure: '108/68',
    spO2: '96%',
    diagnosis: 'Polytrauma / Closed Pelvic Fracture',
    receivingDoctor: 'Dr. Sandra Bell (Trauma Director)',
    receivingDepartment: 'University Trauma Shock Trauma Bay',
    doctorName: 'Dr. Eric Thorne',
    emtName: 'R. Simmons',
    ambulance: 'Unit 07 (ACLS Rotor Support)',
    vehicleNumber: 'ROTOR-07',
    driverName: 'Capt. Donald Hayes',
    driverPhone: '+1 (555) 901-2334',
    etaMinutes: 19,
    liveSpeedKmh: 140,
    remainingKm: 28.0,
    currentTelemetryLocation: 'Flight Corridor Sector 7-B',
    telemetrySignalFreshness: 'CAD Feed: SYNCHRONIZED',
    auditLogs: [
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Triage Lead',
        action: 'All 6/6 Safety Checklist Items Verified OK',
        timestamp: '10:14 AM',
      ),
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Triage Lead',
        action: 'Case marked READY FOR TEAM LEAD HANDOFF',
        timestamp: '10:15 AM',
      ),
    ],
  ),

  // Case 4: Active En-Route Trip (#AM-2025-8919) - Robert Chen
  CustomerCareCase(
    id: 'AM-2025-8919',
    status: 'IN_TRANSIT',
    source: 'CUSTOMER_APP',
    customerName: 'Linda Chen',
    mobileNumber: '+1 (555) 439-0112',
    email: 'linda.chen@example.com',
    relationship: 'Wife',
    patientName: 'Robert Chen',
    age: 59,
    gender: 'Male',
    condition: 'Post-Coronary Arrest • Mechanical Ventilation • Arterial Line',
    isChild: false,
    isEmergency: true,
    isCodeRed: false,
    serviceCategory: 'ROAD',
    dispatchTier: 'MICU Priority 1 • Inter-Facility',
    mrn: 'CARD-773-901',
    pickupAddress: 'Memorial General ICU',
    destinationAddress: 'Univ. Cardio Thoracic Center — Bay 2',
    destinationHospital: 'Univ. Cardio Thoracic Center',
    distanceKm: 18.0,
    durationMins: 22,
    preferredDate: '21 Sep 2026',
    preferredTime: '11:15 AM',
    oxygen: true,
    oxygenFlow: 12.0,
    icu: true,
    ventilator: true,
    ventilatorMode: 'AC Mode 14 BPM',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    pediatric: false,
    doctor: true,
    doctorSpecialization: 'Intensivist Physician',
    emt: true,
    attendant: true,
    equipment: ['Arterial Line Monitor', 'Ventilator', 'Defibrillator Ready'],
    specialInstructions:
        'Wife following in family vehicle. Keep family SMS updated on ETA.',
    callStatus: 'Verified',
    priority: 'HIGH',
    callDurationSeconds: 220,
    notes: 'Patient Robert picked up from Memorial ICU. Vitals stable on norepinephrine drip. ED receiving lead Dr. Weber notified at desk.',
    patientConfirmed: true,
    medicalConfirmed: true,
    locationConfirmed: true,
    dateTimeConfirmed: true,
    checkPatientCondition: true,
    checkOxygenTherapy: true,
    checkVentilatorLoaded: true,
    checkDoctorDesignated: true,
    checkReceivingBedSecured: true,
    checkRoutePriorityCleared: true,
    verifiedBy: 'S. Jenkins, RN',
    createdAt: '35m ago',
    bloodPressure: '114/72',
    spO2: '97%',
    diagnosis: 'Post Cardiac Arrest • RosC Stabilized',
    receivingDoctor: 'Dr. Weber (Desk: +1-555-0922)',
    receivingDepartment: 'Cardiac Intensive Care Unit Bay 2',
    doctorName: 'Dr. S. Rao',
    emtName: 'A. Gomez',
    ambulance: 'Unit 04 (Mercedes Sprinter MICU)',
    vehicleNumber: 'MICU-04',
    driverName: 'Michael Vance',
    driverPhone: '+1 (555) 439-0112',
    etaMinutes: 9,
    liveSpeedKmh: 74,
    remainingKm: 6.8,
    currentTelemetryLocation: 'NW HWY 101 @ MM 42',
    telemetrySignalFreshness: 'Signal 99.4% (10s ago)',
    auditLogs: [
      AuditLogEntry(
        actor: 'Dispatch System',
        role: 'CAD System',
        action: 'Unit 04 departed Memorial General with patient on-board',
        timestamp: '11:06 AM',
      ),
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Customer Care',
        action: 'Family SMS ETA dispatch triggered',
        timestamp: '11:10 AM',
      ),
    ],
  ),

  // Case 5: New Inbound Code Red (#AM-2025-8945) - Brenda Hughes
  CustomerCareCase(
    id: 'AM-2025-8945',
    status: 'NEW',
    source: 'CUSTOMER_CARE_INBOUND',
    customerName: 'Mercy General Triage Desk',
    mobileNumber: '+1 (555) 882-1922',
    email: 'triage@mercygeneral.org',
    relationship: 'Hospital Liaison Desk',
    patientName: 'Brenda Hughes',
    age: 68,
    gender: 'Female',
    condition: 'Acute Ischemic Stroke (LVO Window: 90m)',
    isChild: false,
    isEmergency: true,
    isCodeRed: true,
    serviceCategory: 'ROAD',
    dispatchTier: 'Tier 1 Acute Stroke Evacuation',
    mrn: 'STRK-002-114',
    pickupAddress: 'Mercy Community Hospital',
    destinationAddress: 'Comprehensive Stroke Ctr (Neuro Angio)',
    destinationHospital: 'Comprehensive Stroke Ctr',
    distanceKm: 12.0,
    durationMins: 15,
    preferredDate: '21 Sep 2026',
    preferredTime: '11:20 AM',
    oxygen: true,
    icu: true,
    ventilator: false,
    ventilatorMode: '',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    pediatric: false,
    doctor: false,
    doctorSpecialization: '',
    emt: true,
    attendant: true,
    equipment: [
      'O2 Therapy',
      'Neuro Care',
      'EMT Paramedic',
      'tPA Infusion Ready',
    ],
    specialInstructions:
        'Patient within thrombectomy window. Urgent transport required.',
    callStatus: 'Pending',
    priority: 'CRITICAL_CODE_RED',
    callDurationSeconds: 0,
    notes: '',
    patientConfirmed: false,
    medicalConfirmed: false,
    locationConfirmed: false,
    dateTimeConfirmed: false,
    checkPatientCondition: false,
    checkOxygenTherapy: false,
    checkVentilatorLoaded: false,
    checkDoctorDesignated: false,
    checkReceivingBedSecured: false,
    checkRoutePriorityCleared: false,
    verifiedBy: '',
    createdAt: '7m ago',
    bloodPressure: '164/98',
    spO2: '95%',
    diagnosis: 'Acute MCA Ischemic Stroke',
    receivingDoctor: 'Neuro Interventional Team',
    receivingDepartment: 'Neuro IR Suite 1',
    auditLogs: [],
  ),

  // Case 6: Sent to Team Lead (#AM-2025-8902) - David Miller
  CustomerCareCase(
    id: 'AM-2025-8902',
    status: 'SENT_TO_TEAM_LEAD',
    source: 'CUSTOMER_APP',
    customerName: 'Sarah Miller',
    mobileNumber: '+1 (555) 412-8871',
    email: 'sarah.miller@example.com',
    relationship: 'Mother',
    patientName: 'Noah Miller',
    age: 3,
    gender: 'Male',
    condition: 'Severe Bronchiolitis & Desaturation (SpO2 86%)',
    isChild: true,
    pediatric: true,
    isEmergency: true,
    isCodeRed: false,
    serviceCategory: 'ROAD',
    dispatchTier: 'Pediatric Urgent Transfer',
    mrn: 'PED-990-112',
    pickupAddress: 'Suburban Clinic',
    destinationAddress: "Children's Regional Hospital",
    destinationHospital: "Children's Regional Hospital",
    distanceKm: 15.4,
    durationMins: 20,
    preferredDate: '21 Sep 2026',
    preferredTime: '11:30 AM',
    oxygen: true,
    icu: true,
    ventilator: false,
    ventilatorMode: 'High Flow Cannula',
    cardiacMonitor: true,
    stretcher: true,
    wheelchair: false,
    doctor: true,
    doctorSpecialization: 'Pediatric Specialist',
    emt: true,
    attendant: true,
    equipment: ['Pediatric O2 Mask', 'Pulse Ox', 'Incubator Base'],
    specialInstructions: 'Transferred from suburban triage clinic.',
    callStatus: 'Verified',
    priority: 'HIGH',
    callDurationSeconds: 240,
    notes: 'Triage complete. Pediatric doctor escort assigned. Routed to Team Lead for vehicle dispatch allocation.',
    patientConfirmed: true,
    medicalConfirmed: true,
    locationConfirmed: true,
    dateTimeConfirmed: true,
    checkPatientCondition: true,
    checkOxygenTherapy: true,
    checkVentilatorLoaded: true,
    checkDoctorDesignated: true,
    checkReceivingBedSecured: true,
    checkRoutePriorityCleared: true,
    verifiedBy: 'S. Jenkins, RN',
    createdAt: '45m ago',
    bloodPressure: '88/54',
    spO2: '86% (Critical)',
    diagnosis: 'RSV Bronchiolitis',
    receivingDoctor: 'Dr. Evans',
    receivingDepartment: 'Pediatric High Dependency Unit',
    auditLogs: [
      AuditLogEntry(
        actor: 'Sarah Jenkins, RN',
        role: 'Triage Lead',
        action: 'Case verified and escalated to Operations Team Lead',
        timestamp: '10:02 AM',
      ),
    ],
  ),
];
