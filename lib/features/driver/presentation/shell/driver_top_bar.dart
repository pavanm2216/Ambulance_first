import 'package:flutter/material.dart';

import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/emergency_sos_modal.dart';

class DriverTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DriverTopBar({
    super.key,
    required this.driver,
    this.activeBooking,
    required this.onSosTriggered,
    this.onProfileTap,
  });

  final DriverProfile driver;
  final DriverBooking? activeBooking;
  final VoidCallback onSosTriggered;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  Color get _dutyColor {
    switch (driver.status) {
      case 'AVAILABLE':
        return DriverColors.secondary;
      case 'ON_TRIP':
        return DriverColors.primaryContainer;
      case 'OFF_DUTY':
        return DriverColors.outline;
      case 'LEAVE':
        return DriverColors.warning;
      default:
        return DriverColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLowest,
        border: const Border(
          bottom: BorderSide(
            color: DriverColors.surfaceContainerHigh,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Logo & Pilot Identity
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DriverColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: DriverColors.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Ambulance First',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DriverTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: DriverColors.primaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DRIVER',
                                style: DriverTextStyles.telemetryMicro.copyWith(
                                  color: DriverColors.primaryContainer,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${driver.assignedAmbulanceNumber}  •  ${driver.name.toUpperCase()}',
                      style: DriverTextStyles.telemetryMicro.copyWith(
                        color: DriverColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Duty status pill
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _dutyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _dutyColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dutyColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          driver.status.replaceAll('_', ' '),
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: _dutyColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Emergency SOS Button
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => EmergencySosModal(
                          driverId: driver.id,
                          driverName: driver.name,
                          bookingId: activeBooking?.id,
                          ambulanceUnit: driver.assignedAmbulanceNumber,
                          latitude: driver.latitude,
                          longitude: driver.longitude,
                          onSosTriggered: onSosTriggered,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.tertiary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Profile Avatar
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: DriverColors.surfaceContainerHighest,
                      child: Text(
                        driver.name.isNotEmpty ? driver.name[0] : 'D',
                        style: DriverTextStyles.titleSmall.copyWith(
                          color: DriverColors.primaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
