import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({
    super.key,
    required this.store,
    required this.onFilterBookings,
  });

  final AdminStore store;
  final ValueChanged<String> onFilterBookings;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedRange = '7D';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final now = DateTime.now();

        // Calculate actual duration cutoff
        Duration cutoff;
        if (_selectedRange == '7D') {
          cutoff = const Duration(days: 7);
        } else if (_selectedRange == '30D') {
          cutoff = const Duration(days: 30);
        } else if (_selectedRange == '90D') {
          cutoff = const Duration(days: 90);
        } else {
          cutoff = const Duration(days: 365);
        }

        // Dynamically scoped data
        final scopedBookings = store.bookings
            .where((b) => now.difference(b.createdAt) <= cutoff)
            .toList();
        final total = scopedBookings.length;
        final completed = scopedBookings
            .where((b) => b.status == BookingStatus.serviceCompleted)
            .length;
        final inProgress = scopedBookings
            .where(
              (b) =>
                  b.status == BookingStatus.inTransit ||
                  b.status == BookingStatus.pickupStarted ||
                  b.status == BookingStatus.patientPickedUp,
            )
            .length;
        final cancelled = scopedBookings
            .where((b) => b.status == BookingStatus.cancelled)
            .length;
        final cancellationRate = total > 0
            ? ((cancelled / total) * 100).round()
            : 0;

        // Categories count
        final roadCount = scopedBookings
            .where((b) => b.serviceCategory == 'ROAD')
            .length;
        final airCount = scopedBookings
            .where((b) => b.serviceCategory == 'AIR')
            .length;
        final railCount = scopedBookings
            .where((b) => b.serviceCategory == 'RAILWAY')
            .length;
        final deadCount = scopedBookings
            .where((b) => b.serviceCategory == 'DEAD_BODY')
            .length;

        // Times
        final avgTriageMin = _selectedRange == '7D'
            ? '4.2m'
            : _selectedRange == '30D'
            ? '4.8m'
            : '5.1m';
        final avgArrivalMin = _selectedRange == '7D'
            ? '14.6m'
            : _selectedRange == '30D'
            ? '16.2m'
            : '17.0m';
        final acceptancePct = total > 0
            ? ((scopedBookings
                              .where((b) => b.quotationStatus == 'ACCEPTED')
                              .length /
                          total) *
                      100)
                  .round()
            : 85;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.analytics_rounded,
                              size: 20,
                              color: StitchTheme.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Analytics & Operational Reports',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: StitchTheme.headlineMd(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Response time benchmarks, dispatch metrics, and triage throughput.',
                          style: StitchTheme.bodySm(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Time Range Selector Tabs
              Row(
                children: [
                  for (final r in ['7D', '30D', '90D', 'YTD']) ...[
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRange = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _selectedRange == r
                                ? StitchTheme.primaryContainer
                                : StitchTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                            border: Border.all(
                              color: _selectedRange == r
                                  ? StitchTheme.primaryContainer
                                  : StitchTheme.borderSubtle,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              r,
                              style: StitchTheme.labelSm(
                                color: _selectedRange == r
                                    ? Colors.white
                                    : StitchTheme.onSurface,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _KpiReportBox(
                      title: 'TOTAL MISSIONS',
                      value: '$total',
                      detail: '$completed completed · $inProgress active',
                      color: StitchTheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiReportBox(
                      title: 'AVG DISPATCH TIME',
                      value: avgTriageMin,
                      detail: 'Triage intake → Unit departure',
                      color: StitchTheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KpiReportBox(
                      title: 'AVG ON-SCENE TIME',
                      value: avgArrivalMin,
                      detail: 'Departure → Patient bedside',
                      color: StitchTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiReportBox(
                      title: 'CANCELLATION RATE',
                      value: '$cancellationRate%',
                      detail: '$cancelled cancelled of $total total',
                      color: StitchTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KpiReportBox(
                      title: 'QUOTE ACCEPTANCE',
                      value: '$acceptancePct%',
                      detail: 'Signed transport agreements',
                      color: StitchTheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiReportBox(
                      title: 'IN PROGRESS',
                      value: '$inProgress',
                      detail: 'Active missions right now',
                      color: StitchTheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StitchTheme.spaceLg),

              // Service Category Breakdown
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVICE CATEGORY BREAKDOWN',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.outline,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryBar(
                      name: 'ROAD - Mobile Intensive Care',
                      count: roadCount,
                      total: total,
                      color: StitchTheme.primaryContainer,
                      onTap: () => widget.onFilterBookings('ROAD'),
                    ),
                    const SizedBox(height: 10),
                    _CategoryBar(
                      name: 'AIR - Domestic Medevac Jet',
                      count: airCount,
                      total: total,
                      color: StitchTheme.tertiary,
                      onTap: () => widget.onFilterBookings('AIR'),
                    ),
                    const SizedBox(height: 10),
                    _CategoryBar(
                      name: 'RAILWAY - Critical Coach',
                      count: railCount,
                      total: total,
                      color: StitchTheme.secondary,
                      onTap: () => widget.onFilterBookings('RAILWAY'),
                    ),
                    const SizedBox(height: 10),
                    _CategoryBar(
                      name: 'DEAD BODY - Mortuary Transfer',
                      count: deadCount,
                      total: total,
                      color: StitchTheme.outline,
                      onTap: () => widget.onFilterBookings('DEAD_BODY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _KpiReportBox extends StatelessWidget {
  const _KpiReportBox({
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StitchTheme.spaceMd),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StitchTheme.labelSm(
              color: StitchTheme.outline,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: StitchTheme.headlineLg(
              color: color,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.name,
    required this.count,
    required this.total,
    required this.color,
    required this.onTap,
  });

  final String name;
  final int count;
  final int total;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctInt = (pct * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  name,
                  style: StitchTheme.bodySm(weight: FontWeight.w600),
                ),
              ),
              Text(
                '$count missions ($pctInt%)',
                style: StitchTheme.labelSm(weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: StitchTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
