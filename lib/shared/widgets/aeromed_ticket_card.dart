import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import './aero_surface.dart';

/// A tactile floating ticket / boarding pass card with symmetric inward
/// semicircular punch-out notches and a dashed perforation divider line,
/// exactly as specified in the Stitch AeroMed design system.
class AeroMedTicketCard extends StatelessWidget {
  const AeroMedTicketCard({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.backgroundColor = AppColors.tactileCard,
    this.notchColor = AppColors.surface,
    this.notchRadius = 12.0,
    this.borderRadius = 28.0,
    this.showGradientBar = true,
  });

  final Widget topChild;
  final Widget bottomChild;
  final Color backgroundColor;
  final Color notchColor;
  final double notchRadius;
  final double borderRadius;
  final bool showGradientBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withValues( alpha: 0.10), blurRadius: 22, offset: const Offset(8, 8)),
          BoxShadow(color: AppColors.white.withValues( alpha: 0.90), blurRadius: 18, offset: const Offset(-7, -7)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AeroGlassPanel(
        borderRadius: borderRadius,
        opacity: backgroundColor.a < 1 ? backgroundColor.a : 0.74,
        padding: EdgeInsets.zero,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGradientBar)
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.tertiaryContainer,
                    AppColors.secondary,
                  ],
                ),
              ),
            ),
          topChild,
          AeroMedTicketDivider(
            notchColor: notchColor,
            notchRadius: notchRadius,
          ),
          bottomChild,
        ],
      ),
      ),
    );
  }
}

/// The perforated ticket tear line with symmetric inward punch-outs.
class AeroMedTicketDivider extends StatelessWidget {
  const AeroMedTicketDivider({
    super.key,
    this.notchColor = AppColors.surface,
    this.notchRadius = 12.0,
    this.lineColor = const Color(0x337B8C8A),
  });

  final Color notchColor;
  final double notchRadius;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: notchRadius * 2,
      child: Row(
        children: [
          // Left inward semicircular cutout
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Container(
                width: notchRadius * 2,
                height: notchRadius * 2,
                decoration: BoxDecoration(
                  color: notchColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Dashed perforation line
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dashWidth = 6.0;
                const dashSpace = 4.0;
                final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(count, (_) {
                    return SizedBox(
                      width: dashWidth,
                      height: 1.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: lineColor),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          // Right inward semicircular cutout
          ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: 0.5,
              child: Container(
                width: notchRadius * 2,
                height: notchRadius * 2,
                decoration: BoxDecoration(
                  color: notchColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
