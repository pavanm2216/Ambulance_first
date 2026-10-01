import 'package:flutter/material.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class CallOutcomeSelector extends StatelessWidget {
  const CallOutcomeSelector({
    super.key,
    required this.selectedOutcome,
    required this.onSelectOutcome,
  });

  final String selectedOutcome;
  final ValueChanged<String> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Call Outcome Status',
                style: CustomerCareTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mandatory',
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: CustomerCareColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildOutcomeButton(
                  title: 'Verified',
                  subtitle: 'Call Complete',
                  icon: Icons.verified,
                  isSelected: selectedOutcome == 'Verified',
                  onTap: () => onSelectOutcome('Verified'),
                  activeColor: CustomerCareColors.secondary,
                  activeFg: CustomerCareColors.onSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOutcomeButton(
                  title: 'In Progress',
                  subtitle: 'Agent Talking',
                  icon: Icons.phone_in_talk,
                  isSelected: selectedOutcome == 'In Progress',
                  onTap: () => onSelectOutcome('In Progress'),
                  activeColor: CustomerCareColors.primaryContainer,
                  activeFg: CustomerCareColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOutcomeButton(
                  title: 'Unreachable',
                  subtitle: 'No Answer',
                  icon: Icons.phone_missed,
                  isSelected: selectedOutcome == 'Unreachable',
                  onTap: () => onSelectOutcome('Unreachable'),
                  activeColor: CustomerCareColors.warning,
                  activeFg: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOutcomeButton(
                  title: 'Follow-up',
                  subtitle: 'Call Back Later',
                  icon: Icons.schedule,
                  isSelected: selectedOutcome == 'Follow-up',
                  onTap: () => onSelectOutcome('Follow-up'),
                  activeColor: CustomerCareColors.tertiary,
                  activeFg: CustomerCareColors.onTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => onSelectOutcome('Cancelled'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selectedOutcome == 'Cancelled'
                    ? CustomerCareColors.errorContainer
                    : CustomerCareColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedOutcome == 'Cancelled'
                      ? CustomerCareColors.error
                      : CustomerCareColors.outlineVariant,
                  width: selectedOutcome == 'Cancelled' ? 1.4 : 0.6,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    size: 16,
                    color: selectedOutcome == 'Cancelled'
                        ? CustomerCareColors.error
                        : CustomerCareColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Request Cancelled by Family / Attending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: selectedOutcome == 'Cancelled'
                            ? CustomerCareColors.onErrorContainer
                            : CustomerCareColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color activeFg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : CustomerCareColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : CustomerCareColors.outlineVariant,
            width: isSelected ? 1.4 : 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeFg : CustomerCareColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? activeFg : CustomerCareColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      fontSize: 9.5,
                      color: isSelected
                          ? activeFg.withValues(alpha: 0.85)
                          : CustomerCareColors.onSurfaceVariant,
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
