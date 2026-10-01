import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';
import './aeromed_button.dart';
import './motion.dart';

/// The full-screen success moment shown right after a booking request is
/// submitted. Confirms what just happened (booking ID, ETA) and tells the
/// person exactly what happens next.
class AeroMedBookingConfirmation extends StatelessWidget {
  const AeroMedBookingConfirmation({
    super.key,
    required this.bookingId,
    required this.ambulanceType,
    required this.pickup,
    required this.destination,
    required this.immediate,
    required this.onTrack,
    required this.onDone,
  });

  final String bookingId;
  final String ambulanceType;
  final String pickup;
  final String destination;
  final bool immediate;
  final VoidCallback onTrack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: AppColors.primary.withValues( alpha: 0.3)),
                boxShadow: softShadow(opacity: 0.7),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues( alpha: 0.5), width: 2),
                      boxShadow: mintGlow(opacity: 0.3),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Request Submitted',
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your ambulance request has been submitted successfully. Customer Care will verify the details before dispatch planning.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        _Row('Booking ID', bookingId, isHighlight: true),
                        const SizedBox(height: 10),
                        _Row('Transport Mode', ambulanceType),
                        const SizedBox(height: 10),
                        _Row('Status', 'Awaiting Verification'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pickup,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                destination,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WHAT HAPPENS NEXT',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _NextStep(icon: Icons.person_search_rounded, text: 'Customer Care verifies patient, route and medical requirements.'),
                  const SizedBox(height: 8),
                  const _NextStep(icon: Icons.request_quote_outlined, text: 'Operations prepares and sends a quotation for your approval.'),
                  const SizedBox(height: 8),
                  const _NextStep(icon: Icons.near_me_rounded, text: 'After acceptance, the ambulance and crew are assigned for tracking.'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AeroMedButton(
                          label: 'Done',
                          variant: AeroMedButtonVariant.secondary,
                          height: 48,
                          onTap: onDone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AeroMedButton(
                          label: 'View Booking',
                          icon: Icons.confirmation_number_outlined,
                          height: 48,
                          onTap: onTrack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.isHighlight = false});
  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
