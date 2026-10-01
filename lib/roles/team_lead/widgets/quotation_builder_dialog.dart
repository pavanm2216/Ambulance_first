import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_workflow_repository.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import 'status_badge.dart';

class QuotationBuilderDialog extends StatefulWidget {
  const QuotationBuilderDialog({
    super.key,
    required this.booking,
    this.onQuotationSent,
  });

  final Booking booking;
  final VoidCallback? onQuotationSent;

  static void show(
    BuildContext context, {
    required Booking booking,
    VoidCallback? onQuotationSent,
  }) {
    const allowed = {
      'SENT_TO_TEAM_LEAD',
      'VERIFIED',
      'BUDGET_PENDING',
    };
    if (!allowed.contains(booking.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            booking.status == 'QUOTATION_SENT'
                ? 'Quotation has already been sent to the customer.'
                : 'Quotation cannot be prepared from status ${booking.status}.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuotationBuilderDialog(
        booking: booking,
        onQuotationSent: onQuotationSent,
      ),
    );
  }

  @override
  State<QuotationBuilderDialog> createState() =>
      _QuotationBuilderDialogState();
}

class _QuotationBuilderDialogState extends State<QuotationBuilderDialog> {
  final TeamLeadStore store = TeamLeadStore.instance;
  final SupabaseWorkflowRepository workflow = SupabaseWorkflowRepository();

  final TextEditingController discountController = TextEditingController(text: '0');
  final TextEditingController paymentTermsController = TextEditingController(
    text: 'Payment before dispatch',
  );

  bool submitting = false;
  String? errorMessage;

  @override
  void dispose() {
    discountController.dispose();
    paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _sendQuotation() async {
    if (submitting) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });

    try {
      if (!SupabaseService.isConfigured) {
        throw StateError('Supabase is not configured.');
      }

      final discount = double.tryParse(discountController.text.trim()) ?? 0;
      if (discount < 0) {
        throw StateError('Discount cannot be negative.');
      }

      // The server calculates base, distance, medical, tax and final total
      // from pricing_settings and the persisted booking requirements.
      await workflow.prepareQuotation(
        bookingId: widget.booking.id,
        discount: discount,
        paymentTerms: paymentTermsController.text.trim(),
      );

      await store.refreshFromBackend();
      widget.onQuotationSent?.call();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exact quotation calculated and sent from Supabase.'),
          backgroundColor: TeamLeadTheme.operationalEmerald,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => errorMessage = 'Quotation failed: $error');
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final basicFare = b.basicFare;
    final quotationTotal = b.quotation?.finalAmount ?? b.amount;

    return Dialog(
      backgroundColor: TeamLeadTheme.surfaceLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.request_quote_rounded,
                      color: TeamLeadTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exact Quotation — Server Calculated',
                          style: TeamLeadTheme.titleMedium(weight: FontWeight.w700),
                        ),
                        Text(
                          'Booking ${b.id} • ${b.customerName}',
                          style: TeamLeadTheme.small(
                            color: TeamLeadTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(status: 'SENT_TO_TEAM_LEAD'),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _summaryCard(b, basicFare),
              if (quotationTotal > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Current persisted quotation: ₹${quotationTotal.toStringAsFixed(2)}',
                    style: TeamLeadTheme.small(
                      color: TeamLeadTheme.onSurfaceVariant,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'The quotation amount is not typed into Flutter. Supabase reads the active pricing configuration, route distance, service type and clinical requirements and calculates the final quotation.',
                style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Approved Discount (INR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paymentTermsController,
                decoration: const InputDecoration(
                  labelText: 'Payment Terms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TeamLeadTheme.crimsonBg,
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TeamLeadTheme.small(
                      color: TeamLeadTheme.crimsonText,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: submitting ? null : _sendQuotation,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      submitting ? 'Calculating...' : 'Calculate & Send Quotation',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(Booking b, double basicFare) {
    final requirements = <String>[];
    if (b.icuRequired) requirements.add('ICU');
    if (b.ventilatorRequired) requirements.add('VENTILATOR');
    if (b.oxygenRequired) requirements.add('OXYGEN');
    if (b.doctorRequired) requirements.add('DOCTOR');
    if (b.emtRequired) requirements.add('EMT');
    if (b.pediatricPatient) requirements.add('PEDIATRIC');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLow,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        border: Border.all(color: TeamLeadTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _item('SERVICE', b.transportModeLabel),
              ),
              Expanded(
                child: _item('DISTANCE', '${b.distanceKm.toStringAsFixed(2)} km'),
              ),
              Expanded(
                child: _item('BASIC FARE', '₹${basicFare.toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _item('ROUTE', '${b.pickup} → ${b.destination}'),
          const SizedBox(height: 10),
          _item(
            'CLINICAL REQUIREMENTS',
            requirements.isEmpty ? 'None recorded' : requirements.join(' • '),
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: TeamLeadTheme.small(weight: FontWeight.w700)),
      ],
    );
  }
}
