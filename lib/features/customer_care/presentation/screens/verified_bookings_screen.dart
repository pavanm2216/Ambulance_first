import 'package:flutter/material.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class VerifiedBookingsScreen extends StatelessWidget {
  const VerifiedBookingsScreen({
    super.key,
    required this.onViewDetails,
    required this.onShowToast,
  });

  final ValueChanged<CustomerCareCase> onViewDetails;
  final ValueChanged<String> onShowToast;

  @override
  Widget build(BuildContext context) {
    final repo = CustomerCareRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final verifiedCases = repo.verifiedCases;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CustomerCareColors.outlineVariant,
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: CustomerCareColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Ready for Handoff',
                              style: CustomerCareTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Cases completed by Customer Care awaiting dispatch allocation',
                              style: CustomerCareTextStyles.bodySm.copyWith(
                                color: CustomerCareColors.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${verifiedCases.length} Ready',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onSecondaryFixedVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (verifiedCases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CustomerCareColors.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 36,
                        color: CustomerCareColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Verified Bookings Pending Handoff',
                        style: CustomerCareTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All verified cases have been successfully escalated to the Operations Team Lead.',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: verifiedCases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = verifiedCases[index];
                    return _VerifiedCard(
                      caseItem: item,
                      onViewDetails: () => onViewDetails(item),
                      onHandoff: () async {
                        try {
                          final success = await repo.sendCustomerCareToTeamLead(
                            item.id,
                            item.notes,
                          );
                          if (success) {
                            onShowToast(
                              'Booking #${item.id} escalated to Operations Team Lead.',
                            );
                          }
                        } catch (error) {
                          onShowToast('Verification handoff failed: $error');
                        }
                      },
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({
    required this.caseItem,
    required this.onViewDetails,
    required this.onHandoff,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onViewDetails;
  final VoidCallback onHandoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CustomerCareColors.outlineVariant,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3.5,
            width: double.infinity,
            color: CustomerCareColors.secondary,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${caseItem.id}',
                          style: CustomerCareTextStyles.telemetryDisplay
                              .copyWith(
                                fontSize: 14,
                                color: CustomerCareColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: CustomerCareColors.onSecondaryFixedVariant,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Verified by ${caseItem.verifiedBy.isNotEmpty ? caseItem.verifiedBy : "Customer Care"}',
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${caseItem.patientName}, ${caseItem.age} ${caseItem.gender}',
                  style: CustomerCareTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caseItem.condition,
                  style: CustomerCareTextStyles.bodySm.copyWith(
                    color: CustomerCareColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.secondaryContainer.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 15,
                            color: CustomerCareColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'READY FOR TEAM LEAD HANDOFF',
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: CustomerCareColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Checklist 6/6 OK',
                        style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                          fontSize: 11,
                          color: CustomerCareColors.onSecondaryFixedVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onHandoff,
                        icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
                        label: const Text('Send to Team Lead (Handover)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomerCareColors.primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: CustomerCareTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomerCareColors.onSurface,
                        side: const BorderSide(
                          color: CustomerCareColors.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Details',
                        style: CustomerCareTextStyles.labelSm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
