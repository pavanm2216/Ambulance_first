import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../models/team_lead_models.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import '../widgets/team_lead_kpi_card.dart';
import 'allocation_queue_screen.dart';
import 'quotations_screen.dart';
import 'doctor_roster_screen.dart';

class TeamLeadCommandCenter extends StatefulWidget {
  const TeamLeadCommandCenter({
    super.key,
    this.onOpenAllocation,
    this.onOpenBudget,
    this.onOpenDoctors,
    this.onOpenActiveTrips,
  });

  final VoidCallback? onOpenAllocation;
  final VoidCallback? onOpenBudget;
  final VoidCallback? onOpenDoctors;
  final VoidCallback? onOpenActiveTrips;

  @override
  State<TeamLeadCommandCenter> createState() => _TeamLeadCommandCenterState();
}

class _TeamLeadCommandCenterState extends State<TeamLeadCommandCenter> {
  final TeamLeadStore _store = TeamLeadStore.instance;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _store.refreshFromBackend();
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<Booking> get _bookings => _store.allBookings;

  int get _totalBookings => _bookings.length;

  int get _pendingAllocation => _bookings.where((booking) {
    final status = booking.status.toUpperCase();
    return status == 'SENT_TO_TEAM_LEAD' ||
        status == 'ALLOCATION_PENDING' ||
        status == 'CUSTOMER_ACCEPTED' ||
        status == 'DRIVER_REJECTED';
  }).length;

  int get _pendingQuotations => _bookings.where((booking) {
    final status = booking.status.toUpperCase();
    return status == 'SENT_TO_TEAM_LEAD' ||
        status == 'VERIFIED' ||
        status == 'QUOTATION_PENDING' ||
        status == 'CUSTOMER_REJECTED';
  }).length;

  int get _activeTrips => _bookings.where(_isOperationalTrip).length;

  bool _isOperationalTrip(Booking booking) => const {
    'ASSIGNED',
    'DRIVER_ASSIGNED',
    'PICKUP_STARTED',
    'PATIENT_PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED',
  }.contains(booking.status.trim().toUpperCase());

  int get _completedTrips =>
      _bookings.where((booking) => booking.isCompleted).length;

  int get _availableAmbulances =>
      _store.ambulances.where(_isAvailableStatus).length;

  int get _availableDrivers => _store.drivers.where(_isAvailableStatus).length;

  int get _availableEmts => _store.emts.where(_isAvailableStatus).length;

  int get _availableDoctors => _store.doctors.where(_isAvailableStatus).length;

  bool _isAvailableStatus(dynamic resource) {
    final status = switch (resource) {
      AmbulanceUnit value => value.status,
      DriverRosterItem value => value.status,
      EmtRosterItem value => value.status,
      DoctorRosterItem value => value.status,
      _ => '',
    }.toUpperCase();

    return status == 'AVAILABLE' ||
        status == 'READY' ||
        status == 'ON_DUTY' ||
        status == 'ONLINE' ||
        status == 'ON_CALL';
  }

  void _open(Widget page, VoidCallback? callback) {
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command Center',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17202A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Live Team Lead operational control',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_error != null) _errorBanner(_error!),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _missionBanner(),
              const SizedBox(height: 18),
              _sectionTitle('Operational telemetry'),
              const SizedBox(height: 10),
              _grid([
                _metric(
                  'Pending Allocation',
                  _pendingAllocation,
                  Icons.assignment_outlined,
                  () => _open(
                    const AllocationQueueScreen(),
                    widget.onOpenAllocation,
                  ),
                ),
                _metric(
                  'Pending Quotations',
                  _pendingQuotations,
                  Icons.receipt_long_outlined,
                  () => _open(
                    const BudgetQuotationsScreen(),
                    widget.onOpenBudget,
                  ),
                ),
                _metric(
                  'Active Trips',
                  _activeTrips,
                  Icons.navigation_outlined,
                  widget.onOpenActiveTrips,
                ),
                _metric(
                  'Completed Trips',
                  _completedTrips,
                  Icons.task_alt_outlined,
                  null,
                ),
                _metric(
                  'Available Ambulances',
                  _availableAmbulances,
                  Icons.local_shipping_outlined,
                  null,
                ),
                _metric(
                  'Available Drivers',
                  _availableDrivers,
                  Icons.groups_outlined,
                  null,
                ),
                _metric(
                  'Available EMTs',
                  _availableEmts,
                  Icons.medical_services_outlined,
                  null,
                ),
                _metric(
                  'Available Doctors',
                  _availableDoctors,
                  Icons.health_and_safety_outlined,
                  () => _open(const DoctorRosterScreen(), widget.onOpenDoctors),
                ),
              ]),
              const SizedBox(height: 18),
              _sectionTitle('Live data'),
              const SizedBox(height: 10),
              _infoCard(
                'Single source of truth',
                'Bookings, fleet, drivers, medical crew and doctors are read directly from Supabase. No demo counters are used.',
                Icons.cloud_done_outlined,
              ),
              const SizedBox(height: 10),
              _infoCard(
                'Dispatch rule',
                'Allocation is only allowed after the customer accepts the authoritative quotation.',
                Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 10),
              _infoCard(
                'Quotation rule',
                'The Budget page calls prepare_booking_quotation() so the final amount comes from pricing_settings and the booking requirements.',
                Icons.calculate_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _missionBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7E7D2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF087F5B),
            child: Icon(Icons.shield_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'MISSION CONTROL DISPATCH READY  •  $_totalBookings total bookings  •  $_activeTrips active missions',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF175A45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: Color(0xFF667085),
    ),
  );

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 300
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _metric(String title, int value, IconData icon, VoidCallback? onTap) {
    return TeamLeadKpiCard(
      title: title,
      value: '$value',
      icon: icon,
      onTap: onTap,
      accentColor: TeamLeadTheme.clinicalCobalt,
    );
  }

  Widget _infoCard(String title, String body, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006A9B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Color(0xFF667085))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String error) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF2B8B5)),
    ),
    child: Text(error),
  );
}
