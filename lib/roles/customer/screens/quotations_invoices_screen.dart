import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_button.dart';
import '../../../shared/widgets/aeromed_card.dart';
import '../../../shared/widgets/aeromed_page.dart' hide AeroMedEmptyState;
import '../../../shared/widgets/aeromed_status_badge.dart';
import '../../../shared/widgets/aeromed_ui_states.dart';

class QuotationsInvoicesPage extends StatelessWidget {
  const QuotationsInvoicesPage({
    super.key,
    required this.bookings,
    required this.onRespond,
  });

  final List<Booking> bookings;
  final void Function(Booking booking, bool accepted, String reason) onRespond;

  @override
  Widget build(BuildContext context) {
    final quotes = bookings.where((b) => b.quotation != null).toList();
    final invoices = bookings.where((b) => b.invoice != null).toList();

    return AeroMedPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AeroMedPageHeader(
            title: 'Quotations & Invoices',
            subtitle: 'Review itemized quotations, respond to pricing and access trip invoices.',
          ),
          const SizedBox(height: 18),
          Text('Quotations', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          if (quotes.isEmpty)
            const AeroMedEmptyState(
              title: 'No Quotations Yet',
              message: 'Verified ambulance requests and calculated dispatch quotes will appear here for your review.',
              icon: Icons.request_quote_outlined,
            ),
          ...quotes.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuotationCard(
                  booking: b,
                  onRespond: onRespond,
                ),
              )),
          const SizedBox(height: 16),
          Text('Invoices', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          if (invoices.isEmpty)
            const AeroMedEmptyState(
              title: 'No Invoices Available',
              message: 'Trip receipts and itemized medical invoices will be generated here automatically after service completion.',
              icon: Icons.receipt_long_outlined,
            ),
          ...invoices.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InvoiceTile(booking: b),
              )),
        ],
      ),
    );
  }
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.booking,
    required this.onRespond,
  });

  final Booking booking;
  final void Function(Booking, bool, String) onRespond;

  @override
  Widget build(BuildContext context) {
    final q = booking.quotation!;
    final pending = q.status == 'SENT' || q.status == 'CUSTOMER_VIEWED';

    return AeroMedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.id, style: AppTextStyles.cardTitle),
                    Text(
                      '${booking.id} • ${booking.transportModeLabel}',
                      style: AppTextStyles.supporting,
                    ),
                  ],
                ),
              ),
              AeroMedStatusBadge(q.status.replaceAll('_', ' ')),
            ],
          ),
          const Divider(height: 24),
          _row('Base ambulance', q.baseAmbulanceCharge),
          _row('Distance', q.distanceCharge),
          _row('Doctor', q.doctorCharge),
          _row('EMT', q.emtCharge),
          _row('Oxygen', q.oxygenCharge),
          _row('ICU', q.icuCharge),
          _row('Ventilator', q.ventilatorCharge),
          _row('Equipment', q.equipmentCharge),
          _row('Attendant', q.attendantCharge),
          _row('Additional', q.additionalCharges),
          if (q.discount > 0) _row('Discount', -q.discount),
          _row('Tax (${q.taxPercent.toStringAsFixed(2)}%)', q.taxAmount),
          const Divider(height: 18),
          _row('Final amount', q.finalAmount, bold: true),
          const SizedBox(height: 10),
          Text(
            'Payment: ${q.paymentTerms} • Valid until ${q.validUntil}',
            style: AppTextStyles.supporting,
          ),
          if (q.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(q.notes, style: AppTextStyles.supporting),
            ),
          if (q.rejectionReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Rejection reason: ${q.rejectionReason}',
                style: AppTextStyles.supporting,
              ),
            ),
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AeroMedButton(
                    label: 'Reject',
                    variant: AeroMedButtonVariant.danger,
                    height: 46,
                    onTap: () => _reject(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AeroMedButton(
                    label: 'Accept Quotation',
                    icon: Icons.check_rounded,
                    height: 46,
                    onTap: () => _accept(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: bold ? AppTextStyles.cardTitle : AppTextStyles.body,
              ),
            ),
            Text(
              '₹${value.toStringAsFixed(0)}',
              style: bold ? AppTextStyles.cardTitle : AppTextStyles.body,
            ),
          ],
        ),
      );

  void _accept(BuildContext context) {
    onRespond(booking, true, '');
    showDialog(
      context: context,
      builder: (c) => AeroMedSuccessModal(
        title: 'Quotation Accepted',
        message:
            'Thank you for confirming. Your ambulance and medical team have been notified for priority dispatch.',
        detailRows: [
          ('Booking ID', booking.id),
          ('Quotation ID', booking.quotation!.id),
          ('Total Amount', '₹${booking.quotation!.finalAmount.toStringAsFixed(0)}'),
          ('Pickup', booking.pickup),
          ('Status', 'Allocation in Progress'),
        ],
        primaryActionLabel: 'Done',
        onPrimaryAction: () {},
      ),
    );
  }

  void _reject(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel quotation'),
        content: TextField(
          controller: c,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Cancellation reason *',
            hintText: 'Tell us why you are cancelling this quotation...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isEmpty) return;
              Navigator.pop(context);
              onRespond(booking, false, c.text.trim());
              showAeroMedSuccessToast(
                context,
                message: 'Quotation rejected. Operations team has been notified.',
              );
            },
            child: const Text('Cancel quotation'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final invoice = booking.invoice!;
    return AeroMedCard(
      shadow: false,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.success,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.id, style: AppTextStyles.bodyStrong),
                    Text(
                      '${booking.id} • ${booking.date}',
                      style: AppTextStyles.supporting,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${invoice.total.toStringAsFixed(0)}',
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _view(context, invoice),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _copy(context, invoice.id),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _copy(context, invoice.id),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _view(BuildContext c, Invoice invoice) => showDialog(
        context: c,
        builder: (_) => AlertDialog(
          title: Text(invoice.id),
          content: Text(
            'Ambulance First Customer Invoice\n'
            'Booking: ${invoice.bookingId}\n'
            'Quotation: ${invoice.quotationId}\n'
            'Service: ${invoice.serviceDetails}\n'
            'Amount: ₹${invoice.total.toStringAsFixed(0)}\n'
            'Payment: ${invoice.paymentStatus}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  void _copy(BuildContext c, String id) {
    showAeroMedSuccessToast(c, message: '$id details ready to share.');
  }
}

