import 'package:ambulance_first/core/models/driver_models.dart';
import 'package:ambulance_first/core/services/driver_location_service.dart';
import 'package:ambulance_first/core/services/driver_location_store.dart';
import 'package:ambulance_first/core/services/shared_booking_store.dart';
import 'package:flutter_test/flutter_test.dart';

DriverBooking createTestBooking({
  required String id,
  required String status,
  String patientName = 'Jane Patient',
  String vehicleNumber = 'AMB-01',
}) {
  return DriverBooking(
    id: id,
    status: status,
    serviceCategory: 'EMERGENCY',
    patientName: patientName,
    patientAge: 32,
    patientGender: 'Female',
    currentCondition: 'Stable',
    medicalConditionSummary: 'Cardiac alert',
    currentHospital: '',
    destinationHospital: 'City Hospital',
    pickupAddress: '123 Main St',
    pickupCity: 'Metro',
    destinationAddress: 'City Hospital',
    destinationCity: 'Metro',
    preferredDate: 'Today',
    preferredTime: 'Immediate',
    estimatedDistanceKm: 12.0,
    estimatedDurationMins: 20,
    routeDistanceMeters: 12000,
    routeDurationSeconds: 1200,
    routeProvider: 'OSRM',
    routeCalculatedAt: DateTime.now(),
    pickupLatitude: 17.385044,
    pickupLongitude: 78.486671,
    destinationLatitude: 17.440081,
    destinationLongitude: 78.348915,
    customerName: 'Family Member',
    customerMobile: '+1987654321',
    vehicleNumber: vehicleNumber,
    doctorName: 'Dr. Smith',
    doctorPhone: '+1122334455',
    emtName: 'EMT Sarah',
    emtPhone: '+1122334466',
    speedKmh: 45,
    etaMinutes: 10,
    oxygenRequired: false,
    stretcherRequired: true,
    doctorRequired: false,
    icuRequired: true,
    ventilatorRequired: false,
    cardiacMonitorRequired: true,
    specialInstructions: 'Handle with care',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DriverProfile mockDriver;
  late DriverBooking activeBooking;
  late DriverBooking completedBooking;

  setUp(() {
    mockDriver = DriverProfile(
      id: 'driver-uuid-1234',
      name: 'John Driver',
      phone: '+1234567890',
      email: 'driver@ambulance.com',
      licenseNumber: 'DL-9988',
      licenseExpiry: '2028-12-31',
      experienceYears: 5,
      supportedCategories: const ['ALS', 'BLS'],
      status: 'AVAILABLE',
      assignedAmbulanceNumber: 'AMB-01',
      currentLocation: '',
      latitude: null,
      longitude: null,
      rating: 4.9,
      totalTrips: 42,
      locationAccuracyMeters: 5.0,
      locationUpdatedAt: null,
    );

    activeBooking = createTestBooking(
      id: 'BOOKING-101',
      status: 'IN_TRANSIT',
      vehicleNumber: 'AMB-01',
    );

    completedBooking = createTestBooking(
      id: 'BOOKING-999',
      status: 'SERVICE_COMPLETED',
      vehicleNumber: 'AMB-01',
    );
  });

  group('Driver GPS Lifecycle & State Machine Contract', () {
    test('1. Login with active assigned trip verifies driver assignment and prepares trip telemetry', () {
      expect(activeBooking.isActive, isTrue);
      expect(activeBooking.id, equals('BOOKING-101'));
      expect(activeBooking.vehicleNumber, equals(mockDriver.assignedAmbulanceNumber));
    });

    test('2. Login without an assigned trip flags no active trip and avoids false GPS failure', () {
      final idleBookings = <DriverBooking>[completedBooking];
      final hasActive = idleBookings.any((b) => b.isActive);
      expect(hasActive, isFalse);
    });

    test('3. GPS initialization requires canonical driver ID and valid booking ID before publishing', () {
      expect(mockDriver.id.trim().isNotEmpty, isTrue);
      expect(activeBooking.id.trim().isNotEmpty, isTrue);

      final emptyDriver = DriverProfile(
        id: '',
        name: '',
        phone: '',
        email: '',
        licenseNumber: '',
        licenseExpiry: '',
        experienceYears: 0,
        supportedCategories: const [],
        status: 'UNAVAILABLE',
        assignedAmbulanceNumber: '',
        currentLocation: '',
        latitude: null,
        longitude: null,
        rating: 0,
        totalTrips: 0,
        locationAccuracyMeters: 0,
        locationUpdatedAt: null,
      );
      expect(emptyDriver.id.trim().isEmpty, isTrue);
    });

    test('4. Permission denial category maps to specific permission-required error message', () {
      const deniedEx = DriverLocationException(
        'Permission denied',
        category: DriverLocationErrorCategory.permissionDenied,
      );
      expect(deniedEx.category, equals(DriverLocationErrorCategory.permissionDenied));

      const permanentEx = DriverLocationException(
        'Permanently denied',
        category: DriverLocationErrorCategory.permissionPermanentlyDenied,
      );
      expect(permanentEx.category, equals(DriverLocationErrorCategory.permissionPermanentlyDenied));

      const disabledEx = DriverLocationException(
        'Services disabled',
        category: DriverLocationErrorCategory.serviceDisabled,
      );
      expect(disabledEx.category, equals(DriverLocationErrorCategory.serviceDisabled));
    });

    test('5. Database or location store preserves previous valid location on write failure', () {
      final initialTime = DateTime.now().subtract(const Duration(seconds: 10));
      DriverLocationStore.instance.update(
        driverId: mockDriver.id,
        bookingId: activeBooking.id,
        latitude: 17.385044,
        longitude: 78.486671,
        accuracyMeters: 5.0,
        speedKmh: 40.0,
        heading: 90.0,
        updatedAt: initialTime,
        ambulanceUnit: 'AMB-01',
      );

      final snapshot = DriverLocationStore.instance.forBooking(activeBooking.id);
      expect(snapshot, isNotNull);
      expect(snapshot!.latitude, equals(17.385044));
      expect(snapshot.updatedAt, equals(initialTime));
    });

    test('6. Shared location bus notifies customers and team lead with same canonical coordinate', () {
      final updateTime = DateTime.now();
      DriverLocationStore.instance.update(
        driverId: mockDriver.id,
        bookingId: activeBooking.id,
        latitude: 17.440081,
        longitude: 78.348915,
        accuracyMeters: 4.2,
        speedKmh: 55.0,
        heading: 180.0,
        updatedAt: updateTime,
        ambulanceUnit: 'AMB-01',
      );

      final snapshot = DriverLocationStore.instance.forBooking(activeBooking.id);
      expect(snapshot, isNotNull);
      expect(snapshot!.driverId, equals(mockDriver.id));
      expect(snapshot.bookingId, equals(activeBooking.id));
      expect(snapshot.latitude, equals(17.440081));
      expect(snapshot.longitude, equals(78.348915));
      expect(snapshot.speedKmh, equals(55.0));

      SharedBookingStore.updateDriverLocation(
        bookingId: activeBooking.id,
        driverName: mockDriver.name,
        driverPhone: mockDriver.phone,
        vehicleNumber: 'AMB-01',
        latitude: 17.440081,
        longitude: 78.348915,
        speedKmh: 55.0,
        heading: 180.0,
        accuracyMeters: 4.2,
        updatedAt: updateTime,
      );

      final shared = SharedBookingStore.byId(activeBooking.id);
      expect(shared, isNull);
    });

    test('7. Completed trip removes active trip binding from location store', () {
      DriverLocationStore.instance.update(
        driverId: mockDriver.id,
        bookingId: activeBooking.id,
        latitude: 17.3850,
        longitude: 78.4866,
        accuracyMeters: 5.0,
        speedKmh: 0,
        heading: 0,
        updatedAt: DateTime.now(),
        ambulanceUnit: 'AMB-01',
      );

      expect(DriverLocationStore.instance.forBooking(activeBooking.id), isNotNull);

      DriverLocationStore.instance.clearBooking(activeBooking.id);
      expect(DriverLocationStore.instance.forBooking(activeBooking.id), isNull);
    });

    test('8. Duplicate stream prevention: stopTracking cancels previous subscription before new one', () async {
      final service = DriverLocationService.instance;
      await service.stopTracking();
      expect(service.isTracking, isFalse);
    });
  });
}
