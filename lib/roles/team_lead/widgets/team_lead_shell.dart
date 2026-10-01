import 'package:flutter/material.dart';
import '../../../core/models/auth_user.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import 'notification_panel.dart';

class TeamLeadLayoutShell extends StatefulWidget {
  const TeamLeadLayoutShell({
    super.key,
    required this.user,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.child,
    this.searchQuery = '',
    this.onSearchChanged,
  });

  final AuthUser user;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final Widget child;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;

  static const List<String> navTitles = [
    'Command Center',
    'Allocation Queue',
    'Budget & Quotations',
    'Active Trips',
    'Fleet',
    'Drivers',
    'EMTs',
    'Doctors',
    'Operations Reports',
  ];

  @override
  State<TeamLeadLayoutShell> createState() => _TeamLeadLayoutShellState();
}

class _TeamLeadLayoutShellState extends State<TeamLeadLayoutShell> {
  final store = TeamLeadStore.instance;

  static const List<IconData> navIcons = [
    Icons.dashboard_rounded,
    Icons.assignment_rounded,
    Icons.request_quote_rounded,
    Icons.near_me_rounded,
    Icons.local_shipping_rounded,
    Icons.groups_rounded,
    Icons.medical_services_rounded,
    Icons.person_search_rounded,
    Icons.analytics_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: TeamLeadTheme.canvas,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: TeamLeadTheme.surfaceLowest,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambulance First',
                        style: TeamLeadTheme.titleMedium(
                          color: TeamLeadTheme.primaryDark,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        TeamLeadLayoutShell.navTitles[widget.selectedIndex],
                        style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  actions: [
                    _notificationButton(),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20, color: TeamLeadTheme.textMuted),
                      onPressed: widget.onLogout,
                    ),
                  ],
                )
              : null,
          drawer: isMobile ? _mobileDrawer() : null,
          body: Row(
            children: [
              if (isDesktop) _desktopSidebar(),
              if (isTablet) _tabletNavRail(),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) _topBar(),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isMobile ? _mobileBottomBar() : null,
        );
      },
    );
  }

  Widget _desktopSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        border: Border(right: BorderSide(color: TeamLeadTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TeamLeadTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TeamLeadTheme.primaryDark,
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambulance First',
                        style: TeamLeadTheme.body(
                          color: TeamLeadTheme.primaryDark,
                          weight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Team Lead Command',
                        style: TeamLeadTheme.micro(color: TeamLeadTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: TeamLeadLayoutShell.navTitles.length,
              itemBuilder: (context, i) {
                final isSelected = widget.selectedIndex == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? TeamLeadTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      leading: Icon(
                        navIcons[i],
                        size: 18,
                        color: isSelected ? Colors.white : TeamLeadTheme.onSurfaceVariant,
                      ),
                      title: Text(
                        TeamLeadLayoutShell.navTitles[i],
                        style: TeamLeadTheme.supportingBody(
                          color: isSelected ? Colors.white : TeamLeadTheme.onSurface,
                          weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => widget.onDestinationSelected(i),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Footer Profile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TeamLeadTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: TeamLeadTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'T',
                    style: TeamLeadTheme.small(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.user.name,
                        style: TeamLeadTheme.small(weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Team Lead Ops',
                        style: TeamLeadTheme.micro(color: TeamLeadTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: TeamLeadTheme.textMuted),
                  onPressed: widget.onLogout,
                  tooltip: 'Sign Out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabletNavRail() {
    return NavigationRail(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      backgroundColor: TeamLeadTheme.surfaceLowest,
      labelType: NavigationRailLabelType.selected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TeamLeadTheme.primaryDark,
            borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
          ),
          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
        ),
      ),
      destinations: [
        for (var i = 0; i < TeamLeadLayoutShell.navTitles.length; i++)
          NavigationRailDestination(
            icon: Icon(navIcons[i], size: 20),
            selectedIcon: Icon(navIcons[i], size: 20, color: TeamLeadTheme.primary),
            label: Text(TeamLeadLayoutShell.navTitles[i], style: TeamLeadTheme.micro()),
          ),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        border: Border(bottom: BorderSide(color: TeamLeadTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Text(
            TeamLeadLayoutShell.navTitles[widget.selectedIndex],
            style: TeamLeadTheme.headline(weight: FontWeight.w700),
          ),
          const SizedBox(width: 24),

          // Search Field
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search booking ID, patient, hospital, vehicle...',
                  hintStyle: TeamLeadTheme.small(color: TeamLeadTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TeamLeadTheme.textMuted),
                  filled: true,
                  fillColor: TeamLeadTheme.surfaceLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Operational Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TeamLeadTheme.emeraldBg,
              borderRadius: BorderRadius.circular(TeamLeadTheme.radiusPill),
              border: Border.all(color: TeamLeadTheme.operationalEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: TeamLeadTheme.operationalEmerald, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('OPERATIONS ACTIVE', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.emeraldText, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Notifications
          _notificationButton(),
        ],
      ),
    );
  }

  Widget _notificationButton() {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unread = store.unreadNotificationsCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 22, color: TeamLeadTheme.onSurfaceVariant),
              onPressed: () => NotificationPanelDialog.show(context),
              tooltip: 'Operational Alerts',
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: TeamLeadTheme.medicalCrimson,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _mobileDrawer() {
    return Drawer(
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: TeamLeadTheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ambulance First', style: TeamLeadTheme.headline(color: Colors.white, weight: FontWeight.w800)),
                Text('Team Lead Operations', style: TeamLeadTheme.small(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: TeamLeadLayoutShell.navTitles.length,
              itemBuilder: (ctx, i) {
                final isSelected = widget.selectedIndex == i;
                return ListTile(
                  leading: Icon(navIcons[i], color: isSelected ? TeamLeadTheme.primary : TeamLeadTheme.onSurfaceVariant),
                  title: Text(TeamLeadLayoutShell.navTitles[i], style: TeamLeadTheme.body(weight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selected: isSelected,
                  onTap: () {
                    widget.onDestinationSelected(i);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileBottomBar() {
    // Top 5 essential mobile tabs
    const mobileIndices = [0, 1, 2, 3, 4];
    final currentSubIndex = mobileIndices.indexOf(widget.selectedIndex);

    return NavigationBar(
      selectedIndex: currentSubIndex != -1 ? currentSubIndex : 0,
      backgroundColor: TeamLeadTheme.surfaceLowest,
      onDestinationSelected: (idx) => widget.onDestinationSelected(mobileIndices[idx]),
      destinations: [
        for (final i in mobileIndices)
          NavigationDestination(
            icon: Icon(navIcons[i]),
            selectedIcon: Icon(navIcons[i], color: TeamLeadTheme.primary),
            label: TeamLeadLayoutShell.navTitles[i].split(' ').first,
          ),
      ],
    );
  }
}
