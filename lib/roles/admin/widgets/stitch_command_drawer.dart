import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class StitchCommandDrawer extends StatelessWidget {
  const StitchCommandDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: StitchTheme.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Top: Central Command Branding
            Padding(
              padding: const EdgeInsets.all(StitchTheme.margin),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: StitchTheme.primary,
                              borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              size: 20,
                              color: StitchTheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Central Command',
                                style: StitchTheme.headlineSm(color: StitchTheme.onSurface),
                              ),
                              Text(
                                'ADMINISTRATOR - OPS LEAD',
                                style: StitchTheme.labelSm(
                                  color: StitchTheme.primaryContainer,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: StitchTheme.onSurfaceVariant),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // SOS Override Queue Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: StitchTheme.errorContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: StitchTheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOS OVERRIDE QUEUE',
                                style: StitchTheme.labelSm(
                                  color: StitchTheme.onErrorContainer,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '2 code-red incidents active in dispatch stream',
                                style: StitchTheme.bodySm(color: StitchTheme.onErrorContainer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: StitchTheme.borderSubtle),

            // Navigation Directory Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: StitchTheme.margin, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'OPERATIONS DIRECTORY',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.outline,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _DrawerLink(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(0);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.emergency_share_rounded,
                    title: 'Bookings & Dispatch',
                    isSelected: selectedIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(1);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.local_shipping_rounded,
                    title: 'Fleet & Capabilities',
                    isSelected: selectedIndex == 2,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(2);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.badge_rounded,
                    title: 'Staff & Responders',
                    isSelected: selectedIndex == 3,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(3);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.payments_rounded,
                    title: 'Financial & Quotations',
                    isSelected: selectedIndex == 4,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(4);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.tune_rounded,
                    title: 'Pricing Engine & Settings',
                    isSelected: selectedIndex == 7,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(7);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.analytics_rounded,
                    title: 'Analytics & Reports',
                    isSelected: selectedIndex == 5,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(5);
                    },
                  ),
                  _DrawerLink(
                    icon: Icons.verified_user_rounded,
                    title: 'Audit & Governance',
                    isSelected: selectedIndex == 6,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(6);
                    },
                  ),
                ],
              ),
            ),

            // Sign out action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: StitchTheme.margin),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: StitchTheme.error),
                label: Text('Sign Out', style: StitchTheme.bodyMd(color: StitchTheme.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: StitchTheme.borderSubtle),
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Footer Encryption Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: StitchTheme.margin, vertical: 10),
              color: StitchTheme.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: StitchTheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TLS 1.3 End-to-End Gov Encrypted',
                        style: StitchTheme.labelSm(color: StitchTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Icon(Icons.lock_rounded, size: 14, color: StitchTheme.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        ),
        tileColor: isSelected ? StitchTheme.surfaceContainer : Colors.transparent,
        leading: Icon(
          icon,
          size: 19,
          color: isSelected ? StitchTheme.primaryContainer : StitchTheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: StitchTheme.bodyMd(
            color: isSelected ? StitchTheme.onSurface : StitchTheme.onSurfaceVariant,
            weight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
