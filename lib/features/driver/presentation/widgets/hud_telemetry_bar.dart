import 'package:flutter/material.dart';

import '../../../../core/services/route_telemetry_service.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

enum TelemetryFreshness { live, stale, unavailable }

class HudTelemetryBar extends StatelessWidget {
  const HudTelemetryBar({
    super.key,
    required this.speedKmh,
    required this.etaMinutes,
    required this.remainingKm,
    this.heading = 0,
    this.gpsAccuracyMeters = 0,
    this.freshness = TelemetryFreshness.live,
    this.networkStatus = 'GPS STATUS UNAVAILABLE',
  });

  final double speedKmh;
  final int? etaMinutes;
  final double? remainingKm;
  final double heading;
  final double gpsAccuracyMeters;
  final TelemetryFreshness freshness;
  final String networkStatus;

  String get _compassHeading {
    if (heading >= 337.5 || heading < 22.5) {
      return '${heading.toStringAsFixed(0)}° N';
    }
    if (heading >= 22.5 && heading < 67.5) {
      return '${heading.toStringAsFixed(0)}° NE';
    }
    if (heading >= 67.5 && heading < 112.5) {
      return '${heading.toStringAsFixed(0)}° E';
    }
    if (heading >= 112.5 && heading < 157.5) {
      return '${heading.toStringAsFixed(0)}° SE';
    }
    if (heading >= 157.5 && heading < 202.5) {
      return '${heading.toStringAsFixed(0)}° S';
    }
    if (heading >= 202.5 && heading < 247.5) {
      return '${heading.toStringAsFixed(0)}° SW';
    }
    if (heading >= 247.5 && heading < 292.5) {
      return '${heading.toStringAsFixed(0)}° WNW';
    }
    return '${heading.toStringAsFixed(0)}° NW';
  }

  Color get _freshnessColor {
    switch (freshness) {
      case TelemetryFreshness.live:
        return DriverColors.liveTelemetry;
      case TelemetryFreshness.stale:
        return DriverColors.staleTelemetry;
      case TelemetryFreshness.unavailable:
        return DriverColors.unavailableTelemetry;
    }
  }

  String get _freshnessLabel {
    switch (freshness) {
      case TelemetryFreshness.live:
        return 'LIVE TELEMETRY';
      case TelemetryFreshness.stale:
        return 'TELEMETRY STALE';
      case TelemetryFreshness.unavailable:
        return 'TELEMETRY UNAVAILABLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRemainingKm = remainingKm;
    final displayedEtaMinutes =
        etaMinutes == null ||
            (etaMinutes! <= 0 &&
                currentRemainingKm != null &&
                currentRemainingKm > 0.05)
        ? currentRemainingKm != null && currentRemainingKm > 0.05
              ? RouteTelemetryService.etaMinutes(
                  distanceKm: currentRemainingKm,
                  speedKmh: speedKmh,
                )
              : etaMinutes
        : etaMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DriverColors.inverseSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.hudBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top 3-metric Telemetry HUD grid
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: 'VELOCITY',
                  value: freshness == TelemetryFreshness.unavailable
                      ? '--'
                      : speedKmh.toStringAsFixed(0),
                  unit: 'KM/H',
                  color: DriverColors.secondaryFixed,
                ),
              ),
              Container(width: 1, height: 42, color: DriverColors.hudBorder),
              Expanded(
                child: _MetricCell(
                  label: 'EST. ARRIVAL',
                  value: freshness == TelemetryFreshness.unavailable
                      ? '--'
                      : displayedEtaMinutes?.toString() ?? '--',
                  unit: 'MIN',
                  color: DriverColors.primaryFixed,
                ),
              ),
              Container(width: 1, height: 42, color: DriverColors.hudBorder),
              Expanded(
                child: _MetricCell(
                  label: 'REMAINING',
                  value: freshness == TelemetryFreshness.unavailable
                      ? '--'
                      : remainingKm?.toStringAsFixed(1) ?? '--',
                  unit: 'KM',
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: DriverColors.hudBorder, height: 1),
          const SizedBox(height: 12),
          // Operational GPS fix & Freshness Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _freshnessColor,
                      boxShadow: [
                        BoxShadow(
                          color: _freshnessColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _freshnessLabel,
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: _freshnessColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.navigation_outlined,
                    size: 12,
                    color: DriverColors.primaryFixedDim,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _compassHeading,
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: DriverColors.inverseOnSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GPS ±${gpsAccuracyMeters.toStringAsFixed(1)}M',
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: DriverColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: DriverTextStyles.telemetryMicro.copyWith(
            color: DriverColors.outlineVariant,
            letterSpacing: 0.8,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: DriverTextStyles.telemetryLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: DriverTextStyles.telemetryMicro.copyWith(
                color: DriverColors.outlineVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
