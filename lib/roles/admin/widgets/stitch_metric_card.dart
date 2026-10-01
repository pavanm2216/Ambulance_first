import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class StitchMetricCard extends StatelessWidget {
  const StitchMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.badgeText,
    this.badgeColor,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(StitchTheme.spaceMd),
        decoration: BoxDecoration(
          color: StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          border: Border.all(color: StitchTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Title & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StitchTheme.labelSm(
                      color: StitchTheme.onSurfaceVariant,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: StitchTheme.primaryFixed,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: StitchTheme.onPrimaryFixed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Middle: Value
            Text(
              value,
              style: StitchTheme.displayLgMobile(
                color: StitchTheme.onSurface,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Bottom: Subtitle / Trend
            if (subtitle != null)
              subtitle!
            else if (badgeText != null)
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: badgeColor ?? StitchTheme.tertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    badgeText!,
                    style: StitchTheme.labelSm(
                      color: badgeColor ?? StitchTheme.tertiary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class StitchFleetReadinessCard extends StatelessWidget {
  const StitchFleetReadinessCard({
    super.key,
    required this.availableCount,
    required this.totalCount,
    this.onTap,
  });

  final int availableCount;
  final int totalCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = totalCount > 0 ? (availableCount / totalCount) : 0.0;
    final pctInt = (pct * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(StitchTheme.spaceMd),
        decoration: BoxDecoration(
          color: StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          border: Border.all(color: StitchTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLEET AVAILABILITY & READINESS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StitchTheme.labelSm(
                      color: StitchTheme.onSurfaceVariant,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$availableCount',
                          style: StitchTheme.displayLgMobile(
                            color: StitchTheme.onSurface,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' / $totalCount Units',
                          style: StitchTheme.headlineSm(
                            color: StitchTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: StitchTheme.tertiaryFixed,
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            '$pctInt% Ready',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.onTertiaryFixed,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalCount - availableCount} units offline (maintenance, holds, in depot)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StitchTheme.bodySm(color: StitchTheme.outline),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Circular Progress Indicator
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4.5,
                    backgroundColor: StitchTheme.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      StitchTheme.tertiary,
                    ),
                  ),
                  Text(
                    '$pctInt%',
                    style: StitchTheme.labelSm(
                      color: StitchTheme.onSurface,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
