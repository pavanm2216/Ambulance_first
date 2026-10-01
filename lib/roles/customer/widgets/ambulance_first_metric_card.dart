import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_card.dart';

/// KPI Queue Summary Metric Card matching Stitch screen 43005bdd0c6d425dad1d065abddfcca2.
class AmbulanceFirstMetricCard extends StatelessWidget {
  const AmbulanceFirstMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.valueColor,
    this.subtitleColor,
    this.iconColor,
    this.iconBgColor,
    this.hasPulse = false,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? valueColor;
  final Color? subtitleColor;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool hasPulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AmbulanceFirstCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Title + Icon Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.labelSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? AmbulanceFirstColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: iconColor ?? AmbulanceFirstColors.onSurfaceVariant,
                    ),
                  ),
                  if (hasPulse)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AmbulanceFirstColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Area: Telemetry Number + Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.telemetryNum(
                  color: valueColor ?? AmbulanceFirstColors.onSurface,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.bodySm(
                  color: subtitleColor ?? AmbulanceFirstColors.onSurfaceVariant,
                ).copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
