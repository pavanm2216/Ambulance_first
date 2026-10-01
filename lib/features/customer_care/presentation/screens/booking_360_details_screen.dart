import 'package:flutter/material.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';
import '../widgets/booking_lifecycle_timeline.dart';
import '../widgets/live_gps_telemetry_dialog.dart';

class Booking360DetailsScreen extends StatelessWidget {
  const Booking360DetailsScreen({
    super.key,
    required this.caseItem,
    required this.onBack,
    required this.onStartCallVerify,
    required this.onShowToast,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onBack;
  final VoidCallback onStartCallVerify;
  final ValueChanged<String> onShowToast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerCareColors.background,
      appBar: AppBar(
        backgroundColor: CustomerCareColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomerCareColors.onSurface),
          onPressed: onBack,
        ),
        title: Text(
          'Dossier 360°: #${caseItem.id}',
          style: CustomerCareTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              caseItem.statusLabel.toUpperCase(),
              style: CustomerCareTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w800,
                color: CustomerCareColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient & Caller Section
            _buildSection(
              title: 'Patient & Clinical Profile',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  _buildRow('Full Name', caseItem.patientName),
                  _buildRow('Age / Gender', '${caseItem.age} Years • ${caseItem.gender}'),
                  _buildRow('Clinical Acuity', caseItem.priorityLabel, isHigh: caseItem.isCodeRed),
                  _buildRow('Presenting Condition', caseItem.condition),
                  _buildRow('Diagnostic MRN', caseItem.mrn.isNotEmpty ? caseItem.mrn : 'Unavailable'),
                  _buildRow('Pediatric Patient', caseItem.pediatric ? 'Yes (PICU Protocol)' : 'No'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Caller & Contact Section
            _buildSection(
              title: 'Caller & Next of Kin',
              icon: Icons.contact_phone_rounded,
              child: Column(
                children: [
                  _buildRow('Caller Name', caseItem.customerName),
                  _buildRow('Relationship to Patient', caseItem.relationship),
                  _buildRow('Telephone', caseItem.mobileNumber),
                  _buildRow('Email Contact', caseItem.email.isNotEmpty ? caseItem.email : 'Unavailable'),
                  _buildRow('Intake Channel', caseItem.source == 'CUSTOMER_CARE_INBOUND' ? 'Inbound Dispatch Desk' : 'Customer Mobile App'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Service & Equipment Section
            _buildSection(
              title: 'Service & Medical Assets',
              icon: Icons.medical_services_rounded,
              child: Column(
                children: [
                  _buildRow('Transport Category', caseItem.serviceCategory),
                  _buildRow('High-Flow Oxygen', caseItem.oxygen ? 'Yes (Active)' : 'No'),
                  _buildRow('ICU / Monitor Setup', caseItem.icu ? 'Yes (Active)' : 'No'),
                  _buildRow('Transport Ventilator', caseItem.ventilator ? 'Yes (${caseItem.ventilatorMode})' : 'No'),
                  _buildRow('Physician Escort', caseItem.doctor ? 'Yes (${caseItem.doctorSpecialization})' : 'Not Required'),
                  _buildRow('Lead Paramedic / EMT', caseItem.emt ? 'Assigned' : 'Not Required'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Route & Facility Coordination
            _buildSection(
              title: 'Route & Facility Handover',
              icon: Icons.local_hospital_rounded,
              child: Column(
                children: [
                  _buildRow('Pickup Facility', caseItem.pickupAddress),
                  _buildRow('Receiving Hospital', caseItem.destinationHospital.isNotEmpty ? caseItem.destinationHospital : caseItem.destinationAddress),
                  _buildRow('Department / Room', caseItem.receivingDepartment),
                  _buildRow('Receiving Attending', caseItem.receivingDoctor),
                  _buildRow(
                    'Est. Distance & Time',
                    caseItem.distanceKm > 0 || caseItem.durationMins > 0
                        ? '${caseItem.distanceKm > 0 ? '${caseItem.distanceKm} km' : 'Distance unavailable'} • ${caseItem.durationMins > 0 ? '~${caseItem.durationMins} mins' : 'Duration unavailable'}'
                        : 'Route unavailable',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Customer Care Verification & Directives
            _buildSection(
              title: 'Customer Care Triage Record',
              icon: Icons.verified_user_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Call Outcome', caseItem.callStatus),
                  _buildRow('Triage Lead Verifier', caseItem.verifiedBy.isNotEmpty ? caseItem.verifiedBy : 'Not verified'),
                  _buildRow('Safety Protocol Score', '${caseItem.checklistCompletedCount}/6 Items Confirmed'),
                  _buildRow('Call Duration', '${caseItem.callDurationSeconds}s'),
                  const SizedBox(height: 8),
                  Text(
                    'Handover Directives & Notes:',
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      caseItem.notes.isNotEmpty ? caseItem.notes : 'No additional triage notes recorded.',
                      style: CustomerCareTextStyles.bodySm.copyWith(
                        color: CustomerCareColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Operational Lifecycle Timeline
            FutureBuilder<List<Map<String, dynamic>>>(
              future: CustomerCareRepository.instance.loadBookingHistory(caseItem.id),
              builder: (context, snapshot) {
                return BookingLifecycleTimeline(
                  caseItem: caseItem,
                  history: snapshot.data ?? const [],
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: CustomerCareRepository.instance.loadCallLogs(caseItem.id),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? const [];
                if (logs.isEmpty) return const SizedBox.shrink();
                return _buildSection(
                  title: 'Call History',
                  icon: Icons.phone_callback_rounded,
                  child: Column(
                    children: logs.map((log) => _buildRow(
                      log['outcome']?.toString() ?? 'Outcome unavailable',
                      [
                        if (log['agent']?.toString().isNotEmpty == true) log['agent'].toString(),
                        if (log['duration_seconds'] != null) '${log['duration_seconds']}s',
                        if (log['notes']?.toString().isNotEmpty == true) log['notes'].toString(),
                      ].join(' · '),
                    )).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // 7. Live Telemetry Action
            if (caseItem.status == 'IN_TRANSIT' || caseItem.liveSpeedKmh > 0) ...[
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => LiveGpsTelemetryDialog(caseItem: caseItem),
                  );
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('OPEN LIVE GPS TELEMETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerCareColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: CustomerCareTextStyles.labelLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (caseItem.status != 'SENT_TO_TEAM_LEAD' && caseItem.status != 'IN_TRANSIT')
              ElevatedButton.icon(
                onPressed: onStartCallVerify,
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text('OPEN CALL & VERIFICATION CONSOLE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerCareColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: CustomerCareTextStyles.labelLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: CustomerCareColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: CustomerCareTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: CustomerCareColors.outlineVariant),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHigh = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CustomerCareTextStyles.labelSm.copyWith(
              color: CustomerCareColors.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: CustomerCareTextStyles.bodySm.copyWith(
                fontWeight: isHigh ? FontWeight.w800 : FontWeight.w600,
                color: isHigh ? CustomerCareColors.error : CustomerCareColors.onSurface,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
