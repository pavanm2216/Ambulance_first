import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class TripStageStepper extends StatelessWidget {
  const TripStageStepper({
    super.key,
    required this.status,
  });

  final String status;

  static const List<_StageDef> _stages = [
    _StageDef(code: 'ASSIGNED', title: 'Assigned', icon: Icons.assignment_turned_in_outlined),
    _StageDef(code: 'PICKUP_STARTED', title: 'En Route', icon: Icons.directions_car_outlined),
    _StageDef(code: 'PATIENT_PICKED_UP', title: 'Boarded', icon: Icons.airline_seat_flat_outlined),
    _StageDef(code: 'IN_TRANSIT', title: 'In Transit', icon: Icons.local_hospital_outlined),
    _StageDef(code: 'ARRIVED', title: 'Arrived', icon: Icons.place_outlined),
  ];

  int get _currentStageIndex {
    switch (status) {
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return 0;
      case 'PICKUP_STARTED':
        return 1;
      case 'PATIENT_PICKED_UP':
        return 2;
      case 'IN_TRANSIT':
        return 3;
      case 'ARRIVED':
        return 4;
      case 'SERVICE_COMPLETED':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentStageIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRIP PROGRESSION',
                style: DriverTextStyles.telemetryMicro.copyWith(
                  color: DriverColors.primaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'SERVICE_COMPLETED'
                      ? DriverColors.secondaryContainer
                      : DriverColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'SERVICE_COMPLETED' ? 'COMPLETED' : 'STAGE ${currentIndex + 1} OF 5',
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: status == 'SERVICE_COMPLETED'
                        ? DriverColors.secondary
                        : DriverColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Continuous progress bar background
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 18,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: DriverColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Completed bar fill
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 18,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: currentIndex >= 5
                          ? 1.0
                          : (currentIndex / (_stages.length - 1)).clamp(0.0, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: DriverColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Stepper Nodes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_stages.length, (index) {
                      final isPast = index < currentIndex;
                      final isCurrent = index == currentIndex;
                      final stage = _stages[index];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isCurrent ? 40 : 34,
                            height: isCurrent ? 40 : 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPast
                                  ? DriverColors.secondary
                                  : (isCurrent
                                      ? DriverColors.primaryContainer
                                      : DriverColors.surfaceContainerLowest),
                              border: Border.all(
                                color: isPast
                                    ? DriverColors.secondary
                                    : (isCurrent
                                        ? DriverColors.primaryFixedDim
                                        : DriverColors.outlineVariant),
                                width: isCurrent ? 3 : 2,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: DriverColors.primaryContainer.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isPast
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : (isCurrent
                                      ? const Icon(Icons.autorenew_rounded, size: 20, color: Colors.white)
                                      : Icon(stage.icon, size: 16, color: DriverColors.outline)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stage.title,
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              fontSize: 9.5,
                              color: isCurrent
                                  ? DriverColors.primaryContainer
                                  : (isPast ? DriverColors.secondary : DriverColors.onSurfaceVariant),
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StageDef {
  const _StageDef({
    required this.code,
    required this.title,
    required this.icon,
  });

  final String code;
  final String title;
  final IconData icon;
}
