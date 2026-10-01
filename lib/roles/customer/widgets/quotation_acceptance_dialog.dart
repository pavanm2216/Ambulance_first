import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../theme/ambulance_first_theme.dart';
import 'ambulance_first_button.dart';

/// Interactive Quotation Review & Authorization Dialog
class QuotationAcceptanceDialog extends StatefulWidget {
  const QuotationAcceptanceDialog({
    super.key,
    required this.booking,
    required this.onConfirmAcceptance,
    required this.onConfirmRejection,
  });

  final Booking booking;
  final Future<void> Function() onConfirmAcceptance;
  final Future<void> Function(String reason) onConfirmRejection;

  static void show(
    BuildContext context, {
    required Booking booking,
    required Future<void> Function() onConfirmAcceptance,
    required Future<void> Function(String reason) onConfirmRejection,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuotationAcceptanceDialog(
        booking: booking,
        onConfirmAcceptance: onConfirmAcceptance,
        onConfirmRejection: onConfirmRejection,
      ),
    );
  }

  @override
  State<QuotationAcceptanceDialog> createState() => _QuotationAcceptanceDialogState();
}

class _QuotationAcceptanceDialogState extends State<QuotationAcceptanceDialog> {
  bool _isProcessing = false;
  bool _showDeclineInput = false;
  final TextEditingController _declineReasonCtrl = TextEditingController();

  @override
  void dispose() {
    _declineReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onConfirmAcceptance();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDecline() async {
    final reason = _declineReasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please state a reason for declining this quotation.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await widget.onConfirmRejection(reason);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.booking.quotation;
    if (q == null) {
      return AlertDialog(
        title: const Text('Quotation Unavailable'),
        content: const Text('No active quotation found for this booking.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CLOSE')),
        ],
      );
    }

