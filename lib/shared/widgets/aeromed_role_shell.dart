import 'package:flutter/material.dart';

import '../../core/models/auth_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';
import 'role_profile_sheet.dart';

class AeroMedRoleDestination {
  const AeroMedRoleDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AeroMedRoleShell extends StatelessWidget {
  const AeroMedRoleShell({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.userName,
    required this.user,
    required this.destinations,
    required this.mobileDestinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.child,
    this.notificationCount = 0,
    this.onNotifications,
  });

  final String title;
  final String roleLabel;
  final String userName;
  final AuthUser user;
  final List<AeroMedRoleDestination> destinations;
  final List<int> mobileDestinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final Widget child;
  final int notificationCount;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;

    if (mobile) {
      return _buildMobile(context);
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: _desktopAppBar(context),
      body: Row(
        children: [
          _RoleSidebar(
            title: title,
            roleLabel: roleLabel,
            userName: userName,
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
            onLogout: onLogout,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: _RoleSidebarContent(
            title: title,
            roleLabel: roleLabel,
            userName: userName,
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelect: (value) {
              onSelect(value);
              Navigator.of(context).pop();
            },
            onLogout: onLogout,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _MobileRoleBar(
              title: title,
              roleLabel: roleLabel,
              userName: userName,
              notificationCount: notificationCount,
              onNotifications: onNotifications,
              onProfile: () => RoleProfileSheet.show(
                context,
                user: user,
                onLogout: onLogout,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: _MobileRoleNav(
        destinations: mobileDestinations
            .where((index) => index >= 0 && index < destinations.length)
            .map((index) => (index: index, destination: destinations[index]))
            .toList(),
        selectedIndex: selectedIndex,
        onSelect: onSelect,
      ),
    );
  }

  PreferredSizeWidget _desktopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          Text(roleLabel, style: AppTextStyles.caption),
        ],
      ),
      actions: [
        if (onNotifications != null)
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text('$notificationCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => RoleProfileSheet.show(
              context,
              user: user,
              onLogout: onLogout,
            ),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.secondaryContainer,
              child: Text(
                _initial,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _initial {
    final trimmed = userName.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _RoleSidebar extends StatelessWidget {
  const _RoleSidebar({
    required this.title,
    required this.roleLabel,
    required this.userName,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  final String title;
  final String roleLabel;
  final String userName;
  final List<AeroMedRoleDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: Material(
        color: AppColors.surface,
        child: _RoleSidebarContent(
          title: title,
          roleLabel: roleLabel,
          userName: userName,
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          onLogout: onLogout,
        ),
      ),
    );
  }
}

class _RoleSidebarContent extends StatelessWidget {
  const _RoleSidebarContent({
    required this.title,
    required this.roleLabel,
    required this.userName,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  final String title;
  final String roleLabel;
  final String userName;
  final List<AeroMedRoleDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isEmpty
        ? '?'
        : userName.trim().substring(0, 1).toUpperCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 14, 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    Text(roleLabel, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            itemCount: destinations.length,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 6)
                : const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              final selected = selectedIndex == index;
              return ListTile(
                selected: selected,
                selectedTileColor: AppColors.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                ),
                leading: Icon(
                  destination.icon,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                title: Text(
                  destination.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () => onSelect(index),
              );
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(userName, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            tooltip: 'Sign out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
      ],
    );
  }
}

class _MobileRoleBar extends StatelessWidget {
  const _MobileRoleBar({
    required this.title,
    required this.roleLabel,
    required this.userName,
    required this.notificationCount,
    required this.onNotifications,
    required this.onProfile,
  });

  final String title;
  final String roleLabel;
  final String userName;
  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isEmpty
        ? '?'
        : userName.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
                Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (onNotifications != null)
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: notificationCount > 0,
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onProfile,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.secondaryContainer,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRoleNav extends StatelessWidget {
  const _MobileRoleNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<({int index, AeroMedRoleDestination destination})> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        padding: const EdgeInsets.all(5),
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(AppRadius.nav),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: softShadow(color: Colors.black, opacity: 0.18),
        ),
        child: Row(
          children: [
            for (final item in destinations)
              Expanded(
                child: _MobileRoleNavItem(
                  destination: item.destination,
                  selected: selectedIndex == item.index,
                  onTap: () => onSelect(item.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileRoleNavItem extends StatelessWidget {
  const _MobileRoleNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AeroMedRoleDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected ? mintGlow(opacity: 0.22) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              destination.icon,
              size: 19,
              color: selected
                  ? AppColors.onPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                letterSpacing: 0,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}