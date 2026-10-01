import 'package:flutter/material.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class LiveGpsTelemetryDialog extends StatelessWidget {
  const LiveGpsTelemetryDialog({
    super.key,
    required this.caseItem,
  });

  final CustomerCareCase caseItem;

  @override
  Widget build(BuildContext context) {
    final hasTelemetry = caseItem.liveSpeedKmh > 0 ||
      caseItem.currentTelemetryLocation.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: CustomerCareColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: CustomerCareColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Live CAD & GPS Telemetry',
                        style: CustomerCareTextStyles.headlineSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identifier + Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${caseItem.id}',
                        style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                          fontSize: 16,
                          color: CustomerCareColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          caseItem.statusLabel.toUpperCase(),
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.onSecondaryFixedVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GPS Map Canvas
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: CustomerCareColors.tacticalNavBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CustomerCareColors.tacticalNavBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TelemetryPathPainter(hasData: hasTelemetry),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              caseItem.currentTelemetryLocation.isNotEmpty
                                  ? caseItem.currentTelemetryLocation
                                  : 'Location unavailable',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.primaryFixed,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: caseItem.isTelemetryStale
                                  ? CustomerCareColors.error
                                  : CustomerCareColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              caseItem.isTelemetryStale
                                  ? 'TELEMETRY STALE'
                                  : (caseItem.liveSpeedKmh > 0
                                      ? 'LIVE ${caseItem.liveSpeedKmh} KM/H'
                                      : 'GPS STREAM ACTIVE'),
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Telemetry Metric Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('SPEED', caseItem.liveSpeedKmh > 0 ? '${caseItem.liveSpeedKmh} km/h' : 'Unavailable'),
                        _buildDivider(),
                        _buildMetricCol(
                          'REMAINING',
                          caseItem.remainingKm > 0 ? '${caseItem.remainingKm} km' : 'Unavailable',
                        ),
                        _buildDivider(),
                        _buildMetricCol(
                          'ETA',
                          caseItem.etaMinutes != null ? '${caseItem.etaMinutes}m' : 'Unavailable',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Assignment Details
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCrewRow(
                          'Vehicle / Unit',
                          caseItem.ambulance?.isNotEmpty == true
                              ? caseItem.ambulance!
                              : 'Unassigned',
                        ),
                        const Divider(height: 10, color: CustomerCareColors.outlineVariant),
                        _buildCrewRow(
                          'Driver Operator',
                          caseItem.driverName?.isNotEmpty == true
                              ? caseItem.driverName!
                              : 'Unassigned',
                        ),
                        const Divider(height: 10, color: CustomerCareColors.outlineVariant),
                        _buildCrewRow(
                          'Medical Crew',
                          caseItem.doctorName.isNotEmpty
                              ? '${caseItem.doctorName} • ${caseItem.emtName}'
                              : (caseItem.emtName.isNotEmpty ? caseItem.emtName : 'Unassigned'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Freshness Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: caseItem.isTelemetryStale
                                  ? CustomerCareColors.error
                                  : CustomerCareColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            caseItem.telemetrySignalFreshness,
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: caseItem.isTelemetryStale
                                  ? CustomerCareColors.error
                                  : CustomerCareColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Last CAD Sync: 10s ago',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: CustomerCareTextStyles.labelSm.copyWith(
            color: CustomerCareColors.onSurfaceVariant,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: CustomerCareTextStyles.telemetryDisplay.copyWith(
            fontSize: 14.5,
            color: CustomerCareColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: CustomerCareColors.outlineVariant,
    );
  }

  Widget _buildCrewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CustomerCareTextStyles.labelSm.copyWith(
            color: CustomerCareColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: CustomerCareTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: CustomerCareColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TelemetryPathPainter extends CustomPainter {
  const _TelemetryPathPainter({required this.hasData});
  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF0369A1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(30, size.height * 0.8)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.65, size.height * 0.55)
      ..lineTo(size.width - 40, size.height * 0.2);

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);

    // Origin Dot
    final originDot = Paint()..color = const Color(0xFF68DBA9);
    canvas.drawCircle(Offset(30, size.height * 0.8), 4.5, originDot);

    // Destination Dot
    final destDot = Paint()..color = const Color(0xFFF87171);
    canvas.drawCircle(Offset(size.width - 40, size.height * 0.2), 5, destDot);

    // Ambulance Vehicle Current Position
    final vehicleDot = Paint()..color = const Color(0xFF0369A1);
    final vehicleGlow = Paint()
      ..color = const Color(0xFF0369A1).withValues(alpha: 0.35);
    final pos = Offset(size.width * 0.48, size.height * 0.49);
    canvas.drawCircle(pos, 12, vehicleGlow);
    canvas.drawCircle(pos, 6, vehicleDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
