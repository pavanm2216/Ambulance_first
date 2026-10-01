import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Clinical Operational Buttons for Ambulance First.
enum AmbulanceFirstButtonVariant {
  primary,
  secondary,
  destructive,
  ghost,
  telemetry,
}

class AmbulanceFirstButton extends StatelessWidget {
  const AmbulanceFirstButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AmbulanceFirstButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final AmbulanceFirstButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isLoading) {
      child = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_contentColor),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: _contentColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              softWrap: false,
              style: _textStyle,
            ),
          ),
        ],
      );
    }

    Widget btn;
    switch (variant) {
      case AmbulanceFirstButtonVariant.primary:
        btn = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AmbulanceFirstColors.clinicalCobalt,
            foregroundColor: AmbulanceFirstColors.onPrimary,
            minimumSize: Size(fullWidth ? double.infinity : 80, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
          ),
          child: child,
        );
        break;

      case AmbulanceFirstButtonVariant.secondary:
        btn = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AmbulanceFirstColors.surfaceContainerHigh,
            foregroundColor: AmbulanceFirstColors.onSurfaceVariant,
            minimumSize: Size(fullWidth ? double.infinity : 80, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
          ),
          child: child,
        );
        break;

      case AmbulanceFirstButtonVariant.destructive:
        btn = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AmbulanceFirstColors.medicalCrimson,
            foregroundColor: AmbulanceFirstColors.onError,
            minimumSize: Size(fullWidth ? double.infinity : 80, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
          ),
          child: child,
        );
        break;

      case AmbulanceFirstButtonVariant.ghost:
        btn = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AmbulanceFirstColors.clinicalCobalt,
            side: const BorderSide(color: AmbulanceFirstColors.borderSubtle),
            minimumSize: Size(fullWidth ? double.infinity : 80, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
          ),
          child: child,
        );
        break;

      case AmbulanceFirstButtonVariant.telemetry:
        btn = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AmbulanceFirstColors.surfaceContainer,
            foregroundColor: AmbulanceFirstColors.onSurface,
            side: const BorderSide(color: AmbulanceFirstColors.borderSubtle),
            minimumSize: Size(fullWidth ? double.infinity : 80, height),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
          ),
          child: child,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }

  Color get _contentColor {
    switch (variant) {
      case AmbulanceFirstButtonVariant.primary:
        return AmbulanceFirstColors.onPrimary;
      case AmbulanceFirstButtonVariant.secondary:
        return AmbulanceFirstColors.onSurfaceVariant;
      case AmbulanceFirstButtonVariant.destructive:
        return AmbulanceFirstColors.onError;
      case AmbulanceFirstButtonVariant.ghost:
        return AmbulanceFirstColors.clinicalCobalt;
      case AmbulanceFirstButtonVariant.telemetry:
        return AmbulanceFirstColors.onSurface;
    }
  }

  TextStyle get _textStyle {
    if (variant == AmbulanceFirstButtonVariant.telemetry) {
      return AmbulanceFirstTypography.codeSm(color: _contentColor, weight: FontWeight.w600);
    }
    return AmbulanceFirstTypography.labelLg(color: _contentColor).copyWith(
      fontSize: 13,
      letterSpacing: 0.3,
    );
  }
}
