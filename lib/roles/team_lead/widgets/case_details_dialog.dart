import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import 'status_badge.dart';

class CaseDetailsDialog extends StatelessWidget {
  const CaseDetailsDialog({
    super.key,
    required this.booking,
  });

  final Booking booking;

  static void show(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => CaseDetailsDialog(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TeamLeadStore.instance;
    final relevantAudit = store.auditLogs.where((a) => a.bookingId == booking.id).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg),
      ),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TeamLeadTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                        ),
                        child: const Icon(
                          Icons.medical_information_rounded,
                          color: TeamLeadTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Case Details: ${booking.id}',
                                style: TeamLeadTheme.titleMedium(weight: FontWeight.w700),
                              ),
                              const SizedBox(width: 10),
                              StatusBadge(status: booking.status),
                            ],
                          ),
                          Text(
                            '${booking.transportModeLabel} • Created ${booking.date} at ${booking.time}',
                            style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
              const SizedBox(height: 16),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Patient & Clinical Triage
                      _sectionTitle('Patient & Clinical Triage'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TeamLeadTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                          border: Border.all(color: TeamLeadTheme.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _field('Patient Name', booking.patientName.isNotEmpty ? booking.patientName : 'Not Specified')),
                                Expanded(child: _field('Age / Gender', '${booking.patientAge > 0 ? booking.patientAge : "—"} yrs • ${booking.patientGender}')),
                                Expanded(child: _field('Triage Priority', booking.priority, highlight: booking.priority == 'CRITICAL')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _field('Condition', booking.currentCondition)),
                                Expanded(child: _field('Pickup Facility', booking.currentHospital.isNotEmpty ? booking.currentHospital : 'Home / Residence')),
                                Expanded(child: _field('Receiving Facility', booking.destinationHospital.isNotEmpty ? booking.destinationHospital : 'Not Specified')),
                              ],
                            ),
                            if (booking.medicalSummary.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _field('Clinical Summary & Notes', booking.medicalSummary),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Clinical Requirements & Equipment
                      _sectionTitle('Required Capabilities & Medical Care'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (booking.icuRequired) _capabilityChip('ICU Care', Icons.local_hospital_rounded),
                          if (booking.ventilatorRequired) _capabilityChip('Ventilator Support', Icons.air_rounded),
                          if (booking.oxygenRequired) _capabilityChip('Oxygen (${booking.oxygenFlowLpm ?? "Standard"} LPM)', Icons.water_drop_rounded),
                          if (booking.pediatricPatient) _capabilityChip('Pediatric Patient / PICU', Icons.child_care_rounded),
                          if (booking.cardiacMonitorRequired) _capabilityChip('Cardiac Monitor', Icons.monitor_heart_rounded),
                          if (booking.doctorRequired) _capabilityChip('Doctor Onboard (${booking.doctorSpecialization ?? "Emergency"})', Icons.medical_services_rounded),
                          if (booking.emtRequired) _capabilityChip('EMT / Paramedic', Icons.health_and_safety_rounded),
                          if (booking.stretcherRequired) _capabilityChip('Stretcher', Icons.single_bed_rounded),
                          if (booking.wheelchairRequired) _capabilityChip('Wheelchair', Icons.accessible_rounded),
                          if (booking.transportMode == 'DEAD_BODY_TRANSFER') _capabilityChip('Cryo-Freezer Chamber', Icons.ac_unit_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Route & Schedule
                      _sectionTitle('Transport Route & Trajectory'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TeamLeadTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                          border: Border.all(color: TeamLeadTheme.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.trip_origin_rounded, color: TeamLeadTheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: _field('Pickup Location', booking.pickup)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, color: TeamLeadTheme.operationalEmerald, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: _field('Destination Facility', booking.destination)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _field('Distance', '${booking.distanceKm} km')),
                                Expanded(child: _field('Estimated Duration', '${booking.estimatedDurationMins > 0 ? booking.estimatedDurationMins : "—"} mins')),
                                Expanded(child: _field('Customer Contact', '${booking.customerName} (${booking.mobileNumber})')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Resource Allocation State
                      _sectionTitle('Assigned Crew & Equipment'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TeamLeadTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                          border: Border.all(color: TeamLeadTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _field('Ambulance Unit', booking.vehicleNumber.isNotEmpty ? booking.vehicleNumber : 'Not Assigned Yet', isCode: true)),
                            Expanded(child: _field('Assigned Driver', booking.driverName.isNotEmpty ? '${booking.driverName} (${booking.driverPhone})' : 'Not Assigned Yet')),
                            Expanded(child: _field('Assigned EMT', booking.emtName.isNotEmpty ? booking.emtName : (booking.emtRequired ? 'Pending' : 'Not Required'))),
                            Expanded(child: _field('Assigned Doctor', booking.doctorName.isNotEmpty ? booking.doctorName : (booking.doctorRequired ? 'Pending' : 'Not Required'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 5: Financials / Quotation
                      if (booking.quotation != null) ...[
                        _sectionTitle('Quotation & Financial Summary'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: TeamLeadTheme.surfaceLow,
                            borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                            border: Border.all(color: TeamLeadTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('QUOTATION ID', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                                  Text(booking.quotation!.id, style: TeamLeadTheme.telemetryPrimary(color: TeamLeadTheme.primaryDark)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STATUS', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                                  StatusBadge(status: booking.quotation!.status),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FINAL AMOUNT', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                                  Text(
                                    'INR ${booking.quotation!.finalAmount.toStringAsFixed(0)}',
                                    style: TeamLeadTheme.headline(color: TeamLeadTheme.primary, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Section 6: Audit History
                      if (relevantAudit.isNotEmpty) ...[
                        _sectionTitle('Case Operational Audit Log'),
                        const SizedBox(height: 8),
                        ...relevantAudit.map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TeamLeadTheme.telemetrySecondary(color: TeamLeadTheme.textMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${log.actor} (${log.role}): ${log.action}',
                                  style: TeamLeadTheme.supportingBody(color: TeamLeadTheme.onSurface),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: TeamLeadTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                    ),
                    child: Text('Close Case View', style: TeamLeadTheme.body(color: Colors.white, weight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TeamLeadTheme.supportingBody(
        color: TeamLeadTheme.onSurface,
        weight: FontWeight.w700,
      ),
    );
  }

  Widget _field(String label, String value, {bool highlight = false, bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TeamLeadTheme.small(color: TeamLeadTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: isCode
              ? TeamLeadTheme.telemetrySecondary(color: highlight ? TeamLeadTheme.medicalCrimson : TeamLeadTheme.primaryDark, weight: FontWeight.w600)
              : TeamLeadTheme.supportingBody(color: highlight ? TeamLeadTheme.medicalCrimson : TeamLeadTheme.onSurface, weight: highlight ? FontWeight.w700 : FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _capabilityChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TeamLeadTheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
        border: Border.all(color: TeamLeadTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TeamLeadTheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TeamLeadTheme.small(
              color: TeamLeadTheme.primaryDark,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
