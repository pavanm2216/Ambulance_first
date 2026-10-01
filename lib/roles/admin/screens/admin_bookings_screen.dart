import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import '../widgets/stitch_status_badge.dart';
import 'admin_shared.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({
    super.key,
    required this.store,
    required this.onOpenBookingDetail,
  });

  final AdminStore store;
  final ValueChanged<AdminBooking> onOpenBookingDetail;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final allBookings = widget.store.bookings;
        final q = _searchController.text.trim().toLowerCase();

        final filtered = allBookings.where((b) {
          // Search filter
          if (q.isNotEmpty) {
            final text =
                '${b.id} ${b.patientName} ${b.customerName} ${b.pickupLocation} ${b.destinationLocation} ${b.serviceCategory} ${b.ambulanceId ?? ""} ${b.driverName ?? ""}'
                    .toLowerCase();
            if (!text.contains(q)) return false;
          }

          // Status filter
          if (_selectedStatusFilter == 'ACTIVE') {
            if (b.status != BookingStatus.inTransit &&
                b.status != BookingStatus.pickupStarted &&
                b.status != BookingStatus.patientPickedUp) {
              return false;
            }
          } else if (_selectedStatusFilter == 'NEW' &&
              b.status != BookingStatus.newBooking) {
            return false;
          } else if (_selectedStatusFilter == 'ASSIGNED' &&
              b.status != BookingStatus.assigned) {
            return false;
          } else if (_selectedStatusFilter == 'QUOTATION' &&
              b.status != BookingStatus.quotationSent) {
            return false;
          } else if (_selectedStatusFilter == 'COMPLETED' &&
              b.status != BookingStatus.serviceCompleted) {
            return false;
          } else if (_selectedStatusFilter == 'CANCELLED' &&
              b.status != BookingStatus.cancelled) {
            return false;
          }

          // Category filter
          if (_selectedCategoryFilter != 'ALL' &&
              b.serviceCategory != _selectedCategoryFilter) {
            return false;
          }

          return true;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Operational Sub-Header & Live Actions
              Container(
                padding: const EdgeInsets.all(StitchTheme.margin),
                color: StitchTheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_rounded,
                              size: 20,
                              color: StitchTheme.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'All Bookings',
                              style: StitchTheme.headlineMd(
                                color: StitchTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: StitchTheme.tertiaryFixed,
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            'LIVE TELEMETRY',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.onTertiaryFixed,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search, monitor, and dispatch all active ambulance and medevac transport streams.',
                      style: StitchTheme.bodySm(
                        color: StitchTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.file_download_outlined,
                            label: 'Export',
                            onTap: () => showStitchToast(
                              context,
                              'Exporting dispatch log to CSV...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.sync_rounded,
                            label: 'Sync Now',
                            onTap: () async {
                              await widget.store.refresh();
                              if (!context.mounted) return;
                              showStitchToast(
                                context,
                                widget.store.errorMessage == null
                                    ? 'Booking data refreshed from Supabase.'
                                    : 'Booking refresh failed.',
                                isError: widget.store.errorMessage != null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showStitchToast(
                              context,
                              'Admin booking creation is not connected to the controlled booking RPC yet.',
                              isError: true,
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Create'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StitchTheme.primaryContainer,
                              foregroundColor: StitchTheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  StitchTheme.radiusSm,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Filter & Search Console
              Padding(
                padding: const EdgeInsets.all(StitchTheme.margin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Search ID, Patient, Customer, Destination...',
                        hintStyle: StitchTheme.bodySm(
                          color: StitchTheme.outline,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: StitchTheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: StitchTheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: StitchTheme.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: StitchTheme.borderSubtle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Pills Stream
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TRIAGE & MISSION STATE',
                          style: StitchTheme.labelSm(
                            color: StitchTheme.outline,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Showing ${filtered.length} of ${allBookings.length}',
                          style: StitchTheme.labelSm(
                            color: StitchTheme.primaryContainer,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterPill(
                            label: 'All',
                            count: '${allBookings.length}',
                            isSelected: _selectedStatusFilter == 'ALL',
                            onTap: () =>
                                setState(() => _selectedStatusFilter = 'ALL'),
                          ),
                          const SizedBox(width: 6),
                          _FilterPill(
                            label: 'Active',
                            count: '${widget.store.activeTripsCount}',
                            isSelected: _selectedStatusFilter == 'ACTIVE',
                            hasPulse: true,
                            onTap: () => setState(
                              () => _selectedStatusFilter = 'ACTIVE',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _FilterPill(
                            label: 'NEW',
                            count:
                                '${allBookings.where((b) => b.status == BookingStatus.newBooking).length}',
                            isSelected: _selectedStatusFilter == 'NEW',
                            onTap: () =>
                                setState(() => _selectedStatusFilter = 'NEW'),
                          ),
                          const SizedBox(width: 6),
                          _FilterPill(
                            label: 'ASSIGNED',
                            count:
                                '${allBookings.where((b) => b.status == BookingStatus.assigned).length}',
                            isSelected: _selectedStatusFilter == 'ASSIGNED',
                            onTap: () => setState(
                              () => _selectedStatusFilter = 'ASSIGNED',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _FilterPill(
                            label: 'QUOTATION',
                            count:
                                '${allBookings.where((b) => b.status == BookingStatus.quotationSent).length}',
                            isSelected: _selectedStatusFilter == 'QUOTATION',
                            onTap: () => setState(
                              () => _selectedStatusFilter = 'QUOTATION',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _FilterPill(
                            label: 'COMPLETED',
                            count:
                                '${allBookings.where((b) => b.status == BookingStatus.serviceCompleted).length}',
                            isSelected: _selectedStatusFilter == 'COMPLETED',
                            onTap: () => setState(
                              () => _selectedStatusFilter = 'COMPLETED',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Service Category Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Class: ',
                            style: StitchTheme.labelSm(
                              color: StitchTheme.outline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _CategoryPill(
                            label: 'ROAD',
                            isSelected: _selectedCategoryFilter == 'ROAD',
                            onTap: () => setState(
                              () => _selectedCategoryFilter =
                                  _selectedCategoryFilter == 'ROAD'
                                  ? 'ALL'
                                  : 'ROAD',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _CategoryPill(
                            label: 'AIR MEDEVAC',
                            isSelected: _selectedCategoryFilter == 'AIR',
                            onTap: () => setState(
                              () => _selectedCategoryFilter =
                                  _selectedCategoryFilter == 'AIR'
                                  ? 'ALL'
                                  : 'AIR',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _CategoryPill(
                            label: 'RAIL',
                            isSelected: _selectedCategoryFilter == 'RAILWAY',
                            onTap: () => setState(
                              () => _selectedCategoryFilter =
                                  _selectedCategoryFilter == 'RAILWAY'
                                  ? 'ALL'
                                  : 'RAILWAY',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _CategoryPill(
                            label: 'DEAD BODY',
                            isSelected: _selectedCategoryFilter == 'DEAD_BODY',
                            onTap: () => setState(
                              () => _selectedCategoryFilter =
                                  _selectedCategoryFilter == 'DEAD_BODY'
                                  ? 'ALL'
                                  : 'DEAD_BODY',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Booking Stream List
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_late_outlined,
                        size: 48,
                        color: StitchTheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No bookings match your filters',
                        style: StitchTheme.headlineSm(
                          color: StitchTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try resetting the search keywords or status filter.',
                        style: StitchTheme.bodySm(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _selectedStatusFilter = 'ALL';
                            _selectedCategoryFilter = 'ALL';
                          });
                        },
                        child: const Text('Reset All Filters'),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StitchTheme.margin,
                  ),
                  child: Column(
                    children: [
                      for (final booking in filtered) ...[
                        _BookingCard(
                          booking: booking,
                          onTap360: () => widget.onOpenBookingDetail(booking),
                        ),
                        const SizedBox(height: StitchTheme.spaceMd),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: StitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
          border: Border.all(color: StitchTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: StitchTheme.secondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: StitchTheme.labelSm(
                color: StitchTheme.onSurface,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.hasPulse = false,
  });

  final String label;
  final String count;
  final bool isSelected;
  final bool hasPulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? StitchTheme.primaryContainer
              : StitchTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPulse) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: StitchTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: StitchTheme.labelSm(
                color: isSelected ? Colors.white : StitchTheme.onSurfaceVariant,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : StitchTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                count,
                style: StitchTheme.labelSm(
                  color: isSelected ? Colors.white : StitchTheme.onSurface,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? StitchTheme.surfaceContainer
              : StitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        ),
        child: Text(
          label,
          style: StitchTheme.labelSm(
            color: isSelected
                ? StitchTheme.primaryContainer
                : StitchTheme.onSurfaceVariant,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap360});
  final AdminBooking booking;
  final VoidCallback onTap360;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urgency Stripe
              Container(
                width: 5,
                color: booking.urgencyLevel == 'CRITICAL'
                    ? StitchTheme.error
                    : booking.urgencyLevel == 'HIGH'
                    ? StitchTheme.warning
                    : StitchTheme.primaryContainer,
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(StitchTheme.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '#${booking.id}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: StitchTheme.labelLg(
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '· ${DateTime.now().difference(booking.createdAt).inMinutes}m ago',
                                      maxLines: 1,
                                      style: StitchTheme.labelSm(
                                        color: StitchTheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  booking.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: StitchTheme.labelSm(
                                    color: StitchTheme.primaryContainer,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: StitchStatusBadge.fromBooking(
                                booking.status,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Patient Strip
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: StitchTheme.primaryContainer,
                            child: Text(
                              booking.patientInitials,
                              style: StitchTheme.labelSm(
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.patientName} (${booking.patientAge}y ${booking.patientGender[0]})',
                                  style: StitchTheme.bodySm(
                                    color: StitchTheme.onSurface,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  booking.patientCondition,
                                  style: StitchTheme.bodySm(
                                    color: StitchTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(booking.quotationTotal),
                            style: StitchTheme.labelMd(weight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Route
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: StitchTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 13,
                              color: StitchTheme.primaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${booking.pickupLocation} → ${booking.destinationLocation}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: StitchTheme.labelSm(
                                  color: StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Footer Actions: 360 View & Quick status
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (booking.ambulanceId != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: StitchTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 120,
                                    ),
                                    child: Text(
                                      booking.ambulanceId!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: StitchTheme.labelSm(
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: booking.paymentStatus == 'PAID'
                                      ? StitchTheme.tertiaryFixed.withValues(
                                          alpha: 0.6,
                                        )
                                      : StitchTheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  booking.paymentStatus,
                                  style: StitchTheme.labelSm(
                                    color: booking.paymentStatus == 'PAID'
                                        ? StitchTheme.tertiary
                                        : StitchTheme.onSecondaryContainer,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: onTap360,
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 14,
                            ),
                            label: const Text('360° View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StitchTheme.primaryContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  StitchTheme.radiusSm,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
