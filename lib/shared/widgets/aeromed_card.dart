import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import './aero_surface.dart';

/// The app's single card surface derived from Stitch tokens:
/// - Generous corner radius (28px)
/// - Deep botanical dark container (#13231A or #1D2D24)
/// - Hairline border (#3D4A3D)
/// - Tactile light variant option for boarding passes & tickets
class AeroMedCard extends StatelessWidget {
  const AeroMedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppRadius.card,
    this.onTap,
    this.color = AppColors.surfaceContainer,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color color;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = AeroGlassPanel(
      borderRadius: borderRadius,
      padding: padding,
      opacity: color.a < 1 ? color.a : 0.68,
      onTap: onTap,
      child: child,
    );

    if (!shadow) return content;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues( alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(7, 8),
          ),
          BoxShadow(
            color: AppColors.white.withValues( alpha: 0.88),
            blurRadius: 18,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: content,
    );
  }
}
