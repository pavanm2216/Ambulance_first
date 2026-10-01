import 'package:flutter/material.dart';
import '../theme/team_lead_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.isPill = true,
    this.fontSize = 11,
  });

  final String status;
  final String? customLabel;
  final bool isPill;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStatusStyle(status);
    final label = customLabel ?? _formatStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPill ? 10 : 8,
        vertical: isPill ? 3 : 2,
      ),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(isPill ? TeamLeadTheme.radiusPill : TeamLeadTheme.radiusSm),
        border: Border.all(color: style.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TeamLeadTheme.telemetrySecondary(
              color: style.textColor,
              weight: FontWeight.w600,
            ).copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String s) {
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  _StatusColors _resolveStatusStyle(String s) {
    final normalized = s.toUpperCase().trim();

    // Critical / Code Red
    if (normalized == 'CRITICAL' ||
        normalized == 'EMERGENCY' ||
        normalized == 'CODE_RED' ||
        normalized == 'REJECTED' ||
        normalized == 'CUSTOMER_REJECTED' ||
        normalized == 'CANCELLED') {
      return const _StatusColors(
        bgColor: Color(0xFFFEE2E2),
        borderColor: Color(0xFFEF4444),
        textColor: Color(0xFF991B1B),
        dotColor: Color(0xFFDC2626),
      );
    }

    // Urgent / Warning / Pending Allocation / Waiting
    if (normalized == 'SENT_TO_TEAM_LEAD' ||
        normalized == 'ALLOCATION_PENDING' ||
        normalized == 'BUDGET_PENDING' ||
        normalized == 'QUOTATION_SENT' ||
        normalized == 'PENDING' ||
        normalized == 'DELAYED') {
      return const _StatusColors(
        bgColor: Color(0xFFFEF3C7),
        borderColor: Color(0xFFF59E0B),
        textColor: Color(0xFF92400E),
        dotColor: Color(0xFFD97706),
      );
    }

    // Ready / Verified / Available / Accepted
    if (normalized == 'CUSTOMER_ACCEPTED' ||
        normalized == 'VERIFIED' ||
        normalized == 'AVAILABLE' ||
        normalized == 'READY' ||
        normalized == 'ON_CALL' ||
        normalized == 'SERVICE_COMPLETED' ||
        normalized == 'COMPLETED') {
      return const _StatusColors(
        bgColor: Color(0xFFE6F4EA),
        borderColor: Color(0xFF34D399),
        textColor: Color(0xFF065F46),
        dotColor: Color(0xFF006C4A),
      );
    }

    // In Transit / Active / Assigned
    if (normalized == 'ASSIGNED' ||
        normalized == 'DRIVER_ASSIGNED' ||
        normalized == 'PICKUP_STARTED' ||
        normalized == 'PATIENT_PICKED_UP' ||
        normalized == 'IN_TRANSIT' ||
        normalized == 'ON_TRIP' ||
        normalized == 'ARRIVED') {
      return const _StatusColors(
        bgColor: Color(0xFFE0F2FE),
        borderColor: Color(0xFF38BDF8),
        textColor: Color(0xFF075985),
        dotColor: Color(0xFF0284C7),
      );
    }

    // Maintenance / Offline / Off Duty
    return const _StatusColors(
      bgColor: Color(0xFFF1F5F9),
      borderColor: Color(0xFF94A3B8),
      textColor: Color(0xFF475569),
      dotColor: Color(0xFF64748B),
    );
  }
}

class _StatusColors {
  const _StatusColors({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });

  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;
}
