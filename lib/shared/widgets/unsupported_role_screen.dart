import 'package:flutter/material.dart';

import '../../core/models/auth_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.message,
  });

  final AuthUser user;
  final VoidCallback onSignOut;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 54,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Role not available in this app',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${user.name.isEmpty ? user.email : user.name}\nRole: ${user.backendRole}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyStrong,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.supporting,
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
