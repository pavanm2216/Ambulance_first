import 'package:flutter/material.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class BookingLifecycleTimeline extends StatelessWidget {
  const BookingLifecycleTimeline({
    super.key,
    required this.caseItem,
    this.history = const [],
  });

  final CustomerCareCase caseItem;
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final events = _buildEventsList();

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
                'Operational Lifecycle Timeline',
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
                  'AUDITED',
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: CustomerCareColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              final isLast = index == events.length - 1;
              return _TimelineStep(
                title: ev.title,
                subtitle: ev.subtitle,
                timestamp: ev.timestamp,
                isCompleted: ev.isCompleted,
                isCurrent: ev.isCurrent,
                isLast: isLast,
              );
            },
          ),
        ],
      ),
    );
  }

  List<_TimelineItemData> _buildEventsList() {
    if (history.isNotEmpty) {
      return history.map((entry) {
        final status = entry['status']?.toString() ?? 'Status unavailable';
        final title = entry['milestone_title']?.toString() ?? status;
        final description = entry['milestone_description']?.toString() ??
            entry['description']?.toString() ??
            entry['notes']?.toString() ??
            'Details unavailable';
        return _TimelineItemData(
          title: title,
          subtitle: [
            description,
            if (entry['changed_by']?.toString().isNotEmpty == true)
              'Changed by ${entry['changed_by']}',
            if (entry['changed_by_role']?.toString().isNotEmpty == true)
              'Role: ${entry['changed_by_role']}',
          ].join(' · '),
          timestamp: entry['timestamp']?.toString() ??
              entry['created_at']?.toString() ??
              '',
          isCompleted: status != caseItem.status,
          isCurrent: status == caseItem.status,
        );
      }).toList();
    }

    // Never fabricate lifecycle events or timestamps when the persisted
    // history RPC returns no rows. The canonical booking status is still
    // shown, while the absence of history remains explicit.
    return [
      _TimelineItemData(
        title: 'Current Booking Status',
        subtitle: 'Canonical status: ${caseItem.status}',
        timestamp: '',
        isCompleted: false,
        isCurrent: true,
      ),
    ];
  }

}

class _TimelineItemData {
  final String title;
  final String subtitle;
  final String timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const _TimelineItemData({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isCompleted
        ? CustomerCareColors.secondary
        : (isCurrent ? CustomerCareColors.primaryContainer : CustomerCareColors.outlineVariant);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: isCurrent
                      ? Border.all(color: CustomerCareColors.primaryFixed, width: 3)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? CustomerCareColors.secondary.withValues(alpha: 0.5)
                        : CustomerCareColors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: CustomerCareTextStyles.bodyMd.copyWith(
                          fontWeight: isCompleted || isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: CustomerCareColors.onSurface,
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CustomerCareTextStyles.bodySm.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                      fontSize: 11.5,
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
}
