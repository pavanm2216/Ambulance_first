import 'package:flutter/material.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class KpiQueueCard extends StatelessWidget {
  const KpiQueueCard({
    super.key,
    required this.title,
    required this.count,
    required this.badgeText,
    required this.subtitle,
    required this.accentColor,
    required this.badgeBgColor,
    required this.badgeFgColor,
    this.icon,
    this.hasPulse = false,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String count;
  final String badgeText;
  final String subtitle;
  final Color accentColor;
  final Color badgeBgColor;
  final Color badgeFgColor;
  final IconData? icon;
  final bool hasPulse;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 104,
        decoration: BoxDecoration(
          color: CustomerCareColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : CustomerCareColors.outlineVariant,
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 160;
            final indicator = hasPulse
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  )
                : icon != null
                ? Icon(icon, size: 16, color: accentColor)
                : const SizedBox.shrink();

            final countText = Text(
              count,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                fontSize: 22,
                color: CustomerCareColors.onSurface,
              ),
            );
            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomerCareTextStyles.labelSm.copyWith(
                  color: badgeFgColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  width: double.infinity,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CustomerCareTextStyles.labelSm.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  indicator,
                                ],
                              ),
                              countText,
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: badge,
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: hasPulse
                                      ? accentColor
                                      : CustomerCareColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CustomerCareTextStyles.labelSm.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  indicator,
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  countText,
                                  const SizedBox(width: 8),
                                  Flexible(child: badge),
                                ],
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: hasPulse
                                      ? accentColor
                                      : CustomerCareColors.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
