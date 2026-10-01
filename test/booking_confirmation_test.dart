import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/core/models/booking.dart';

void main() {
  test('missing onboard confirmation is treated as unconfirmed', () {
    final booking = Booking(
      id: 'booking-1',
      pickup: 'Pickup',
      destination: 'Hospital',
      date: '',
      time: '',
      ambulanceType: 'Road Ambulance',
      status: 'PATIENT_PICKED_UP',
      patientOnboardConfirmed: null,
      amount: 0,
    );

    expect(booking.patientOnboardConfirmed, isFalse);

    booking.patientOnboardConfirmed = true;

    expect(booking.patientOnboardConfirmed, isTrue);
  });
}
