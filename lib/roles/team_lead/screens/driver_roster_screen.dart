import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/status_badge.dart';

class DriverRosterScreen extends StatefulWidget {
  const DriverRosterScreen({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  State<DriverRosterScreen> createState() => _DriverRosterScreenState();
}

class _DriverRosterScreenState extends State<DriverRosterScreen> {
  final store = TeamLeadStore.instance;

  String _search = '';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
  }

  @override
  void didUpdateWidget(covariant DriverRosterScreen oldWidget) {
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
        final drivers = store.drivers;

        final availableCount = drivers.where((d) => d.isAvailable).length;
        final assignedCount = drivers.where((d) => d.isAssigned || d.isOnTrip).length;
        final offDutyCount = drivers.where((d) => d.isOffDuty).length;

        final filtered = drivers.where((d) {
          if (_selectedStatus != 'ALL' && d.status != _selectedStatus) return false;

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchName = d.name.toLowerCase().contains(q);
            final matchPhone = d.phone.toLowerCase().contains(q);
            final matchLicense = d.licenseNumber.toLowerCase().contains(q);
            if (!matchName && !matchPhone && !matchLicense) return false;
          }

          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              LayoutBuilder(
                builder: (context, constraints) {
                  final title = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commercial Driver Personnel Roster', maxLines: constraints.maxWidth < 700 ? 2 : 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                      Text('$availableCount available on standby • $assignedCount on missions • $offDutyCount off duty', maxLines: 2, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                    ],
                  );
                  final refresh = OutlinedButton.icon(
                    onPressed: () => store.hydrateFromBackend(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Refresh Drivers', style: TeamLeadTheme.body(weight: FontWeight.w700)),
                  );
                  if (constraints.maxWidth < 700) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 10), refresh]);
                  }
                  return Row(children: [Expanded(child: title), const SizedBox(width: 16), refresh]);
                },
              ),
              const SizedBox(height: 16),

              // Search & Filter
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
                        hintText: 'Search driver name, phone, commercial license #...',
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
                        _filterChip('ALL', 'All Drivers'),
                        _filterChip('AVAILABLE', 'Available'),
                        _filterChip('ASSIGNED', 'Assigned'),
                        _filterChip('ON_TRIP', 'On Mission'),
                        _filterChip('OFF_DUTY', 'Off Duty'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No drivers found matching criteria.', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisExtent: 205,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final driver = filtered[i];
                          return _driverCard(driver);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label, style: TeamLeadTheme.small(color: isSelected ? Colors.white : TeamLeadTheme.onSurfaceVariant)),
      selected: isSelected,
      selectedColor: TeamLeadTheme.primary,
      backgroundColor: TeamLeadTheme.surfaceLow,
      onSelected: (val) {
        if (val) setState(() => _selectedStatus = key);
      },
    );
  }

  Widget _driverCard(DriverRosterItem driver) {
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: TeamLeadTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      driver.name.isNotEmpty ? driver.name[0] : 'D',
                      style: TeamLeadTheme.body(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.body(weight: FontWeight.w700)),
                      Text('${driver.experienceYears} yrs experience', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                    ],
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: StatusBadge(status: driver.status))),
            ],
          ),
          const SizedBox(height: 6),

          Text('License: ${driver.licenseNumber}', style: TeamLeadTheme.telemetrySecondary(color: TeamLeadTheme.primaryDark)),
          Text('Phone: ${driver.phone} • Depot: ${driver.depot}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
          Text('Categories: ${driver.supportedCategories.join(", ")}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.micro(color: TeamLeadTheme.textMuted)),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Completed Missions: ${driver.completedTrips}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: TeamLeadTheme.textMuted),
                onSelected: (newStatus) {
                  store.setDriverStatus(driver.id, newStatus);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'AVAILABLE', child: Text('Set Available')),
                  const PopupMenuItem(value: 'OFF_DUTY', child: Text('Set Off Duty')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
