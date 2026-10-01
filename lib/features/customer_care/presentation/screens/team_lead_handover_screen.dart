import 'package:flutter/material.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class TeamLeadHandoverScreen extends StatelessWidget {
  const TeamLeadHandoverScreen({
    super.key,
    required this.onViewDetails,
  });

  final ValueChanged<CustomerCareCase> onViewDetails;

  @override
  Widget build(BuildContext context) {
    final repo = CustomerCareRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final cases = repo.handedOverCases;

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
                  border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_ind_rounded,
                              size: 22,
                              color: CustomerCareColors.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Team Lead Handover Monitor',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomerCareTextStyles.headlineSm.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Tracking downstream ambulance allocation & quotations',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomerCareTextStyles.bodySm.copyWith(
                                      color: CustomerCareColors.onSurfaceVariant,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.primaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cases.length} In Pipeline',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.onPrimaryFixedVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 12),

              if (cases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 36,
                        color: CustomerCareColors.primaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Cases Currently in Lead Queue',
                        style: CustomerCareTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verify incoming bookings to escalate them to the Operations Team Lead.',
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
                  itemCount: cases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = cases[index];
                    return _HandoverMonitorCard(
                      caseItem: c,
                      onTap: () => onViewDetails(c),
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

class _HandoverMonitorCard extends StatelessWidget {
  const _HandoverMonitorCard({
    required this.caseItem,
    required this.onTap,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: CustomerCareColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '#${caseItem.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                            fontSize: 14,
                            color: CustomerCareColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            caseItem.createdAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerCareTextStyles.labelSm.copyWith(fontSize: 9.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        caseItem.statusLabel.toUpperCase(),
                        maxLines: 1,
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onPrimaryFixedVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${caseItem.patientName}, ${caseItem.age} ${caseItem.gender}',
              style: CustomerCareTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
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
                color: CustomerCareColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: CustomerCareColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Team Lead queue',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Unit: ${caseItem.vehicleNumber?.isNotEmpty == true ? caseItem.vehicleNumber : "Unassigned"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
