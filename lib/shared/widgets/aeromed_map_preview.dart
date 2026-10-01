
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';

/// Telematics cartographic vector map preview inspired by Stitch Active Trip Tracker.
class AeroMedMapPreview extends StatelessWidget {
  const AeroMedMapPreview({
    super.key,
    this.progress = 0.5,
    this.height = 280,
    this.borderRadius,
    this.showWaypoints = true,
  });

  final double progress;
  final double height;
  final BorderRadius? borderRadius;
  final bool showWaypoints;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppColors.surfaceContainerLowest,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TacticalMapPainter(progress: progress),
              ),
            ),
            // Subtle gradient vignette top and bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface.withValues( alpha: 0.5),
                      Colors.transparent,
                      AppColors.surface.withValues( alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            if (showWaypoints) ...[
              // Pickup Location Chip (bottom left)
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues( alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.primary.withValues( alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'KORAMANGALA (HOME)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Hospital Destination Chip (top right)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh.withValues( alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.secondary.withValues( alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'MANIPAL HOSP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TacticalMapPainter extends CustomPainter {
  const _TacticalMapPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw a softer map grid so the live-trip preview reads as a calm medical dashboard.
    final background = Paint()..color = AppColors.surfaceContainerLowest.withValues(alpha: 0.82);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    for (double x = -40; x < size.width + 60; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x + 80, size.height), gridPaint);
    }
    for (double y = 20; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw curved route path
    final start = Offset(48, size.height - 40);
    final control1 = Offset(size.width * 0.35, size.height * 0.70);
    final control2 = Offset(size.width * 0.60, size.height * 0.35);
    final end = Offset(size.width - 48, 48);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues( alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // Core path
    final corePaint = Paint()
      ..color = AppColors.primary.withValues( alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);

    // 3. Compute ambulance position along path
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0));
    final ambulancePos = tangent?.position ?? start;
    final angle = tangent != null ? -tangent.angle : 0.0;

    // 4. Draw Start waypoint (Koramangala)
    final pulsePaint = Paint()
      ..color = AppColors.primaryFixedDim.withValues( alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, 14, pulsePaint);
    canvas.drawCircle(start, 7, Paint()..color = AppColors.primaryFixedDim);
    canvas.drawCircle(start, 3, Paint()..color = AppColors.surface);

    // 5. Draw End waypoint (Manipal Hospital)
    canvas.drawCircle(end, 16, Paint()..color = AppColors.tertiary.withValues( alpha: 0.25));
    canvas.drawCircle(end, 8, Paint()..color = AppColors.tertiary);
    canvas.drawCircle(end, 3.5, Paint()..color = AppColors.onPrimaryContainer);

    // 6. Draw Moving Ambulance Node with Radar Glow
    // Radar ping ring
    canvas.drawCircle(ambulancePos, 20, Paint()..color = AppColors.primary.withValues( alpha: 0.25));
    canvas.drawCircle(ambulancePos, 14, Paint()..color = AppColors.primary);
    canvas.drawCircle(ambulancePos, 6, Paint()..color = AppColors.onPrimary);

    // Radar cone pointing along motion
    canvas.save();
    canvas.translate(ambulancePos.dx, ambulancePos.dy);
    canvas.rotate(angle);
    final conePath = Path()
      ..moveTo(0, 0)
      ..lineTo(22, -10)
      ..arcToPoint(const Offset(22, 10), radius: const Radius.circular(16))
      ..close();
    canvas.drawPath(
      conePath,
      Paint()
        ..color = AppColors.primary.withValues( alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class AeroMedMapChip extends StatelessWidget {
  const AeroMedMapChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues( alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
