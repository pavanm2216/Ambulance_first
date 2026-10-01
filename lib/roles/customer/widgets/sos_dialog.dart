import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_button.dart';

/// Emergency SOS Dispatch Confirmation Dialog
class EmergencySosDialog extends StatelessWidget {
  const EmergencySosDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const EmergencySosDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with SOS Icon
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AmbulanceFirstColors.errorContainer,
                    borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: AmbulanceFirstColors.medicalCrimson,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY SOS DISPATCH',
                        style: AmbulanceFirstTypography.codeSm(
                          color: AmbulanceFirstColors.medicalCrimson,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      Text(
                        'Direct Critical Response',
                        style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                border: Border.all(color: AmbulanceFirstColors.medicalCrimson.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AmbulanceFirstColors.medicalCrimson),
                      const SizedBox(width: 6),
                      Text(
                        'Immediate Clinical Dispatch Desk',
                        style: AmbulanceFirstTypography.labelMd(
                          color: AmbulanceFirstColors.onErrorContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Triggering SOS connects your device directly with our 24/7 National Emergency Command Dispatcher and broadcasts your GPS coordinates to the nearest Advanced Life Support (ALS) squad.',
                    style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hotline Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                border: Border.all(color: AmbulanceFirstColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Emergency Hotline',
                        style: AmbulanceFirstTypography.labelSm(color: AmbulanceFirstColors.onSurfaceVariant),
                      ),
                      Text(
                        'Support contact unavailable',
                        style: AmbulanceFirstTypography.bodyMd(
                          color: AmbulanceFirstColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filled(
                    onPressed: null,
                    icon: const Icon(Icons.call, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AmbulanceFirstColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Triggers
            Row(
              children: [
                Expanded(
                  child: AmbulanceFirstButton(
                    label: 'CANCEL',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: AmbulanceFirstButtonVariant.ghost,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AmbulanceFirstButton(
                    label: 'CALL DISPATCH NOW',
                    icon: Icons.emergency,
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency support contact unavailable.'),
                          backgroundColor: AmbulanceFirstColors.medicalCrimson,
                        ),
                      );
                    },
                    variant: AmbulanceFirstButtonVariant.destructive,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
