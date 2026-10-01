import '../models/booking.dart';

/// Centralized customer-side workflow coordinator.
///
/// Internal roles are represented as controlled mock transitions; no internal
/// portal is exposed in the Customer app. Every transition mutates the same
/// Booking instance so lists, quotations, active trip, and history stay linked.
class CustomerBookingWorkflowService {
  CustomerBookingWorkflowService._();


















  static List<Booking> forCustomer(
    Iterable<Booking> bookings,
    String customerId,
  ) {
    if (customerId.trim().isEmpty) return const [];
    return bookings.where((booking) => booking.customerId == customerId).toList();
  }
}

extension BookingTransportModeLabel on Booking {
  String get transportModeLabel {
    if (isHomeService || transportMode == 'HOME_SERVICE') {
      return 'Home Service';
    }

    switch (transportMode) {
      case 'RAILWAY_AMBULANCE':
        return 'Railway Ambulance';
      case 'AIR_AMBULANCE':
        return 'Air Ambulance';
      case 'DEAD_BODY_TRANSFER':
        return 'Dead Body Transfer';
      default:
        return 'Road Ambulance';
    }
  }
}
