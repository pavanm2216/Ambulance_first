import 'package:flutter/material.dart';
import '../../../core/models/auth_user.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/customer_booking_workflow_service.dart';
import '../../../core/services/shared_booking_store.dart';
import '../theme/ambulance_first_theme.dart';
import '../widgets/ambulance_first_button.dart';
import '../widgets/ambulance_first_card.dart';
import '../widgets/ambulance_first_states.dart';
import '../widgets/ambulance_first_status_badge.dart';
import '../widgets/booking_details_dialog.dart';

/// Customer Booking History Screen
class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({
    super.key,
    required this.user,
    required this.onBookNewAmbulance,
  });

  final AuthUser user;
  final VoidCallback onBookNewAmbulance;

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  String _historyFilter = 'ALL'; // ALL, COMPLETED, CANCELLED

  List<Booking> get _historyBookings {
    final all = CustomerBookingWorkflowService.forCustomer(SharedBookingStore.bookings, widget.user.id);
    return all.where((b) {
        final isPast = b.isCompleted ||
          b.status == 'CANCELLED' ||
          b.status == 'CUSTOMER_REJECTED';

      if (!isPast) return false;

      if (_historyFilter == 'COMPLETED') {
        return b.isCompleted;
      } else if (_historyFilter == 'CANCELLED') {
        return b.status == 'CANCELLED' || b.status == 'CUSTOMER_REJECTED';
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = _historyBookings;

    final completedCount = history.where((b) => b.status == 'SERVICE_COMPLETED' || b.status == 'COMPLETED').length;
    final totalSpent = history
        .where((b) => b.status == 'SERVICE_COMPLETED' || b.status == 'COMPLETED')
        .fold<double>(0, (sum, b) => sum + (b.quotation != null ? b.quotation!.finalAmount : b.amount));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final horizontalPadding = isDesktop
            ? AmbulanceFirstSpacing.margin
            : AmbulanceFirstSpacing.marginMobile;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historical Transports Ledger',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.headlineMd(color: AmbulanceFirstColors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Past completed transfers, cancelled bookings, and digital tax invoices',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary Strip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AmbulanceFirstColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg),
                      border: Border.all(color: AmbulanceFirstColors.borderSubtle),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runSpacing: 12,
                      spacing: 18,
                      children: [
                        _metricCol('Completed Transfers', '$completedCount', AmbulanceFirstColors.secondary),
                        _metricCol('Cumulative Spend', '₹ ${totalSpent.toStringAsFixed(0)}', AmbulanceFirstColors.onSurface),
                        _metricCol('Clinical Records', '${history.length}', AmbulanceFirstColors.clinicalCobalt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterTab('ALL', 'All History'),
                      _filterTab('COMPLETED', 'Completed Transfers'),
                      _filterTab('CANCELLED', 'Cancelled / Declined'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // History List
                  if (history.isEmpty)
                    const AmbulanceFirstEmptyState(
                      icon: Icons.history_rounded,
                      heading: 'No Booking History',
                      description: 'Completed and cancelled ambulance journeys will be archived here.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildHistoryCard(context, history[i]),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AmbulanceFirstTypography.telemetryNum(color: color, size: 20),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _filterTab(String key, String label) {
    final isSelected = _historyFilter == key;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AmbulanceFirstTypography.labelMd(
        color: isSelected ? AmbulanceFirstColors.onPrimary : AmbulanceFirstColors.onSurfaceVariant,
      ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      selectedColor: AmbulanceFirstColors.clinicalCobalt,
      side: BorderSide(
        color: isSelected ? AmbulanceFirstColors.clinicalCobalt : AmbulanceFirstColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
      ),
      onSelected: (_) => setState(() => _historyFilter = key),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Booking booking) {
    final isCompleted = booking.status == 'SERVICE_COMPLETED' || booking.status == 'COMPLETED';

    return AmbulanceFirstCard(
      urgencyPriority: booking.priority,
      onTap: () => BookingDetailsDialog.show(context, booking: booking),
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: ID, Patient Name, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.id.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.codeMd(
                        color: AmbulanceFirstColors.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      booking.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AmbulanceFirstStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),

          // Route & Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 14, color: AmbulanceFirstColors.clinicalCobalt),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.pickup} → ${booking.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${booking.date}, ${booking.time}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footer: Crew details, Total Fare & Invoice Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                booking.driverName.isNotEmpty
                  ? 'Driver: ${booking.driverName}${booking.vehicleNumber.isNotEmpty ? ' • ${booking.vehicleNumber}' : ''}'
                  : 'Assignment unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.invoice != null
                        ? '₹ ${booking.invoice!.total.toStringAsFixed(2)}'
                        : 'Invoice unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.telemetryNum(
                        color: isCompleted ? AmbulanceFirstColors.secondary : AmbulanceFirstColors.onSurfaceVariant,
                        size: 16,
                      ),
                    ),
                  ),
                  if (booking.invoice != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AmbulanceFirstColors.clinicalCobalt),
                      tooltip: 'View Invoice',
                      onPressed: () => _showInvoiceDialog(context, booking),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Booking booking) {
    final inv = booking.invoice!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: AmbulanceFirstColors.clinicalCobalt),
            const SizedBox(width: 8),
            Text('Tax Invoice #${inv.id}', style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Reference: ${booking.id}', style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Patient: ${booking.patientName}', style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface)),
            const SizedBox(height: 4),
            Text('Service: ${inv.serviceDetails}', style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Date: ${inv.invoiceDate}', style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Invoice Number: ${inv.invoiceNumber.isNotEmpty ? inv.invoiceNumber : "Unavailable"}', style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Payment: ${inv.paymentStatus}${inv.paymentMethod.isNotEmpty ? ' · ${inv.paymentMethod}' : ''}', style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant)),
            const Divider(height: 20),
            if (inv.subtotal > 0) _invoiceRow('Subtotal', inv.subtotal),
            if (inv.taxAmount > 0) _invoiceRow('Tax', inv.taxAmount),
            if (inv.discount > 0) _invoiceRow('Discount', -inv.discount),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid:', style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface)),
                Text('₹ ${inv.total.toStringAsFixed(2)}', style: AmbulanceFirstTypography.telemetryNum(color: AmbulanceFirstColors.secondary, size: 20)),
              ],
            ),
          ],
        ),
        actions: [
          AmbulanceFirstButton(
            label: 'CLOSE',
            onPressed: () => Navigator.of(ctx).pop(),
            variant: AmbulanceFirstButtonVariant.ghost,
          ),
          AmbulanceFirstButton(
            label: inv.pdfUrl.isNotEmpty ? 'OPEN PDF' : 'PDF UNAVAILABLE',
            icon: Icons.download_rounded,
            onPressed: inv.pdfUrl.isEmpty ? null : () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice PDF link is available.')));
            },
            variant: AmbulanceFirstButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant)),
          Text('₹ ${amount.toStringAsFixed(2)}', style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurface)),
        ],
      ),
    );
  }
}
