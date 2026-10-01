import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_metrics.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_button.dart';
import '../../../shared/widgets/aeromed_ticket_card.dart';

/// AeroMed Booking Summary Boarding Pass Ticket Sheet
/// Recreated from Stitch Screen #59c5a6b3fa934a5fa19eff4172eba9c2
class BookingSummarySheet extends StatefulWidget {
  const BookingSummarySheet({
    super.key,
    required this.bookingId,
    required this.pickup,
    required this.destination,
    required this.ambulanceType,
    required this.patientName,
    this.extraDetails = '',
    required this.onConfirmDispatch,
  });

  final String bookingId;
  final String pickup;
  final String destination;
  final String ambulanceType;
  final String patientName;
  final String extraDetails;
  final VoidCallback onConfirmDispatch;

  @override
  State<BookingSummarySheet> createState() => _BookingSummarySheetState();
}

class _BookingSummarySheetState extends State<BookingSummarySheet> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Step Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '5',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STEP 5 OF 5',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'REVIEW & CONFIRM',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress line
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: double.infinity,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Booking Summary',
              style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Review your medical transportation request before sending it to Customer Care.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Tactile Boarding Pass Ticket Card
            AeroMedTicketCard(
              notchColor: AppColors.surface,
              topChild: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ticket Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AEROMED EXPRESS',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardSecondary),
                                ),
                                Text(
                                  widget.bookingId,
                                  style: AppTextStyles.routeIndicator.copyWith(
                                    fontSize: 15,
                                    color: AppColors.onTactileCard,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8EFEC),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF06766D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'REQUEST DRAFT',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF06766D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Journey Route Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Origin
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PICKUP POINT (TODAY • 2:30 PM)', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardSecondary)),
                                    Text(
                                      widget.pickup.isEmpty ? 'Koramangala 4th Block, Bengaluru' : widget.pickup,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Telemetry distance badge
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2EEEE),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '3.4 km • Est. 12 min ETA',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Destination
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF06766D)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DESTINATION MEDICAL CENTER', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardSecondary)),
                                    Text(
                                      widget.destination.isEmpty ? 'Manipal Hospital, Old Airport Road' : widget.destination,
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (widget.extraDetails.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: Text(widget.extraDetails, style: AppTextStyles.supporting.copyWith(color: AppColors.secondary)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Patient & Manifest Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PATIENT NAME', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardMuted)),
                                Text(
                                  widget.patientName.isEmpty ? 'Kushal Kumar' : widget.patientName,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700),
                                ),
                                Text('32 yrs • Male', style: AppTextStyles.caption.copyWith(color: AppColors.onTactileCardSecondary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBFB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CLINICAL STATUS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardMuted)),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF7DAD8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Severe Dyspnea',
                                      style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFF7DAD8), fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                Text('Vitals Monitored', style: AppTextStyles.caption.copyWith(color: const Color(0xFF06766D))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vehicle Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2EEEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.ambulanceType,
                                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                                ),
                                Text(
                                  'KA 01 AB 1234 • Paramedic + ALS Driver',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_rounded, color: AppColors.secondary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomChild: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('NO PRICE AT REQUEST STAGE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onTactileCardMuted)),
                    const SizedBox(height: 8),
                    Text('This is a service request, not a package purchase. Customer Care will verify the details first; the Team Lead will calculate the dispatch cost and send a quotation later.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onTactileCardSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Emergency contact on file
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.secondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMERGENCY CONTACT ON FILE', style: AppTextStyles.labelSmall),
                        Text(
                          '+91 98765 43210 (Kin: Dr. Aditi K.)',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Confirm Dispatch CTA
            AeroMedButton(
              label: 'Submit Booking Request',
              icon: Icons.send_rounded,
              trailingIcon: Icons.arrow_forward_rounded,
              onTap: widget.onConfirmDispatch,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Our Customer Care team will verify your request before dispatch planning.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
