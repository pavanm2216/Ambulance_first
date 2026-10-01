import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

class MilestoneStep {
  const MilestoneStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    this.timestamp,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final String? timestamp;
}

/// Clinical Milestone Timeline for Active Ambulance Transports
class AmbulanceFirstTimeline extends StatelessWidget {
  const AmbulanceFirstTimeline({
    super.key,
    required this.steps,
  });

  final List<MilestoneStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Milestone Node + Vertical Connector Line
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? AmbulanceFirstColors.secondary
                            : (step.isCurrent
                                ? AmbulanceFirstColors.clinicalCobalt
                                : AmbulanceFirstColors.surfaceContainerHigh),
                        border: Border.all(
                          color: step.isCurrent
                              ? AmbulanceFirstColors.primaryFixed
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: step.isCompleted
                          ? const Icon(Icons.check, size: 8, color: Colors.white)
                          : (step.isCurrent
                              ? Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.isCompleted
                              ? AmbulanceFirstColors.secondaryContainer
                              : AmbulanceFirstColors.borderSubtle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Milestone Text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: AmbulanceFirstTypography.bodyMd(
                                color: step.isCurrent
                                    ? AmbulanceFirstColors.clinicalCobalt
                                    : (step.isCompleted
                                        ? AmbulanceFirstColors.onSurface
                                        : AmbulanceFirstColors.onSurfaceVariant),
                              ).copyWith(
                                fontWeight: step.isCurrent ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (step.timestamp != null)
                            Text(
                              step.timestamp!,
                              style: AmbulanceFirstTypography.codeSm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ).copyWith(fontSize: 10),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: AmbulanceFirstTypography.bodySm(
                          color: AmbulanceFirstColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
