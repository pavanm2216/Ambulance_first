import 'dart:async';

import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import '../widgets/stitch_metric_card.dart';
import '../widgets/stitch_status_badge.dart';
import 'admin_shared.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.store,
    required this.onOpenBookingDetail,
    required this.onNavigateTab,
  });

  final AdminStore store;
  final ValueChanged<AdminBooking> onOpenBookingDetail;
  final ValueChanged<int> onNavigateTab;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tickerIndex = 0;
  bool _isTickerRunning = true;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  List<String> _liveTickerMessages() {
    final active = widget.store.bookings
        .where(
          (b) =>
              b.status == BookingStatus.inTransit ||
              b.status == BookingStatus.pickupStarted ||
              b.status == BookingStatus.patientPickedUp,
        )
        .toList();
    if (active.isEmpty) {
      return const ['No active incidents currently recorded in Supabase.'];
    }
    return active.map((b) {
      final unit = b.ambulanceCad ?? b.ambulanceId ?? 'unassigned unit';
      return '${b.id} · ${b.status.label} · $unit · ${b.destinationLocation}';
    }).toList();
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isTickerRunning || !mounted) return;
      setState(() {
        final messages = _liveTickerMessages();
        _tickerIndex = (_tickerIndex + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final activeBookings = store.bookings
            .where(
              (b) =>
                  b.status == BookingStatus.inTransit ||
                  b.status == BookingStatus.pickupStarted ||
                  b.status == BookingStatus.patientPickedUp,
            )
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Incident Triage Ticker
              _buildTriageTicker(),
              const SizedBox(height: StitchTheme.spaceMd),

              // 2. Executive KPI Grid
              Row(
                children: [
                  Expanded(
                    child: StitchMetricCard(
                      title: 'Total Bookings',
                      value: '${store.totalBookingsCount}',
                      icon: Icons.calendar_month_rounded,
                      badgeText: 'Live',
                      onTap: () => widget.onNavigateTab(1), // Go to Bookings
                    ),
                  ),
                  const SizedBox(width: StitchTheme.spaceSm),
                  Expanded(
                    child: StitchMetricCard(
                      title: 'Active Trips',
                      value: '${store.activeTripsCount} Live',
                      icon: Icons.emergency_rounded,
                      subtitle: Text(
                        '${store.inTransitCount} Transit · ${store.pickupStartedCount} Strt · ${store.patientPickedUpCount} Pckd',
                        style: StitchTheme.labelSm(
                          color: StitchTheme.onSurfaceVariant,
                          weight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => widget.onNavigateTab(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StitchTheme.spaceSm),

              // 3. Fleet Availability Gauge Card
              StitchFleetReadinessCard(
                availableCount: store.availableAmbulancesCount,
                totalCount: store.totalAmbulancesCount,
                onTap: () => widget.onNavigateTab(2), // Go to Fleet
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // 4. Revenue & Quotations Breakdown Matrix
              _buildFinancialMatrix(store),
              const SizedBox(height: StitchTheme.spaceLg),

              // 5. Live Active Bookings Feed
              _buildActiveBookingsFeed(activeBookings),
              const SizedBox(height: StitchTheme.spaceLg),

              // 6. Medical Staff Readiness Section
              _buildStaffAvailabilitySummary(store),
              const SizedBox(height: StitchTheme.spaceLg),

              // 7. Recent Governance & Audit Feed
              _buildAuditFeed(store),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTriageTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: StitchTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TRIAGE TICKER: ',
            style: StitchTheme.labelSm(
              color: StitchTheme.error,
              weight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _liveTickerMessages()[_tickerIndex %
                    _liveTickerMessages().length],
                key: ValueKey<int>(_tickerIndex),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StitchTheme.bodySm(color: StitchTheme.onSurface),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => _isTickerRunning = !_isTickerRunning);
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _isTickerRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 16,
                color: StitchTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMatrix(AdminStore store) {
    return Container(
      padding: const EdgeInsets.all(StitchTheme.spaceMd),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_rounded,
                      size: 18,
                      color: StitchTheme.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Revenue & Quotations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StitchTheme.headlineSm(
                          color: StitchTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                ),
                child: Text(
                  'CAD MTD',
                  style: StitchTheme.labelSm(
                    color: StitchTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: StitchTheme.primaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Statutory Protocol: Quoted ≠ Recognized Revenue until destination signoff.',
                    style: StitchTheme.labelSm(
                      color: StitchTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FinanceBox(
                  label: 'QUOTED PIPELINE',
                  value: money(store.quotedPipelineTotal),
                  subtitle: 'Pending triage bill',
                ),
              ),
              const SizedBox(width: StitchTheme.spaceXs),
              Expanded(
                child: _FinanceBox(
                  label: 'ACCEPTED ORDERS',
                  value: money(store.acceptedOrdersTotal),
                  subtitle: 'Locked agreements',
                  valueColor: StitchTheme.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: StitchTheme.spaceXs),
          Row(
            children: [
              Expanded(
                child: _FinanceBox(
                  label: 'PAID / RECOGNIZED',
                  value: money(store.paidRecognizedTotal),
                  subtitle: 'Funds cleared',
                  valueColor: StitchTheme.tertiary,
                ),
              ),
              const SizedBox(width: StitchTheme.spaceXs),
              Expanded(
                child: _FinanceBox(
                  label: 'OUTSTANDING',
                  value: money(store.outstandingCollectionsTotal),
                  subtitle: 'Collections queue',
                  valueColor: StitchTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingsFeed(List<AdminBooking> activeList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Icon(
                    Icons.monitor_heart_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  Text(
                    'Live Active Bookings',
                    style: StitchTheme.headlineSm(color: StitchTheme.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: StitchTheme.errorContainer,
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    ),
                    child: Text(
                      '${activeList.length} CRITICAL',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.onErrorContainer,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => widget.onNavigateTab(1),
              child: Row(
                children: [
                  Text(
                    'Stream',
                    style: StitchTheme.labelSm(
                      color: StitchTheme.primaryContainer,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: StitchTheme.primaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final booking in activeList) ...[
          _ActiveBookingItem(
            booking: booking,
            onTap: () => widget.onOpenBookingDetail(booking),
          ),
          const SizedBox(height: StitchTheme.spaceSm),
        ],
      ],
    );
  }

  Widget _buildStaffAvailabilitySummary(AdminStore store) {
    final availableDocs = store.doctors
        .where((d) => d.status == StaffStatus.available)
        .length;
    final availableEmts = store.emts
        .where((e) => e.status == StaffStatus.available)
        .length;
    final availableDrivers = store.drivers
        .where((d) => d.status == StaffStatus.available)
        .length;

    return Container(
      padding: const EdgeInsets.all(StitchTheme.spaceMd),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: StitchTheme.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Medical Staff Readiness',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StitchTheme.headlineSm(
                          color: StitchTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => widget.onNavigateTab(3), // Staff tab
                child: Text(
                  'Manage',
                  style: StitchTheme.labelSm(
                    color: StitchTheme.primaryContainer,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StaffRosterRow(
            icon: Icons.personal_injury_rounded,
            title: 'Doctors',
            available: availableDocs,
            total: store.doctors.length,
            subtitle:
                '${store.doctors.length - availableDocs} Assigned or on duty',
          ),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          _StaffRosterRow(
            icon: Icons.medical_services_rounded,
            title: 'EMTs',
            available: availableEmts,
            total: store.emts.length,
            subtitle:
                '${store.emts.length - availableEmts} Assigned on mission',
          ),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          _StaffRosterRow(
            icon: Icons.sports_motorsports_rounded,
            title: 'Drivers',
            available: availableDrivers,
            total: store.drivers.length,
            subtitle: '${store.drivers.length - availableDrivers} In Transit',
          ),
        ],
      ),
    );
  }

  Widget _buildAuditFeed(AdminStore store) {
    final recent = store.auditLogs.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(StitchTheme.spaceMd),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      'Recent Governance & Audit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StitchTheme.headlineSm(
                        color: StitchTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'ENCRYPTED LOG',
                style: StitchTheme.labelSm(
                  color: StitchTheme.tertiary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in recent) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.severity == 'CRITICAL'
                        ? StitchTheme.errorContainer
                        : entry.severity == 'WARNING'
                        ? StitchTheme.secondaryContainer
                        : StitchTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                  child: Icon(
                    entry.severity == 'CRITICAL'
                        ? Icons.warning_rounded
                        : entry.severity == 'WARNING'
                        ? Icons.build_rounded
                        : Icons.check_circle_rounded,
                    size: 14,
                    color: entry.severity == 'CRITICAL'
                        ? StitchTheme.error
                        : entry.severity == 'WARNING'
                        ? StitchTheme.secondary
                        : StitchTheme.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.entityId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StitchTheme.labelSm(
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateTime.now().difference(entry.timestamp).inMinutes}m ago',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.outline,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        entry.details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StitchTheme.bodySm(
                          color: StitchTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigateTab(6), // Audit tab
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Inspect Full Audit Trail'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              side: const BorderSide(color: StitchTheme.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceBox extends StatelessWidget {
  const _FinanceBox({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StitchTheme.labelSm(
              color: StitchTheme.outline,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: StitchTheme.labelLg(
              color: valueColor ?? StitchTheme.onSurface,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StaffRosterRow extends StatelessWidget {
  const _StaffRosterRow({
    required this.icon,
    required this.title,
    required this.available,
    required this.total,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final int available;
  final int total;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 18, color: StitchTheme.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: StitchTheme.headlineSm()),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StitchTheme.bodySm(color: StitchTheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  '$available ',
                  style: StitchTheme.labelLg(
                    color: StitchTheme.tertiary,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/ $total',
                  style: StitchTheme.bodySm(
                    color: StitchTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              'Available',
              style: StitchTheme.labelSm(
                color: StitchTheme.tertiary,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActiveBookingItem extends StatelessWidget {
  const _ActiveBookingItem({required this.booking, required this.onTap});

  final AdminBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          border: Border.all(color: StitchTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Urgency Pip
                Container(
                  width: 5,
                  color: booking.urgencyLevel == 'CRITICAL'
                      ? StitchTheme.error
                      : StitchTheme.warning,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(StitchTheme.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: ID + Time + Status Pill + ETA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '#${booking.id}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: StitchTheme.labelLg(
                                        color: StitchTheme.onSurface,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '· ${DateTime.now().difference(booking.createdAt).inMinutes}m ago',
                                    maxLines: 1,
                                    style: StitchTheme.labelSm(
                                      color: StitchTheme.outline,
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
                                child: StitchStatusBadge.fromBooking(
                                  booking.status,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Patient + Acuity
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: StitchTheme.primaryContainer,
                              child: Text(
                                booking.patientInitials,
                                style: StitchTheme.labelSm(
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${booking.patientName} (${booking.patientAge}y ${booking.patientGender[0]}) · ${booking.patientCondition}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: StitchTheme.bodySm(
                                  color: StitchTheme.onSurface,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'ETA: ${booking.etaMinutes}m',
                              style: StitchTheme.labelSm(
                                color: StitchTheme.error,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Route & Ambulance
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: StitchTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.navigation_rounded,
                                size: 14,
                                color: StitchTheme.primaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${booking.pickupLocation} → ${booking.destinationLocation}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (booking.ambulanceId != null)
                                Flexible(
                                  child: Text(
                                    booking.ambulanceId!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: StitchTheme.labelSm(
                                      color: StitchTheme.primaryContainer,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
