import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_button.dart';

/// Standardized Empty State Display for Ambulance First
class AmbulanceFirstEmptyState extends StatelessWidget {
  const AmbulanceFirstEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
  });

  final IconData icon;
  final String heading;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg),
              ),
              child: Icon(icon, size: 28, color: AmbulanceFirstColors.clinicalCobalt),
            ),
            const SizedBox(height: 16),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurfaceVariant),
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 20),
              AmbulanceFirstButton(
                label: ctaLabel!,
                onPressed: onCtaPressed,
                variant: AmbulanceFirstButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized Error State Display with Retry Action
class AmbulanceFirstErrorState extends StatelessWidget {
  const AmbulanceFirstErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.errorContainer,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: AmbulanceFirstColors.medicalCrimson,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Operational Error',
              style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AmbulanceFirstButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: AmbulanceFirstButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized Loading State Skeleton / Progress Indicator
class AmbulanceFirstLoadingState extends StatelessWidget {
  const AmbulanceFirstLoadingState({
    super.key,
    this.message = 'Loading clinical transport data...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AmbulanceFirstColors.clinicalCobalt),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
