import 'package:flutter/material.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';

class NotificationPanelDialog extends StatelessWidget {
  const NotificationPanelDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const NotificationPanelDialog());
  }

  @override
  Widget build(BuildContext context) {
    final store = TeamLeadStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final notifications = store.notifications;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
          backgroundColor: TeamLeadTheme.surfaceLowest,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TeamLeadTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: TeamLeadTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Operational Notifications', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                              Text('${store.unreadNotificationsCount} unread alerts', style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (notifications.any((n) => !n.read))
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => store.markAllNotificationsAsRead(),
                        child: Text('Mark all as read', style: TeamLeadTheme.small(color: TeamLeadTheme.primary, weight: FontWeight.w600)),
                      ),
                    ),
                  const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
                  const SizedBox(height: 8),

                  Expanded(
                    child: notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_none_rounded, size: 40, color: TeamLeadTheme.textMuted),
                                const SizedBox(height: 8),
                                Text('No operational alerts', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
                            itemBuilder: (ctx, i) {
                              final item = notifications[i];
                              final isCritical = item.severity == 'CRITICAL';
                              final isWarning = item.severity == 'WARNING';

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isCritical
                                        ? TeamLeadTheme.crimsonBg
                                        : isWarning
                                            ? TeamLeadTheme.amberBg
                                            : TeamLeadTheme.surfaceLow,
                                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                                  ),
                                  child: Icon(
                                    isCritical
                                        ? Icons.error_outline_rounded
                                        : isWarning
                                            ? Icons.warning_amber_rounded
                                            : Icons.info_outline_rounded,
                                    color: isCritical
                                        ? TeamLeadTheme.medicalCrimson
                                        : isWarning
                                            ? TeamLeadTheme.urgentAmber
                                            : TeamLeadTheme.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TeamLeadTheme.body(
                                          weight: item.read ? FontWeight.w500 : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TeamLeadTheme.telemetryMicro(),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      item.message,
                                      style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                                    ),
                                    if (item.bookingId != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ref: ${item.bookingId}',
                                        style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.primary),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: !item.read
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: TeamLeadTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  store.markNotificationAsRead(item.id);
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TeamLeadTheme.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      ),
                      child: Text('Close Alerts', style: TeamLeadTheme.body(color: TeamLeadTheme.onSurfaceVariant)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
