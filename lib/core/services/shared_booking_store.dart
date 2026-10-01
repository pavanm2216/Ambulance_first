import '../models/booking.dart';

/// Single in-memory operational source of truth shared by Customer, Team Lead, and Driver.
/// All role screens receive references to these same Booking objects.
class SharedBookingStore {
  SharedBookingStore._();

  static final List<Booking> bookings = <Booking>[
    /*
    // --------------------------------------------------------
    // 1. ACTIVE MISSION — STITCH SCREEN MATCH: BK-9018
    // --------------------------------------------------------
    Booking(
      id: 'BK-9018',
      pickup: "Apollo Children's Hospital",
      destination: 'St. Jude Specialized PICU Bay 2',
      date: 'Today',
      time: '14:20',
      ambulanceType: 'Pediatric / Neonatal (PICU/NICU)',
      transportMode: 'ROAD_AMBULANCE',
      status: 'IN_TRANSIT',
      amount: 12500,
      customerName: _customerName,
      mobileNumber: _customerPhone,
      email: _customerEmail,
      patientName: 'Baby Leo K.',
      patientAge: 0,
      patientGender: 'Male',
      relationshipToPatient: 'Primary Parent: Sarah K.',
      currentCondition: 'Critical Pediatric Transfer - Neonatal Distress',
      pediatricPatient: true,
      icuRequired: true,
      ventilatorRequired: true,
      oxygenRequired: true,
      cardiacMonitorRequired: true,
      doctorRequired: true,
      doctorName: 'Dr. S. Mehta',
      doctorSpecialization: 'Pediatric Intensivist',
      emtRequired: true,
      emtName: 'D. Nair (Paramedic)',
      driverName: 'Ramesh Patel',
      driverPhone: '+91 98220 11928',
      vehicleNumber: 'MH-02-EE-4491',
      etaMinutes: 14,
      distanceKm: 18,
      driverSpeedKmh: 48,
      driverLocationSharing: true,
      tripMilestone: 'Patient onboard • Transiting with active PICU protocol',
      priority: 'CRITICAL',
      vitals: const [
        VitalSign(
          time: '14:25',
          heartRate: 138,
          spo2: 97,
          bp: '82/50',
          respiratoryRate: 36,
          temperature: 36.8,
          oxygenFlowLpm: 3.0,
          clinicalNotes: 'Neonatal vitals stable under transport ventilator',
          recordedBy: 'Dr. S. Mehta',
        ),
      ],
    ),

    // --------------------------------------------------------
    // 2. PENDING QUOTATION — STITCH SCREEN MATCH: BK-9021 / QT-2024-8841
    // --------------------------------------------------------
    Booking(
      id: 'BK-9021',
      pickup: 'City General Hosp.',
      destination: 'St. Jude Med Center',
      date: 'Today',
      time: '15:45',
      ambulanceType: 'Advanced Life Support (ALS)',
      transportMode: 'ROAD_AMBULANCE',
      status: 'QUOTATION_SENT',
      amount: 8450,
      customerName: _customerName,
      mobileNumber: _customerPhone,
      email: _customerEmail,
      patientName: 'Elena Vance',
      patientAge: 72,
      patientGender: 'Female',
      relationshipToPatient: 'Daughter / Clinical Guardian',
      currentCondition: 'Cardiac Monitoring Required',
      priority: 'URGENT',
      cardiacMonitorRequired: true,
      oxygenRequired: true,
      icuRequired: false,
      ventilatorRequired: false,
      emtRequired: true,
      distanceKm: 14,
      etaMinutes: 20,
      tripMilestone: 'Quotation sent • Awaiting customer authorization',
      quotation: Quotation(
        id: 'QT-2024-8841',
        status: 'SENT',
        baseAmbulanceCharge: 4500,
        distanceCharge: 1200,
        doctorCharge: 0,
        emtCharge: 1200,
        oxygenCharge: 600,
        icuCharge: 0,
        ventilatorCharge: 0,
        equipmentCharge: 500,
        attendantCharge: 0,
        additionalCharges: 150,
        discount: 0,
        taxPercent: 5.0,
        paymentTerms: 'Payment due on delivery or insurance copay',
        validUntil: 'Today, 18:00 (Expires 42m)',
        notes: 'Includes ALS grade equipment, multi-parameter cardiac monitor, and dedicated paramedic attendant.',
      ),
    ),

    // --------------------------------------------------------
    // 3. RECENT COMPLETED — STITCH SCREEN MATCH: BK-9015
    // --------------------------------------------------------
    Booking(
      id: 'BK-9015',
      pickup: 'Victoria Heights, Res 402',
      destination: 'St. Jude Nephrology Pavilion',
      date: 'Yesterday',
      time: '18:30',
      ambulanceType: 'Basic Life Support (BLS)',
      transportMode: 'ROAD_AMBULANCE',
      status: 'SERVICE_COMPLETED',
      amount: 3200,
      customerName: _customerName,
      mobileNumber: _customerPhone,
      email: _customerEmail,
      patientName: 'Marcus Vance',
      patientAge: 58,
      patientGender: 'Male',
      relationshipToPatient: 'Self',
      currentCondition: 'Scheduled Dialysis Routine Transfer',
      wheelchairRequired: true,
      oxygenRequired: false,
      vehicleNumber: 'KA-01-EA-1055',
      driverName: 'Suresh Gowda',
      distanceKm: 8,
      tripMilestone: 'Trip completed safely and signed off',
      invoice: Invoice(
        id: 'INV-2026-9015',
        bookingId: 'BK-9015',
        quotationId: 'QT-2026-9015',
        serviceDetails: 'BLS Non-Emergency Transfer • Dialysis Routine',
        total: 3200,
        paymentStatus: 'Paid',
        invoiceDate: 'Yesterday, 19:15',
      ),
    ),

    // --------------------------------------------------------
    // 4. RECENT COMPLETED (CRITICAL) — STITCH SCREEN MATCH: BK-9012
    // --------------------------------------------------------
    Booking(
      id: 'BK-9012',
      pickup: 'Fortis Memorial Hospital ICU',
      destination: 'St. Jude Critical Care Institute',
      date: '14 Oct',
      time: '09:15',
      ambulanceType: 'Advanced Life Support (ALS)',
      transportMode: 'ROAD_AMBULANCE',
      status: 'SERVICE_COMPLETED',
      amount: 14800,
      customerName: _customerName,
      mobileNumber: _customerPhone,
      email: _customerEmail,
      patientName: 'Sophia Chen',
      patientAge: 34,
      patientGender: 'Female',
      relationshipToPatient: 'Clinical Desk Handoff',
      currentCondition: 'Inter-Hospital Ventilator Transit',
      priority: 'CRITICAL',
      icuRequired: true,
      ventilatorRequired: true,
      doctorRequired: true,
      doctorName: 'Dr. Kabir Roy',
      emtRequired: true,
      emtName: 'P. Sharma',
      vehicleNumber: 'KA-01-EA-1010',
      driverName: 'M. Qureshi',
      distanceKm: 26,
      tripMilestone: 'Critical transfer completed without incident',
      invoice: Invoice(
        id: 'INV-2026-9012',
        bookingId: 'BK-9012',
        quotationId: 'QT-2026-9012',
        serviceDetails: 'ICU Critical Care Transit with Mobile Ventilator',
        total: 14800,
        paymentStatus: 'Paid',
        invoiceDate: '14 Oct, 11:30',
      ),
    ),

    // --------------------------------------------------------
    // 5. ADDITIONAL ACTIVE TRIP — AMB-2026-1048
    // --------------------------------------------------------
    Booking(
      id: 'AMB-2026-1048',
      pickup: 'Koramangala 4th Block, Bengaluru',
      destination: 'Manipal Hospital, Old Airport Road',
      date: '13 Sep 2026',
      time: '2:30 PM',
      ambulanceType: 'Advanced Life Support (ALS)',
      transportMode: 'ROAD_AMBULANCE',
      status: 'IN_TRANSIT',
      amount: 2450,
      customerName: _customerName,
      mobileNumber: _customerPhone,
      email: _customerEmail,
      patientName: 'Kushal Kumar',
      patientAge: 42,
      patientGender: 'Male',
      currentCondition: 'Chest discomfort • Pre-cardiac observation',
      emtRequired: true,
      stretcherRequired: true,
      vehicleNumber: 'KA-01-AB-1234',
      driverName: 'Rajesh Kumar',
      driverPhone: '+91 98765 43210',
      emtName: 'Arun',
      etaMinutes: 12,
      distanceKm: 15,
      driverSpeedKmh: 54,
      driverLocationSharing: true,
      tripMilestone: 'Patient picked up • en route to hospital',
      vitals: const [
        VitalSign(
          time: '14:42',
          heartRate: 86,
          spo2: 98,
          bp: '124/78',
          respiratoryRate: 17,
          temperature: 36.7,
        ),
      ],
    ),
    */
  ];

