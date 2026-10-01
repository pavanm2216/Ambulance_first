import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../theme/team_lead_theme.dart';

class TelemetryBadge extends StatelessWidget {
  const TelemetryBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  final TelemetryState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (state) {
      TelemetryState.live => ('LIVE', TeamLeadTheme.telemetryLive, const Color(0xFFE6F4EA)),
      TelemetryState.stale => ('STALE', TeamLeadTheme.telemetryStale, const Color(0xFFFEF3C7)),
      TelemetryState.unavailable => ('UNAVAILABLE', TeamLeadTheme.telemetryUnavailable, const Color(0xFFFEE2E2)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TeamLeadTheme.telemetryMicro(
              color: color,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TelemetrySummaryStrip extends StatelessWidget {
  const TelemetrySummaryStrip({
    super.key,
    required this.telemetry,
    this.onTapDetails,
  });

  final LiveTelemetry telemetry;
  final VoidCallback? onTapDetails;

  @override
  Widget build(BuildContext context) {
    if (telemetry.isUnavailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TeamLeadTheme.surfaceLow,
          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
          border: Border.all(color: TeamLeadTheme.borderSubtle),
        ),
        child: Row(
          children: [
            const TelemetryBadge(state: TelemetryState.unavailable, compact: true),
            const SizedBox(width: 8),
            Text(
              'Live location unavailable',
              style: TeamLeadTheme.telemetrySecondary(
                color: TeamLeadTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTapDetails,
      borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TeamLeadTheme.surfaceLow,
          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
          border: Border.all(color: TeamLeadTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                TelemetryBadge(state: telemetry.state, compact: true),
                const SizedBox(width: 10),
                Text(
                  telemetry.callsign,
                  style: TeamLeadTheme.telemetryPrimary(
                    color: TeamLeadTheme.primaryDark,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _metricItem('SPEED', '${telemetry.speedKmh} km/h'),
                const SizedBox(width: 14),
                _metricItem('ETA', '${telemetry.etaMinutes} min'),
                const SizedBox(width: 14),
                _metricItem('UPDATE', '${telemetry.lastUpdatedSecondsAgo}s ago'),
                if (onTapDetails != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: TeamLeadTheme.textMuted),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted),
        ),
        Text(
          value,
          style: TeamLeadTheme.telemetrySecondary(
            color: TeamLeadTheme.onSurface,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
