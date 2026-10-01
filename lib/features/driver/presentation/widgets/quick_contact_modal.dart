import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class QuickContactModal extends StatefulWidget {
  const QuickContactModal({
    super.key,
    required this.bookingId,
    required this.doctorName,
    required this.doctorPhone,
    required this.emtName,
    required this.emtPhone,
    required this.customerName,
    required this.customerPhone,
    this.dispatchPhone = '+91 1800 263 3633',
  });

  final String bookingId;
  final String doctorName;
  final String doctorPhone;
  final String emtName;
  final String emtPhone;
  final String customerName;
  final String customerPhone;
  final String dispatchPhone;

  @override
  State<QuickContactModal> createState() => _QuickContactModalState();
}

class _QuickContactModalState extends State<QuickContactModal> {
  String? _callingTitle;
  String? _callingNumber;
  bool _isConnected = false;

  void _startCall(String title, String number) {
    if (number.isEmpty || number == 'Not assigned' || number == '+91 90000 00000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact unavailable for $title')),
      );
      return;
    }

    setState(() {
      _callingTitle = title;
      _callingNumber = number;
      _isConnected = false;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
      });
    });
  }

  void _endCall() {
    setState(() {
      _callingTitle = null;
      _callingNumber = null;
      _isConnected = false;
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
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DriverColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: DriverColors.primaryContainer, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operational Contacts', style: DriverTextStyles.headlineSmall),
                        Text(
                          'MISSION REF: ${widget.bookingId}',
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: DriverColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_callingTitle != null) ...[
              // Active Call View
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isConnected ? DriverColors.secondary : DriverColors.primaryContainer,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isConnected ? Icons.call : Icons.ring_volume_rounded,
                      size: 36,
                      color: _isConnected ? DriverColors.secondary : DriverColors.primaryContainer,
                    ),
                    const SizedBox(height: 10),
                    Text(_callingTitle!, style: DriverTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(_callingNumber!, style: DriverTextStyles.telemetrySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isConnected ? DriverColors.secondaryContainer : DriverColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isConnected ? 'CALL CONNECTED' : 'DIALING...',
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: _isConnected ? DriverColors.secondary : DriverColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end, size: 18),
                      label: const Text('END CALL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverColors.tertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Contact Directory List
              _ContactTile(
                role: 'CAD DISPATCH TEAM LEAD',
                name: 'Central Emergency Dispatch',
                phone: widget.dispatchPhone,
                icon: Icons.headset_mic_rounded,
                accentColor: DriverColors.primaryContainer,
                onCall: () => _startCall('CAD Dispatch Desk', widget.dispatchPhone),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                role: 'ONBOARD DOCTOR',
                name: widget.doctorName,
                phone: widget.doctorPhone,
                icon: Icons.medical_services_rounded,
                accentColor: DriverColors.secondary,
                onCall: () => _startCall('Doctor: ${widget.doctorName}', widget.doctorPhone),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                role: 'ONBOARD EMT',
                name: widget.emtName,
                phone: widget.emtPhone,
                icon: Icons.health_and_safety_rounded,
                accentColor: DriverColors.primary,
                onCall: () => _startCall('EMT: ${widget.emtName}', widget.emtPhone),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                role: 'PATIENT ATTENDANT',
                name: widget.customerName,
                phone: widget.customerPhone,
                icon: Icons.person_pin_rounded,
                accentColor: DriverColors.warning,
                onCall: () => _startCall('Attendant: ${widget.customerName}', widget.customerPhone),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.role,
    required this.name,
    required this.phone,
    required this.icon,
    required this.accentColor,
    required this.onCall,
  });

  final String role;
  final String name;
  final String phone;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onCall;

  bool get _isUnavailable => phone.isEmpty || phone == 'Not assigned' || phone == '+91 90000 00000';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DriverColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name,
                  style: DriverTextStyles.titleSmall.copyWith(
                    color: DriverColors.onSurface,
                  ),
                ),
                Text(
                  _isUnavailable ? 'Unavailable' : phone,
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: DriverColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isUnavailable ? null : onCall,
            icon: Icon(
              Icons.phone,
              color: _isUnavailable ? DriverColors.outlineVariant : DriverColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
