import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared visual primitives for AeroMed's soft Glassmorphism + Neumorphism system.
/// Glass keeps the existing teal palette visible through a subtle translucent layer;
/// Neumorphism uses paired light/dark shadows instead of heavy drop shadows.
class AeroGlassPanel extends StatelessWidget {
  const AeroGlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 24,
    this.blur = 14,
    this.opacity = 0.62,
    this.border = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final bool border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.tactileCard.withValues( alpha: opacity),
            borderRadius: radius,
            border: border
                ? Border.all(color: AppColors.white.withValues( alpha: 0.72), width: 1)
                : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: panel),
    );
  }
}

class AeroNeumorphic extends StatelessWidget {
  const AeroNeumorphic({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 20,
    this.pressed = false,
    this.inset = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool pressed;
  final bool inset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final light = AppColors.white.withValues( alpha: 0.92);
    final dark = AppColors.primaryDark.withValues( alpha: 0.13);
    final shadows = pressed || inset
        ? <BoxShadow>[
            BoxShadow(color: dark, blurRadius: 8, offset: const Offset(3, 3)),
            BoxShadow(color: light, blurRadius: 8, offset: const Offset(-3, -3)),
          ]
        : <BoxShadow>[
            BoxShadow(color: dark, blurRadius: 18, offset: const Offset(7, 7)),
            BoxShadow(color: light, blurRadius: 18, offset: const Offset(-7, -7)),
          ];

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: radius,
        border: Border.all(color: AppColors.white.withValues( alpha: 0.55)),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
