import '../models/booking.dart';

class OperationsResource {
  OperationsResource({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.capabilities = const <String>{},
    this.phone = '',
    this.specialization = '',
    this.assignedBookingId,
  });
  final String id;
  String name;
  final String type;
  String status;
  final Set<String> capabilities;
  final String phone;
  final String specialization;
  String? assignedBookingId;

  bool get available => status == 'AVAILABLE' || status == 'READY';
}

class OperationsAuditEntry {
  OperationsAuditEntry({required this.actor, required this.role, required this.bookingId, required this.action, this.previousStatus, this.newStatus}) : timestamp = DateTime.now();
  final DateTime timestamp;
  final String actor;
  final String role;
  final String bookingId;
  final String action;
  final String? previousStatus;
  final String? newStatus;
}

class OperationsNotification {
  OperationsNotification({required this.recipientRole, required this.title, required this.message, this.bookingId});
  final String recipientRole;
  final String title;
  final String message;
  final String? bookingId;
  final DateTime timestamp = DateTime.now();
  bool read = false;
}

class TeamLeadOperationsService {
  TeamLeadOperationsService._();
  static final TeamLeadOperationsService instance = TeamLeadOperationsService._();

  final List<OperationsAuditEntry> audit = <OperationsAuditEntry>[];
  final List<OperationsNotification> notifications = <OperationsNotification>[];

  final List<OperationsResource> ambulances = <OperationsResource>[
    OperationsResource(id: 'AF-AMB-07', name: 'AF-AMB-07', type: 'Advanced Life Support', status: 'READY', capabilities: {'OXYGEN','ICU','VENTILATOR','CARDIAC_MONITOR','STRETCHER'}),
    OperationsResource(id: 'AF-AMB-11', name: 'AF-AMB-11', type: 'Basic Life Support', status: 'AVAILABLE', capabilities: {'OXYGEN','STRETCHER','WHEELCHAIR'}),
    OperationsResource(id: 'AF-AMB-14', name: 'AF-AMB-14', type: 'Pediatric ICU', status: 'READY', capabilities: {'OXYGEN','ICU','VENTILATOR','PEDIATRIC','CARDIAC_MONITOR','STRETCHER'}),
    OperationsResource(id: 'AF-AMB-19', name: 'AF-AMB-19', type: 'Dead Body Transport', status: 'MAINTENANCE', capabilities: {'FREEZER','STRETCHER'}),
  ];
  final List<OperationsResource> drivers = <OperationsResource>[
    OperationsResource(id: 'DRV-01', name: 'Vikram Singh', type: 'Driver', status: 'AVAILABLE', phone: '+91 90000 10001'),
    OperationsResource(id: 'DRV-02', name: 'Kiran Reddy', type: 'Driver', status: 'ON_TRIP', phone: '+91 90000 10002'),
    OperationsResource(id: 'DRV-03', name: 'Sanjay Kumar', type: 'Driver', status: 'AVAILABLE', phone: '+91 90000 10003'),
    OperationsResource(id: 'DRV-04', name: 'Aravind Rao', type: 'Driver', status: 'OFF_DUTY', phone: '+91 90000 10004'),
  ];
  final List<OperationsResource> emts = <OperationsResource>[
    OperationsResource(id: 'EMT-01', name: 'Priya EMT', type: 'EMT', status: 'AVAILABLE', capabilities: {'PEDIATRIC'}),
    OperationsResource(id: 'EMT-02', name: 'Meena Thomas', type: 'EMT', status: 'AVAILABLE'),
    OperationsResource(id: 'EMT-03', name: 'Rahul EMT', type: 'EMT', status: 'ON_TRIP'),
    OperationsResource(id: 'EMT-04', name: 'Swathi Rao', type: 'EMT', status: 'AVAILABLE'),
  ];
  final List<OperationsResource> doctors = <OperationsResource>[
    OperationsResource(id: 'DOC-01', name: 'Dr. Arjun Rao', type: 'Doctor', status: 'AVAILABLE', specialization: 'Emergency Medicine'),
    OperationsResource(id: 'DOC-02', name: 'Dr. Kavya Menon', type: 'Doctor', status: 'ON_CALL', specialization: 'Pediatrics'),
    OperationsResource(id: 'DOC-03', name: 'Dr. Naveen Kumar', type: 'Doctor', status: 'AVAILABLE', specialization: 'Critical Care'),
    OperationsResource(id: 'DOC-04', name: 'Dr. Sana Ali', type: 'Doctor', status: 'OFF_DUTY', specialization: 'Emergency Medicine'),
  ];

  List<OperationsResource> compatibleAmbulances(Booking b) => ambulances.where((a) => a.available && _ambulanceCompatible(a, b)).toList();
  List<OperationsResource> availableDrivers(Booking b) => drivers.where((d) => d.available).toList();
  List<OperationsResource> availableEmts(Booking b) => emts.where((e) => e.available && (!b.pediatricPatient || e.capabilities.contains('PEDIATRIC'))).toList();
  List<OperationsResource> availableDoctors(Booking b) => doctors.where((d) => d.available && (!b.pediatricPatient || d.specialization.toLowerCase().contains('pediatric'))).toList();

