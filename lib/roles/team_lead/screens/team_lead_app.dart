import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../store/team_lead_store.dart';
import '../widgets/team_lead_shell.dart';

import 'active_trips_screen.dart';
import 'allocation_queue_screen.dart';
import 'doctor_roster_screen.dart';
import 'driver_roster_screen.dart';
import 'emt_roster_screen.dart';
import 'fleet_screen.dart';
import 'reports_screen.dart';

// Live Supabase Team Lead screens.
import 'command_center_screen.dart';
import 'quotations_screen.dart';

/// Ambulance First — Team Lead Operations Command Portal.
///
/// Navigation shell for the 9 Team Lead operational modules.
///
/// Data is loaded by the individual screens/store from Supabase.
/// This shell is responsible only for navigation and shared search state.
class TeamLeadShell extends StatefulWidget {
  const TeamLeadShell({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  State<TeamLeadShell> createState() => _TeamLeadShellState();
}

class _TeamLeadShellState extends State<TeamLeadShell> {
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    TeamLeadStore.instance.startLiveBackendSync(userId: widget.user.id);
  }

  @override
  void dispose() {
    TeamLeadStore.instance.stopLiveBackendSync();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index > 8) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _openAllocationQueue() {
    _onDestinationSelected(1);
  }

  void _openBudgetQuotations() {
    _onDestinationSelected(2);
  }

  void _openDoctors() {
    _onDestinationSelected(7);
  }

  void _openActiveTrips() {
    _onDestinationSelected(3);
  }

  @override
  Widget build(BuildContext context) {
    return TeamLeadLayoutShell(
      user: widget.user,
      selectedIndex: _currentIndex,
      onDestinationSelected: _onDestinationSelected,
      onLogout: widget.onLogout,
      searchQuery: _searchQuery,
      onSearchChanged: _onSearchChanged,
      child: IndexedStack(
        index: _currentIndex,
        children: [
          // ============================================================
          // 0 — COMMAND CENTER
          // ============================================================

          TeamLeadCommandCenter(
            onOpenAllocation: _openAllocationQueue,
            onOpenBudget: _openBudgetQuotations,
            onOpenDoctors: _openDoctors,
            onOpenActiveTrips: _openActiveTrips,
          ),

          // ============================================================
          // 1 — ALLOCATION QUEUE
          // ============================================================
          AllocationQueueScreen(initialSearch: _searchQuery),

          // ============================================================
          // 2 — BUDGET & QUOTATIONS
          // ============================================================
          const BudgetQuotationsScreen(),

          // ============================================================
          // 3 — ACTIVE TRIPS
          // ============================================================
          ActiveTripsScreen(initialSearch: _searchQuery),

          // ============================================================
          // 4 — FLEET
          // ============================================================
          FleetScreen(initialSearch: _searchQuery),

          // ============================================================
          // 5 — DRIVER ROSTER
          // ============================================================
          DriverRosterScreen(initialSearch: _searchQuery),

          // ============================================================
          // 6 — EMT / MEDICAL CREW
          // ============================================================
          EmtRosterScreen(initialSearch: _searchQuery),

          // ============================================================
          // 7 — DOCTOR ROSTER
          // ============================================================
          //
          // DoctorRosterScreen currently manages its own search/filter,
          // so do not pass initialSearch here.
          const DoctorRosterScreen(),

          // ============================================================
          // 8 — REPORTS
          // ============================================================
          const ReportsScreen(),
        ],
      ),
    );
  }
}
