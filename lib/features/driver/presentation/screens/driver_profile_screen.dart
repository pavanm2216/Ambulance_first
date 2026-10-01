import 'package:flutter/material.dart';
import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/driver_duty_switcher.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({
    super.key,
    required this.driver,
    required this.onStatusChanged,
    required this.onSignOut,
  });

  final DriverProfile driver;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pilot Credential Dossier Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: DriverColors.primaryContainer,
                  child: Text(
                    driver.name.isNotEmpty ? driver.name[0] : 'R',
                    style: DriverTextStyles.headlineLarge.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(driver.name, style: DriverTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  'PILOT ID: ${driver.id}',
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: DriverColors.primaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DriverColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CERTIFIED EMERGENCY PILOT',
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: DriverColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Duty Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPERATIONAL DUTY STATUS', style: DriverTextStyles.titleSmall),
                const SizedBox(height: 12),
                DriverDutySwitcher(
                  currentStatus: driver.status,
                  hasActiveTrip: driver.status == 'ON_TRIP',
                  onStatusChanged: onStatusChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Operational Details List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CREDENTIALS & ASSIGNMENTS', style: DriverTextStyles.titleSmall),
                const SizedBox(height: 14),
                _InfoRow(label: 'Assigned Ambulance', value: driver.assignedAmbulanceNumber),
                const Divider(height: 20, color: DriverColors.surfaceContainerHigh),
                _InfoRow(label: 'Commercial Driving License', value: driver.licenseNumber),
                const Divider(height: 20, color: DriverColors.surfaceContainerHigh),
                _InfoRow(label: 'License Expiration Date', value: driver.licenseExpiry),
                const Divider(height: 20, color: DriverColors.surfaceContainerHigh),
                _InfoRow(label: 'Emergency Driving Exp', value: '${driver.experienceYears} Years'),
                const Divider(height: 20, color: DriverColors.surfaceContainerHigh),
                _InfoRow(label: 'Total Completed Missions', value: '${driver.totalTrips} Transports'),
                const Divider(height: 20, color: DriverColors.surfaceContainerHigh),
                _InfoRow(label: 'Pilot Quality Rating', value: '${driver.rating} / 5.0'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Supported Medical Transport Categories
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AUTHORIZED VEHICLE CERTIFICATIONS', style: DriverTextStyles.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: driver.supportedCategories.map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DriverColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cat,
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, color: DriverColors.tertiary, size: 18),
            label: Text('SIGN OUT OF DRIVER WORKSPACE', style: DriverTextStyles.button.copyWith(color: DriverColors.tertiary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DriverColors.tertiary, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: DriverTextStyles.bodyMedium),
        Text(value, style: DriverTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
