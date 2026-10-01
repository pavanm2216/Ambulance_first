import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/status_badge.dart';

class EmtRosterScreen extends StatefulWidget {
  const EmtRosterScreen({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  State<EmtRosterScreen> createState() => _EmtRosterScreenState();
}

class _EmtRosterScreenState extends State<EmtRosterScreen> {
  final store = TeamLeadStore.instance;

  String _search = '';
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
  }

  @override
  void didUpdateWidget(covariant EmtRosterScreen oldWidget) {
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
        final emts = store.emts;

        final availableCount = emts.where((e) => e.isAvailable).length;
        final pediatricCount = emts.where((e) => e.hasPediatricCapability).length;

        final filtered = emts.where((e) {
          if (_selectedFilter == 'AVAILABLE' && !e.isAvailable) return false;
          if (_selectedFilter == 'PEDIATRIC' && !e.hasPediatricCapability) return false;
          if (_selectedFilter == 'OFF_DUTY' && !e.isOffDuty) return false;

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchName = e.name.toLowerCase().contains(q);
            final matchQual = e.qualification.toLowerCase().contains(q);
            final matchDepot = e.depot.toLowerCase().contains(q);
            if (!matchName && !matchQual && !matchDepot) return false;
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
                      Text('Emergency Medical Technicians & Paramedics', maxLines: constraints.maxWidth < 700 ? 2 : 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                      Text('$availableCount available on active standby • $pediatricCount pediatric (PALS) certified', maxLines: 2, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                    ],
                  );
                  final refresh = OutlinedButton.icon(
                    onPressed: () => store.hydrateFromBackend(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Refresh EMTs', style: TeamLeadTheme.body(weight: FontWeight.w700)),
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
                        hintText: 'Search EMT name, degree qualification, certifications...',
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
                        _filterChip('ALL', 'All EMTs'),
                        _filterChip('AVAILABLE', 'Available'),
                        _filterChip('PEDIATRIC', 'Pediatric / PALS Certified'),
                        _filterChip('OFF_DUTY', 'Off Duty'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No EMTs found matching criteria.', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisExtent: 200,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final emt = filtered[i];
                          return _emtCard(emt);
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

  Widget _emtCard(EmtRosterItem emt) {
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
                    backgroundColor: TeamLeadTheme.operationalEmerald.withValues(alpha: 0.1),
                    child: Text(
                      emt.name.isNotEmpty ? emt.name[0] : 'E',
                      style: TeamLeadTheme.body(color: TeamLeadTheme.operationalEmerald, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emt.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.body(weight: FontWeight.w700)),
                      Text('${emt.experienceYears} yrs clinical experience', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                    ],
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: StatusBadge(status: emt.status))),
            ],
          ),
          const SizedBox(height: 6),

          Text(emt.qualification, style: TeamLeadTheme.supportingBody(color: TeamLeadTheme.primaryDark, weight: FontWeight.w600)),
          Text('Depot: ${emt.depot} • Phone: ${emt.phone}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.small(color: TeamLeadTheme.textMuted)),

          const SizedBox(height: 6),
          Row(
            children: [
              Wrap(
                spacing: 4,
                children: emt.certifications.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: TeamLeadTheme.surfaceLow, borderRadius: BorderRadius.circular(2)),
                  child: Text(c, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700)),
                )).toList(),
              ),
              if (emt.hasPediatricCapability) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: TeamLeadTheme.emeraldBg, borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill)),
                  child: Text('PEDIATRIC CERTIFIED', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.emeraldText, weight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(
                'Status derived from active booking assignment',
                style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
