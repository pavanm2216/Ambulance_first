import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/admin_theme.dart';

class StitchStatusBadge extends StatelessWidget {
  const StitchStatusBadge({
    super.key,
    required this.statusText,
    this.hasPulse = false,
    this.isCompact = false,
  });

  final String statusText;
  final bool hasPulse;
  final bool isCompact;

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  factory StitchStatusBadge.fromBooking(
    BookingStatus status,
  ) {
    switch (status) {
      // --------------------------------------------------------
      // NEW
      // --------------------------------------------------------

      case BookingStatus.newBooking:
        return const StitchStatusBadge(
          statusText: 'NEW',
        );

      // --------------------------------------------------------
      // CUSTOMER CARE
      // --------------------------------------------------------

      case BookingStatus.customerCareContactPending:
        return const StitchStatusBadge(
          statusText: 'CC_CONTACT_PENDING',
          hasPulse: true,
        );

      case BookingStatus.customerCareContacted:
        return const StitchStatusBadge(
          statusText: 'CC_CONTACTED',
        );

      // --------------------------------------------------------
      // VERIFICATION
      // --------------------------------------------------------

      case BookingStatus.verificationPending:
        return const StitchStatusBadge(
          statusText: 'VERIFICATION_PENDING',
          hasPulse: true,
        );

      case BookingStatus.verified:
        return const StitchStatusBadge(
          statusText: 'VERIFIED',
        );

      // --------------------------------------------------------
      // TEAM LEAD / ALLOCATION
      // --------------------------------------------------------

      case BookingStatus.sentToTeamLead:
        return const StitchStatusBadge(
          statusText: 'SENT_TO_TEAM_LEAD',
        );

      case BookingStatus.allocationPending:
        return const StitchStatusBadge(
          statusText: 'ALLOCATION_PENDING',
          hasPulse: true,
        );

      // --------------------------------------------------------
      // QUOTATION
      // --------------------------------------------------------

      case BookingStatus.quotationSent:
        return const StitchStatusBadge(
          statusText: 'QUOTATION',
        );

      case BookingStatus.customerAccepted:
        return const StitchStatusBadge(
          statusText: 'CUSTOMER_ACCEPTED',
        );

      case BookingStatus.customerRejected:
        return const StitchStatusBadge(
          statusText: 'CUSTOMER_REJECTED',
        );

      // --------------------------------------------------------
      // ASSIGNMENT
      // --------------------------------------------------------

      case BookingStatus.assigned:
        return const StitchStatusBadge(
          statusText: 'ASSIGNED',
        );

      case BookingStatus.driverAssigned:
        return const StitchStatusBadge(
          statusText: 'DRIVER_ASSIGNED',
          hasPulse: true,
        );

      // --------------------------------------------------------
      // TRIP
      // --------------------------------------------------------

      case BookingStatus.pickupStarted:
        return const StitchStatusBadge(
          statusText: 'PICKUP_STARTED',
          hasPulse: true,
        );

      case BookingStatus.patientPickedUp:
        return const StitchStatusBadge(
          statusText: 'PATIENT_PICKED_UP',
          hasPulse: true,
        );

      case BookingStatus.inTransit:
        return const StitchStatusBadge(
          statusText: 'IN_TRANSIT · P1',
          hasPulse: true,
        );

      case BookingStatus.arrived:
        return const StitchStatusBadge(
          statusText: 'ARRIVED',
        );

      // --------------------------------------------------------
      // COMPLETION
      // --------------------------------------------------------

      case BookingStatus.serviceCompleted:
        return const StitchStatusBadge(
          statusText: 'COMPLETED',
        );

      case BookingStatus.invoiceGenerated:
        return const StitchStatusBadge(
          statusText: 'INVOICE_GENERATED',
        );

      case BookingStatus.completed:
        return const StitchStatusBadge(
          statusText: 'COMPLETED',
        );

      // --------------------------------------------------------
      // CANCEL / REJECT
      // --------------------------------------------------------

      case BookingStatus.cancelled:
        return const StitchStatusBadge(
          statusText: 'CANCELLED',
        );

      case BookingStatus.driverRejected:
        return const StitchStatusBadge(
          statusText: 'DRIVER_REJECTED',
        );
    }
  }

  // ============================================================
  // FLEET STATUS
  // ============================================================

