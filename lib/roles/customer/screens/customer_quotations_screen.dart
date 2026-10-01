import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/customer_booking_workflow_service.dart';
import '../../../core/services/customer_portal_cache.dart';
import '../../../core/services/shared_booking_store.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_workflow_repository.dart';
import '../theme/ambulance_first_theme.dart';
import '../widgets/ambulance_first_booking_id.dart';
import '../widgets/ambulance_first_button.dart';
import '../widgets/ambulance_first_card.dart';
import '../widgets/ambulance_first_states.dart';
import '../widgets/quotation_acceptance_dialog.dart';

/// Dedicated Quotations Management Screen for Ambulance First.
class CustomerQuotationsScreen extends StatefulWidget {
  const CustomerQuotationsScreen({
    super.key,
    required this.user,
    required this.onBookNewAmbulance,
  });

  final AuthUser user;
  final VoidCallback onBookNewAmbulance;

  @override
  State<CustomerQuotationsScreen> createState() =>
      _CustomerQuotationsScreenState();
}

class _CustomerQuotationsScreenState
    extends State<CustomerQuotationsScreen> {
  String _activeFilter = 'PENDING';

  final SupabaseWorkflowRepository _workflow =
      SupabaseWorkflowRepository();

  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();

  bool _responding = false;

  // ---------------------------------------------------------------------------
  // CUSTOMER BOOKINGS
  // ---------------------------------------------------------------------------

  List<Booking> get _allCustomerBookings =>
      CustomerBookingWorkflowService.forCustomer(
        SharedBookingStore.bookings,
        widget.user.id,
      );

  List<Booking> get _quotedBookings {
    final withQuotes = _allCustomerBookings
        .where((booking) => booking.quotation != null)
        .toList();

    if (_activeFilter == 'PENDING') {
      return withQuotes
          .where((booking) => booking.status == 'QUOTATION_SENT')
          .toList();
    }

    if (_activeFilter == 'ACCEPTED') {
      return withQuotes.where((booking) {
        return booking.status == 'CUSTOMER_ACCEPTED' ||
            booking.status == 'ASSIGNED' ||
            booking.status == 'DRIVER_ASSIGNED' ||
            booking.status == 'PICKUP_STARTED' ||
            booking.status == 'PATIENT_PICKED_UP' ||
            booking.status == 'IN_TRANSIT' ||
            booking.status == 'ARRIVED' ||
            booking.status == 'SERVICE_COMPLETED';
      }).toList();
    }

    return withQuotes;
  }

  int? _quotationVersionFor(String bookingId) {
    for (final row in CustomerPortalCache.quotations.reversed) {
      if (row['booking_id']?.toString() == bookingId) {
        final value = row['quotation_version_no'];

        if (value is num) {
          return value.toInt();
        }

        return int.tryParse(value?.toString() ?? '');
      }
    }

    return null;
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final quotations = _quotedBookings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        final horizontalPadding = isDesktop
            ? AmbulanceFirstSpacing.margin
            : AmbulanceFirstSpacing.marginMobile;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ----------------------------------------------------------------
                  // HEADER
                  // ----------------------------------------------------------------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quotations & Billing Approval',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.headlineMd(
                          color: AmbulanceFirstColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review itemized cost sheets, clinical equipment rates, and authorize dispatch',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(
                          color: AmbulanceFirstColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------------
                  // FILTER
                  // ----------------------------------------------------------------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterTab(
                        'PENDING',
                        'Pending Sign-off',
                      ),
                      _filterTab(
                        'ACCEPTED',
                        'Accepted',
                      ),
                      _filterTab(
                        'ALL',
                        'All Quotes',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------------
                  // QUOTATIONS
                  // ----------------------------------------------------------------
                  if (quotations.isEmpty)
                    AmbulanceFirstEmptyState(
                      icon: Icons.request_quote_outlined,
                      heading: 'No Quotations Found',
                      description:
                          _activeFilter == 'PENDING'
                              ? 'You have no quotations currently requiring approval.'
                              : 'No quotation records found for this category.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: quotations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildQuotationCard(
                          context,
                          quotations[index],
                        );
                      },
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

  // ---------------------------------------------------------------------------
  // FILTER TAB
  // ---------------------------------------------------------------------------

  Widget _filterTab(
    String key,
    String label,
  ) {
    final isSelected = _activeFilter == key;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle:
          AmbulanceFirstTypography.labelMd(
        color: isSelected
            ? AmbulanceFirstColors.onPrimary
            : AmbulanceFirstColors.onSurfaceVariant,
      ).copyWith(
        fontWeight: isSelected
            ? FontWeight.w600
            : FontWeight.w500,
      ),
      backgroundColor:
          AmbulanceFirstColors.surfaceContainerLowest,
      selectedColor:
          AmbulanceFirstColors.clinicalCobalt,
      side: BorderSide(
        color: isSelected
            ? AmbulanceFirstColors.clinicalCobalt
            : AmbulanceFirstColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AmbulanceFirstSpacing.radiusPill,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _activeFilter = key;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // QUOTATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildQuotationCard(
    BuildContext context,
    Booking booking,
  ) {
    final q = booking.quotation!;

    final version =
        q.versionNo ?? _quotationVersionFor(booking.id);

    final isPending =
        booking.status == 'QUOTATION_SENT';

    final isAccepted =
        booking.status == 'CUSTOMER_ACCEPTED' ||
            booking.status == 'ASSIGNED' ||
            booking.status == 'DRIVER_ASSIGNED' ||
            booking.status == 'PICKUP_STARTED' ||
            booking.status == 'PATIENT_PICKED_UP' ||
            booking.status == 'IN_TRANSIT' ||
            booking.status == 'ARRIVED' ||
            booking.status == 'SERVICE_COMPLETED';

    return AmbulanceFirstCard(
      topIndicatorColor: isPending
          ? AmbulanceFirstColors.medicalCrimson
          : isAccepted
              ? AmbulanceFirstColors.secondary
              : AmbulanceFirstColors.outlineVariant,
      padding: const EdgeInsets.all(
        AmbulanceFirstSpacing.spaceSm,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ----------------------------------------------------------------
          // HEADER ROW
          // ----------------------------------------------------------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AmbulanceFirstBookingId(
                      id: q.id,
                      prefix: 'QUOTE',
                      fontSize: 14,
                    ),
                  ),
                  if (version != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'v$version',
                      style: AmbulanceFirstTypography.codeSm(
                        color: AmbulanceFirstColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? AmbulanceFirstColors.warningContainer
                          : isAccepted
                              ? AmbulanceFirstColors.secondaryContainer
                              : AmbulanceFirstColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        AmbulanceFirstSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      q.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.codeSm(
                        color: isPending
                            ? AmbulanceFirstColors.onWarning
                            : isAccepted
                                ? AmbulanceFirstColors.onSecondaryContainer
                                : AmbulanceFirstColors.onSurfaceVariant,
                        weight: FontWeight.w700,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₹ ${q.finalAmount.toStringAsFixed(2)}',
                  style: AmbulanceFirstTypography.telemetryNum(
                    color: AmbulanceFirstColors.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------------------
          // BOOKING CONTEXT
          // ----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors
                  .surfaceContainerLow,
              borderRadius:
                  BorderRadius.circular(
                AmbulanceFirstSpacing.radiusMd,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.patientName} (${booking.patientAge}y / ${booking.patientGender})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.headlineSm(
                    color: AmbulanceFirstColors.onSurface,
                  ).copyWith(fontSize: 13),
                ),
                Text(
                  'REF #${booking.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.codeSm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${booking.pickup} → ${booking.destination} (${booking.distanceKm} km transit)',
                  style:
                      AmbulanceFirstTypography.bodySm(
                    color:
                        AmbulanceFirstColors
                            .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------------------
          // ITEMIZED CHARGES
          // ----------------------------------------------------------------
          _itemRow(
            'Base Transport (${booking.ambulanceType})',
            q.baseAmbulanceCharge,
          ),

          _itemRow(
            'Distance Mileage Rate',
            q.distanceCharge,
          ),

          if (q.doctorCharge > 0)
            _itemRow(
              'Physician Care',
              q.doctorCharge,
            ),

          if (q.emtCharge > 0)
            _itemRow(
              'EMT / Paramedic',
              q.emtCharge,
            ),

          if (q.icuCharge > 0)
            _itemRow(
              'ICU Pack',
              q.icuCharge,
            ),

          if (q.ventilatorCharge > 0)
            _itemRow(
              'Ventilator Pack',
              q.ventilatorCharge,
            ),

          if (q.oxygenCharge > 0)
            _itemRow(
              'Oxygen Cylinders',
              q.oxygenCharge,
            ),

          if (q.discount > 0)
            _itemRow(
              'Discount / Waiver',
              -q.discount,
              isDiscount: true,
            ),

          _itemRow(
            'Applicable Taxes (GST ${q.taxPercent.toInt()}%)',
            q.taxAmount,
          ),

          const Divider(height: 16),

          // ----------------------------------------------------------------
          // ACTIONS
          // ----------------------------------------------------------------
          if (isPending)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AmbulanceFirstButton(
                    label: 'REVIEW & AUTHORIZE',
                    icon: Icons.verified_rounded,
                    onPressed: _responding
                        ? null
                        : () => _openAcceptanceDialog(
                              context,
                              booking,
                            ),
                    variant:
                        AmbulanceFirstButtonVariant.primary,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: AmbulanceFirstButton(
                    label: 'DECLINE',
                    onPressed: _responding
                        ? null
                        : () => _openAcceptanceDialog(
                              context,
                              booking,
                            ),
                    variant:
                        AmbulanceFirstButtonVariant.secondary,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAccepted
                        ? 'Authorized on delivery terms: ${q.paymentTerms}'
                        : 'Declined by customer',
                    style:
                        AmbulanceFirstTypography.bodySm(
                      color: isAccepted
                          ? AmbulanceFirstColors.secondary
                          : AmbulanceFirstColors
                              .medicalCrimson,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                AmbulanceFirstButton(
                  label: 'VIEW DOSSIER',
                  height: 36,
                  variant:
                      AmbulanceFirstButtonVariant.ghost,
                  onPressed: _responding
                      ? null
                      : () => _openAcceptanceDialog(
                            context,
                            booking,
                          ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM ROW
  // ---------------------------------------------------------------------------

  Widget _itemRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style:
                  AmbulanceFirstTypography.bodySm(
                color:
                    AmbulanceFirstColors
                        .onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            isDiscount
                ? '- ₹ ${amount.abs().toStringAsFixed(2)}'
                : '₹ ${amount.toStringAsFixed(2)}',
            style:
                AmbulanceFirstTypography.codeSm(
              color: isDiscount
                  ? AmbulanceFirstColors.secondary
                  : AmbulanceFirstColors.onSurface,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCEPT / REJECT DIALOG
  // ---------------------------------------------------------------------------

  void _openAcceptanceDialog(
    BuildContext context,
    Booking booking,
  ) {
    QuotationAcceptanceDialog.show(
      context,
      booking: booking,

      // ================================================================
      // ACCEPT QUOTATION
      // ================================================================
      onConfirmAcceptance: () async {
        if (_responding) return;

        setState(() {
          _responding = true;
        });

        try {
          if (!SupabaseService.isConfigured) {
            throw StateError(
              'Supabase is not configured.',
            );
          }

          if (booking.quotation == null) {
            throw StateError(
              'Quotation is missing for this booking.',
            );
          }

          await _workflow.respondToQuotation(
            bookingId: booking.id,
            accept: true,
          );

          // Reload the actual booking from Supabase.
          final customerBookings =
              await _bookingRepository
                  .getCustomerBookings();

          Booking? persisted;

          for (final item in customerBookings) {
            if (item.id == booking.id) {
              persisted = item;
              break;
            }
          }

          if (persisted == null) {
            throw StateError(
              'Accepted quotation was saved but the booking could not be reloaded.',
            );
          }

          // Update local shared state only AFTER DB success.
          SharedBookingStore.upsert(
            persisted,
          );

          CustomerPortalCache.quotations =
              await _bookingRepository
                  .getCustomerQuotations();

          if (!context.mounted) return;

          _refresh();

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Quotation ${booking.quotation?.id ?? booking.id} accepted and saved.',
              ),
              backgroundColor:
                  AmbulanceFirstColors.secondary,
            ),
          );
        } catch (error) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
                  Text('Acceptance failed: $error'),
              backgroundColor:
                  AmbulanceFirstColors
                      .medicalCrimson,
            ),
          );
        } finally {
          if (mounted) {
            setState(() {
              _responding = false;
            });
          }
        }
      },

      // ================================================================
      // REJECT QUOTATION
      // ================================================================
      onConfirmRejection: (reason) async {
        if (_responding) return;

        setState(() {
          _responding = true;
        });

        try {
          if (!SupabaseService.isConfigured) {
            throw StateError(
              'Supabase is not configured.',
            );
          }

          if (booking.quotation == null) {
            throw StateError(
              'Quotation is missing for this booking.',
            );
          }

          await _workflow.respondToQuotation(
            bookingId: booking.id,
            accept: false,
            reason: reason,
          );

          // Reload from Supabase.
          final customerBookings =
              await _bookingRepository
                  .getCustomerBookings();

          Booking? persisted;

          for (final item in customerBookings) {
            if (item.id == booking.id) {
              persisted = item;
              break;
            }
          }

          if (persisted == null) {
            throw StateError(
              'Rejected quotation was saved but the booking could not be reloaded.',
            );
          }

          // Update local state only after successful DB operation.
          SharedBookingStore.upsert(
            persisted,
          );

          CustomerPortalCache.quotations =
              await _bookingRepository
                  .getCustomerQuotations();

          if (!context.mounted) return;

          _refresh();

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content:
                  Text('Quotation declined and saved.'),
              backgroundColor:
                  AmbulanceFirstColors
                      .medicalCrimson,
            ),
          );
        } catch (error) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
                  Text('Rejection failed: $error'),
              backgroundColor:
                  AmbulanceFirstColors
                      .medicalCrimson,
            ),
          );
        } finally {
          if (mounted) {
            setState(() {
              _responding = false;
            });
          }
        }
      },
    );
  }
}
