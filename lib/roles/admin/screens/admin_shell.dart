import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/services/admin_repository.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';

import '../widgets/stitch_bottom_nav.dart';
import '../widgets/stitch_command_drawer.dart';
import '../widgets/stitch_header.dart';

import 'admin_audit_screen.dart';
import 'admin_booking_detail_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_pricing_screen.dart';
import 'admin_quotations_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_staff_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.user,
    required this.onSignOut,
    this.repository,
  });

  final AuthUser user;

  final VoidCallback onSignOut;

  final AdminRepository? repository;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late final AdminStore _store;

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  AdminBooking? _activeDetailBooking;

  static const List<String> _titles = [
    'Dashboard',
    'Bookings',
    'Fleet',
    'Staff',
    'Finance',
    'Reports',
    'Audit',
    'Pricing Settings',
  ];

  @override
  void initState() {
    super.initState();

    _store = AdminStore(
      repository: widget.repository,
    );

    // IMPORTANT:
    // Admin data is loaded directly from Supabase.
    // There is no dummy-data initialization here.
    _store.loadFromDatabase();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _navigateToTab(int index) {
    if (index < 0 || index >= _titles.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _activeDetailBooking = null;
    });
  }

  // ============================================================
  // BOOKING DETAIL
  // ============================================================

  void _openBookingDetail(AdminBooking booking) {
    setState(() {
      _activeDetailBooking = booking;
    });
  }

  void _closeBookingDetail() {
    setState(() {
      _activeDetailBooking = null;
    });
  }

  // ============================================================
  // SCREEN BUILDER
  // ============================================================

  List<Widget> _buildPages() {
    return [
      // --------------------------------------------------------
      // 0 - DASHBOARD
      // --------------------------------------------------------

      AdminDashboardScreen(
        store: _store,
        onOpenBookingDetail: _openBookingDetail,
        onNavigateTab: _navigateToTab,
      ),

      // --------------------------------------------------------
      // 1 - BOOKINGS
      // --------------------------------------------------------

      AdminBookingsScreen(
        store: _store,
        onOpenBookingDetail: _openBookingDetail,
      ),

      // --------------------------------------------------------
      // 2 - FLEET
      // --------------------------------------------------------

      AdminFleetScreen(
        store: _store,
      ),

      // --------------------------------------------------------
      // 3 - STAFF
      // --------------------------------------------------------

      AdminStaffScreen(
        store: _store,
      ),

      // --------------------------------------------------------
      // 4 - FINANCE / QUOTATIONS
      // --------------------------------------------------------

      AdminQuotationsScreen(
        store: _store,
      ),

      // --------------------------------------------------------
      // 5 - REPORTS
      // --------------------------------------------------------

      AdminReportsScreen(
        store: _store,
        onFilterBookings: (category) {
          // Reports can take the Admin user to the
          // Bookings tab when a report category is selected.
          _navigateToTab(1);
        },
      ),

      // --------------------------------------------------------
      // 6 - AUDIT
      // --------------------------------------------------------

      AdminAuditScreen(
        store: _store,
      ),

      // --------------------------------------------------------
      // 7 - PRICING
      // --------------------------------------------------------

      AdminPricingScreen(
        store: _store,
      ),
    ];
  }

  // ============================================================
  // BOOKING DETAIL VIEW
  // ============================================================

  Widget _buildBookingDetail() {
    final booking = _activeDetailBooking;

    if (booking == null) {
      return const SizedBox.shrink();
    }

    return AdminBookingDetailScreen(
      booking: booking,
      store: _store,
      onBack: _closeBookingDetail,
    );
  }

  // ============================================================
  // ERROR BAR
  // ============================================================

  Widget _buildDatabaseErrorBar() {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final error = _store.errorMessage;

        if (error == null || error.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: StitchTheme.error.withValues(
            alpha: 0.08,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 17,
                color: StitchTheme.error,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StitchTheme.labelSm(
                    color: StitchTheme.error,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              TextButton(
                onPressed: _store.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LOADING BAR
  // ============================================================

  Widget _buildLoadingBar() {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        if (!_store.isLoading) {
          return const SizedBox.shrink();
        }

        return const LinearProgressIndicator(
          minHeight: 2,
        );
      },
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // If user opened a booking detail page, show it directly.
    // ----------------------------------------------------------

    if (_activeDetailBooking != null) {
      return Scaffold(
        backgroundColor: StitchTheme.background,
        body: SafeArea(
          bottom: false,
          child: _buildBookingDetail(),
        ),
      );
    }

    final pages = _buildPages();

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: StitchTheme.background,

      // ========================================================
      // RIGHT SIDE COMMAND DRAWER
      // ========================================================

      endDrawer: StitchCommandDrawer(
        selectedIndex: _currentIndex,

        onSelect: _navigateToTab,

        onSignOut: widget.onSignOut,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        bottom: false,

        child: Column(
          children: [
            // --------------------------------------------------
            // ADMIN HEADER
            // --------------------------------------------------

            StitchHeader(
              title: _titles[_currentIndex],

              userName: widget.user.name,

              userEmail: widget.user.email,

              onOpenDrawer: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },

              // IMPORTANT:
              // Refreshes ALL Admin data from Supabase.
              onSync: _store.refresh,

              onSignOut: widget.onSignOut,
            ),

            // --------------------------------------------------
            // DATABASE LOADING INDICATOR
            // --------------------------------------------------

            _buildLoadingBar(),

            // --------------------------------------------------
            // DATABASE ERROR
            // --------------------------------------------------

            _buildDatabaseErrorBar(),

            // --------------------------------------------------
            // ADMIN PAGES
            // --------------------------------------------------

            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: StitchBottomNav(
        selectedIndex: _currentIndex,

        onSelect: _navigateToTab,

        onOpenMore: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _store.dispose();

    super.dispose();
  }
}