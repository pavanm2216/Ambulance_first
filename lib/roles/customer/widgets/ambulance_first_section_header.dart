import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Standardized Section Header with optional Count Badge and Action Button
class AmbulanceFirstSectionHeader extends StatelessWidget {
  const AmbulanceFirstSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onActionTap,
    this.icon,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AmbulanceFirstColors.clinicalCobalt),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AmbulanceFirstColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
                  ),
                  child: Text(
                    '$count',
                    style: AmbulanceFirstTypography.codeSm(
                      color: AmbulanceFirstColors.onSurfaceVariant,
                      weight: FontWeight.w700,
                    ).copyWith(fontSize: 10),
                  ),
                ),
              ],
            ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AmbulanceFirstTypography.labelMd(
                        color: AmbulanceFirstColors.clinicalCobalt,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AmbulanceFirstColors.clinicalCobalt,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
