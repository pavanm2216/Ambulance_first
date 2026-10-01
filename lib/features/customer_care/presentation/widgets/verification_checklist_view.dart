import 'package:flutter/material.dart';

import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class VerificationChecklistView extends StatelessWidget {
  const VerificationChecklistView({
    super.key,
    required this.checkPatientCondition,
    required this.checkOxygenTherapy,
    required this.checkVentilatorLoaded,
    required this.checkDoctorDesignated,
    required this.checkReceivingBedSecured,
    required this.checkRoutePriorityCleared,
    required this.businessVerificationComplete,
    required this.onTogglePatientCondition,
    required this.onToggleOxygenTherapy,
    required this.onToggleVentilatorLoaded,
    required this.onToggleDoctorDesignated,
    required this.onToggleReceivingBedSecured,
    required this.onToggleRoutePriorityCleared,
  });

  final bool checkPatientCondition;
  final bool checkOxygenTherapy;
  final bool checkVentilatorLoaded;
  final bool checkDoctorDesignated;
  final bool checkReceivingBedSecured;
  final bool checkRoutePriorityCleared;
  final bool businessVerificationComplete;

  final ValueChanged<bool?> onTogglePatientCondition;
  final ValueChanged<bool?> onToggleOxygenTherapy;
  final ValueChanged<bool?> onToggleVentilatorLoaded;
  final ValueChanged<bool?> onToggleDoctorDesignated;
  final ValueChanged<bool?> onToggleReceivingBedSecured;
  final ValueChanged<bool?> onToggleRoutePriorityCleared;

  int get completedCount {
    int c = 0;
    if (checkPatientCondition) c++;
    if (checkOxygenTherapy) c++;
    if (checkVentilatorLoaded) c++;
    if (checkDoctorDesignated) c++;
    if (checkReceivingBedSecured) c++;
    if (checkRoutePriorityCleared) c++;
    return c;
  }

  bool get isAllComplete => completedCount == 6;

  bool get isReadyForHandoff => isAllComplete && businessVerificationComplete;

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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Handover Protocol',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomerCareTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Complete all 6 items to unlock dispatch pass',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReadyForHandoff
                      ? CustomerCareColors.secondaryContainer
                      : CustomerCareColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completedCount/6',
                  style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                    fontSize: 14,
                    color: isReadyForHandoff
                        ? CustomerCareColors.secondary
                        : CustomerCareColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Banner Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isAllComplete
                  ? CustomerCareColors.secondaryContainer.withValues(alpha: 0.4)
                  : CustomerCareColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAllComplete
                    ? CustomerCareColors.secondary.withValues(alpha: 0.3)
                    : CustomerCareColors.outlineVariant,
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isReadyForHandoff
                      ? Icons.verified_user
                      : Icons.pending_actions_rounded,
                  size: 18,
                  color: isReadyForHandoff
                      ? CustomerCareColors.secondary
                      : CustomerCareColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReadyForHandoff
                        ? 'All 4/4 business confirmations and 6/6 safety items completed — Ready for Handoff'
                        : isAllComplete
                        ? '6/6 Safety Items Complete — Business verification pending'
                        : '$completedCount/6 Confirmed — Mandatory verification pending',
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isReadyForHandoff
                          ? CustomerCareColors.onSecondaryFixedVariant
                          : CustomerCareColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Items
          _buildCheckItem(
            'Patient Condition & Stability Confirmed',
            checkPatientCondition,
            '04:12',
            onTogglePatientCondition,
          ),
          _buildCheckItem(
            'High Flow O2 (15L Non-Rebreather) Verified',
            checkOxygenTherapy,
            '04:18',
            onToggleOxygenTherapy,
          ),
          _buildCheckItem(
            'Transport Ventilator & ICU Monitor Loaded',
            checkVentilatorLoaded,
            '04:22',
            onToggleVentilatorLoaded,
          ),
          _buildCheckItem(
            'Doctor Escort Designated for In-Transit ACLS',
            checkDoctorDesignated,
            '04:25',
            onToggleDoctorDesignated,
          ),
          _buildCheckItem(
            'Receiving Cath Lab Room 4 Bed Secured',
            checkReceivingBedSecured,
            '04:30',
            onToggleReceivingBedSecured,
          ),
          _buildCheckItem(
            'Direct Express Route & Signal Priority Cleared',
            checkRoutePriorityCleared,
            '04:33',
            onToggleRoutePriorityCleared,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(
    String label,
    bool value,
    String timeBadge,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: CustomerCareColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: value
                            ? CustomerCareColors.secondary
                            : CustomerCareColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: value
                              ? CustomerCareColors.secondary
                              : CustomerCareColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: value
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: CustomerCareTextStyles.bodyMd.copyWith(
                          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                          color: CustomerCareColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value ? timeBadge : 'PENDING',
                style: CustomerCareTextStyles.labelSm.copyWith(
                  color: value
                      ? CustomerCareColors.onSurfaceVariant
                      : CustomerCareColors.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
