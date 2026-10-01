import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import '../widgets/stitch_safety_dialog.dart';
import '../widgets/stitch_status_badge.dart';
import 'admin_fleet_register_screen.dart';
import 'admin_shared.dart';

class AdminFleetScreen extends StatefulWidget {
  const AdminFleetScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'ALL';
  String _selectedStatus = 'ALL';
  final Set<String> _expandedTelemetryIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final q = _searchCtrl.text.trim().toLowerCase();

        final filtered = store.ambulances.where((a) {
          if (q.isNotEmpty) {
            final text =
                '${a.callSign} ${a.vehicleCadNo} ${a.platform} ${a.stationBase} ${a.currentLocation}'
                    .toLowerCase();
            if (!text.contains(q)) return false;
          }
          if (_selectedCategory != 'ALL' && a.category != _selectedCategory) {
            return false;
          }
          if (_selectedStatus != 'ALL' && a.status.label != _selectedStatus) {
            return false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Headline & Action
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.all(StitchTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: StitchTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                    border: Border.all(color: StitchTheme.borderSubtle),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 10,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth > 520
                              ? (constraints.maxWidth - 220).clamp(
                                  0.0,
                                  double.infinity,
                                )
                              : constraints.maxWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 22,
                                    color: StitchTheme.primaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Fleet Command',
                                      style: StitchTheme.headlineMd(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Real-time readiness, vehicle telemetry, and lifecycle maintenance.',
                                style: StitchTheme.bodySm(
                                  color: StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => AdminFleetRegisterScreen(
                                  store: store,
                                  onFinished: () => Navigator.of(ctx).pop(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('+ Register Ambulance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StitchTheme.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                StitchTheme.radiusSm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // 2. KPI Metric Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 880;
                  final tileWidth = isWide
                      ? (constraints.maxWidth - 18) / 4
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: _FleetKpiTile(
                          label: 'TOTAL FLEET',
                          value: '${store.totalAmbulancesCount}',
                          unit: 'units',
                          barPct: 1.0,
                          barColor: StitchTheme.primaryContainer,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _FleetKpiTile(
                          label: 'AVAILABLE',
                          value: '${store.availableAmbulancesCount}',
                          unit: '${store.fleetAvailabilityPercentage.round()}%',
                          barPct: store.fleetAvailabilityPercentage / 100,
                          barColor: StitchTheme.tertiary,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _FleetKpiTile(
                          label: 'ON MISSION',
                          value: '${store.activeMissionAmbulancesCount}',
                          unit: 'Active',
                          barPct: store.totalAmbulancesCount > 0
                              ? store.activeMissionAmbulancesCount /
                                    store.totalAmbulancesCount
                              : 0.0,
                          barColor: StitchTheme.primaryContainer,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _FleetKpiTile(
                          label: 'SERVICE',
                          value: '${store.maintenanceAmbulancesCount}',
                          unit: 'Maint',
                          barPct: store.totalAmbulancesCount > 0
                              ? store.maintenanceAmbulancesCount /
                                    store.totalAmbulancesCount
                              : 0.0,
                          barColor: StitchTheme.secondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // 3. Search & Filters Container
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
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Search by vehicle number, call sign, base...',
                        hintStyle: StitchTheme.bodySm(
                          color: StitchTheme.outline,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: StitchTheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Type: ',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.outline,
                            ),
                          ),
                          _FleetFilterChip(
                            label: 'All Categories',
                            isSelected: _selectedCategory == 'ALL',
                            onTap: () =>
                                setState(() => _selectedCategory = 'ALL'),
                          ),
                          _FleetFilterChip(
                            label: 'ROAD',
                            isSelected: _selectedCategory == 'ROAD',
                            onTap: () =>
                                setState(() => _selectedCategory = 'ROAD'),
                          ),
                          _FleetFilterChip(
                            label: 'AIR',
                            isSelected: _selectedCategory == 'AIR',
                            onTap: () =>
                                setState(() => _selectedCategory = 'AIR'),
                          ),
                          _FleetFilterChip(
                            label: 'DEAD_BODY',
                            isSelected: _selectedCategory == 'DEAD_BODY',
                            onTap: () =>
                                setState(() => _selectedCategory = 'DEAD_BODY'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Status Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Status: ',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.outline,
                            ),
                          ),
                          _FleetFilterChip(
                            label: 'All',
                            isSelected: _selectedStatus == 'ALL',
                            onTap: () =>
                                setState(() => _selectedStatus = 'ALL'),
                          ),
                          _FleetFilterChip(
                            label: 'AVAILABLE',
                            isSelected: _selectedStatus == 'AVAILABLE',
                            onTap: () =>
                                setState(() => _selectedStatus = 'AVAILABLE'),
                          ),
                          _FleetFilterChip(
                            label: 'ACTIVE MISSION',
                            isSelected: _selectedStatus == 'ACTIVE MISSION',
                            onTap: () => setState(
                              () => _selectedStatus = 'ACTIVE MISSION',
                            ),
                          ),
                          _FleetFilterChip(
                            label: 'MAINTENANCE',
                            isSelected: _selectedStatus == 'MAINTENANCE',
                            onTap: () =>
                                setState(() => _selectedStatus = 'MAINTENANCE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceSm),

              // 4. Governance Policy Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.policy_rounded,
                      size: 18,
                      color: StitchTheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notice: Active or Assigned vehicles cannot transition to Available without formal patient handover confirmation.',
                        style: StitchTheme.bodySm(color: StitchTheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // 5. Vehicle Manifest Stream
              for (final amb in filtered) ...[
                _AmbulanceCard(
                  ambulance: amb,
                  isTelemetryExpanded: _expandedTelemetryIds.contains(amb.id),
                  onToggleTelemetry: () {
                    setState(() {
                      if (_expandedTelemetryIds.contains(amb.id)) {
                        _expandedTelemetryIds.remove(amb.id);
                      } else {
                        _expandedTelemetryIds.add(amb.id);
                      }
                    });
                  },
                  onStatusChange: () => _handleStatusChange(amb),
                ),
                const SizedBox(height: StitchTheme.spaceMd),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _handleStatusChange(AdminAmbulance amb) {
    // 1. If currently on Active Mission: blocked!
    if (amb.status == FleetStatus.activeMission ||
        amb.status == FleetStatus.inTransit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: StitchTheme.surfaceContainerLowest,
          title: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: StitchTheme.error),
              const SizedBox(width: 8),
              Text('Safety Governance Lock', style: StitchTheme.headlineSm()),
            ],
          ),
          content: Text(
            'Unit ${amb.callSign} is currently on active mission #${amb.activeIncidentId ?? "CURRENT"}.\n\nTransitioning to "Available" is blocked until hospital clinical receiving confirms electronic patient handover.',
            style: StitchTheme.bodyMd(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. If in Maintenance: requires clinical checklist signoff + PIN!
    if (amb.status == FleetStatus.maintenance) {
      showDialog(
        context: context,
        builder: (ctx) => StitchSafetySignoffDialog(
          ambulance: amb,
          onConfirm: (pin, checklistPassed) {
            () async {
              final res = await widget.store.updateAmbulanceStatusAsync(
                ambulanceId: amb.id,
                newStatus: FleetStatus.available,
                supervisorPin: pin,
                checklistPassed: checklistPassed,
              );
              if (!mounted) return;
              showStitchToast(context, res.$2, isError: !res.$1);
            }();
          },
        ),
      );
      return;
    }

    // 3. If Available: can transition to Maintenance
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StitchTheme.surfaceContainerLowest,
        title: Text(
          'Shift ${amb.callSign} to Maintenance?',
          style: StitchTheme.headlineSm(),
        ),
        content: Text(
          'Vehicle will be taken out of active dispatch pool for scheduled inspection or bay servicing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              () async {
                final res = await widget.store.updateAmbulanceStatusAsync(
                  ambulanceId: amb.id,
                  newStatus: FleetStatus.maintenance,
                );
                if (!mounted) return;
                showStitchToast(context, res.$2, isError: !res.$1);
              }();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StitchTheme.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Maintenance'),
          ),
        ],
      ),
    );
  }
}

class _FleetKpiTile extends StatelessWidget {
  const _FleetKpiTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.barPct,
    required this.barColor,
  });

  final String label;
  final String value;
  final String unit;
  final double barPct;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusMd),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StitchTheme.labelSm(
              color: StitchTheme.outline,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: StitchTheme.headlineMd()),
              const SizedBox(width: 3),
              Text(
                unit,
                style: StitchTheme.labelSm(
                  color: barColor,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: barPct.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: StitchTheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetFilterChip extends StatelessWidget {
  const _FleetFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? StitchTheme.primaryContainer
                : StitchTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
          ),
          child: Text(
            label,
            style: StitchTheme.labelSm(
              color: isSelected ? Colors.white : StitchTheme.onSurface,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbulanceCard extends StatelessWidget {
  const _AmbulanceCard({
    required this.ambulance,
    required this.isTelemetryExpanded,
    required this.onToggleTelemetry,
    required this.onStatusChange,
  });

  final AdminAmbulance ambulance;
  final bool isTelemetryExpanded;
  final VoidCallback onToggleTelemetry;
  final VoidCallback onStatusChange;

  @override
  Widget build(BuildContext context) {
    final a = ambulance;
    final topBarColor =
        a.status == FleetStatus.activeMission ||
            a.status == FleetStatus.inTransit
        ? StitchTheme.primaryContainer
        : a.status == FleetStatus.available
        ? StitchTheme.tertiary
        : StitchTheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Accent Stripe
            Container(height: 4, width: double.infinity, color: topBarColor),

            Padding(
              padding: const EdgeInsets.all(StitchTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: CallSign, Model, and Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    a.callSign,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: StitchTheme.headlineSm(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: StitchTheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      a.vehicleCadNo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: StitchTheme.labelSm(
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.platform,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StitchTheme.bodySm(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: StitchStatusBadge.fromFleet(a.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location / Active Mission Strip
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: StitchTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: StitchTheme.primaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  a.currentLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.onSurface,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (a.activeIncidentId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: StitchTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '#${a.activeIncidentId!}',
                              style: StitchTheme.labelSm(
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Operational Telemetry: Fuel Gauge & Oxygen Pressure
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fuel',
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.outline,
                                  ),
                                ),
                                Text(
                                  '${a.fuelPercent}%',
                                  style: StitchTheme.labelSm(
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: a.fuelPercent / 100,
                              minHeight: 4,
                              backgroundColor: StitchTheme.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                a.fuelPercent > 30
                                    ? StitchTheme.primaryContainer
                                    : StitchTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'O2 Pressure',
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.outline,
                                  ),
                                ),
                                Text(
                                  '${a.oxygenPressureBar} Bar',
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.tertiary,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: (a.oxygenPressureBar / 200).clamp(
                                0.0,
                                1.0,
                              ),
                              minHeight: 4,
                              backgroundColor: StitchTheme.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                StitchTheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Capabilities Chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (a.hasOxygen) _CapChip(label: 'OXYGEN'),
                      if (a.hasIcu) _CapChip(label: 'ICU'),
                      if (a.hasVentilator) _CapChip(label: 'VENT'),
                      if (a.hasPicu) _CapChip(label: 'PICU'),
                      if (a.hasIncubator) _CapChip(label: 'INCUBATOR'),
                      if (a.hasFreezer) _CapChip(label: 'FREEZER'),
                    ],
                  ),

                  // Expandable Telemetry Drawer
                  if (isTelemetryExpanded) ...[
                    const Divider(height: 16, color: StitchTheme.borderSubtle),
                    Text(
                      'TECHNICAL DIAGNOSTICS',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.outline,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assigned Driver: ${a.assignedDriver ?? "Pool Standby"}',
                    ),
                    Text('Station Base: ${a.stationBase}'),
                    Text(
                      'Service Date: ${a.serviceDate} (${a.inspectionStatus})',
                    ),
                    if (a.workOrder != null)
                      Text(
                        'Work Order: ${a.workOrder!}',
                        style: StitchTheme.bodySm(color: StitchTheme.error),
                      ),
                  ],

                  const SizedBox(height: 10),

                  // Card Bottom Actions
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 6,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onToggleTelemetry,
                        icon: Icon(
                          isTelemetryExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isTelemetryExpanded
                              ? 'Hide Specs'
                              : 'Telemetry Specs',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onStatusChange,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: StitchTheme.borderSubtle,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          a.status == FleetStatus.maintenance
                              ? 'Safety Clear Ready'
                              : 'Change Status',
                          style: StitchTheme.labelSm(
                            color: StitchTheme.primaryContainer,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _CapChip extends StatelessWidget {
  const _CapChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Text(
        label,
        style: StitchTheme.labelSm(
          color: StitchTheme.onSurfaceVariant,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}
