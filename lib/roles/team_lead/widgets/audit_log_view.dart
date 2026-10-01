import 'package:flutter/material.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';

class AuditLogView extends StatelessWidget {
  const AuditLogView({super.key, this.bookingFilter});

  final String? bookingFilter;

  @override
  Widget build(BuildContext context) {
    final store = TeamLeadStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final logs = bookingFilter == null
            ? store.auditLogs
            : store.auditLogs.where((l) => l.bookingId == bookingFilter).toList();

        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TeamLeadTheme.surfaceLowest,
              borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
              border: Border.all(color: TeamLeadTheme.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 36, color: TeamLeadTheme.textMuted),
                const SizedBox(height: 8),
                Text('No audit records captured yet', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: TeamLeadTheme.surfaceLowest,
            borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
            border: Border.all(color: TeamLeadTheme.borderSubtle),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
            itemBuilder: (ctx, i) {
              final log = logs[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TeamLeadTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 16, color: TeamLeadTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${log.actor} (${log.role})',
                                style: TeamLeadTheme.body(weight: FontWeight.w600),
                              ),
                              Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                style: TeamLeadTheme.telemetryMicro(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.action,
                            style: TeamLeadTheme.supportingBody(color: TeamLeadTheme.onSurfaceVariant),
                          ),
                          if (log.bookingId != 'SYSTEM' && log.bookingId != 'ROSTER' && log.bookingId != 'FLEET') ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Booking: ', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                                Text(log.bookingId, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.primary, weight: FontWeight.w700)),
                                if (log.previousState != null && log.newState != null) ...[
                                  const SizedBox(width: 8),
                                  Text('${log.previousState} → ${log.newState}', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                                ],
                              ],
                            ),
                          ],
                          if (log.reason != null && log.reason!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: TeamLeadTheme.amberBg.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                              ),
                              child: Text(
                                'Note: ${log.reason}',
                                style: TeamLeadTheme.small(color: TeamLeadTheme.amberText),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
