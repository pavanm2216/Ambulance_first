import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class DriverDutySwitcher extends StatelessWidget {
  const DriverDutySwitcher({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.hasActiveTrip = false,
  });

  final String currentStatus;
  final ValueChanged<String> onStatusChanged;
  final bool hasActiveTrip;

  static const List<_DutyOption> _options = [
    _DutyOption(code: 'AVAILABLE', label: 'AVAILABLE', icon: Icons.check_circle_outline_rounded, activeColor: DriverColors.secondary),
    _DutyOption(code: 'ON_TRIP', label: 'ON TRIP', icon: Icons.local_shipping_outlined, activeColor: DriverColors.primaryContainer),
    _DutyOption(code: 'OFF_DUTY', label: 'OFF DUTY', icon: Icons.bedtime_outlined, activeColor: DriverColors.outline),
    _DutyOption(code: 'LEAVE', label: 'LEAVE', icon: Icons.calendar_today_outlined, activeColor: DriverColors.warning),
  ];

  void _handleSelect(BuildContext context, String code) {
    if (code == currentStatus) return;

    if (hasActiveTrip && (code == 'OFF_DUTY' || code == 'LEAVE')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Active Mission In Progress', style: DriverTextStyles.headlineSmall),
          content: Text(
            'You cannot switch to ${code.replaceAll('_', ' ')} while an emergency mission is active. Please complete the trip handover first.',
            style: DriverTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Understood', style: DriverTextStyles.button.copyWith(color: DriverColors.primaryContainer)),
            ),
          ],
        ),
      );
      return;
    }

    onStatusChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.surfaceContainerHighest),
      ),
      child: Row(
        children: _options.map((opt) {
          final isSelected = currentStatus == opt.code;
          return Expanded(
            child: InkWell(
              onTap: () => _handleSelect(context, opt.code),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? DriverColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 16,
                      color: isSelected ? opt.activeColor : DriverColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opt.label,
                      style: DriverTextStyles.telemetryMicro.copyWith(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? DriverColors.onSurface : DriverColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DutyOption {
  const _DutyOption({
    required this.code,
    required this.label,
    required this.icon,
    required this.activeColor,
  });

  final String code;
  final String label;
  final IconData icon;
  final Color activeColor;
}
