import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Standardized Monospace Booking ID Display Chip.
/// Examples: AMB-2026-001245, BK-9021, TRIP #BK-9018.
class AmbulanceFirstBookingId extends StatelessWidget {
  const AmbulanceFirstBookingId({
    super.key,
    required this.id,
    this.prefix,
    this.fontSize = 13,
    this.color,
    this.isBold = true,
  });

  final String id;
  final String? prefix;
  final double fontSize;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AmbulanceFirstColors.onSurface;
    final formatted = id.toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (prefix != null && prefix!.isNotEmpty) ...[
          Text(
            prefix!.toUpperCase(),
            style: AmbulanceFirstTypography.codeSm(
              color: AmbulanceFirstColors.onSurfaceVariant,
              weight: FontWeight.w600,
            ).copyWith(fontSize: fontSize * 0.85),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            formatted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AmbulanceFirstTypography.codeMd(
              color: effectiveColor,
              weight: isBold ? FontWeight.w700 : FontWeight.w600,
            ).copyWith(
              fontSize: fontSize,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
