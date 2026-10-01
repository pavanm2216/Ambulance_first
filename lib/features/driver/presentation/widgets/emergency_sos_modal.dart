import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

enum SosWorkflowState {
  ready,
  confirming,
  broadcasting,
  awaitingAck,
  acknowledged,
  resolved,
}

class EmergencySosModal extends StatefulWidget {
  const EmergencySosModal({
    super.key,
    required this.driverId,
    required this.driverName,
    this.bookingId,
    this.ambulanceUnit = 'KA 01 AB 1234',
    this.latitude,
    this.longitude,
    required this.onSosTriggered,
  });

  final String driverId;
  final String driverName;
  final String? bookingId;
  final String ambulanceUnit;
  final double? latitude;
  final double? longitude;
  final VoidCallback onSosTriggered;

  @override
  State<EmergencySosModal> createState() => _EmergencySosModalState();
}

class _EmergencySosModalState extends State<EmergencySosModal> {
  SosWorkflowState _state = SosWorkflowState.confirming;
  String _emergencyType = 'Vehicle Collision / Breakdown';
  int _secondsToEscalate = 45;
  Timer? _countdownTimer;

  static const List<String> _emergencyTypes = [
    'Critical Medical Deterioration',
    'Vehicle Collision / Breakdown',
    'Severe Traffic Blockade / Delay',
    'Security / Hostile Incident',
    'Equipment Malfunction (Oxygen/ICU)',
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _broadcastSos() {
    setState(() {
      _state = SosWorkflowState.broadcasting;
    });

    widget.onSosTriggered();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _state = SosWorkflowState.awaitingAck;
        _secondsToEscalate = 45;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_secondsToEscalate <= 1) {
          timer.cancel();
          setState(() {
            _state = SosWorkflowState.acknowledged; // Escalated & automatically routed
          });
        } else {
          setState(() {
            _secondsToEscalate -= 1;
          });
          // Simulate CAD acknowledgement at 38s remaining
          if (_secondsToEscalate == 38) {
            timer.cancel();
            setState(() {
              _state = SosWorkflowState.acknowledged;
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: DriverColors.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top SOS Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DriverColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sos_rounded, color: DriverColors.tertiary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY SOS',
                        style: DriverTextStyles.headlineSmall.copyWith(
                          color: DriverColors.tertiary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'CAD Priority Emergency Broadcast',
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_state == SosWorkflowState.confirming) ...[
              Text('Select Incident Classification:', style: DriverTextStyles.titleSmall),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverColors.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _emergencyType,
                    isExpanded: true,
                    items: _emergencyTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t, style: DriverTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _emergencyType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'AMBULANCE UNIT', value: widget.ambulanceUnit),
                    const SizedBox(height: 4),
                    _DetailRow(label: 'PILOT ID', value: widget.driverId),
                    const SizedBox(height: 4),
                    _DetailRow(
                      label: 'MISSION REF',
                      value: widget.bookingId ?? 'STANDBY DEPOT',
                    ),
                    const SizedBox(height: 4),
                    _DetailRow(
                      label: 'CURRENT GPS',
                      value: widget.latitude != null
                          ? '${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}'
                          : 'STANDBY POSITION',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _broadcastSos,
                icon: const Icon(Icons.warning_amber_rounded, size: 20),
                label: const Text('BROADCAST HIGH PRIORITY SOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.tertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ] else if (_state == SosWorkflowState.broadcasting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator(color: DriverColors.tertiary)),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'DISPATCHING SOS TRANSMISSION...',
                  style: DriverTextStyles.telemetrySmall.copyWith(
                    color: DriverColors.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_state == SosWorkflowState.awaitingAck) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DriverColors.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DriverColors.tertiary),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DriverColors.tertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SOS BROADCAST ACTIVE',
                          style: DriverTextStyles.telemetrySmall.copyWith(
                            color: DriverColors.tertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto-escalating in $_secondsToEscalate seconds if unacknowledged by central CAD team.',
                      textAlign: TextAlign.center,
                      style: DriverTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  setState(() => _state = SosWorkflowState.resolved);
                },
                child: const Text('STAND DOWN / CANCEL SOS'),
              ),
            ] else if (_state == SosWorkflowState.acknowledged) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DriverColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DriverColors.secondary),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: DriverColors.secondary, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'SOS ACKNOWLEDGED BY CAD',
                      style: DriverTextStyles.headlineSmall.copyWith(
                        color: DriverColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dispatch Team Lead & Patrol Response have received your coordinates and incident details.',
                      textAlign: TextAlign.center,
                      style: DriverTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: DriverColors.secondary),
                child: const Text('DISMISS CONSOLE'),
              ),
            ] else if (_state == SosWorkflowState.resolved) ...[
              Center(
                child: Text('Emergency Stand Down Confirmed', style: DriverTextStyles.headlineSmall),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: DriverTextStyles.telemetryMicro.copyWith(color: DriverColors.onSurfaceVariant)),
        Text(value, style: DriverTextStyles.telemetryMicro.copyWith(color: DriverColors.onSurface, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
