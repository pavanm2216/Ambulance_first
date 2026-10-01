import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Standardized clinical status badge for Ambulance First.
/// Never communicates state using color alone.
class AmbulanceFirstStatusBadge extends StatelessWidget {
  const AmbulanceFirstStatusBadge({
    super.key,
    required this.status,
    this.isPill = true,
    this.compact = false,
  });

  final String status;
  final bool isPill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStatusStyle(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(
          isPill ? AmbulanceFirstSpacing.radiusPill : AmbulanceFirstSpacing.radiusSm,
        ),
        border: Border.all(color: style.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.hasPulse) ...[
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: style.textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (style.icon != null) ...[
            Icon(style.icon, size: compact ? 12 : 14, color: style.textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AmbulanceFirstTypography.codeSm(
                color: style.textColor,
                weight: FontWeight.w700,
              ).copyWith(
                fontSize: compact ? 9 : 10,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusStyle _resolveStatusStyle(String rawStatus) {
    final s = rawStatus.toUpperCase().trim();

    if (s == 'IN_TRANSIT' || s == 'PATIENT_PICKED_UP') {
      return _StatusStyle(
        label: s == 'PATIENT_PICKED_UP' ? 'PATIENT ONBOARD' : 'IN TRANSIT',
        bgColor: AmbulanceFirstColors.secondaryContainer,
        borderColor: AmbulanceFirstColors.secondary,
        textColor: AmbulanceFirstColors.onSecondaryContainer,
        hasPulse: true,
      );
    }

    if (s == 'PICKUP_STARTED') {
      return const _StatusStyle(
        label: 'EN ROUTE TO PICKUP',
        bgColor: AmbulanceFirstColors.primaryFixed,
        borderColor: AmbulanceFirstColors.clinicalCobalt,
        textColor: AmbulanceFirstColors.onPrimaryFixed,
        icon: Icons.directions_run_rounded,
      );
    }

    if (s == 'ASSIGNED' || s == 'DRIVER_ASSIGNED' || s == 'EMT_ASSIGNED' || s == 'DOCTOR_ASSIGNED') {
      return const _StatusStyle(
        label: 'UNIT ASSIGNED',
        bgColor: AmbulanceFirstColors.surfaceContainerHigh,
        borderColor: AmbulanceFirstColors.clinicalCobalt,
        textColor: AmbulanceFirstColors.clinicalCobalt,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    if (s == 'CUSTOMER_ACCEPTED') {
      return const _StatusStyle(
        label: 'QUOTE ACCEPTED',
        bgColor: AmbulanceFirstColors.secondaryFixed,
        borderColor: AmbulanceFirstColors.secondary,
        textColor: AmbulanceFirstColors.onSecondaryFixed,
        icon: Icons.verified_rounded,
      );
    }

    if (s == 'QUOTATION_SENT' || s == 'BUDGET_PENDING') {
      return const _StatusStyle(
        label: 'QUOTE READY',
        bgColor: AmbulanceFirstColors.warningContainer,
        borderColor: AmbulanceFirstColors.warning,
        textColor: AmbulanceFirstColors.onWarning,
        icon: Icons.receipt_long_rounded,
      );
    }

    if (s == 'SENT_TO_TEAM_LEAD' || s == 'ALLOCATION_PENDING') {
      return const _StatusStyle(
        label: 'DISPATCH PLANNING',
        bgColor: AmbulanceFirstColors.surfaceContainer,
        borderColor: AmbulanceFirstColors.outlineVariant,
        textColor: AmbulanceFirstColors.onSurfaceVariant,
        icon: Icons.schedule_rounded,
      );
    }

    if (s == 'VERIFIED' || s == 'CUSTOMER_CARE_CONTACTED') {
      return const _StatusStyle(
        label: 'VERIFIED',
        bgColor: AmbulanceFirstColors.primaryFixed,
        borderColor: AmbulanceFirstColors.clinicalCobalt,
        textColor: AmbulanceFirstColors.clinicalCobalt,
        icon: Icons.verified_user_rounded,
      );
    }

    if (s == 'NEW' || s == 'CUSTOMER_CARE_CONTACT_PENDING') {
      return const _StatusStyle(
        label: 'REQUEST SUBMITTED',
        bgColor: AmbulanceFirstColors.surfaceContainerLow,
        borderColor: AmbulanceFirstColors.outlineVariant,
        textColor: AmbulanceFirstColors.onSurfaceVariant,
        icon: Icons.fiber_new_rounded,
      );
    }

    if (s == 'SERVICE_COMPLETED' || s == 'COMPLETED' || s == 'ARRIVED') {
      return _StatusStyle(
        label: s == 'ARRIVED' ? 'ARRIVED AT DEST' : 'COMPLETED',
        bgColor: AmbulanceFirstColors.secondaryContainer,
        borderColor: AmbulanceFirstColors.secondary,
        textColor: AmbulanceFirstColors.secondary,
        icon: Icons.check_circle_rounded,
      );
    }

    if (s == 'CANCELLED' || s == 'CUSTOMER_REJECTED') {
      return _StatusStyle(
        label: s == 'CUSTOMER_REJECTED' ? 'QUOTE DECLINED' : 'CANCELLED',
        bgColor: AmbulanceFirstColors.errorContainer,
        borderColor: AmbulanceFirstColors.medicalCrimson,
        textColor: AmbulanceFirstColors.medicalCrimson,
        icon: Icons.cancel_rounded,
      );
    }

    if (s == 'CRITICAL') {
      return const _StatusStyle(
        label: 'CRITICAL',
        bgColor: AmbulanceFirstColors.errorContainer,
        borderColor: AmbulanceFirstColors.medicalCrimson,
        textColor: AmbulanceFirstColors.medicalCrimson,
        icon: Icons.warning_amber_rounded,
      );
    }

    return _StatusStyle(
      label: s.replaceAll('_', ' '),
      bgColor: AmbulanceFirstColors.surfaceContainer,
      borderColor: AmbulanceFirstColors.outlineVariant,
      textColor: AmbulanceFirstColors.onSurfaceVariant,
      icon: Icons.info_outline_rounded,
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.icon,
    this.hasPulse = false,
  });

  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
  final bool hasPulse;
}
