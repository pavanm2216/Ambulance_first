import 'package:flutter/material.dart';
import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.booking,
    required this.onAcknowledge,
    this.onReject,
    this.onViewDetails,
    this.isDriverOffDuty = false,
  });

  final DriverBooking booking;
  final VoidCallback onAcknowledge;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;
  final bool isDriverOffDuty;

  bool get _isCodeRed => booking.icuRequired || booking.ventilatorRequired || booking.cardiacMonitorRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isCodeRed ? DriverColors.tertiary.withValues(alpha: 0.3) : DriverColors.surfaceContainerHigh,
          width: _isCodeRed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isCodeRed
                ? DriverColors.tertiary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Urgency Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isCodeRed
                  ? DriverColors.tertiary.withValues(alpha: 0.08)
                  : DriverColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isCodeRed ? DriverColors.tertiary : DriverColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isCodeRed ? Icons.warning_amber_rounded : Icons.local_hospital_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCodeRed ? 'CODE RED' : 'SCHEDULED',
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      booking.id,
                      style: DriverTextStyles.bookingId.copyWith(
                        color: DriverColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DriverColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${booking.preferredDate} • ${booking.preferredTime}',
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: DriverColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${booking.patientName}, ${booking.patientAge} ${booking.patientGender[0]}',
                            style: DriverTextStyles.headlineSmall.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.medicalConditionSummary,
                            style: DriverTextStyles.bodyMedium.copyWith(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DriverColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.currentCondition,
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Medical Equipment Requirement Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (booking.oxygenRequired)
                      _RequirementChip(icon: Icons.air, label: 'Oxygen'),
                    if (booking.stretcherRequired)
                      _RequirementChip(icon: Icons.airline_seat_flat, label: 'Stretcher'),
                    if (booking.doctorRequired)
                      _RequirementChip(icon: Icons.medical_services_outlined, label: 'Doctor Required', isHighlight: true),
                    if (booking.cardiacMonitorRequired)
                      _RequirementChip(icon: Icons.monitor_heart_outlined, label: 'Cardiac Monitor', isHighlight: true),
                    if (booking.icuRequired)
                      _RequirementChip(icon: Icons.local_hospital_outlined, label: 'ICU Rig', isHighlight: true),
                    if (booking.ventilatorRequired)
                      _RequirementChip(icon: Icons.masks_outlined, label: 'Ventilator', isHighlight: true),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: DriverColors.surfaceContainerHigh),
                const SizedBox(height: 14),

                // Route Segment
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 10, color: DriverColors.primaryContainer),
                        Container(width: 2, height: 36, color: DriverColors.outlineVariant),
                        const Icon(Icons.location_on, size: 12, color: DriverColors.tertiary),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.currentHospital.isNotEmpty
                                ? '${booking.currentHospital} (${booking.pickupAddress})'
                                : booking.pickupAddress,
                            style: DriverTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DriverColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            booking.destinationHospital.isNotEmpty
                                ? '${booking.destinationHospital} (${booking.destinationAddress})'
                                : booking.destinationAddress,
                            style: DriverTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DriverColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Crew summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DriverColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: DriverColors.primaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'Dr: ${booking.doctorName}',
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: DriverColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 14, color: DriverColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'EMT: ${booking.emtName}',
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: DriverColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${booking.estimatedDistanceKm} KM',
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Primary Action Button
                if (booking.status == 'ASSIGNED') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isDriverOffDuty ? null : onReject,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('REJECT'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isDriverOffDuty ? null : onAcknowledge,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('ACCEPT & START PICKUP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCodeRed ? DriverColors.tertiary : DriverColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (booking.status == 'DRIVER_ASSIGNED') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isDriverOffDuty ? null : onAcknowledge,
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('START PICKUP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCodeRed ? DriverColors.tertiary : DriverColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ] else if (booking.isActive) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('OPEN ACTIVE TRIP CONSOLE'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: DriverColors.primaryContainer,
                        side: const BorderSide(color: DriverColors.primaryContainer, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  final IconData icon;
  final String label;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? DriverColors.tertiary.withValues(alpha: 0.1) : DriverColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight ? DriverColors.tertiary.withValues(alpha: 0.3) : DriverColors.surfaceContainerHighest,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isHighlight ? DriverColors.tertiary : DriverColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DriverTextStyles.telemetryMicro.copyWith(
              color: isHighlight ? DriverColors.tertiaryDark : DriverColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
