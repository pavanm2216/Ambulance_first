import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import 'admin_shared.dart';

class AdminQuotationsScreen extends StatelessWidget {
  const AdminQuotationsScreen({super.key, required this.store});

  final AdminStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final bookings = store.bookings;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_rounded,
                              size: 20,
                              color: StitchTheme.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Financial & Quotations',
                              style: StitchTheme.headlineMd(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contracts, quotation pipelines, and billing ledger.',
                          style: StitchTheme.bodySm(),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Export'),
                      onPressed: () => showStitchToast(
                        context,
                        'Exporting financial quotations to CSV...',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StitchTheme.primaryContainer,
                        side: const BorderSide(
                          color: StitchTheme.primaryContainer,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _KpiBox(
                      title: 'QUOTED PIPELINE',
                      value: money(store.quotedPipelineTotal),
                      color: StitchTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiBox(
                      title: 'ACCEPTED ORDERS',
                      value: money(store.acceptedOrdersTotal),
                      color: StitchTheme.primaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KpiBox(
                      title: 'PAID & RECOGNIZED',
                      value: money(store.paidRecognizedTotal),
                      color: StitchTheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiBox(
                      title: 'OUTSTANDING',
                      value: money(store.outstandingCollectionsTotal),
                      color: StitchTheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StitchTheme.spaceLg),

              Text(
                'QUOTATION CONTRACTS',
                style: StitchTheme.labelSm(
                  color: StitchTheme.outline,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              for (final b in bookings) ...[
                _QuotationCard(
                  booking: b,
                  onTap: () => _openQuotationDetailSheet(context, b),
                ),
                const SizedBox(height: StitchTheme.spaceSm),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _openQuotationDetailSheet(BuildContext context, AdminBooking b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: StitchTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(StitchTheme.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotation #${b.quotationId}',
                      style: StitchTheme.headlineSm(),
                    ),
                    Text(
                      'Associated with Booking #${b.id}',
                      style: StitchTheme.bodySm(color: StitchTheme.outline),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(height: 16),
            _rowVal('Customer Liaison', b.customerName),
            _rowVal(
              'Patient Acuity',
              '${b.patientName} (${b.patientCondition})',
            ),
            _rowVal(
              'Transport Class',
              '${b.serviceCategory} · ${b.serviceSubtype}',
            ),
            const Divider(height: 12),
            _rowVal('Base Fare', money(b.baseFare)),
            _rowVal(
              'Distance Charge (${b.distanceKm} km)',
              money(b.distanceCharge),
            ),
            if (b.doctorFee > 0)
              _rowVal('Physician Charge', money(b.doctorFee)),
            if (b.emtFee > 0) _rowVal('Paramedic Charge', money(b.emtFee)),
            if (b.equipmentFee > 0)
              _rowVal('Equipment Surcharge', money(b.equipmentFee)),
            _rowVal('GST/PST Tax', money(b.tax)),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Payable Amount', style: StitchTheme.headlineSm()),
                Text(
                  money(b.quotationTotal),
                  style: StitchTheme.headlineSm(
                    color: StitchTheme.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                showStitchToast(
                  context,
                  'Receipt PDF for ${b.quotationId} generated and transmitted.',
                );
              },
              icon: const Icon(Icons.receipt_rounded, size: 16),
              label: const Text('Download Itemized Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchTheme.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowVal(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
          ),
          Text(
            val,
            style: StitchTheme.labelSm(
              color: StitchTheme.onSurface,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiBox extends StatelessWidget {
  const _KpiBox({
    required this.title,
    required this.value,
    required this.color,
  });
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StitchTheme.labelSm(
              color: StitchTheme.outline,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: StitchTheme.headlineSm(
              color: color,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.booking, required this.onTap});
  final AdminBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(StitchTheme.spaceMd),
        decoration: BoxDecoration(
          color: StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          border: Border.all(color: StitchTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '#${b.quotationId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StitchTheme.labelMd(weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '(#${b.id})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StitchTheme.labelSm(
                            color: StitchTheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  money(b.quotationTotal),
                  style: StitchTheme.labelMd(
                    color: StitchTheme.primaryContainer,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${b.customerName} · ${b.patientName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StitchTheme.bodySm(
                color: StitchTheme.onSurface,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Text(
                  '${b.serviceCategory} (${b.distanceKm} km)',
                  style: StitchTheme.bodySm(color: StitchTheme.outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: b.paymentStatus == 'PAID'
                        ? StitchTheme.tertiaryFixed
                        : StitchTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${b.quotationStatus} · ${b.paymentStatus}',
                    style: StitchTheme.labelSm(
                      color: b.paymentStatus == 'PAID'
                          ? StitchTheme.onTertiaryFixed
                          : StitchTheme.onSecondaryContainer,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
