import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/auth_user.dart' as app_models;
import '../core/services/supabase_service.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_metrics.dart';
import '../shared/theme/app_text_styles.dart';
import '../shared/widgets/aeromed_button.dart';

/// First-time setup screen for users arriving from a Supabase staff invitation.
///
/// Supabase establishes the invited user's authenticated session when the
/// invitation link is accepted. The invited user then chooses their password
/// here through auth.updateUser(). No password is ever sent to the Admin or
/// stored by the Flutter client.
class InviteSetupScreen extends StatefulWidget {
  const InviteSetupScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  final app_models.AuthUser user;
  final VoidCallback onComplete;

  @override
  State<InviteSetupScreen> createState() => _InviteSetupScreenState();
}

class _InviteSetupScreenState extends State<InviteSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    setState(() => _error = null);

    if (password.length < 8) {
      setState(() => _error = 'Password must contain at least 8 characters.');
      return;
    }

    if (password != confirmation) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }

    if (!SupabaseService.isConfigured ||
        SupabaseService.client.auth.currentUser == null) {
      setState(() {
        _error =
            'This invitation session is no longer active. Please request a new invitation.';
      });
      return;
    }

    setState(() => _busy = true);

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      setState(() => _busy = false);
      widget.onComplete();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('same password')) {
      return 'Please choose a new password.';
    }
    if (text.contains('Password should be at least')) {
      return 'Password must contain at least 8 characters.';
    }
    if (text.contains('session')) {
      return 'The invitation session has expired. Please request a new invitation.';
    }
    return text.replaceFirst('AuthException: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Complete your staff account',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your invitation has been accepted. Set a password to finish activating your ${_roleLabel(widget.user.backendRole)} account.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.user.name,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.email,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              _roleLabel(widget.user.backendRole),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PasswordField(
                      controller: _passwordController,
                      label: 'New password',
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      obscureText: _obscureConfirm,
                      onToggle: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use at least 8 characters. Keep this password private; administrators cannot see it.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.urgentRed.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.urgentRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    AeroMedButton(
                      label: _busy ? 'Activating…' : 'Activate account',
                      icon: Icons.verified_rounded,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onTap: _busy ? null : _setPassword,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'After activation, you can sign out and use the normal Ambulance First login page with this email and password.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'CUSTOMER_CARE':
        return 'Customer Care';
      case 'TEAM_LEAD':
        return 'Team Lead';
      case 'DRIVER':
        return 'Driver';
      case 'DOCTOR':
        return 'Doctor';
      default:
        return role;
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
    );
  }
}
