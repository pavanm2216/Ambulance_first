import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Clinical Tonal Card with optional left urgency indicator stripe (4-5px).
/// Sourced from Stitch design specifications.
class AmbulanceFirstCard extends StatelessWidget {
  const AmbulanceFirstCard({
    super.key,
    required this.child,
    this.urgencyPriority,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.topIndicatorColor,
  });

  final Widget child;

  /// CRITICAL, URGENT, NORMAL, or custom color indicator
  final String? urgencyPriority;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? topIndicatorColor;

  Color? get _urgencyColor {
    if (urgencyPriority == null) return null;
    switch (urgencyPriority!.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return AmbulanceFirstColors.medicalCrimson;
      case 'URGENT':
      case 'MEDIUM':
        return AmbulanceFirstColors.warning;
      case 'NORMAL':
      case 'LOW':
      default:
        return AmbulanceFirstColors.clinicalCobalt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardRadius = borderRadius ?? AmbulanceFirstSpacing.radiusLg;
    final leftStripe = _urgencyColor;

    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AmbulanceFirstColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: borderColor ?? AmbulanceFirstColors.borderSubtle,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topIndicatorColor != null)
              Container(
                height: 4,
                width: double.infinity,
                color: topIndicatorColor,
              ),
            if (leftStripe != null)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      color: leftStripe,
                    ),
                    Expanded(
                      child: Padding(
                        padding: padding ?? const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
                        child: child,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: padding ?? const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
                child: child,
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cardRadius),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
