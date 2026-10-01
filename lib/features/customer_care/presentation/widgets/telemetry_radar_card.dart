import 'package:flutter/material.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class TelemetryRadarCard extends StatelessWidget {
  const TelemetryRadarCard({
    super.key,
    this.sector = 'Unavailable',
    this.flightUnit = 'Unit unavailable',
    this.eta = 'ETA unavailable',
    this.status = 'No active trip',
    this.onTap,
  });

  final String sector;
  final String flightUnit;
  final String eta;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              children: [
                const Icon(
                  Icons.airplanemode_active,
                  size: 18,
                  color: CustomerCareColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Active Corridor Airspaces',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomerCareTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Align(alignment: Alignment.centerRight, child: _sectorBadge(sector)),
          ] else
            Row(
              children: [
                const Icon(
                  Icons.airplanemode_active,
                  size: 18,
                  color: CustomerCareColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Active Corridor Airspaces',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomerCareTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sectorBadge(sector),
              ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: CustomerCareColors.tacticalNavBackground,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071426),
                    Color(0xFF0F2642),
                    Color(0xFF0A1D33),
                  ],
                ),
                border: Border.all(color: CustomerCareColors.tacticalNavBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Vector radar flight grid lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AirspaceRadarPainter(),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'IN-FLIGHT MEDEVAC',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.labelSm.copyWith(
                                    color: CustomerCareColors.onPrimaryContainer,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$flightUnit • $eta',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: CustomerCareColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _sectorBadge(String sector) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        sector,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CustomerCareTextStyles.labelSm.copyWith(
          color: CustomerCareColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AirspaceRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF94CCFF).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF0369A1).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Concentric radar arcs
    final center = Offset(size.width * 0.7, size.height * 0.4);
    canvas.drawCircle(center, 30, linePaint);
    canvas.drawCircle(center, 65, linePaint);
    canvas.drawCircle(center, 100, linePaint);

    // Flight route path
    final path = Path()
      ..moveTo(20, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.2, size.width * 0.7, size.height * 0.4)
      ..lineTo(size.width - 20, size.height * 0.3);
    canvas.drawPath(path, dashPaint);

    // Aircraft waypoint beacon
    final beaconPaint = Paint()..color = const Color(0xFF68DBA9);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.4), 4, beaconPaint);

    final pulsePaint = Paint()
      ..color = const Color(0xFF68DBA9).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.4), 10, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
