import 'package:flutter/material.dart';

import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

enum DriverActionType { boardPatient, arriveAtDestination }

class DriverConfirmDialog extends StatelessWidget {
  const DriverConfirmDialog({
    super.key,
    required this.actionType,
    required this.bookingId,
    required this.patientName,
    required this.onConfirm,
  });

  final DriverActionType actionType;
  final String bookingId;
  final String patientName;
  final VoidCallback onConfirm;

  String get _title {
    switch (actionType) {
      case DriverActionType.boardPatient:
        return 'Confirm Patient Boarding';
      case DriverActionType.arriveAtDestination:
        return 'Confirm Destination Arrival';
    }
  }

  String get _message {
    switch (actionType) {
      case DriverActionType.boardPatient:
        return 'Confirm that patient $patientName has safely boarded ambulance unit and is secured with medical equipment active.';
      case DriverActionType.arriveAtDestination:
        return 'Confirm that the ambulance and patient have reached the booked drop-off location. The customer must confirm the handoff before this assignment is completed.';
    }
  }

  IconData get _icon {
    switch (actionType) {
      case DriverActionType.boardPatient:
        return Icons.airline_seat_flat_rounded;
      case DriverActionType.arriveAtDestination:
        return Icons.local_hospital_rounded;
    }
  }

  Color get _accentColor {
    switch (actionType) {
      case DriverActionType.boardPatient:
        return DriverColors.primaryContainer;
      case DriverActionType.arriveAtDestination:
        return DriverColors.warning;
    }
  }

  String get _confirmLabel {
    switch (actionType) {
      case DriverActionType.boardPatient:
        return 'CONFIRM BOARDED';
      case DriverActionType.arriveAtDestination:
        return 'CONFIRM ARRIVAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: DriverColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _accentColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title, style: DriverTextStyles.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        'BOOKING: $bookingId',
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DriverColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DriverColors.surfaceContainerHigh),
              ),
              child: Text(
                _message,
                style: DriverTextStyles.bodyMedium.copyWith(
                  color: DriverColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                    ),
                    child: Text(_confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