    return Dialog(
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Indicator
            Container(height: 4, color: AmbulanceFirstColors.clinicalCobalt),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OFFICIAL CLINICAL QUOTATION',
                        style: AmbulanceFirstTypography.codeSm(
                          color: AmbulanceFirstColors.clinicalCobalt,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.id,
                        style: AmbulanceFirstTypography.codeLg(
                          color: AmbulanceFirstColors.onSurface,
                          weight: FontWeight.w700,
                        ).copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AmbulanceFirstColors.warningContainer,
                      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
                      border: Border.all(color: AmbulanceFirstColors.warning),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AmbulanceFirstColors.onWarning),
                        const SizedBox(width: 4),
                        Text(
                          q.validUntil.isNotEmpty ? q.validUntil : 'Validity unavailable',
                          style: AmbulanceFirstTypography.codeSm(
                            color: AmbulanceFirstColors.onWarning,
                            weight: FontWeight.w700,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Itemized Cost Ledger
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient & Mission Snapshot
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AmbulanceFirstColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.booking.patientName} (${widget.booking.patientAge}y / ${widget.booking.patientGender})',
                                style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface).copyWith(fontSize: 14),
                              ),
                              Text(
                                'REF #${widget.booking.id}',
                                style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Route: ${widget.booking.pickup} → ${widget.booking.destination} (${widget.booking.distanceKm > 0 ? "${widget.booking.distanceKm} km" : "distance unavailable"})',
                            style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Cost Breakdown & Line Items',
                      style: AmbulanceFirstTypography.labelMd(color: AmbulanceFirstColors.onSurface).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    _feeRow('Base Ambulance Charge (${widget.booking.ambulanceType})', q.baseAmbulanceCharge),
                    _feeRow('Distance Rate (${widget.booking.distanceKm} km transit)', q.distanceCharge),
                    if (q.doctorCharge > 0) _feeRow('Attending Doctor / Physician', q.doctorCharge),
                    if (q.emtCharge > 0) _feeRow('EMT / Paramedic Staff', q.emtCharge),
                    if (q.icuCharge > 0) _feeRow('ICU Equipment & Life Support Pack', q.icuCharge),
                    if (q.ventilatorCharge > 0) _feeRow('Transport Ventilator & Circuits', q.ventilatorCharge),
                    if (q.oxygenCharge > 0) _feeRow('Medical Oxygen Cylinders', q.oxygenCharge),
                    if (q.pediatricIcuCharge > 0) _feeRow('Specialized PICU / PALS Protocols', q.pediatricIcuCharge),
                    if (q.equipmentCharge > 0) _feeRow('Ancillary Monitoring Equipment', q.equipmentCharge),
                    if (q.attendantCharge > 0) _feeRow('Certified Medical Attendant', q.attendantCharge),
                    if (q.airAmbulanceCharges > 0) _feeRow('Air ambulance charges', q.airAmbulanceCharges),
                    if (q.railwayCharges > 0) _feeRow('Railway transfer charges', q.railwayCharges),
                    if (q.additionalCharges > 0) _feeRow('Additional quotation adjustment', q.additionalCharges),
                    if (q.discount > 0) _feeRow('Quotation discount', -q.discount, isDiscount: true),

                    const Divider(height: 20),
                    _feeRow('Subtotal', q.subtotal, isBold: true),
                    _feeRow('Taxes (GST ${q.taxPercent.toInt()}%)', q.taxAmount),
                    const SizedBox(height: 8),

                    // Total Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AmbulanceFirstColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                        border: Border.all(color: AmbulanceFirstColors.clinicalCobalt.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAYABLE',
                                style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.clinicalCobalt, weight: FontWeight.w700),
                              ),
                              Text(
                                q.paymentTerms,
                                style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            '₹ ${q.finalAmount.toStringAsFixed(2)}',
                            style: AmbulanceFirstTypography.telemetryNum(
                              color: AmbulanceFirstColors.onSurface,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Decline Form Field (if toggled)
                    if (_showDeclineInput) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _declineReasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Declining Quotation',
                          hintText: 'e.g. Disagree with pricing, alternate transport arranged, etc.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AmbulanceFirstColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  if (!_showDeclineInput) ...[
                    AmbulanceFirstButton(
                      label: 'DECLINE',
                      onPressed: _isProcessing ? null : () => setState(() => _showDeclineInput = true),
                      variant: AmbulanceFirstButtonVariant.ghost,
                    ),
                    const Spacer(),
                    AmbulanceFirstButton(
                      label: 'CANCEL',
                      onPressed: () => Navigator.of(context).pop(),
                      variant: AmbulanceFirstButtonVariant.ghost,
                    ),
                    const SizedBox(width: 10),
                    AmbulanceFirstButton(
                      label: 'CONFIRM ACCEPTANCE',
                      icon: Icons.verified_rounded,
                      isLoading: _isProcessing,
                      onPressed: _handleAccept,
                      variant: AmbulanceFirstButtonVariant.primary,
                    ),
                  ] else ...[
                    AmbulanceFirstButton(
                      label: 'BACK',
                      onPressed: () => setState(() => _showDeclineInput = false),
                      variant: AmbulanceFirstButtonVariant.ghost,
                    ),
                    const Spacer(),
                    AmbulanceFirstButton(
                      label: 'SUBMIT DECLINE',
                      isLoading: _isProcessing,
                      onPressed: _handleDecline,
                      variant: AmbulanceFirstButtonVariant.destructive,
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

  Widget _feeRow(String label, double amount, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AmbulanceFirstTypography.bodySm(
                color: isDiscount ? AmbulanceFirstColors.secondary : AmbulanceFirstColors.onSurfaceVariant,
              ).copyWith(fontWeight: isBold ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
          Text(
            isDiscount ? '- ₹ ${amount.abs().toStringAsFixed(2)}' : '₹ ${amount.toStringAsFixed(2)}',
            style: AmbulanceFirstTypography.codeSm(
              color: isDiscount
                  ? AmbulanceFirstColors.secondary
                  : (isBold ? AmbulanceFirstColors.onSurface : AmbulanceFirstColors.onSurfaceVariant),
              weight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
