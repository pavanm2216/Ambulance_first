import 'dart:async';

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
import '../widgets/ambulance_first_status_badge.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/quotation_acceptance_dialog.dart';

/// Customer Bookings Management Screen
class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({
    super.key,
    required this.user,
    required this.onBookNewAmbulance,
  });

  final AuthUser user;
  final VoidCallback onBookNewAmbulance;

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL';
  final SupabaseWorkflowRepository _workflow = SupabaseWorkflowRepository();
  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();
  Timer? _bookingRefreshTimer;
  bool _isRefreshingBookings = false;
  String? _confirmingDropoffBookingId;
  String? _confirmingOnboardBookingId;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshCustomerBookings());
    _bookingRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshCustomerBookings()),
    );
  }

  @override
  void dispose() {
    _bookingRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCustomerBookings() async {
    if (_isRefreshingBookings || !SupabaseService.isConfigured) return;
    _isRefreshingBookings = true;
    try {
      final bookings = await _bookingRepository.getCustomerBookings();
      for (final booking in bookings) {
        SharedBookingStore.upsert(booking);
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Keep the latest known customer bookings during transient failures.
    } finally {
      _isRefreshingBookings = false;
    }
  }

  List<Booking> get _allBookings => CustomerBookingWorkflowService.forCustomer(
    SharedBookingStore.bookings,
    widget.user.id,
  );

  List<Booking> get _filteredBookings {
    return _allBookings.where((b) {
      // 1. Status Filter
      if (_selectedFilter == 'ACTIVE') {
        final active =
            b.status == 'IN_TRANSIT' ||
            b.status == 'ARRIVED' ||
            b.status == 'PATIENT_PICKED_UP' ||
            b.status == 'PICKUP_STARTED' ||
            b.status == 'ASSIGNED' ||
            b.status == 'DRIVER_ASSIGNED';
        if (!active) {
          return false;
        }
      } else if (_selectedFilter == 'PENDING') {
        final pending =
            b.status == 'NEW' ||
            b.status == 'VERIFIED' ||
            b.status == 'SENT_TO_TEAM_LEAD' ||
            b.status == 'QUOTATION_SENT' ||
            b.status == 'CUSTOMER_ACCEPTED';
        if (!pending) {
          return false;
        }
      } else if (_selectedFilter == 'COMPLETED') {
        if (b.status != 'SERVICE_COMPLETED') {
          return false;
        }
      } else if (_selectedFilter == 'CANCELLED') {
        if (b.status != 'CANCELLED' && b.status != 'CUSTOMER_REJECTED') {
          return false;
        }
      }

      // 2. Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = b.id.toLowerCase().contains(q);
        final matchPatient = b.patientName.toLowerCase().contains(q);
        final matchPickup = b.pickup.toLowerCase().contains(q);
        final matchDest = b.destination.toLowerCase().contains(q);
        final matchAmbulance = b.ambulanceType.toLowerCase().contains(q);
        if (!matchId &&
            !matchPatient &&
            !matchPickup &&
            !matchDest &&
            !matchAmbulance) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final horizontalPadding = isDesktop
            ? AmbulanceFirstSpacing.margin
            : AmbulanceFirstSpacing.marginMobile;
        final compactHeader = constraints.maxWidth < 640;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  compactHeader
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'My Transport Bookings',
                              style: AmbulanceFirstTypography.headlineMd(
                                color: AmbulanceFirstColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track, review, and manage all your emergency & inter-facility requests',
                              style: AmbulanceFirstTypography.bodySm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: AmbulanceFirstButton(
                                label: 'BOOK AMBULANCE',
                                icon: Icons.add_circle_outline_rounded,
                                onPressed: widget.onBookNewAmbulance,
                                variant: AmbulanceFirstButtonVariant.primary,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Transport Bookings',
                                    style: AmbulanceFirstTypography.headlineMd(
                                      color: AmbulanceFirstColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Track, review, and manage all your emergency & inter-facility requests',
                                    style: AmbulanceFirstTypography.bodySm(
                                      color: AmbulanceFirstColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            AmbulanceFirstButton(
                              label: 'BOOK AMBULANCE',
                              icon: Icons.add_circle_outline_rounded,
                              onPressed: widget.onBookNewAmbulance,
                              variant: AmbulanceFirstButtonVariant.primary,
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),

                  // Search Bar & Filter Chips
                  _buildSearchAndFilters(),
                  const SizedBox(height: 16),

                  // Bookings List
                  if (bookings.isEmpty)
                    const AmbulanceFirstEmptyState(
                      icon: Icons.assignment_late_outlined,
                      heading: 'No Bookings Found',
                      description: 'No ambulance requests match your active search and filter criteria.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookings.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) =>
                          _buildBookingCard(context, bookings[i]),
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

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: AmbulanceFirstTypography.bodyMd(
            color: AmbulanceFirstColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search by patient name, booking ID, or hospital...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AmbulanceFirstColors.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => setState(() => _searchQuery = ''),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('ALL', 'All Bookings (${_allBookings.length})'),
              const SizedBox(width: 8),
              _filterChip('ACTIVE', 'Active Transports'),
              const SizedBox(width: 8),
              _filterChip('PENDING', 'Pending & Quotes'),
              const SizedBox(width: 8),
              _filterChip('COMPLETED', 'Completed'),
              const SizedBox(width: 8),
              _filterChip('CANCELLED', 'Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedFilter == key;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: AmbulanceFirstTypography.labelMd(
        color: isSelected
            ? AmbulanceFirstColors.onPrimary
            : AmbulanceFirstColors.onSurfaceVariant,
      ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
      backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
      selectedColor: AmbulanceFirstColors.clinicalCobalt,
      side: BorderSide(
        color: isSelected
            ? AmbulanceFirstColors.clinicalCobalt
            : AmbulanceFirstColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return AmbulanceFirstCard(
      urgencyPriority: booking.priority,
      onTap: () => BookingDetailsDialog.show(
        context,
        booking: booking,
        onReviewQuotation: booking.status == 'QUOTATION_SENT'
            ? () => _openQuotationDialog(context, booking)
            : null,
      ),
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: ID, Patient, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        AmbulanceFirstBookingId(id: booking.id, fontSize: 14),
                        const Text(
                          '·',
                          style: TextStyle(
                            color: AmbulanceFirstColors.onSurfaceVariant,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            booking.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmbulanceFirstTypography.headlineSm(
                              color: AmbulanceFirstColors.onSurface,
                            ).copyWith(fontSize: 14),
                          ),
                        ),
                        if (booking.priority == 'CRITICAL')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AmbulanceFirstColors.errorContainer,
                              borderRadius: BorderRadius.circular(
                                AmbulanceFirstSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              'CRITICAL',
                              style: AmbulanceFirstTypography.codeSm(
                                color: AmbulanceFirstColors.medicalCrimson,
                                weight: FontWeight.w700,
                              ).copyWith(fontSize: 9),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${booking.ambulanceType} • ${booking.date} at ${booking.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.bodySm(
                        color: AmbulanceFirstColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AmbulanceFirstStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 10),

          // Route Details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(
                AmbulanceFirstSpacing.radiusMd,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.navigation_outlined,
                      size: 14,
                      color: AmbulanceFirstColors.clinicalCobalt,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.pickup} → ${booking.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(
                          color: AmbulanceFirstColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    booking.distanceKm > 0
                        ? '${booking.distanceKm} km'
                        : 'Distance unavailable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmbulanceFirstTypography.codeSm(
                      color: AmbulanceFirstColors.onSurface,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (const {
                'PATIENT_PICKED_UP',
                'IN_TRANSIT',
                'ARRIVED',
              }.contains(booking.status) &&
              !booking.patientOnboardConfirmed) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmingOnboardBookingId == booking.id
                    ? null
                    : () => _confirmCustomerPatientOnboard(booking),
                icon: _confirmingOnboardBookingId == booking.id
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.airline_seat_recline_extra_rounded),
                label: Text(
                  _confirmingOnboardBookingId == booking.id
                      ? 'CONFIRMING ONBOARD...'
                      : 'CONFIRM PATIENT ONBOARD',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (booking.status == 'ARRIVED') ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmingDropoffBookingId == booking.id
                    ? null
                    : () => _confirmCustomerDropoff(booking),
                icon: _confirmingDropoffBookingId == booking.id
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: Text(
                  _confirmingDropoffBookingId == booking.id
                      ? 'CONFIRMING DROP-OFF...'
                      : 'CONFIRM PATIENT DROP-OFF',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Footer: Milestone or Crew + Total Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      booking.status == 'IN_TRANSIT'
                          ? Icons.directions_run_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: AmbulanceFirstColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.tripMilestone.isNotEmpty
                            ? booking.tripMilestone
                            : booking.customerStatusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(
                          color: AmbulanceFirstColors.onSurfaceVariant,
                        ).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _bookingPrice(booking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingPrice(Booking booking) {
    final quotation = booking.quotation;
    final hasQuotation = quotation != null && quotation.finalAmount > 0;
    final label = hasQuotation ? 'QUOTED TOTAL' : 'BASIC FARE';
    final amount = hasQuotation ? quotation.finalAmount : booking.basicFare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AmbulanceFirstTypography.codeSm(
            color: AmbulanceFirstColors.onSurfaceVariant,
          ).copyWith(fontSize: 9),
        ),
        Text(
          amount > 0 ? '₹ ${amount.toStringAsFixed(2)}' : 'Quote pending',
          style: AmbulanceFirstTypography.telemetryNum(
            color: AmbulanceFirstColors.onSurface,
            size: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _openQuotationDialog(
    BuildContext context,
    Booking booking,
  ) async {
    try {
      // Reload immediately before displaying the decision screen. This avoids
      // presenting a stale booking row when Team Lead has just sent a quote.
      final persisted = (await _bookingRepository.getCustomerBookings())
          .where((item) => item.id == booking.id)
          .firstOrNull;
      if (persisted == null || persisted.quotation == null) {
        throw StateError(
          'The sent quotation is not available to this customer yet.',
        );
      }

      SharedBookingStore.upsert(persisted);
      if (!context.mounted) return;

      QuotationAcceptanceDialog.show(
        context,
        booking: persisted,
        onConfirmAcceptance: () =>
            _respondToQuotation(persisted, response: 'ACCEPTED'),
        onConfirmRejection: (reason) => _respondToQuotation(
          persisted,
          response: 'REJECTED',
          reason: reason,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load quotation: $error'),
          backgroundColor: AmbulanceFirstColors.medicalCrimson,
        ),
      );
    }
  }

  Future<void> _confirmCustomerDropoff(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm patient drop-off'),
        content: Text(
          'Has the patient been safely dropped at ${booking.destination}? '
          'Confirming completes this booking and releases its assigned resources.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm drop-off'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirmingDropoffBookingId = booking.id);
    try {
      if (!SupabaseService.isConfigured) {
        throw StateError('An authenticated customer session is required.');
      }
      await _workflow.confirmCustomerDropoff(bookingId: booking.id);
      booking.status = 'SERVICE_COMPLETED';
      SharedBookingStore.upsert(booking);
      if (!mounted) return;
      setState(() {});
      unawaited(_refreshCustomerBookings());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Drop-off confirmed. The ambulance and assigned resources are available.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (error.toString().contains(
        'Customer must confirm patient onboard before drop-off',
      )) {
        await _refreshCustomerBookings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please confirm patient onboard before confirming drop-off. The trip has been refreshed.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to confirm drop-off: $error')),
      );
    } finally {
      if (mounted) setState(() => _confirmingDropoffBookingId = null);
    }
  }

  Future<void> _confirmCustomerPatientOnboard(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm patient onboard'),
        content: Text(
          booking.status == 'PATIENT_PICKED_UP'
              ? 'Has ${booking.patientName} safely boarded the ambulance at ${booking.pickup}? Confirming lets the driver start toward ${booking.destination}.'
              : 'Did ${booking.patientName} board the ambulance at ${booking.pickup}? Confirming this lets the trip continue to completion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm onboard'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirmingOnboardBookingId = booking.id);
    try {
      await _workflow.confirmCustomerPatientOnboard(bookingId: booking.id);
      booking.patientOnboardConfirmed = true;
      SharedBookingStore.upsert(booking);
      if (!mounted) return;
      setState(() {});
      unawaited(_refreshCustomerBookings());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Patient onboard confirmed. The driver can start to destination.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to confirm patient onboard: $error')),
      );
    } finally {
      if (mounted) setState(() => _confirmingOnboardBookingId = null);
    }
  }

  Future<void> _respondToQuotation(
    Booking booking, {
    required String response,
    String? reason,
  }) async {
    try {
      if (!SupabaseService.isConfigured || booking.quotation == null) {
        throw StateError(
          'An authenticated Supabase session and quotation are required.',
        );
      }

      await _workflow.respondToQuotation(
        bookingId: booking.id,
        accept: response == 'ACCEPTED',
        reason: reason,
      );

      final persisted = (await _bookingRepository.getCustomerBookings())
          .where((item) => item.id == booking.id)
          .firstOrNull;
      if (persisted == null) {
        throw StateError(
          'Quotation response was saved but the booking could not be reloaded.',
        );
      }

      SharedBookingStore.upsert(persisted);
      CustomerPortalCache.quotations = await _bookingRepository
          .getCustomerQuotations();
      if (!mounted) return;

      setState(() {});
      final accepted = response == 'ACCEPTED';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Quotation accepted and saved. Dispatch team notified.'
                : 'Quotation declined and saved.',
          ),
          backgroundColor: accepted
              ? AmbulanceFirstColors.secondary
              : AmbulanceFirstColors.medicalCrimson,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quotation response failed: $error'),
          backgroundColor: AmbulanceFirstColors.medicalCrimson,
        ),
      );
      rethrow;
    }
  }
}
