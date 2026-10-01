import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_booking_id.dart';
import 'ambulance_first_button.dart';
import 'ambulance_first_status_badge.dart';

/// Comprehensive Patient and Logistics Dossier Dialog
class BookingDetailsDialog extends StatelessWidget {
  const BookingDetailsDialog({
    super.key,
    required this.booking,
    this.onReviewQuotation,
    this.onAcceptQuote,
    this.onDeclineQuote,
  });

  final Booking booking;
  /// Opens the full customer quotation review, including accept and decline.
  final VoidCallback? onReviewQuotation;
  final VoidCallback? onAcceptQuote;
  final VoidCallback? onDeclineQuote;

  static void show(
    BuildContext context, {
    required Booking booking,
    VoidCallback? onReviewQuotation,
    VoidCallback? onAcceptQuote,
    VoidCallback? onDeclineQuote,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BookingDetailsDialog(
        booking: booking,
        onReviewQuotation: onReviewQuotation,
        onAcceptQuote: onAcceptQuote,
        onDeclineQuote: onDeclineQuote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return Dialog(
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AmbulanceFirstColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AmbulanceFirstBookingId(id: b.id, fontSize: 15),
                            const SizedBox(width: 8),
                            AmbulanceFirstStatusBadge(status: b.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${b.ambulanceType} • ${b.date} at ${b.time}',
                          style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            // Scrollable Content Dossier
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Demographics
                    _sectionTitle('Patient Demographics', Icons.person_rounded),
                    const SizedBox(height: 8),
                    _dataCard([
                      _dataRow('Patient Name', '${b.patientName.isNotEmpty ? b.patientName : "Unavailable"} (${b.patientAge > 0 ? "${b.patientAge}y" : "Age unavailable"} / ${b.patientGender})'),
                      if (b.patientWeightKg != null)
                        _dataRow('Patient Weight', '${b.patientWeightKg} kg'),
                      _dataRow('Clinical Condition', b.currentCondition.isNotEmpty ? b.currentCondition : 'Unavailable', isHighlight: b.isEmergency),
                      if (b.medicalSummary.isNotEmpty)
                        _dataRow('Clinical Summary', b.medicalSummary),
                      _dataRow('Conscious State', b.isConscious ? 'Conscious' : 'Unconscious'),
                      _dataRow('Relationship', b.relationshipToPatient),
                      _dataRow('Customer Name', b.customerName.isNotEmpty ? b.customerName : 'Unavailable'),
                      _dataRow('Customer Phone', b.mobileNumber.isNotEmpty ? b.mobileNumber : 'Unavailable'),
                      _dataRow('Customer Email', b.email.isNotEmpty ? b.email : 'Unavailable'),
                    ]),
                    const SizedBox(height: 16),

                    // Transport Route
                    _sectionTitle('Transport Route', Icons.navigation_rounded),
                    const SizedBox(height: 8),
                    _dataCard([
                      _dataRow('Pickup Location', b.pickup),
                      if (b.currentHospital.isNotEmpty)
                        _dataRow('Current Hospital', b.currentHospital),
                      _dataRow('Destination', b.destination),
                      if (b.destinationHospital.isNotEmpty)
                        _dataRow('Destination Hospital', b.destinationHospital),
                      _dataRow('Estimated Distance', b.distanceKm > 0 ? '${b.distanceKm} km' : 'Unavailable'),
                      _dataRow('Estimated Duration', b.estimatedDurationMins > 0 ? '${b.estimatedDurationMins} mins' : 'Unavailable'),
                    ]),
                    const SizedBox(height: 16),

                    // Clinical Requirements
                    _sectionTitle('Clinical Capabilities Required', Icons.medical_services_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (b.icuRequired) _tag('ICU KIT', AmbulanceFirstColors.medicalCrimson),
                        if (b.ventilatorRequired) _tag('VENTILATOR', AmbulanceFirstColors.medicalCrimson),
                        if (b.oxygenRequired) _tag('OXYGEN CYLINDER', AmbulanceFirstColors.clinicalCobalt),
                        if (b.cardiacMonitorRequired) _tag('CARDIAC MONITOR', AmbulanceFirstColors.clinicalCobalt),
                        if (b.pediatricPatient) _tag('PEDIATRIC / PICU', AmbulanceFirstColors.tertiaryContainer),
                        if (b.doctorRequired) _tag('PHYSICIAN ONBOARD', AmbulanceFirstColors.secondary),
                        if (b.emtRequired) _tag('PARAMEDIC / EMT', AmbulanceFirstColors.clinicalCobalt),
                        if (b.stretcherRequired) _tag('STRETCHER', AmbulanceFirstColors.onSurfaceVariant),
                        if (b.wheelchairRequired) _tag('WHEELCHAIR', AmbulanceFirstColors.onSurfaceVariant),
                        if (b.medicalAttendantRequired) _tag('MEDICAL ATTENDANT', AmbulanceFirstColors.secondary),
                        ...b.additionalEquipment.map((item) => _tag(item, AmbulanceFirstColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Assigned Crew & Telemetry (if assigned)
                    if (b.driverName.isNotEmpty || b.vehicleNumber.isNotEmpty) ...[
                      _sectionTitle('Assigned Logistics & Crew', Icons.airport_shuttle_rounded),
                      const SizedBox(height: 8),
                      _dataCard([
                        if (b.vehicleNumber.isNotEmpty)
                          _dataRow('Ambulance Vehicle', b.vehicleNumber),
                        if (b.driverName.isNotEmpty)
                          _dataRow('Primary Driver', '${b.driverName} ${b.driverPhone.isNotEmpty ? "(${b.driverPhone})" : ""}'),
                        if (b.emtName.isNotEmpty)
                          _dataRow('EMT / Paramedic', b.emtName),
                        if (b.doctorName.isNotEmpty)
                          _dataRow('Attending Physician', b.doctorName),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Financial / Quotation Preview
                    _sectionTitle('Financial Summary', Icons.payments_rounded),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AmbulanceFirstColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.quotation != null
                                    ? 'Authoritative Quotation'
                                    : b.status == 'QUOTATION_SENT'
                                        ? 'Quotation details are not available yet'
                                    : b.basicFare > 0
                                        ? 'Basic fare only — quotation pending'
                                        : 'Quotation unavailable',
                                style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                              ),
                              Text(
                                b.quotation != null
                                    ? b.quotation!.id
                                    : b.status == 'QUOTATION_SENT'
                                        ? 'Use REVIEW QUOTATION to reload it'
                                    : b.basicFare > 0
                                        ? 'Not the final customer price'
                                        : 'No quotation',
                                style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.clinicalCobalt, weight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Text(
                            b.quotation != null
                                ? '₹ ${b.quotation!.finalAmount.toStringAsFixed(2)}'
                                : b.basicFare > 0
                                    ? '₹ ${b.basicFare.toStringAsFixed(2)}'
                                    : 'Unavailable',
                            style: AmbulanceFirstTypography.telemetryNum(
                              color: AmbulanceFirstColors.onSurface,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AmbulanceFirstColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AmbulanceFirstButton(
                    label: 'CLOSE',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: AmbulanceFirstButtonVariant.ghost,
                  ),
                  if (b.status == 'QUOTATION_SENT' && onReviewQuotation != null) ...[
                    const SizedBox(width: 12),
                    AmbulanceFirstButton(
                      label: 'REVIEW QUOTATION',
                      icon: Icons.request_quote_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onReviewQuotation!();
                      },
                      variant: AmbulanceFirstButtonVariant.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AmbulanceFirstColors.clinicalCobalt),
        const SizedBox(width: 6),
        Text(
          title,
          style: AmbulanceFirstTypography.labelMd(
            color: AmbulanceFirstColors.onSurface,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _dataCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _dataRow(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AmbulanceFirstColors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AmbulanceFirstTypography.bodyMd(
                color: isHighlight ? AmbulanceFirstColors.medicalCrimson : AmbulanceFirstColors.onSurface,
              ).copyWith(
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AmbulanceFirstTypography.codeSm(color: color, weight: FontWeight.w700).copyWith(fontSize: 10),
      ),
    );
  }
}
