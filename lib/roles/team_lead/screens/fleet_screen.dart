import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/status_badge.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final store = TeamLeadStore.instance;

  String _search = '';
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
  }

  @override
  void didUpdateWidget(covariant FleetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearch != oldWidget.initialSearch) {
      setState(() => _search = widget.initialSearch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final ambulances = store.ambulances;

        final alsCount = ambulances.where((a) => a.category == 'Advanced Life Support').length;
        final picuCount = ambulances.where((a) => a.category.contains('Pediatric') || a.hasCapability('PICU')).length;
        final availableCount = ambulances.where((a) => a.isAvailable).length;
        final maintenanceCount = ambulances.where((a) => a.isMaintenance).length;
        final inTransitCount = ambulances.where((a) => a.isInTransit || a.isAssigned).length;

        final filtered = ambulances.where((a) {
          if (_selectedFilter == 'AVAILABLE' && !a.isAvailable) return false;
          if (_selectedFilter == 'MAINTENANCE' && !a.isMaintenance) return false;
          if (_selectedFilter == 'ASSIGNED' && !a.isAssigned && !a.isInTransit) return false;
          if (_selectedFilter == 'ALS' && a.category != 'Advanced Life Support') return false;
          if (_selectedFilter == 'PICU' && !a.hasCapability('PICU')) return false;
          if (_selectedFilter == 'MORTUARY' && !a.hasCapability('FREEZER')) return false;

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchName = a.name.toLowerCase().contains(q);
            final matchReg = a.registrationNumber.toLowerCase().contains(q);
            final matchModel = a.model.toLowerCase().contains(q);
            final matchDepot = a.baseStation.toLowerCase().contains(q);
            if (!matchName && !matchReg && !matchModel && !matchDepot) return false;
          }

          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final title = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambulance Fleet Registry & Readiness',
                        maxLines: constraints.maxWidth < 700 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TeamLeadTheme.titleMedium(weight: FontWeight.w700),
                      ),
                      Text(
                        '${ambulances.length} registered vehicles across central & regional depots',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                      ),
                    ],
                  );
                  final refresh = OutlinedButton.icon(
                    onPressed: () => store.hydrateFromBackend(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Refresh Live Fleet', style: TeamLeadTheme.body(weight: FontWeight.w700)),
                  );

                  if (constraints.maxWidth < 700) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 10), refresh],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      refresh,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  return Row(
                    children: [
                      _kpiMini('Total Fleet', '${ambulances.length}', TeamLeadTheme.primaryDark),
                      const SizedBox(width: 10),
                      _kpiMini('Available', '$availableCount', TeamLeadTheme.operationalEmerald),
                      const SizedBox(width: 10),
                      _kpiMini('In Transit / Assigned', '$inTransitCount', TeamLeadTheme.clinicalCobalt),
                      const SizedBox(width: 10),
                      _kpiMini('Maintenance', '$maintenanceCount', TeamLeadTheme.urgentAmber),
                      if (isDesktop) ...[
                        const SizedBox(width: 10),
                        _kpiMini('ALS Units', '$alsCount', TeamLeadTheme.primary),
                        const SizedBox(width: 10),
                        _kpiMini('PICU / NICU', '$picuCount', TeamLeadTheme.primary),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TeamLeadTheme.surfaceLowest,
                  borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                  border: Border.all(color: TeamLeadTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _search = val),
                      decoration: InputDecoration(
                        hintText: 'Search callsign, license plate, model, depot...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: TeamLeadTheme.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip('ALL', 'All Units'),
                        _filterChip('AVAILABLE', 'Available'),
                        _filterChip('ASSIGNED', 'Assigned / Active'),
                        _filterChip('MAINTENANCE', 'In Maintenance'),
                        _filterChip('ALS', 'ALS Fleet'),
                        _filterChip('PICU', 'Pediatric / Neonatal'),
                        _filterChip('MORTUARY', 'Mortuary Cryo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fleet Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No vehicles found matching current criteria.', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisExtent: 225,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final unit = filtered[i];
                          return _ambulanceCard(unit);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiMini(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TeamLeadTheme.surfaceLowest,
          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
          border: Border.all(color: TeamLeadTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: TeamLeadTheme.headline(color: color, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label, style: TeamLeadTheme.small(color: isSelected ? Colors.white : TeamLeadTheme.onSurfaceVariant)),
      selected: isSelected,
      selectedColor: TeamLeadTheme.primary,
      backgroundColor: TeamLeadTheme.surfaceLow,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _ambulanceCard(AmbulanceUnit unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        border: Border.all(color: TeamLeadTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: TeamLeadTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    ),
                    child: const Icon(Icons.airport_shuttle_rounded, color: TeamLeadTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.body(weight: FontWeight.w700)),
                      Text(unit.registrationNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.telemetrySecondary(color: TeamLeadTheme.primaryDark, weight: FontWeight.w600)),
                    ],
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: StatusBadge(status: unit.status))),
            ],
          ),
          const SizedBox(height: 6),

          Text('${unit.model} • ${unit.category}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
          Text('Depot: ${unit.baseStation}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.textMuted)),

          const SizedBox(height: 6),
          // Capabilities wrap
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: unit.capabilities.take(5).map((cap) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: TeamLeadTheme.surfaceLow,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: TeamLeadTheme.borderSubtle),
              ),
              child: Text(cap, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.primaryDark)),
            )).toList(),
          ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  unit.assignedBookingId != null ? 'Booking: ${unit.assignedBookingId}' : 'Standby in Depot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TeamLeadTheme.telemetryMicro(color: unit.assignedBookingId != null ? TeamLeadTheme.primary : TeamLeadTheme.textMuted),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: TeamLeadTheme.textMuted),
                onSelected: (newStatus) {
                  if (unit.assignedBookingId != null && newStatus == 'MAINTENANCE') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot place an assigned ambulance into maintenance. Please reassign the booking first.')),
                    );
                    return;
                  }
                  store.setAmbulanceStatus(unit.id, newStatus);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'AVAILABLE', child: Text('Mark Available')),
                  const PopupMenuItem(value: 'MAINTENANCE', child: Text('Set Maintenance')),
                  const PopupMenuItem(value: 'OFFLINE', child: Text('Take Offline')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
