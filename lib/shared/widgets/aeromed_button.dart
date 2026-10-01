import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';


enum AeroMedButtonVariant { primary, secondary, danger, ghost }

/// The app's core button component derived from Stitch MCP specifications:
/// - Pill shape (rounded-full)
/// - Height 52-56px for touch ergonomics
/// - Primary: Vital Mint (#63F28A) with dark text (#07170F)
/// - Secondary: Deep Forest (#173B25) with soft celadon text
/// - Danger: Crimson urgent (#E5484D)
class AeroMedButton extends StatefulWidget {
  const AeroMedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailingIcon,
    this.variant = AeroMedButtonVariant.primary,
    this.height = 54,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final AeroMedButtonVariant variant;
  final double height;
  final bool expand;

  @override
  State<AeroMedButton> createState() => _AeroMedButtonState();
}

class _AeroMedButtonState extends State<AeroMedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final Color background;
    final Color foreground;
    final Border? border;
    final List<BoxShadow> shadow;

    switch (widget.variant) {
      case AeroMedButtonVariant.primary:
        background = disabled ? AppColors.surfaceContainerHigh : AppColors.primary;
        foreground = disabled ? AppColors.textMuted : AppColors.onPrimary;
        border = Border.all(color: AppColors.white.withValues( alpha: 0.28));
        shadow = disabled
            ? const []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues( alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ];
        break;
      case AeroMedButtonVariant.secondary:
        background = disabled ? AppColors.surfaceContainerHigh : AppColors.secondaryContainer;
        foreground = disabled ? AppColors.textMuted : AppColors.secondary;
        border = Border.all(color: AppColors.secondary.withValues( alpha: 0.25));
        shadow = [
          BoxShadow(color: AppColors.primaryDark.withValues( alpha: 0.10), blurRadius: 12, offset: const Offset(4, 4)),
          BoxShadow(color: AppColors.white.withValues( alpha: 0.9), blurRadius: 12, offset: const Offset(-4, -4)),
        ];
        break;
      case AeroMedButtonVariant.danger:
        background = disabled ? AppColors.surfaceContainerHigh : AppColors.urgentRed;
        foreground = Colors.white;
        border = null;
        shadow = disabled
            ? const []
            : [
                BoxShadow(
                  color: AppColors.urgentRed.withValues( alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ];
        break;
      case AeroMedButtonVariant.ghost:
        background = Colors.transparent;
        foreground = disabled ? AppColors.textMuted : AppColors.textPrimary;
        border = Border.all(color: AppColors.outlineVariant);
        shadow = const [];
        break;
    }

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: border,
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.button.copyWith(color: foreground),
                  ),
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(widget.trailingIcon, color: foreground, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
