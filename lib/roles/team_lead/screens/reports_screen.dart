import 'package:flutter/material.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/audit_log_view.dart';
import '../widgets/team_lead_kpi_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final store = TeamLeadStore.instance;
  String _selectedRange = 'TODAY';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final bookings = store.allBookings;
        final ambulances = store.ambulances;
        final drivers = store.drivers;
        final emts = store.emts;
        final doctors = store.doctors;

        final totalBookings = bookings.length;
        final activeTrips = bookings.where((b) => b.isActive).length;
        final completedTrips = bookings.where((b) => b.status == 'SERVICE_COMPLETED' || b.status == 'COMPLETED').toList();
        final totalRevenue = completedTrips.fold<double>(0.0, (sum, b) => sum + b.amount);

        // Modality Distribution
        final roadCount = bookings.where((b) => b.transportMode == 'ROAD_AMBULANCE' || b.serviceCategory == 'ROAD').length;
        final airCount = bookings.where((b) => b.transportMode == 'AIR_AMBULANCE').length;
        final railCount = bookings.where((b) => b.transportMode == 'RAILWAY_AMBULANCE').length;
        final mortuaryCount = bookings.where((b) => b.transportMode == 'DEAD_BODY_TRANSFER').length;

        // Resource Readiness ratios
        final fleetAvail = ambulances.where((a) => a.isAvailable).length;
        final fleetRatio = ambulances.isNotEmpty ? (fleetAvail / ambulances.length) : 0.0;

        final driverAvail = drivers.where((d) => d.isAvailable).length;
        final driverRatio = drivers.isNotEmpty ? (driverAvail / drivers.length) : 0.0;

        final emtAvail = emts.where((e) => e.isAvailable).length;
        final emtRatio = emts.isNotEmpty ? (emtAvail / emts.length) : 0.0;

        final docAvail = doctors.where((d) => d.isAvailable).length;
        final docRatio = doctors.isNotEmpty ? (docAvail / doctors.length) : 0.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Timeframe Selector
              _reportsHeader(),
              const SizedBox(height: 20),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    children: [
                      TeamLeadKpiCard(
                        title: 'Total Operations Bookings',
                        value: '$totalBookings',
                        subtitle: '$activeTrips currently active in corridor',
                        icon: Icons.assignment_turned_in_rounded,
                        accentColor: TeamLeadTheme.primary,
                        badgeText: 'LIFECYCLE TOTAL',
                      ),
                      TeamLeadKpiCard(
                        title: 'Completed Transport Missions',
                        value: '${completedTrips.length}',
                        icon: Icons.check_circle_rounded,
                        accentColor: TeamLeadTheme.operationalEmerald,
                        badgeText: completedTrips.isEmpty ? 'NO COMPLETED TRIPS' : 'DATABASE DERIVED',
                        badgeColor: TeamLeadTheme.emeraldBg,
                        badgeTextColor: TeamLeadTheme.emeraldText,
                      ),
                      TeamLeadKpiCard(
                        title: 'Billed Operational Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.payments_rounded,
                        accentColor: TeamLeadTheme.clinicalCobalt,
                        badgeText: 'REALIZED TARIFFS',
                      ),
                      TeamLeadKpiCard(
                        title: 'Active Dispatch Missions',
                        value: activeTrips > 0 ? '$activeTrips active' : '—',
                        icon: Icons.timer_rounded,
                        accentColor: TeamLeadTheme.urgentAmber,
                        badgeText: 'LIVE DB STATUS',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Two Column Dashboard: Modality Distribution & Readiness Ratios
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  return isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _modalityCard(roadCount, airCount, railCount, mortuaryCount, totalBookings)),
                            const SizedBox(width: 16),
                            Expanded(child: _readinessCard(fleetAvail, ambulances.length, fleetRatio, driverAvail, drivers.length, driverRatio, emtAvail, emts.length, emtRatio, docAvail, doctors.length, docRatio)),
                          ],
                        )
                      : Column(
                          children: [
                            _modalityCard(roadCount, airCount, railCount, mortuaryCount, totalBookings),
                            const SizedBox(height: 16),
                            _readinessCard(fleetAvail, ambulances.length, fleetRatio, driverAvail, drivers.length, driverRatio, emtAvail, emts.length, emtRatio, docAvail, doctors.length, docRatio),
                          ],
                        );
                },
              ),
              const SizedBox(height: 24),

              // Operational Audit Log Section
              Text('COMPLETE OPERATIONAL ACTIVITY AUDIT TIMELINE', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              const AuditLogView(),
            ],
          ),
        );
      },
    );
  }

  Widget _timeChip(String key, String label) {
    final isSelected = _selectedRange == key;
    return ChoiceChip(
      label: Text(label, style: TeamLeadTheme.small(color: isSelected ? Colors.white : TeamLeadTheme.onSurfaceVariant)),
      selected: isSelected,
      selectedColor: TeamLeadTheme.primary,
      backgroundColor: TeamLeadTheme.surfaceLowest,
      onSelected: (v) {
        if (v) setState(() => _selectedRange = key);
      },
    );
  }

  Widget _reportsHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chips = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _timeChip('TODAY', 'Today'),
            _timeChip('WEEK', 'This Week'),
            _timeChip('MONTH', 'Month to Date'),
          ],
        );

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operations Telemetry & Performance Reports',
              maxLines: constraints.maxWidth < 600 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TeamLeadTheme.titleMedium(weight: FontWeight.w700),
            ),
            Text(
              'Clinical SLA monitoring, dispatch velocity, fleet readiness, and audit logs',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
            ),
          ],
        );

        if (constraints.maxWidth < 800) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), chips],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            chips,
          ],
        );
      },
    );
  }

  Widget _modalityCard(int road, int air, int rail, int mortuary, int total) {
    final t = total > 0 ? total : 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        border: Border.all(color: TeamLeadTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Modality Breakdown', style: TeamLeadTheme.supportingBody(weight: FontWeight.w700)),
              const Icon(Icons.pie_chart_rounded, size: 18, color: TeamLeadTheme.primary),
            ],
          ),
          const SizedBox(height: 14),
          _distributionBar('Road ALS / BLS Ambulance', road, road / t, TeamLeadTheme.primary),
          const SizedBox(height: 10),
          _distributionBar('Pediatric & Neonatal Mobile ICU', air, air / t, TeamLeadTheme.clinicalCobalt),
          const SizedBox(height: 10),
          _distributionBar('Railway Medical Transport', rail, rail / t, TeamLeadTheme.urgentAmber),
          const SizedBox(height: 10),
          _distributionBar('Mortuary Cryo Transfer', mortuary, mortuary / t, TeamLeadTheme.textMuted),
        ],
      ),
    );
  }

  Widget _distributionBar(String label, int count, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
            Text('$count (${(ratio * 100).toStringAsFixed(0)}%)', style: TeamLeadTheme.telemetrySecondary(weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: TeamLeadTheme.surfaceLow,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _readinessCard(int fa, int ft, double fr, int da, int dt, double dr, int ea, int et, double er, int doa, int dot, double dor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        border: Border.all(color: TeamLeadTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Operational Resource Readiness Ratios', style: TeamLeadTheme.supportingBody(weight: FontWeight.w700)),
              const Icon(Icons.bar_chart_rounded, size: 18, color: TeamLeadTheme.operationalEmerald),
            ],
          ),
          const SizedBox(height: 14),
          _readinessMeter('Ambulance Fleet Availability', '$fa / $ft ready', fr),
          const SizedBox(height: 10),
          _readinessMeter('Commercial Drivers On Standby', '$da / $dt ready', dr),
          const SizedBox(height: 10),
          _readinessMeter('EMT / Paramedic Staff Readiness', '$ea / $et ready', er),
          const SizedBox(height: 10),
          _readinessMeter('On-Call Physicians & Intensivists', '$doa / $dot ready', dor),
        ],
      ),
    );
  }

  Widget _readinessMeter(String label, String detail, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
            Text(detail, style: TeamLeadTheme.telemetrySecondary(weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: TeamLeadTheme.surfaceLow,
            valueColor: AlwaysStoppedAnimation(ratio > 0.5 ? TeamLeadTheme.operationalEmerald : TeamLeadTheme.urgentAmber),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
