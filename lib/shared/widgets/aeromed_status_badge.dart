import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';

/// A booking/trip status label. Color reinforces meaning but never
/// carries it alone — the text label is always present, and a live
/// status gets an explicit moving dot rather than color alone.
class AeroMedStatusBadge extends StatelessWidget {
  const AeroMedStatusBadge(this.status, {super.key, this.live = false});

  final String status;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues( alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.white.withValues( alpha: 0.58)),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withValues( alpha: 0.07), blurRadius: 8, offset: const Offset(2, 3)),
          BoxShadow(color: AppColors.white.withValues( alpha: 0.75), blurRadius: 7, offset: const Offset(-2, -2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          ],
          Text(
            status,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
