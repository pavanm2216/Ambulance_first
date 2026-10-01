import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';
import 'aeromed_button.dart';
import 'aeromed_card.dart';
import 'motion.dart';

// ============================================================================
// STATE 1: EMPTY STATE
// ============================================================================

/// Displayed when there is no data available yet (e.g., no bookings, no
/// quotations, empty history, or unassigned rosters).
class AeroMedEmptyState extends StatelessWidget {
  const AeroMedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return FadeSlideIn(
      child: AeroMedCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveIconColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 34,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AeroMedButton(
                  label: actionLabel!,
                  onTap: onAction,
                  variant: AeroMedButtonVariant.primary,
                  height: 48,
                ),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 2: LOADING STATE & SHIMMER SKELETON
// ============================================================================

/// Shimmer effect that pulses over placeholder shapes while content is loading.
class AeroMedShimmer extends StatefulWidget {
  const AeroMedShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<AeroMedShimmer> createState() => _AeroMedShimmerState();
}

class _AeroMedShimmerState extends State<AeroMedShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.surfaceContainerHigh;
    final highlight = widget.highlightColor ?? AppColors.surfaceBright;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.0, 0.5, 1.0],
              colors: [base, highlight, base],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// A pre-styled skeleton card to represent loading list items.
class AeroMedSkeletonCard extends StatelessWidget {
  const AeroMedSkeletonCard({super.key, this.height = 110});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AeroMedShimmer(
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone loading view with spinner and reassuring medical status text.
class AeroMedLoadingView extends StatelessWidget {
  const AeroMedLoadingView({
    super.key,
    this.message = 'Loading medical records...',
    this.subMessage,
  });

  final String message;
  final String? subMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                subMessage!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 3: ERROR STATE (WITH 1-TAP EMERGENCY FALLBACK)
// ============================================================================

/// Shown when an operational or network request fails. Always includes an
/// immediate emergency hotline button so patients are never stranded in an error.
class AeroMedErrorState extends StatelessWidget {
  const AeroMedErrorState({
    super.key,
    this.title = 'Unable to Load Information',
    required this.message,
    this.onRetry,
    this.showEmergencyFallback = true,
    this.emergencyNumber = '108',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool showEmergencyFallback;
  final String emergencyNumber;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.urgentRed.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: softShadow(opacity: 0.15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.urgentRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.urgentRed.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.urgentRed,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.urgentRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceBright,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        side: BorderSide(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                if (showEmergencyFallback) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dialing Emergency Hotline: $emergencyNumber'),
                          backgroundColor: AppColors.urgentRed,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.urgentRed,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                    label: Text('Call $emergencyNumber'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 4: NO INTERNET / OFFLINE STATE
// ============================================================================

/// Persistent non-intrusive banner indicating offline status.
class AeroMedOfflineBanner extends StatelessWidget {
  const AeroMedOfflineBanner({
    super.key,
    this.onRetry,
    this.onCallHotline,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onCallHotline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B3234),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFFFB4A9),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No internet connection. Offline emergency mode active.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Retry',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onCallHotline ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calling Emergency Dispatch: 108'),
                      backgroundColor: AppColors.urgentRed,
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.urgentRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '108',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
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

// ============================================================================
// STATE 5: SLOW NETWORK STATE
// ============================================================================

/// Non-blocking warning pill alerting users that live GPS telemetry or sync is delayed.
class AeroMedSlowNetworkBanner extends StatelessWidget {
  const AeroMedSlowNetworkBanner({
    super.key,
    this.message = 'Slow connection detected. Real-time GPS updates may lag.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warningSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.network_check_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATE 6: NO SEARCH RESULTS STATE
// ============================================================================

/// Distinct from general empty state: shown specifically when a filter or search
/// query matches 0 items, offering an immediate clear search button.
class AeroMedNoSearchResultsState extends StatelessWidget {
  const AeroMedNoSearchResultsState({
    super.key,
    required this.query,
    required this.onClearSearch,
    this.suggestion,
  });

  final String query;
  final VoidCallback onClearSearch;
  final String? suggestion;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: AeroMedCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'No bookings or records matched "'),
                  TextSpan(
                    text: query,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '".'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              suggestion ?? 'Check spelling or search by Booking ID, patient name, or destination.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceBright,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  side: const BorderSide(color: AppColors.primary),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
              icon: const Icon(Icons.clear_rounded, size: 17),
              label: const Text('Clear Search & Show All'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 7: PERMISSION DENIED STATE
// ============================================================================

/// Clinical justification card shown when critical permissions (e.g. Location/GPS)
/// are denied by the user.
class AeroMedPermissionDeniedCard extends StatelessWidget {
  const AeroMedPermissionDeniedCard({
    super.key,
    this.permissionTitle = 'Location Permission Required',
    required this.clinicalRationale,
    this.onGrantPermission,
    this.onManualFallback,
    this.manualFallbackLabel = 'Enter Pickup Address Manually',
  });

  final String permissionTitle;
  final String clinicalRationale;
  final VoidCallback? onGrantPermission;
  final VoidCallback? onManualFallback;
  final String manualFallbackLabel;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: softShadow(opacity: 0.15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    permissionTitle,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              clinicalRationale,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onGrantPermission != null)
                  ElevatedButton.icon(
                    onPressed: onGrantPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                    label: const Text('Grant in Settings'),
                  ),
                if (onManualFallback != null)
                  OutlinedButton.icon(
                    onPressed: onManualFallback,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                    label: Text(manualFallbackLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 8: SESSION EXPIRED STATE
// ============================================================================

/// Modal dialog triggered when a user's session token expires, keeping medical
/// information secure and providing a clean route to re-authenticate.
class AeroMedSessionExpiredDialog extends StatelessWidget {
  const AeroMedSessionExpiredDialog({
    super.key,
    required this.onLoginAgain,
  });

  final VoidCallback onLoginAgain;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: softShadow(opacity: 0.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Session Expired',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'To safeguard patient records and emergency dispatch confidentiality, your session has timed out. Please sign in again.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AeroMedButton(
                label: 'Sign In Again',
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onLoginAgain();
                },
                variant: AeroMedButtonVariant.primary,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 9: FORM VALIDATION FEEDBACK SUMMARY
// ============================================================================

/// Displayed when an emergency form or booking request fails validation.
class AeroMedFormValidationSummary extends StatelessWidget {
  const AeroMedFormValidationSummary({
    super.key,
    required this.errors,
    this.title = 'Please complete required medical details',
  });

  final List<String> errors;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: AppColors.urgentRed.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.report_problem_rounded,
                  color: AppColors.urgentRed,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.urgentRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.urgentRed, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          error,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATE 10: SUCCESS STATE (MODAL & TOAST)
// ============================================================================

/// Standardized modal for successful milestones (e.g. Quotation Accepted,
/// Booking Dispatched, Service Completed).
class AeroMedSuccessModal extends StatelessWidget {
  const AeroMedSuccessModal({
    super.key,
    required this.title,
    required this.message,
    this.detailRows = const [],
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final List<(String, String)> detailRows;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeSlideIn(
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            boxShadow: softShadow(opacity: 0.7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: mintGlow(opacity: 0.25),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (detailRows.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: detailRows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              row.$1,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              row.$2,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              AeroMedButton(
                label: primaryActionLabel,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onPrimaryAction();
                },
                variant: AeroMedButtonVariant.primary,
                height: 48,
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    onSecondaryAction!();
                  },
                  child: Text(
                    secondaryActionLabel!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick floating success toast helper.
void showAeroMedSuccessToast(
  BuildContext context, {
  required String message,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
