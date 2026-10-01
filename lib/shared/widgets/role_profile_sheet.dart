import 'package:flutter/material.dart';

import '../../core/models/auth_user.dart';

class RoleProfileSheet extends StatelessWidget {
  const RoleProfileSheet({
    super.key,
    required this.user,
    required this.onLogout,
    this.useAdminPalette = false,
  });

  final AuthUser user;
  final VoidCallback onLogout;
  final bool useAdminPalette;

  static void show(
    BuildContext context, {
    required AuthUser user,
    required VoidCallback onLogout,
    bool useAdminPalette = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleProfileSheet(
        user: user,
        onLogout: onLogout,
        useAdminPalette: useAdminPalette,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim();
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final theme = Theme.of(context);
    final primary = useAdminPalette
        ? const Color(0xFF0369A1)
        : theme.colorScheme.primary;
    final primaryContainer = useAdminPalette
        ? const Color(0xFFCDE5FF)
        : theme.colorScheme.primaryContainer;
    final onPrimaryContainer = useAdminPalette
        ? const Color(0xFF001D32)
        : theme.colorScheme.onPrimaryContainer;
    final surface = useAdminPalette
        ? const Color(0xFFFFFFFF)
        : theme.colorScheme.surface;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 30,
              offset: Offset(0, -8),
              color: Color(0x24000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: onPrimaryContainer,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.role,
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileRow(
              icon: Icons.badge_outlined,
              label: 'Account ID',
              value: user.id,
              accent: primary,
            ),
            _ProfileRow(
              icon: Icons.alternate_email_rounded,
              label: 'Login',
              value: user.email,
              accent: primary,
            ),
            _ProfileRow(
              icon: Icons.phone_outlined,
              label: 'Mobile',
              value: user.phone.isEmpty ? 'Not provided' : user.phone,
              accent: primary,
            ),
            _ProfileRow(
              icon: Icons.work_outline_rounded,
              label: 'Role',
              value: user.role,
              accent: primary,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
