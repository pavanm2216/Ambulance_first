import 'package:flutter/material.dart';

import '../../../core/services/doctor_repository.dart';
import '../../../shared/theme/app_colors.dart';

class DoctorBookingScreen extends StatefulWidget {
  const DoctorBookingScreen({super.key, required this.repository, required this.doctor, required this.bookings});

  final DoctorRepository repository;
  final Map<String, dynamic>? doctor;
  final List<Map<String, dynamic>> bookings;

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  Map<String, dynamic>? selected;
  List<Map<String, dynamic>> vitals = const [];
  List<Map<String, dynamic>> assessments = const [];
  bool loadingDetails = false;

  Future<void> _select(Map<String, dynamic> booking) async {
    setState(() {
      selected = booking;
      loadingDetails = true;
      vitals = const [];
      assessments = const [];
    });
    try {
      final result = await Future.wait([
        widget.repository.vitals('${booking['id']}'),
        widget.repository.assessments('${booking['id']}'),
      ]);
      if (!mounted) return;
      setState(() {
        vitals = result[0];
        assessments = result[1];
        loadingDetails = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.doctor == null) {
      return const Center(child: Text('Doctor resource is not linked to this profile.'));
    }

    if (selected == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Assigned patients', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Select a booking to inspect patient and clinical data.'),
          const SizedBox(height: 18),
          if (widget.bookings.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No assigned bookings are currently available.')))
          else
            ...widget.bookings.map((booking) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${booking['patient_name'] ?? 'Unnamed patient'}'),
                    subtitle: Text('${booking['id']} · ${booking['status'] ?? '—'}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _select(booking),
                  ),
                )),
        ],
      );
    }

    final booking = selected!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => selected = null), icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: Text('${booking['patient_name'] ?? 'Patient'}', style: Theme.of(context).textTheme.headlineSmall)),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 24,
              runSpacing: 14,
              children: [
                _Info(label: 'Booking', value: '${booking['id']}'),
                _Info(label: 'Status', value: '${booking['status'] ?? '—'}'),
                _Info(label: 'Age', value: '${booking['patient_age'] ?? '—'}'),
                _Info(label: 'Gender', value: '${booking['patient_gender'] ?? '—'}'),
                _Info(label: 'Condition', value: '${booking['patient_current_condition'] ?? '—'}'),
                _Info(label: 'Emergency', value: booking['patient_is_emergency'] == true ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(title: 'Patient & route', children: [
          Text('Pickup: ${booking['pickup_address'] ?? '—'}'),
          const SizedBox(height: 6),
          Text('Destination: ${booking['patient_destination_hospital'] ?? booking['destination_address'] ?? '—'}'),
          const SizedBox(height: 6),
          Text('Medical summary: ${booking['patient_medical_summary'] ?? 'Not provided'}'),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Latest vitals', children: [
          if (loadingDetails)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (vitals.isEmpty)
            const Text('No vitals have been recorded for this booking.')
          else
            _vitals(vitals.first),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Doctor assessments', children: [
          if (loadingDetails)
            const Text('Loading assessment history…')
          else if (assessments.isEmpty)
            const Text('No doctor assessment has been recorded yet.')
          else
            ...assessments.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a['timestamp'] ?? '—'}', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 5),
                    Text('Diagnosis: ${a['diagnosis'] ?? '—'}'),
                    Text('Condition: ${a['patient_condition'] ?? '—'}'),
                    Text('Notes: ${a['notes'] ?? '—'}'),
                  ]),
                )),
        ]),
        const SizedBox(height: 16),
        Card(
          color: AppColors.warningSoft,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.lock_outline, color: AppColors.warning),
              SizedBox(width: 12),
              Expanded(child: Text('Assessment, medication, intervention and vitals submission is intentionally locked until the Doctor RLS/write contract is verified in Supabase.')),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _vitals(Map<String, dynamic> v) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Vital(label: 'Heart rate', value: '${v['heart_rate_bpm'] ?? '—'} bpm'),
          _Vital(label: 'BP', value: '${v['bp_systolic'] ?? '—'}/${v['bp_diastolic'] ?? '—'}'),
          _Vital(label: 'SpO₂', value: '${v['spo2_percent'] ?? '—'}%'),
          _Vital(label: 'Respiratory', value: '${v['respiratory_rate'] ?? '—'} /min'),
          _Vital(label: 'Temperature', value: '${v['temperature_celsius'] ?? '—'} °C'),
          _Vital(label: 'Glucose', value: '${v['glucose_mg_dl'] ?? '—'} mg/dL'),
          _Vital(label: 'Oxygen', value: '${v['oxygen_flow_lpm'] ?? '—'} L/min'),
          _Vital(label: 'Ventilator pressure', value: '${v['ventilator_pressure'] ?? '—'}'),
        ],
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(width: 170, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 3), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)]));
}

class _Vital extends StatelessWidget {
  const _Vital({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(width: 150, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12), ...children])));
}
