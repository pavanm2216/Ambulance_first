import 'package:flutter/material.dart';
import '../theme/team_lead_theme.dart';

class TeamLeadKpiCard extends StatelessWidget {
  const TeamLeadKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.onTap,
    this.subtitle,
    this.accentColor = TeamLeadTheme.primary,
  });

  final String title;
  final String? value;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final displayValue = (value != null && value!.isNotEmpty) ? value! : '—';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: TeamLeadTheme.surfaceLowest,
            borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
            border: Border.all(color: TeamLeadTheme.borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TeamLeadTheme.supportingBody(
                        color: TeamLeadTheme.onSurfaceVariant,
                        weight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayValue,
                    style: TeamLeadTheme.headline(
                      color: TeamLeadTheme.onSurface,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? TeamLeadTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill),
                      ),
                      child: Text(
                        badgeText!,
                        style: TeamLeadTheme.telemetryMicro(
                          color: badgeTextColor ?? TeamLeadTheme.onSurfaceVariant,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TeamLeadTheme.small(
                    color: TeamLeadTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