  bool _ambulanceCompatible(OperationsResource a, Booking b) {
    if (b.transportMode == 'DEAD_BODY_TRANSFER' && !a.capabilities.contains('FREEZER')) return false;
    if (b.icuRequired && !a.capabilities.contains('ICU')) return false;
    if (b.ventilatorRequired && !a.capabilities.contains('VENTILATOR')) return false;
    if (b.oxygenRequired && !a.capabilities.contains('OXYGEN')) return false;
    if (b.cardiacMonitorRequired && !a.capabilities.contains('CARDIAC_MONITOR')) return false;
    if (b.stretcherRequired && !a.capabilities.contains('STRETCHER')) return false;
    if (b.wheelchairRequired && !a.capabilities.contains('WHEELCHAIR')) return false;
    if (b.pediatricPatient && !a.capabilities.contains('PEDIATRIC')) return false;
    return true;
  }

  bool allocate(Booking b, {required String ambulanceId, required String driverId, String? emtId, String? doctorId, List<String> equipment = const []}) {
    final ambulance = _find(ambulances, ambulanceId);
    final driver = _find(drivers, driverId);
    final emt = emtId == null ? null : _find(emts, emtId);
    final doctor = doctorId == null ? null : _find(doctors, doctorId);
    if (ambulance == null || driver == null || !ambulance.available || !driver.available) return false;
    if (!_ambulanceCompatible(ambulance, b)) return false;
    if (b.emtRequired && (emt == null || !emt.available || (b.pediatricPatient && !emt.capabilities.contains('PEDIATRIC')))) return false;
    if (b.doctorRequired && (doctor == null || !doctor.available)) return false;
    _releasePrevious(b.id);
    final previous = b.status;
    ambulance.status = 'ASSIGNED'; ambulance.assignedBookingId = b.id;
    driver.status = 'ASSIGNED'; driver.assignedBookingId = b.id;
    if (emt != null) { emt.status = 'ASSIGNED'; emt.assignedBookingId = b.id; }
    if (doctor != null) { doctor.status = 'ASSIGNED'; doctor.assignedBookingId = b.id; }
    b.vehicleNumber = ambulance.name;
    b.driverName = driver.name;
    b.driverPhone = driver.phone;
    b.emtName = emt?.name ?? '';
    b.doctorName = doctor?.name ?? '';
    b.assignedEquipment = List<String>.from(equipment);
    b.status = 'ASSIGNED';
    b.tripMilestone = 'Ambulance and crew assigned';
    _audit('Team Lead', 'Team Lead', b.id, 'Resources allocated', previous, b.status);
    _notify('Driver', 'New ambulance assignment', '${b.id} is assigned to you.', b.id);
    _notify('Customer', 'Ambulance assigned', 'Your ambulance and care team are assigned.', b.id);
    return true;
  }

  Quotation prepareQuotation(Booking b, {double discount = 0, double taxPercent = 5, String paymentTerms = 'Payment before dispatch', String validUntil = 'Valid for 24 hours', double additionalCharges = 0}) {
    final base = switch (b.transportMode) { 'AIR_AMBULANCE' => 12000.0, 'RAILWAY_AMBULANCE' => 5000.0, 'DEAD_BODY_TRANSFER' => 3500.0, _ => 2000.0 };
    final q = Quotation(
      id: 'QT-${b.id.replaceAll(RegExp(r'[^0-9]'), '')}', status: 'DRAFT',
      baseAmbulanceCharge: base, distanceCharge: b.distanceKm * 35,
      doctorCharge: b.doctorRequired ? 900 : 0, emtCharge: b.emtRequired ? 350 : 0,
      oxygenCharge: b.oxygenRequired ? 300 : 0, icuCharge: b.icuRequired ? 1200 : 0,
      ventilatorCharge: b.ventilatorRequired ? 1500 : 0, equipmentCharge: b.additionalEquipment.length * 250,
      attendantCharge: b.medicalAttendantRequired ? 200 : 0, additionalCharges: additionalCharges,
      discount: discount < 0 ? 0 : discount, taxPercent: taxPercent.clamp(0, 100).toDouble(),
      paymentTerms: paymentTerms, validUntil: validUntil, notes: 'Prepared by Ambulance First Team Lead.',
    );
    b.quotation = q; b.amount = q.finalAmount; b.status = 'BUDGET_PENDING';
    _audit('Team Lead', 'Team Lead', b.id, 'Quotation calculated', null, b.status);
    return q;
  }

  bool sendQuotation(Booking b) {
    if (b.quotation == null) prepareQuotation(b);
    b.quotation!.status = 'SENT';
    final previous = b.status; b.status = 'QUOTATION_SENT'; b.tripMilestone = 'Quotation sent to customer';
    _audit('Team Lead', 'Team Lead', b.id, 'Quotation sent', previous, b.status);
    _notify('Customer', 'Quotation ready', 'Quotation ${b.quotation!.id} is ready for your review.', b.id);
    return true;
  }

