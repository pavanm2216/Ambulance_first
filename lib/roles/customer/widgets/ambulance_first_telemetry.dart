import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

enum TelemetryState { live, stale, unavailable }

/// Truthful Telemetry Strip and Capsule for active trips.
/// Never fabricates GPS, speed, or ETA.
class AmbulanceFirstTelemetryCapsule extends StatelessWidget {
  const AmbulanceFirstTelemetryCapsule({
    super.key,
    required this.state,
    this.updatedAgo,
    this.customLabel,
  });

  final TelemetryState state;
  final String? updatedAgo;
  final String? customLabel;

  Color get _color {
    switch (state) {
      case TelemetryState.live:
        return AmbulanceFirstColors.telemetryLive;
      case TelemetryState.stale:
        return AmbulanceFirstColors.telemetryStale;
      case TelemetryState.unavailable:
        return AmbulanceFirstColors.telemetryUnavailable;
    }
  }

  String get _title {
    if (customLabel != null) return customLabel!;
    switch (state) {
      case TelemetryState.live:
        return 'LIVE TELEMETRY STREAM';
      case TelemetryState.stale:
        return 'STALE TELEMETRY CACHE';
      case TelemetryState.unavailable:
        return 'LOCATION UNAVAILABLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmbulanceFirstTypography.codeSm(
                      color: AmbulanceFirstColors.onSurface,
                      weight: FontWeight.w700,
                    ).copyWith(fontSize: 10, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          if (updatedAgo != null && updatedAgo!.isNotEmpty)
            Flexible(
              flex: 2,
              child: Text(
                updatedAgo!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AmbulanceFirstTypography.codeSm(
                  color: AmbulanceFirstColors.onSurfaceVariant,
                ).copyWith(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3-Metric Tile Display (ETA, Speed, Assigned Unit)
/// Matches Stitch Customer Dashboard specification.
class AmbulanceFirstMissionTile extends StatelessWidget {
  const AmbulanceFirstMissionTile({
    super.key,
    this.etaMinutes,
    this.speedKmh,
    this.unitName,
    this.isLive = true,
  });

  final int? etaMinutes;
  final double? speedKmh;
  final String? unitName;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
      ),
      child: Row(
        children: [
          // 1. ETA
          Expanded(
            child: Column(
              children: [
                Text(
                  'ETA',
                  style: AmbulanceFirstTypography.labelSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  (etaMinutes != null && etaMinutes! > 0) ? '$etaMinutes MIN' : '—',
                  style: AmbulanceFirstTypography.telemetryNum(
                    color: AmbulanceFirstColors.onSurface,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AmbulanceFirstColors.borderSubtle),

          // 2. Speed
          Expanded(
            child: Column(
              children: [
                Text(
                  'TELEMETRY SPEED',
                  style: AmbulanceFirstTypography.labelSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  (speedKmh != null && speedKmh! > 0) ? '${speedKmh!.toInt()} km/h' : (isLive ? '0 km/h' : '—'),
                  style: AmbulanceFirstTypography.telemetryNum(
                    color: (speedKmh != null && speedKmh! > 0)
                        ? AmbulanceFirstColors.secondary
                        : AmbulanceFirstColors.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AmbulanceFirstColors.borderSubtle),

          // 3. Unit Assigned
          Expanded(
            child: Column(
              children: [
                Text(
                  'UNIT ASSIGNED',
                  style: AmbulanceFirstTypography.labelSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  (unitName != null && unitName!.isNotEmpty) ? unitName! : 'PENDING',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.codeMd(
                    color: AmbulanceFirstColors.onSurface,
                    weight: FontWeight.w700,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
