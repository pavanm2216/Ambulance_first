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
import '../widgets/ambulance_first_button.dart';
import '../widgets/ambulance_first_card.dart';
import '../widgets/ambulance_first_metric_card.dart';
import '../widgets/ambulance_first_section_header.dart';
import '../widgets/ambulance_first_status_badge.dart';
import '../widgets/ambulance_first_telemetry.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/quotation_acceptance_dialog.dart';

/// Customer Dashboard Screen
/// Faithful Flutter implementation of Stitch screen 43005bdd0c6d425dad1d065abddfcca2
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({
    super.key,
    required this.user,
    required this.onBookNewAmbulance,
    required this.onNavigateToSection,
  });

  final AuthUser user;
  final VoidCallback onBookNewAmbulance;
  final ValueChanged<int> onNavigateToSection;

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final SupabaseWorkflowRepository _workflow = SupabaseWorkflowRepository();
  final SupabaseBookingRepository _bookingRepository = SupabaseBookingRepository();

  List<Booking> get _customerBookings =>
      CustomerBookingWorkflowService.forCustomer(SharedBookingStore.bookings, widget.user.id);

  Booking? get _activeMission {
    final active = _customerBookings.where((b) => b.isActive);
    return active.isNotEmpty ? active.first : null;
  }

  Booking? get _pendingQuotationBooking {
    final pending = _customerBookings.where((b) => b.hasPendingQuotation);
    return pending.isNotEmpty ? pending.first : null;
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _customerBookings;
    final activeCount = bookings.where((b) => b.isActive).length;
    final pendingQuoteCount = bookings.where((b) => b.hasPendingQuotation).length;
    final completedCount = bookings.where((b) => b.isCompleted).length;

    final activeTrip = _activeMission;
    final pendingQuote = _pendingQuotationBooking;
    final recentBookings = bookings.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final horizontalPadding = isDesktop
            ? AmbulanceFirstSpacing.margin
            : AmbulanceFirstSpacing.marginMobile;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Clinical Welcome Banner
                  _buildWelcomeBanner(context, bookings.length, pendingQuoteCount),
                  const SizedBox(height: 16),

                  // 2. KPI Queue Summary Cards (2x2 Grid on mobile, 4 columns on desktop)
                  _buildKpiGrid(
                    isDesktop: isDesktop,
                    totalBookings: bookings.length,
                    activeTrips: activeCount,
                    pendingActions: pendingQuoteCount,
                    completed: completedCount,
                  ),
                  const SizedBox(height: 16),

                  // 3. Urgent Action: Pending Quotation Card (if exists)
                  if (pendingQuote != null) ...[
                    _buildPendingQuotationCard(context, pendingQuote),
                    const SizedBox(height: 16),
                  ],

                  // 4. Active Transport Mission Card (High Priority Clinical Execution)
                  if (activeTrip != null) ...[
                    _buildActiveTransportCard(context, activeTrip),
                    const SizedBox(height: 16),
                  ],

                  // 5. Recent Requests Preview
                  AmbulanceFirstSectionHeader(
                    title: 'Recent Requests',
                    count: bookings.length,
                    actionLabel: 'View All',
                    onActionTap: () => widget.onNavigateToSection(1), // Bookings tab
                  ),
                  const SizedBox(height: 8),

                  if (recentBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AmbulanceFirstColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg),
                        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
                      ),
                      child: Center(
                        child: Text(
                          'No recent ambulance requests found.',
                          style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...recentBookings.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecentBookingItem(context, b),
                        )),

                  const SizedBox(height: 8),

                  // 6. Patient Transport Dispatch Hub Helper
                  _buildDispatchDeskHelper(context),
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
  // 1. Clinical Welcome Banner
  // ---------------------------------------------------------------------------
  Widget _buildWelcomeBanner(BuildContext context, int totalTransfers, int pendingQuotes) {
    return AmbulanceFirstCard(
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: AmbulanceFirstColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'VERIFIED CLINICAL COORDINATOR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmbulanceFirstTypography.codeSm(
                              color: AmbulanceFirstColors.onSurfaceVariant,
                              weight: FontWeight.w700,
                            ).copyWith(letterSpacing: 0.5, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.headlineMd(color: AmbulanceFirstColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.email.isNotEmpty ? widget.user.email : 'Customer profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AmbulanceFirstColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 24,
                  color: AmbulanceFirstColors.clinicalCobalt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Operational status indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AmbulanceFirstColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                      children: [
                        TextSpan(text: '$totalTransfers hospital transfers under care · '),
                        TextSpan(
                          text: pendingQuotes > 0
                              ? '$pendingQuotes quotation requires authorization'
                              : 'All active transfers nominal',
                          style: TextStyle(
                            color: pendingQuotes > 0 ? AmbulanceFirstColors.medicalCrimson : AmbulanceFirstColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CTA: Book New Ambulance
          AmbulanceFirstButton(
            label: 'BOOK NEW AMBULANCE',
            icon: Icons.add_circle_outline_rounded,
            fullWidth: true,
            onPressed: widget.onBookNewAmbulance,
            variant: AmbulanceFirstButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KPI Summary Grid
  // ---------------------------------------------------------------------------
  Widget _buildKpiGrid({
    required bool isDesktop,
    required int totalBookings,
    required int activeTrips,
    required int pendingActions,
    required int completed,
  }) {
    final cards = [
      AmbulanceFirstMetricCard(
        title: 'Total Bookings',
        value: totalBookings < 10 ? '0$totalBookings' : '$totalBookings',
        subtitle: 'All-time requests',
        icon: Icons.assignment_outlined,
        onTap: () => widget.onNavigateToSection(1),
      ),
      AmbulanceFirstMetricCard(
        title: 'Active Trips',
        value: activeTrips < 10 ? '0$activeTrips' : '$activeTrips',
        subtitle: 'En route to PICU',
        icon: Icons.airport_shuttle_rounded,
        valueColor: AmbulanceFirstColors.clinicalCobalt,
        subtitleColor: AmbulanceFirstColors.secondary,
        iconColor: AmbulanceFirstColors.onSecondaryContainer,
        iconBgColor: AmbulanceFirstColors.secondaryContainer,
        hasPulse: true,
        onTap: () => widget.onNavigateToSection(2),
      ),
      AmbulanceFirstMetricCard(
        title: 'Pending Action',
        value: pendingActions < 10 ? '0$pendingActions' : '$pendingActions',
        subtitle: 'Quote pending sign-off',
        icon: Icons.pending_actions_rounded,
        valueColor: AmbulanceFirstColors.medicalCrimson,
        subtitleColor: AmbulanceFirstColors.medicalCrimson,
        iconColor: AmbulanceFirstColors.medicalCrimson,
        iconBgColor: AmbulanceFirstColors.errorContainer,
        onTap: () => widget.onNavigateToSection(3),
      ),
      AmbulanceFirstMetricCard(
        title: 'Completed',
        value: completed < 10 ? '0$completed' : '$completed',
        subtitle: 'Discharge & transfers',
        icon: Icons.check_circle_outline_rounded,
        valueColor: AmbulanceFirstColors.secondary,
        subtitleColor: AmbulanceFirstColors.onSurfaceVariant,
        iconColor: AmbulanceFirstColors.secondary,
        iconBgColor: AmbulanceFirstColors.surfaceContainer,
        onTap: () => widget.onNavigateToSection(4),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: cards,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Urgent Action: Pending Quotation Card
  // ---------------------------------------------------------------------------
  Widget _buildPendingQuotationCard(BuildContext context, Booking booking) {
    final q = booking.quotation!;

    return AmbulanceFirstCard(
      topIndicatorColor: AmbulanceFirstColors.medicalCrimson,
      backgroundColor: AmbulanceFirstColors.surfaceContainerLow,
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QUOTATION · ${q.id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmbulanceFirstTypography.codeLg(
              color: AmbulanceFirstColors.onSurface,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AmbulanceFirstColors.errorContainer,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusPill),
              ),
              child: Text(
                q.validUntil.isNotEmpty ? q.validUntil : 'Validity unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.codeSm(
                  color: AmbulanceFirstColors.onErrorContainer,
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Booking and Patient Context Canvas
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.patientName} (${booking.patientAge}y / ${booking.patientGender == "Female" ? "F" : "M"})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface).copyWith(fontSize: 14),
                ),
                Text(
                  'REF #${booking.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monitor_heart_outlined, size: 14, color: AmbulanceFirstColors.medicalCrimson),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.currentCondition.isNotEmpty
                            ? booking.currentCondition
                            : 'Clinical condition unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.medicalCrimson).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.navigation_outlined, size: 14, color: AmbulanceFirstColors.clinicalCobalt),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${booking.pickup} → ${booking.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.distanceKm > 0 ? '(${booking.distanceKm} km)' : 'Distance unavailable',
                      style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurface, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Service Tier & Pricing Row
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, size: 16, color: AmbulanceFirstColors.clinicalCobalt),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.ambulanceType,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FINAL AGREED',
                    style: AmbulanceFirstTypography.labelSm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 9),
                  ),
                  Text(
                    '₹ ${q.finalAmount.toStringAsFixed(2)}',
                    style: AmbulanceFirstTypography.telemetryNum(color: AmbulanceFirstColors.onSurface, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Review & Authorize vs Decline
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AmbulanceFirstButton(
                  label: 'REVIEW & AUTHORIZE',
                  icon: Icons.verified_rounded,
                  onPressed: () => _openQuotationDialog(context, booking),
                  variant: AmbulanceFirstButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AmbulanceFirstButton(
                  label: 'DECLINE',
                  onPressed: () => _openQuotationDialog(context, booking),
                  variant: AmbulanceFirstButtonVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Active Transport Mission Card (High Priority Clinical Execution)
  // ---------------------------------------------------------------------------
  Widget _buildActiveTransportCard(BuildContext context, Booking booking) {
    return AmbulanceFirstCard(
      topIndicatorColor: AmbulanceFirstColors.clinicalCobalt,
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Live dot, Trip ID, Status Pill
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AmbulanceFirstColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TRIP #${booking.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmbulanceFirstTypography.codeLg(
                          color: AmbulanceFirstColors.clinicalCobalt,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: -0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AmbulanceFirstStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),

          // Live Telemetry Capsule
            AmbulanceFirstTelemetryCapsule(
              state: booking.driverLocationSharing
                  ? TelemetryState.live
                  : TelemetryState.unavailable,
              updatedAgo: booking.driverLocationUpdatedAt?.toIso8601String(),
            ),
          const SizedBox(height: 10),

          // Patient Demographics & Tag
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            runSpacing: 8,
            spacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.patientName} (${booking.patientAge > 0 ? "${booking.patientAge}y" : "4m"} / ${booking.patientGender == "Female" ? "F" : "M"})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.relationshipToPatient.isNotEmpty
                          ? booking.relationshipToPatient
                          : 'Accompanied Family Guardian',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AmbulanceFirstColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
                ),
                child: Text(
                  booking.pediatricPatient ? 'PICU / PEDIATRIC' : 'ADVANCED ICU',
                  style: AmbulanceFirstTypography.codeSm(
                    color: AmbulanceFirstColors.onTertiaryFixed,
                    weight: FontWeight.w700,
                  ).copyWith(fontSize: 10, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dynamic Mission Dashboard Tile (ETA, Speed, Unit)
          AmbulanceFirstMissionTile(
            etaMinutes: booking.etaMinutes,
            speedKmh: booking.driverSpeedKmh > 0 ? booking.driverSpeedKmh : null,
            isLive: false,
                    unitName: booking.vehicleNumber,
          ),
          const SizedBox(height: 10),

          // Route Indicator Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AmbulanceFirstColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 14, color: AmbulanceFirstColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.pickup,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  alignment: Alignment.centerLeft,
                  height: 12,
                  child: Container(width: 2, height: 12, color: AmbulanceFirstColors.borderSubtle),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AmbulanceFirstColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.destination,
                        style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Crew & Vehicle details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crew: ${booking.emtName.isNotEmpty ? booking.emtName : "Unavailable"} & ${booking.doctorName.isNotEmpty ? booking.doctorName : "Unavailable"}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
              ),
              Text(
                booking.vehicleNumber.isNotEmpty ? booking.vehicleNumber : 'Vehicle unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CTAs: Track Live Mission vs View Dossier
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AmbulanceFirstButton(
                  label: 'TRACK LIVE MISSION',
                  icon: Icons.my_location_rounded,
                  onPressed: () => widget.onNavigateToSection(2), // Active Trips Tab
                  variant: AmbulanceFirstButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AmbulanceFirstButton(
                  label: 'VIEW DOSSIER',
                  onPressed: () => BookingDetailsDialog.show(context, booking: booking),
                  variant: AmbulanceFirstButtonVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Recent Booking Item
  // ---------------------------------------------------------------------------
  Widget _buildRecentBookingItem(BuildContext context, Booking booking) {
    return AmbulanceFirstCard(
      urgencyPriority: booking.priority,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => BookingDetailsDialog.show(context, booking: booking),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.id.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmbulanceFirstTypography.codeMd(color: AmbulanceFirstColors.onSurface, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Text(
            booking.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            booking.currentCondition,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.date}, ${booking.time} · ${booking.ambulanceType}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AmbulanceFirstStatusBadge(status: booking.status, compact: true),
              Text(
                '₹ ${booking.amount.toInt()}',
                style: AmbulanceFirstTypography.codeSm(color: AmbulanceFirstColors.onSurface, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Patient Transport Dispatch Hub Helper
  // ---------------------------------------------------------------------------
  Widget _buildDispatchDeskHelper(BuildContext context) {
    final supportIcon = Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.support_agent_rounded,
        size: 20,
        color: AmbulanceFirstColors.clinicalCobalt,
      ),
    );
    final supportDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Dispatch Desk',
          style: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface).copyWith(fontSize: 13),
        ),
        Text(
          'Direct priority line for ICU-to-ICU handoffs',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AmbulanceFirstTypography.bodySm(color: AmbulanceFirstColors.onSurfaceVariant).copyWith(fontSize: 11),
        ),
      ],
    );
    final supportButton = AmbulanceFirstButton(
      label: 'Support unavailable',
      icon: Icons.call,
      height: 34,
      variant: AmbulanceFirstButtonVariant.telemetry,
      onPressed: null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        return Container(
          padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
          decoration: BoxDecoration(
            color: AmbulanceFirstColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusLg),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        supportIcon,
                        const SizedBox(width: 12),
                        Expanded(child: supportDetails),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: supportButton),
                  ],
                )
              : Row(
                  children: [
                    supportIcon,
                    const SizedBox(width: 12),
                    Expanded(child: supportDetails),
                    const SizedBox(width: 8),
                    supportButton,
                  ],
                ),
        );
      },
    );
  }

  void _openQuotationDialog(BuildContext context, Booking booking) {
    QuotationAcceptanceDialog.show(
      context,
      booking: booking,
      onConfirmAcceptance: () async {
        try {
          if (!SupabaseService.isConfigured || booking.quotation == null) {
            throw StateError('An authenticated Supabase session and quotation are required.');
          }
          await _workflow.respondToQuotation(
            bookingId: booking.id,
            accept: true,
          );
          final persisted = (await _bookingRepository.getCustomerBookings())
              .where((item) => item.id == booking.id)
              .firstOrNull;
          if (persisted == null) throw StateError('Accepted quotation could not be reloaded.');
          SharedBookingStore.upsert(persisted);
          CustomerPortalCache.quotations = await _bookingRepository.getCustomerQuotations();
          if (!context.mounted) return;
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quotation ${booking.quotation?.id ?? booking.id} accepted and saved. Dispatch team notified.'), backgroundColor: AmbulanceFirstColors.secondary),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Acceptance failed: $error'), backgroundColor: AmbulanceFirstColors.medicalCrimson),
          );
        }
      },
      onConfirmRejection: (reason) async {
        try {
          if (!SupabaseService.isConfigured || booking.quotation == null) {
            throw StateError('An authenticated Supabase session and quotation are required.');
          }
          await _workflow.respondToQuotation(
            bookingId: booking.id,
            accept: false,
            reason: reason,
          );
          final persisted = (await _bookingRepository.getCustomerBookings())
              .where((item) => item.id == booking.id)
              .firstOrNull;
          if (persisted == null) throw StateError('Rejected quotation could not be reloaded.');
          SharedBookingStore.upsert(persisted);
          CustomerPortalCache.quotations = await _bookingRepository.getCustomerQuotations();
          if (!context.mounted) return;
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation declined and saved.'), backgroundColor: AmbulanceFirstColors.medicalCrimson),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rejection failed: $error'), backgroundColor: AmbulanceFirstColors.medicalCrimson),
          );
        }
      },
    );
  }

}
