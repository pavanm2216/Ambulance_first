import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.doctor,
    required this.bookings,
    required this.onRefresh,
    required this.onOpenBooking,
  });

  final bool loading;
  final String? error;
  final Map<String, dynamic>? doctor;
  final List<Map<String, dynamic>> bookings;
  final VoidCallback onRefresh;
  final ValueChanged<Map<String, dynamic>> onOpenBooking;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Clinical overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Review patients assigned to your existing doctor resource. Clinical writes remain locked until doctor-specific RLS is verified.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (error != null) _Notice(message: error!, error: true),
          if (doctor != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: .12),
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${doctor!['name'] ?? 'Doctor'}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${doctor!['specialization'] ?? 'General Physician'} · ${doctor!['status'] ?? '—'}'),
                        ],
                      ),
                    ),
                    TextButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _Metric(label: 'Assigned', value: '${bookings.length}', icon: Icons.assignment_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _Metric(label: 'Critical', value: '${bookings.where((b) => b['patient_is_emergency'] == true).length}', icon: Icons.priority_high_rounded)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Assigned bookings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (bookings.isEmpty)
              const _Notice(message: 'No patients are currently assigned to this doctor resource.')
            else
              ...bookings.take(8).map((booking) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text('${booking['patient_name'] ?? 'Unnamed patient'}'),
                      subtitle: Text('${booking['id']} · ${booking['status'] ?? '—'}\n${booking['pickup_address'] ?? 'Pickup not provided'} → ${booking['patient_destination_hospital'] ?? booking['destination_address'] ?? 'Destination not provided'}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onOpenBooking(booking),
                    ),
                  )),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Card(
        color: error ? AppColors.errorSoft : AppColors.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(error ? Icons.info_outline : Icons.inbox_outlined, color: error ? AppColors.error : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}
