import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/mission_card.dart';

class ActiveTripsScreen extends StatefulWidget {
  const ActiveTripsScreen({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  State<ActiveTripsScreen> createState() => _ActiveTripsScreenState();
}

class _ActiveTripsScreenState extends State<ActiveTripsScreen> {
  final store = TeamLeadStore.instance;

  String _search = '';
  String _selectedMilestone = 'ALL';

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
  }

  @override
  void didUpdateWidget(covariant ActiveTripsScreen oldWidget) {
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
        final all = store.allBookings;

        final allActiveMissions = all.where(_isOperationalTrip).toList();
        final activeMissions = allActiveMissions.where((b) {
          final status = b.status.trim().toUpperCase();

          // Milestone filter
          if (_selectedMilestone != 'ALL') {
            if (_selectedMilestone == 'ASSIGNED' &&
                status != 'ASSIGNED' &&
                status != 'DRIVER_ASSIGNED') {
              return false;
            }
            if (_selectedMilestone != 'ASSIGNED' &&
                status != _selectedMilestone) {
              return false;
            }
          }

          // Search filter
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchesId = b.id.toLowerCase().contains(q);
            final matchesPatient = b.patientName.toLowerCase().contains(q);
            final matchesVehicle = b.vehicleNumber.toLowerCase().contains(q);
            final matchesDriver = b.driverName.toLowerCase().contains(q);
            if (!matchesId &&
                !matchesPatient &&
                !matchesVehicle &&
                !matchesDriver) {
              return false;
            }
          }

          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Milestone Filter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TeamLeadTheme.surfaceLowest,
                  borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                  border: Border.all(color: TeamLeadTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _search = val),
                      decoration: InputDecoration(
                        hintText: 'Search active missions by vehicle callsign, booking ID, patient...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: TeamLeadTheme.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            TeamLeadTheme.radiusSm,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip('ALL', 'All Active Missions'),
                        _filterChip('ASSIGNED', 'Assigned & Preparing'),
                        _filterChip('PICKUP_STARTED', 'En Route to Pickup'),
                        _filterChip('PATIENT_PICKED_UP', 'Patient Onboard'),
                        _filterChip('IN_TRANSIT', 'In Transit Corridor'),
                        _filterChip('ARRIVED', 'Arrived at Facility'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${activeMissions.length} SHOWN · ${allActiveMissions.length} ACTIVE MISSIONS · ${_lastRefreshLabel(store.lastSuccessfulBookingRefresh)}',
                      style: TeamLeadTheme.telemetryMicro(
                        color: TeamLeadTheme.textMuted,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh active missions',
                    onPressed: store.isRefreshingFromBackend
                        ? null
                        : () => store.refreshFromBackend(),
                    icon: store.isRefreshingFromBackend
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (store.bookingFeedError != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    'Live booking refresh failed. Showing the last successful data. ${store.bookingFeedError}',
                    style: TeamLeadTheme.small(color: const Color(0xFF991B1B)),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Missions List
              Expanded(
                child: activeMissions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              size: 48,
                              color: TeamLeadTheme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              allActiveMissions.isEmpty
                                  ? 'No Active Missions'
                                  : 'No Missions Match This Filter',
                              style: TeamLeadTheme.titleMedium(
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              allActiveMissions.isEmpty
                                  ? 'Active bookings from Supabase appear here with assigned resources, live GPS, and trip progression.'
                                  : 'Change the milestone filter or search term to see the other active missions.',
                              textAlign: TextAlign.center,
                              style: TeamLeadTheme.small(
                                color: TeamLeadTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: activeMissions.length,
                        itemBuilder: (context, i) {
                          final b = activeMissions[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: MissionCard(booking: b),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isOperationalTrip(Booking booking) => const {
    'ASSIGNED',
    'DRIVER_ASSIGNED',
    'PICKUP_STARTED',
    'PATIENT_PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED',
  }.contains(booking.status.trim().toUpperCase());

  String _lastRefreshLabel(DateTime? updatedAt) {
    if (updatedAt == null) return 'NOT SYNCED';
    final age = DateTime.now().difference(updatedAt);
    if (age.inSeconds < 10) return 'UPDATED JUST NOW';
    if (age.inMinutes < 1) return 'UPDATED ${age.inSeconds}s AGO';
    return 'UPDATED ${age.inMinutes}m AGO';
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedMilestone == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TeamLeadTheme.small(
          color: isSelected ? Colors.white : TeamLeadTheme.onSurfaceVariant,
        ),
      ),
      selected: isSelected,
      selectedColor: TeamLeadTheme.primary,
      backgroundColor: TeamLeadTheme.surfaceLow,
      onSelected: (val) {
        if (val) setState(() => _selectedMilestone = key);
      },
    );
  }
}
