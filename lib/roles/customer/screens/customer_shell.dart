import 'package:flutter/material.dart';
import '../../../core/models/auth_user.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/customer_booking_workflow_service.dart';
import '../../../core/services/customer_portal_cache.dart';
import '../../../core/services/shared_booking_store.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../theme/ambulance_first_theme.dart';
import '../widgets/ambulance_first_button.dart';
import '../widgets/sos_dialog.dart';
import 'book_ambulance_wizard_screen.dart';
import 'customer_active_trip_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_dashboard_screen.dart';
import 'customer_history_screen.dart';
import 'home_services_screen.dart';
import 'customer_quotations_screen.dart';

/// Responsive Customer Portal Shell for Ambulance First
/// Translates the Stitch design system (projects/5751480897733590618)
/// into a production-grade adaptive Flutter workspace.
class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.user,
    this.onLogout,
  });

  final AuthUser user;
  final VoidCallback? onLogout;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;
  bool _isBookingWizardOpen = false;

  List<Booking> get _userBookings =>
      CustomerBookingWorkflowService.forCustomer(SharedBookingStore.bookings, widget.user.id);

  int get _pendingQuotesCount =>
      _userBookings.where((b) => b.hasPendingQuotation).length;

    int get _unreadNotificationsCount => CustomerPortalCache.notifications
      .where((notification) =>
        notification['read'] != true && notification['is_read'] != true)
      .length;

  int get _activeTripsCount => _userBookings.where((b) =>
      b.isActive).length;

  void _navigateToSection(int index) {
    setState(() {
      _currentIndex = index;
      _isBookingWizardOpen = false;
    });
  }

  void _openBookingWizard() {
    setState(() => _isBookingWizardOpen = true);
  }

  void _closeBookingWizard() {
    setState(() => _isBookingWizardOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AmbulanceFirstTheme.lightTheme(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          return Scaffold(
            backgroundColor: AmbulanceFirstColors.surface,
            // App Bar (Always visible on mobile/tablet, top-right controls on desktop)
            appBar: _buildAppBar(context, isDesktop),
            body: Row(
              children: [
                // Desktop Persistent Left Navigation Rail
                if (isDesktop) _buildDesktopNavRail(),

                // Main Workspace Area
                Expanded(
                  child: _isBookingWizardOpen
                      ? BookAmbulanceWizardScreen(
                          user: widget.user,
                          onBookingCreated: (b) {
                            _closeBookingWizard();
                            _navigateToSection(1); // Jump to bookings
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking #${b.id} submitted successfully!'),
                                backgroundColor: AmbulanceFirstColors.secondary,
                              ),
                            );
                          },
                          onCancel: _closeBookingWizard,
                        )
                      : IndexedStack(
                          index: _currentIndex,
                          children: [
                            CustomerDashboardScreen(
                              user: widget.user,
                              onBookNewAmbulance: _openBookingWizard,
                              onNavigateToSection: _navigateToSection,
                            ),
                            CustomerBookingsScreen(
                              user: widget.user,
                              onBookNewAmbulance: _openBookingWizard,
                            ),
                            CustomerActiveTripScreen(
                              user: widget.user,
                              onBookNewAmbulance: _openBookingWizard,
                            ),
                            CustomerQuotationsScreen(
                              user: widget.user,
                              onBookNewAmbulance: _openBookingWizard,
                            ),
                            CustomerHistoryScreen(
                              user: widget.user,
                              onBookNewAmbulance: _openBookingWizard,
                            ),
                            HomeServicesScreen(
                              user: widget.user,
                              onBookingCreated: (b) {
                                _navigateToSection(1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Home service booking #${b.id} submitted successfully!',
                                    ),
                                    backgroundColor: AmbulanceFirstColors.secondary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
            // Mobile Bottom Navigation Bar (Hidden in Wizard mode or Desktop)
            bottomNavigationBar: (!isDesktop && !_isBookingWizardOpen)
                ? _buildMobileBottomNav()
                : null,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar: Brand Logo + Section Title + Emergency SOS + Notifications + Avatar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    final title = _isBookingWizardOpen
        ? 'New Request'
        : _navTitles[_currentIndex];

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: isDesktop ? 20 : 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.clinicalCobalt,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
            child: const Center(
              child: Icon(
                Icons.local_hospital_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AMBULANCE FIRST',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.codeSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                    weight: FontWeight.w700,
                  ).copyWith(letterSpacing: 1.2, fontSize: 10),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.headlineSm(
                    color: AmbulanceFirstColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 1. Emergency SOS Trigger
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => EmergencySosDialog.show(context),
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AmbulanceFirstColors.errorContainer,
                  borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      size: 18,
                      color: AmbulanceFirstColors.medicalCrimson,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SOS',
                      style: AmbulanceFirstTypography.codeSm(
                        color: AmbulanceFirstColors.medicalCrimson,
                        weight: FontWeight.w700,
                      ).copyWith(letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          IconButton(
            onPressed: () => EmergencySosDialog.show(context),
            tooltip: 'Emergency SOS',
            style: IconButton.styleFrom(
              backgroundColor: AmbulanceFirstColors.errorContainer,
              foregroundColor: AmbulanceFirstColors.medicalCrimson,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.emergency_rounded, size: 20),
          ),

        // 2. Notification Center with unread indicator
        IconButton(
          onPressed: () => _showNotifications(context),
          tooltip: 'Notifications',
          visualDensity: VisualDensity.compact,
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 22),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AmbulanceFirstColors.medicalCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 3. User Avatar Profile Button
        Padding(
          padding: EdgeInsets.only(right: isDesktop ? 16 : 8, left: 2),
          child: InkWell(
            onTap: () => _showProfileDialog(context),
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AmbulanceFirstColors.surfaceContainerHigh,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name.substring(0, widget.user.name.length >= 2 ? 2 : 1).toUpperCase()
                    : 'AT',
                style: AmbulanceFirstTypography.codeSm(
                  color: AmbulanceFirstColors.clinicalCobalt,
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop Navigation Rail
  // ---------------------------------------------------------------------------
  Widget _buildDesktopNavRail() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        border: Border(right: BorderSide(color: AmbulanceFirstColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Primary CTA in Rail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AmbulanceFirstButton(
              label: 'BOOK AMBULANCE',
              icon: Icons.add_circle_outline_rounded,
              fullWidth: true,
              onPressed: _openBookingWizard,
              variant: AmbulanceFirstButtonVariant.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Destinations List
          _railItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
          _railItem(1, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'My Bookings'),
          _railItem(2, Icons.airport_shuttle_outlined, Icons.airport_shuttle_rounded, 'Active Trips', badge: _activeTripsCount > 0 ? '$_activeTripsCount' : null, isPulse: _activeTripsCount > 0),
          _railItem(3, Icons.request_quote_outlined, Icons.request_quote_rounded, 'Quotations', badge: _pendingQuotesCount > 0 ? '$_pendingQuotesCount' : null),
          _railItem(4, Icons.history_rounded, Icons.history_rounded, 'History'),
          _railItem(5, Icons.home_work_outlined, Icons.home_work_rounded, 'Home Services'),

          const Spacer(),
          const Divider(height: 1),

          // Logged In User Profile Bar at bottom of Rail
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AmbulanceFirstColors.surfaceContainerHigh,
              child: const Icon(Icons.person, size: 16, color: AmbulanceFirstColors.clinicalCobalt),
            ),
            title: Text(
              widget.user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              widget.user.role,
              style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 10),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 18, color: AmbulanceFirstColors.onSurfaceVariant),
              tooltip: 'Sign Out',
              onPressed: widget.onLogout,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _railItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label, {
    String? badge,
    bool isPulse = false,
  }) {
    final isSelected = !_isBookingWizardOpen && _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected
            ? AmbulanceFirstColors.primaryFixed.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
        child: InkWell(
          onTap: () => _navigateToSection(index),
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected ? AmbulanceFirstColors.clinicalCobalt : AmbulanceFirstColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AmbulanceFirstTypography.bodyMd(
                      color: isSelected ? AmbulanceFirstColors.clinicalCobalt : AmbulanceFirstColors.onSurface,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPulse ? AmbulanceFirstColors.secondary : AmbulanceFirstColors.clinicalCobalt,
                      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
                    ),
                    child: Text(
                      badge,
                      style: AmbulanceFirstTypography.codeSm(color: Colors.white, weight: FontWeight.w700).copyWith(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile Bottom Navigation Bar matching Stitch screen
  // ---------------------------------------------------------------------------
  Widget _buildMobileBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AmbulanceFirstColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
              _bottomNavItem(1, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Bookings'),
              _bottomNavItem(2, Icons.airport_shuttle_outlined, Icons.airport_shuttle_rounded, 'Active', isPulse: _activeTripsCount > 0),
              _bottomNavItem(3, Icons.request_quote_outlined, Icons.request_quote_rounded, 'Quotes', badgeCount: _pendingQuotesCount),
              _bottomNavItem(4, Icons.history_rounded, Icons.history_rounded, 'History'),
              _bottomNavItem(5, Icons.home_work_outlined, Icons.home_work_rounded, 'Home'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isPulse = false,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToSection(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected
                      ? AmbulanceFirstColors.clinicalCobalt
                      : AmbulanceFirstColors.onSurfaceVariant,
                ),
                if (isPulse)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AmbulanceFirstColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AmbulanceFirstColors.clinicalCobalt,
                        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: AmbulanceFirstTypography.codeSm(color: Colors.white, weight: FontWeight.w700).copyWith(fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmbulanceFirstTypography.labelSm(
                color: isSelected
                    ? AmbulanceFirstColors.clinicalCobalt
                    : AmbulanceFirstColors.onSurfaceVariant,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _navTitles = [
    'Dashboard',
    'Bookings',
    'Active Trips',
    'Quotations',
    'History',
    'Home Services',
  ];

  void _showProfileDialog(BuildContext context) {
    final profile = CustomerPortalCache.profile;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AmbulanceFirstColors.secondary),
            const SizedBox(width: 8),
            Text(
              'Account Profile',
              style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user.name,
              style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Role:', style: AmbulanceFirstTypography.labelSm(color: AmbulanceFirstColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    profile?['role']?.toString().isNotEmpty == true
                        ? profile!['role'].toString()
                        : 'Unavailable',
                    style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE'),
          ),
          if (widget.onLogout != null)
            AmbulanceFirstButton(
              label: 'SIGN OUT',
              icon: Icons.logout_rounded,
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onLogout!();
              },
              variant: AmbulanceFirstButtonVariant.destructive,
            ),
        ],
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
    final repository = SupabaseBookingRepository();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
        title: Text(
          'Notifications',
          style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
        ),
        content: SizedBox(
          width: 420,
          child: CustomerPortalCache.notifications.isEmpty
              ? const Text('No notifications found.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: CustomerPortalCache.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final notification = CustomerPortalCache.notifications[index];
                    final notificationId = notification['id']?.toString() ?? '';
                    final isRead = notification['read'] == true || notification['is_read'] == true;
                    return ListTile(
                      dense: true,
                      title: Text(
                        notification['title']?.toString() ?? 'Notification',
                        style: TextStyle(fontWeight: isRead ? FontWeight.w400 : FontWeight.w700),
                      ),
                      subtitle: Text([
                        if (notification['message']?.toString().isNotEmpty == true)
                          notification['message'].toString(),
                        if (notification['notification_type']?.toString().isNotEmpty == true)
                          'Type: ${notification['notification_type']}',
                        if (notification['booking_id']?.toString().isNotEmpty == true)
                          'Booking: ${notification['booking_id']}',
                        if (notification['created_at']?.toString().isNotEmpty == true)
                          notification['created_at'].toString(),
                      ].join(' · ')),
                      trailing: isRead || notificationId.isEmpty
                          ? null
                          : const Icon(Icons.mark_email_read_outlined, size: 18),
                      onTap: isRead || notificationId.isEmpty
                          ? null
                          : () async {
                              try {
                                final marked = await repository.markCustomerNotificationRead(notificationId);
                                if (marked && mounted) setState(() {});
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Notification update failed: $error')),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }
}