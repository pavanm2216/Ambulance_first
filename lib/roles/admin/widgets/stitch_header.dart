import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../shared/widgets/role_profile_sheet.dart';
import '../theme/admin_theme.dart';

class StitchHeader extends StatefulWidget {
  const StitchHeader({
    super.key,
    required this.title,
    this.subtitle = 'Supabase Live',
    this.userName = 'Administrator',
    this.userEmail = 'admin@ambulancefirst.com',
    this.onSync,
    this.onOpenDrawer,
    this.onNotifications,
    this.onSignOut,
  });

  final String title;
  final String subtitle;
  final String userName;
  final String userEmail;
  final VoidCallback? onSync;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignOut;

  @override
  State<StitchHeader> createState() => _StitchHeaderState();
}

class _StitchHeaderState extends State<StitchHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 8,
        left: StitchTheme.margin,
        right: StitchTheme.margin,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: StitchTheme.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: StitchTheme.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Live Dispatch & Profile/Notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Live Dispatch Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: StitchTheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE ADMIN DATA',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.tertiary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification and Profile Action
              Row(
                children: [
                  IconButton(
                    tooltip: 'Open notifications',
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 20,
                          color: StitchTheme.onSurfaceVariant,
                        ),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: StitchTheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: StitchTheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed:
                        widget.onNotifications ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notifications are managed by the connected backend.',
                              ),
                            ),
                          );
                        },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Admin profile',
                    onPressed: () {
                      RoleProfileSheet.show(
                        context,
                        user: AuthUser(
                          id: widget.userEmail,
                          name: widget.userName,
                          email: widget.userEmail,
                          phone: '',
                          role: 'ADMIN',
                        ),
                        onLogout: widget.onSignOut ?? () {},
                        useAdminPalette: true,
                      );
                    },
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: StitchTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: StitchTheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom Row: Screen Title + Version + Sync
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StitchTheme.headlineSm(
                          color: StitchTheme.onSurface,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StitchTheme.labelSm(
                          color: StitchTheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap:
                        widget.onSync ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Admin data refreshed.'),
                            ),
                          );
                        },
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: StitchTheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