  factory StitchStatusBadge.fromFleet(
    FleetStatus status,
  ) {
    switch (status) {
      case FleetStatus.available:
        return const StitchStatusBadge(
          statusText: 'AVAILABLE',
        );

      case FleetStatus.activeMission:
        return const StitchStatusBadge(
          statusText: 'ACTIVE MISSION',
          hasPulse: true,
        );

      case FleetStatus.inTransit:
        return const StitchStatusBadge(
          statusText: 'IN_TRANSIT',
          hasPulse: true,
        );

      case FleetStatus.assigned:
        return const StitchStatusBadge(
          statusText: 'ASSIGNED',
        );

      case FleetStatus.maintenance:
        return const StitchStatusBadge(
          statusText: 'MAINTENANCE',
        );

      case FleetStatus.outOfService:
        return const StitchStatusBadge(
          statusText: 'OUT OF SERVICE',
        );
    }
  }

  // ============================================================
  // STAFF STATUS
  // ============================================================

  factory StitchStatusBadge.fromStaff(
    StaffStatus status,
  ) {
    switch (status) {
      case StaffStatus.available:
        return const StitchStatusBadge(
          statusText: 'AVAILABLE',
        );

      case StaffStatus.assigned:
        return const StitchStatusBadge(
          statusText: 'ASSIGNED',
        );

      case StaffStatus.busy:
        return const StitchStatusBadge(
          statusText: 'BUSY',
          hasPulse: true,
        );

      case StaffStatus.suspended:
        return const StitchStatusBadge(
          statusText: 'SUSPENDED',
        );

      case StaffStatus.inactive:
        return const StitchStatusBadge(
          statusText: 'INACTIVE',
        );

      case StaffStatus.offDuty:
        return const StitchStatusBadge(
          statusText: 'OFF_DUTY',
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final clean = statusText.toUpperCase();

    Color bg;
    Color fg;
    Color? dotColor;

    // ----------------------------------------------------------
    // CRITICAL / IN TRANSIT / REJECTED
    // ----------------------------------------------------------

    if (clean.contains('CRITICAL') ||
        clean.contains('CODE-3') ||
        clean.contains('IN_TRANSIT') ||
        clean.contains('REJECTED') ||
        clean.contains('CANCELLED')) {
      bg = StitchTheme.errorContainer;
      fg = StitchTheme.onErrorContainer;
      dotColor = StitchTheme.error;
    }

    // ----------------------------------------------------------
    // ACTIVE
    // ----------------------------------------------------------

    else if (clean.contains('ACTIVE') ||
        clean.contains('ASSIGNED') ||
        clean.contains('PICKUP') ||
        clean.contains('PATIENT_PICKED_UP') ||
        clean.contains('DRIVER_ASSIGNED')) {
      bg = StitchTheme.surfaceContainerHigh;
      fg = StitchTheme.primaryContainer;
      dotColor = StitchTheme.primaryContainer;
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    else if (clean.contains('AVAILABLE') ||
        clean.contains('COMPLETED') ||
        clean.contains('PAID') ||
        clean.contains('ACCEPTED') ||
        clean.contains('ARRIVED') ||
        clean == 'VERIFIED') {
      bg = StitchTheme.tertiaryFixed.withValues(
        alpha: 0.6,
      );
      fg = StitchTheme.tertiary;
      dotColor = StitchTheme.tertiary;
    }

    // ----------------------------------------------------------
    // PENDING
    // ----------------------------------------------------------

    else if (clean.contains('MAINTENANCE') ||
        clean.contains('PENDING') ||
        clean.contains('CONTACT') ||
        clean.contains('VERIFICATION') ||
        clean.contains('ALLOCATION') ||
        clean.contains('QUOTATION')) {
      bg = StitchTheme.secondaryContainer;
      fg = StitchTheme.onSecondaryContainer;
      dotColor = StitchTheme.secondary;
    }

    // ----------------------------------------------------------
    // SUSPENDED / INACTIVE
    // ----------------------------------------------------------

    else if (clean.contains('SUSPENDED') ||
        clean.contains('INACTIVE') ||
        clean.contains('OFF_DUTY')) {
      bg = StitchTheme.errorContainer;
      fg = StitchTheme.onErrorContainer;
    }

    // ----------------------------------------------------------
    // DEFAULT
    // ----------------------------------------------------------

    else {
      bg = StitchTheme.surfaceContainer;
      fg = StitchTheme.onSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          StitchTheme.radiusSm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],

          Text(
            statusText,
            style: StitchTheme.labelSm(
              color: fg,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}