  static void replaceAll(Iterable<Booking> values) {
    bookings
      ..clear()
      ..addAll(values);
  }

  static void upsert(Booking booking) {
    final index = bookings.indexWhere((item) => item.id == booking.id);
    if (index >= 0) {
      bookings[index] = booking;
    } else {
      bookings.insert(0, booking);
    }
  }

  static void add(Booking booking) {
    bookings.insert(0, booking);
  }

  static Booking? byId(String id) {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  static void updateDriverLocation({
    required String bookingId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
    required double latitude,
    required double longitude,
    required double speedKmh,
    required double heading,
    required double accuracyMeters,
    required DateTime updatedAt,
  }) {
    final booking = byId(bookingId);
    if (booking == null) return;

    booking.driverName = driverName;
    booking.driverPhone = driverPhone;
    booking.vehicleNumber = vehicleNumber;
    booking.driverLatitude = latitude;
    booking.driverLongitude = longitude;
    booking.driverSpeedKmh = speedKmh;
    booking.driverHeading = heading;
    booking.driverLocationAccuracyMeters = accuracyMeters;
    booking.driverLocationUpdatedAt = updatedAt;
    booking.driverLocationSharing = true;
  }

  static void stopDriverLocation(String bookingId) {
    final booking = byId(bookingId);
    if (booking == null) return;
    booking.driverLocationSharing = false;
  }
}