  bool acceptQuotation(Booking b) {
    if (b.quotation == null || b.status != 'QUOTATION_SENT') return false;
    b.quotation!.status = 'CUSTOMER_ACCEPTED'; b.amount = b.quotation!.finalAmount;
    final previous = b.status; b.status = 'CUSTOMER_ACCEPTED'; b.tripMilestone = 'Quotation accepted • ready for dispatch';
    _audit('Customer', 'Customer', b.id, 'Customer accepted quotation', previous, b.status);
    _notify('Team Lead', 'Quotation accepted', '${b.id} has been accepted and is ready for allocation.', b.id);
    return true;
  }

  bool rejectQuotation(Booking b, String reason) {
    if (b.quotation == null || b.status != 'QUOTATION_SENT') return false;
    b.quotation!.status = 'CUSTOMER_REJECTED'; b.quotation!.rejectionReason = reason;
    final previous = b.status; b.status = 'CUSTOMER_REJECTED'; b.tripMilestone = 'Quotation rejected • operations notified';
    _audit('Customer', 'Customer', b.id, 'Customer rejected quotation: $reason', previous, b.status);
    _notify('Team Lead', 'Quotation rejected', '${b.id} was rejected. Review and re-quote if required.', b.id);
    return true;
  }

  /// Records a quotation response made from the Customer app. Because all
  /// roles use SharedBookingStore, the Booking status and rejection reason are
  /// already shared; this adds the operational audit trail and notifications.
  void recordCustomerQuotationResponse(
    Booking b, {
    required bool accepted,
    String reason = '',
  }) {
    final action = accepted
        ? 'Customer accepted quotation'
        : 'Customer rejected quotation: ${reason.trim()}';
    _audit('Customer', 'Customer', b.id, action, 'QUOTATION_SENT', b.status);
    _notify(
      'Team Lead',
      accepted ? 'Quotation accepted' : 'Quotation rejected',
      accepted
          ? '${b.id} has been accepted and is ready for allocation.'
          : '${b.id} was rejected. Reason: ${reason.trim()}',
      b.id,
    );
    _notify(
      'Customer Care',
      accepted ? 'Quotation accepted' : 'Quotation rejected',
      accepted
          ? '${b.id} quotation accepted by customer.'
          : '${b.id} quotation rejected. Reason: ${reason.trim()}',
      b.id,
    );
  }

  bool transition(Booking b, String next) {
    const allowed = <String, Set<String>>{
      'ASSIGNED': {'PICKUP_STARTED'}, 'PICKUP_STARTED': {'PATIENT_PICKED_UP'},
      'PATIENT_PICKED_UP': {'IN_TRANSIT'}, 'IN_TRANSIT': {'ARRIVED'},
      'ARRIVED': {'SERVICE_COMPLETED'},
    };
    if (!(allowed[b.status]?.contains(next) ?? false)) return false;
    final previous = b.status; b.status = next;
    if (next == 'SERVICE_COMPLETED') b.invoice = Invoice(id: 'INV-${b.id.replaceAll(RegExp(r'[^0-9]'), '')}', bookingId: b.id, quotationId: b.quotation?.id ?? 'N/A', serviceDetails: '${b.transportModeLabel} • ${b.pickup} → ${b.destination}', total: b.amount, paymentStatus: 'Pending', invoiceDate: DateTime.now().toIso8601String());
    b.tripMilestone = _milestone(next); _audit('Team Lead', 'Team Lead', b.id, 'Trip status changed', previous, next);
    if (next == 'SERVICE_COMPLETED') _releasePrevious(b.id);
    return true;
  }

  void _releasePrevious(String bookingId) {
    for (final r in [...ambulances, ...drivers, ...emts, ...doctors]) {
      if (r.assignedBookingId == bookingId) { r.assignedBookingId = null; r.status = r.type == 'Ambulance' ? 'AVAILABLE' : 'AVAILABLE'; }
    }
  }
  OperationsResource? _find(List<OperationsResource> list, String id) { for (final r in list) { if (r.id == id) return r; } return null; }
  void _audit(String actor, String role, String id, String action, String? previous, String? next) => audit.insert(0, OperationsAuditEntry(actor: actor, role: role, bookingId: id, action: action, previousStatus: previous, newStatus: next));
  void _notify(String role, String title, String message, String bookingId) => notifications.insert(0, OperationsNotification(recipientRole: role, title: title, message: message, bookingId: bookingId));
  String _milestone(String s) => switch (s) { 'PICKUP_STARTED' => 'Ambulance on the way', 'PATIENT_PICKED_UP' => 'Patient onboard', 'IN_TRANSIT' => 'Patient in transit', 'ARRIVED' => 'Arrived at destination', 'SERVICE_COMPLETED' => 'Trip completed', _ => s };
}
