import 'package:flutter/material.dart';

import '../../../../core/models/auth_user.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';
import '../screens/customer_care_dashboard_screen.dart';
import '../screens/call_verification_console_screen.dart';
import '../screens/active_trips_screen.dart';
import '../screens/new_bookings_intake_screen.dart';
import '../screens/verified_bookings_screen.dart';
import '../screens/team_lead_handover_screen.dart';
import '../screens/all_bookings_archive_screen.dart';
import '../screens/booking_360_details_screen.dart';
import 'tactical_drawer.dart';
import 'customer_care_top_bar.dart';

class CustomerCareShell extends StatefulWidget {
  const CustomerCareShell({super.key, this.user, this.onLogout});

  final AuthUser? user;
  final VoidCallback? onLogout;

  @override
  State<CustomerCareShell> createState() => _CustomerCareShellState();
}

class _CustomerCareShellState extends State<CustomerCareShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0;
  CustomerCareCase? _activeCaseForConsole;
  CustomerCareCase? _activeCaseForDetails;
  bool _showArchive = false;
  bool _showVerifiedQueue = false;

  @override
  void initState() {
    super.initState();
    final repository = CustomerCareRepository.instance;
    if (repository.allCases.isEmpty && !repository.isLoading) {
      repository.load().catchError((_) {});
    }
  }

  String? _toastMessage;
  bool _showToast = false;

  void _displayToast(String message) {
    setState(() {
      _toastMessage = message;
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showToast = false;
        });
      }
    });
  }

  void _openCallVerify(CustomerCareCase caseItem) {
    setState(() {
      _activeCaseForConsole = caseItem;
      _activeCaseForDetails = null;
    });
  }

  void _openDetails(CustomerCareCase caseItem) {
    setState(() {
      _activeCaseForDetails = caseItem;
      _activeCaseForConsole = null;
    });
  }

  void _openArchive() {
    setState(() {
      _showArchive = true;
      _activeCaseForConsole = null;
      _activeCaseForDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = CustomerCareRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final newCount = repo.newInboundCount;
        final pendingCount = repo.pendingCallsCount;

        // If currently in detail view or console view, render them
        if (_activeCaseForConsole != null) {
          return CallVerificationConsoleScreen(
            caseItem: _activeCaseForConsole!,
            onBack: () => setState(() => _activeCaseForConsole = null),
            onVerificationComplete: () {
              setState(() {
                _activeCaseForConsole = null;
                _selectedTabIndex = 0;
              });
            },
            onShowToast: _displayToast,
          );
        }

        if (_activeCaseForDetails != null) {
          return Booking360DetailsScreen(
            caseItem: _activeCaseForDetails!,
            onBack: () => setState(() => _activeCaseForDetails = null),
            onStartCallVerify: () {
              final c = _activeCaseForDetails!;
              setState(() {
                _activeCaseForDetails = null;
                _activeCaseForConsole = c;
              });
            },
            onShowToast: _displayToast,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 840;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: CustomerCareColors.background,
              appBar: isDesktop
                  ? null
                  : CustomerCareTopBar(
                      onOpenDrawer: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      agentName: widget.user?.name ?? 'Customer Care',
                      onCallHotline: () =>
                          _displayToast('Support contact unavailable.'),
                      onNotificationsTap: () =>
                          _showNotifications(context, repo),
                    ),
              drawer: isDesktop
                  ? null
                  : TacticalDrawer(
                      currentTab: _selectedTabIndex,
                      onSelectTab: (idx) {
                        setState(() {
                          _selectedTabIndex = idx;
                          _showArchive = false;
                          _showVerifiedQueue = false;
                        });
                      },
                      onOpenArchive: _openArchive,
                      onLogout: widget.onLogout,
                    ),
              body: Stack(
                children: [
                  Row(
                    children: [
                      // Desktop Persistent Navigation Rail
                      if (isDesktop)
                        Container(
                          width: 240,
                          color: CustomerCareColors.surfaceContainerLowest,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color:
                                            CustomerCareColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ambulance First',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomerCareTextStyles
                                                .headlineSm
                                                .copyWith(
                                                  color: CustomerCareColors
                                                      .primaryContainer,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                          ),
                                          Text(
                                            'Customer Care Ops',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomerCareTextStyles.labelSm
                                                .copyWith(
                                                  color: CustomerCareColors
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: CustomerCareColors.outlineVariant,
                              ),
                              const SizedBox(height: 12),
                              _buildRailItem(
                                0,
                                Icons.grid_view_rounded,
                                'Dashboard',
                              ),
                              _buildRailItem(
                                1,
                                Icons.move_to_inbox_rounded,
                                'New Requests',
                                badge: '$newCount',
                              ),
                              _buildRailItem(
                                2,
                                Icons.phone_in_talk_rounded,
                                'Pending Calls',
                                badge: '$pendingCount',
                              ),
                              _buildRailItem(
                                3,
                                Icons.assignment_ind_rounded,
                                'Handoff Monitor',
                              ),
                              _buildRailItem(
                                4,
                                Icons.flight_takeoff_rounded,
                                'Active Trips',
                              ),
                              _buildRailItem(
                                5,
                                Icons.inventory_2_rounded,
                                'All Bookings Archive',
                              ),
                              const Spacer(),
                              if (widget.onLogout != null)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onLogout,
                                    icon: const Icon(Icons.logout, size: 16),
                                    label: const Text('Sign Out'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      foregroundColor:
                                          CustomerCareColors.onSurface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // Main Content Area
                      Expanded(child: _buildCurrentContent(repo)),
                    ],
                  ),

                  // Floating Toast Banner
                  if (_showToast && _toastMessage != null)
                    Positioned(
                      bottom: 84,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.inverseSurface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: CustomerCareColors.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _toastMessage!,
                                    style: CustomerCareTextStyles.bodySm
                                        .copyWith(
                                          color: CustomerCareColors
                                              .inverseOnSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              Text(
                                'Ambulance First Dispatch',
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: CustomerCareColors.inverseOnSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: isDesktop
                  ? null
                  : _buildBottomNav(newCount, pendingCount),
            );
          },
        );
      },
    );
  }

  Future<void> _showNotifications(
    BuildContext context,
    CustomerCareRepository repo,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 420,
          child: repo.notifications.isEmpty
              ? const Text('No notifications found.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: repo.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final notification = repo.notifications[index];
                    final id = notification['id']?.toString() ?? '';
                    final read =
                        notification['read'] == true ||
                        notification['is_read'] == true;
                    return ListTile(
                      title: Text(
                        notification['title']?.toString() ?? 'Notification',
                      ),
                      subtitle: Text(
                        notification['message']?.toString() ??
                            'Message unavailable',
                      ),
                      trailing: read || id.isEmpty
                          ? null
                          : const Icon(Icons.mark_email_read_outlined),
                      onTap: read || id.isEmpty
                          ? null
                          : () async {
                              try {
                                await repo.markNotificationRead(id);
                                if (mounted) {
                                  setState(() {});
                                }
                              } catch (error) {
                                if (mounted) {
                                  _displayToast(
                                    'Notification update failed: $error',
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
  }

  Widget _buildCurrentContent(CustomerCareRepository repo) {
    if (_showArchive) {
      return AllBookingsArchiveScreen(onViewDetails: _openDetails);
    }
    if (_showVerifiedQueue) {
      return VerifiedBookingsScreen(
        onViewDetails: _openDetails,
        onShowToast: _displayToast,
      );
    }

    switch (_selectedTabIndex) {
      case 0:
        return CustomerCareDashboardScreen(
          onNavigateToCallVerify: _openCallVerify,
          onNavigateToDetails: _openDetails,
          onNavigateToNewIntake: () => setState(() => _selectedTabIndex = 1),
          onNavigateToPending: () => setState(() => _selectedTabIndex = 2),
          onNavigateToVerified: () => setState(() => _showVerifiedQueue = true),
          onNavigateToHandoff: () => setState(() => _selectedTabIndex = 3),
          onShowToast: _displayToast,
        );
      case 1:
        return NewBookingsIntakeScreen(
          onStartCallVerify: _openCallVerify,
          onShowToast: _displayToast,
        );
      case 2:
        // Pending Calls: open first pending or open dashboard with filter
        final pending = repo.pendingCallCases.firstOrNull;
        if (pending == null) {
          return const Center(child: Text('No pending Customer Care calls.'));
        }
        return CallVerificationConsoleScreen(
          caseItem: pending,
          onBack: () => setState(() => _selectedTabIndex = 0),
          onVerificationComplete: () => setState(() => _selectedTabIndex = 0),
          onShowToast: _displayToast,
        );
      case 3:
        return TeamLeadHandoverScreen(onViewDetails: _openDetails);
      case 4:
        return ActiveTripsScreen(
          onViewDetails: _openDetails,
          onShowToast: _displayToast,
        );
      default:
        return CustomerCareDashboardScreen(
          onNavigateToCallVerify: _openCallVerify,
          onNavigateToDetails: _openDetails,
          onNavigateToNewIntake: () => setState(() => _selectedTabIndex = 1),
          onNavigateToPending: () => setState(() => _selectedTabIndex = 2),
          onNavigateToVerified: () => setState(() => _showVerifiedQueue = true),
          onNavigateToHandoff: () => setState(() => _selectedTabIndex = 3),
          onShowToast: _displayToast,
        );
    }
  }

  Widget _buildRailItem(
    int index,
    IconData icon,
    String label, {
    String? badge,
  }) {
    final isSelected =
        !_showArchive && !_showVerifiedQueue && _selectedTabIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? CustomerCareColors.surfaceContainerHigh
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            setState(() {
              if (index == 5) {
                _showArchive = true;
                _showVerifiedQueue = false;
              } else {
                _selectedTabIndex = index;
                _showArchive = false;
                _showVerifiedQueue = false;
              }
            });
          },
          dense: true,
          leading: Icon(
            icon,
            size: 19,
            color: isSelected
                ? CustomerCareColors.primaryContainer
                : CustomerCareColors.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: CustomerCareTextStyles.bodyMd.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? CustomerCareColors.primaryContainer
                  : CustomerCareColors.onSurface,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBottomNav(int newCount, int pendingCount) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: CustomerCareColors.outlineVariant, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
              _buildNavItem(
                1,
                Icons.move_to_inbox_rounded,
                'New',
                badge: '$newCount',
                isErrorBadge: true,
              ),
              _buildNavItem(
                2,
                Icons.phone_in_talk_rounded,
                'Pending',
                badge: '$pendingCount',
              ),
              _buildNavItem(3, Icons.assignment_ind_rounded, 'Handoff'),
              _buildNavItem(
                4,
                Icons.flight_takeoff_rounded,
                'Active',
                hasGreenDot: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    String? badge,
    bool isErrorBadge = false,
    bool hasGreenDot = false,
  }) {
    final isSelected =
        !_showArchive && !_showVerifiedQueue && _selectedTabIndex == index;
    final color = isSelected
        ? CustomerCareColors.primaryContainer
        : CustomerCareColors.onSurfaceVariant;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _showArchive = false;
          _showVerifiedQueue = false;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 23, color: color),
                if (badge != null)
                  Positioned(
                    top: -3,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isErrorBadge
                            ? CustomerCareColors.error
                            : CustomerCareColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (hasGreenDot)
                  Positioned(
                    top: -1,
                    right: -3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomerCareColors.secondary,
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: CustomerCareTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
