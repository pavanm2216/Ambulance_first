import 'dart:async';

import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import '../widgets/stitch_status_badge.dart';
import 'admin_shared.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  const AdminBookingDetailScreen({
    super.key,
    required this.booking,
    required this.store,
    required this.onBack,
  });

  final AdminBooking booking;
  final AdminStore store;
  final VoidCallback onBack;

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  Timer? _telemetryRefreshTimer;
  bool _isRefreshingTelemetry = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshTelemetry());
    _telemetryRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshTelemetry()),
    );
  }

  @override
  void dispose() {
    _telemetryRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshTelemetry() async {
    if (_isRefreshingTelemetry) return;
    _isRefreshingTelemetry = true;
    try {
      await widget.store.refreshBooking(widget.booking.id);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Admin booking telemetry refresh failed: $error');
    } finally {
      _isRefreshingTelemetry = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.store.bookingById(widget.booking.id) ?? widget.booking;

    return Scaffold(
      backgroundColor: StitchTheme.background,
      appBar: AppBar(
        backgroundColor: StitchTheme.surface.withValues(alpha: 0.95),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: StitchTheme.onSurface,
          ),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Incident Detail',
              style: StitchTheme.headlineSm(color: StitchTheme.onSurface),
            ),
            Text(
              'INCIDENT TERMINAL',
              style: StitchTheme.labelSm(color: StitchTheme.outline),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(StitchTheme.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mission Notification Alert Banner
            if (b.urgencyLevel == 'CRITICAL' ||
                b.status == BookingStatus.inTransit) ...[
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.errorContainer,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      size: 22,
                      color: StitchTheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${b.priority} · ACTIVE MISSION',
                                style: StitchTheme.labelSm(
                                  color: StitchTheme.onErrorContainer,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'ETA: ${b.etaMinutes} MIN',
                                style: StitchTheme.labelSm(
                                  color: StitchTheme.onErrorContainer,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.triageNotes,
                            style: StitchTheme.bodySm(
                              color: StitchTheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),
            ],

            // 2. Meta Context & Status
            Row(
              children: [
                Text(
                  'Bookings',
                  style: StitchTheme.bodySm(color: StitchTheme.outline),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: StitchTheme.outline,
                ),
                Text(
                  '#${b.id}',
                  style: StitchTheme.bodySm(
                    color: StitchTheme.primaryContainer,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Booking 360° Detail', style: StitchTheme.headlineLg()),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: StitchTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                  child: Text(
                    'REV 3.2',
                    style: StitchTheme.labelSm(color: StitchTheme.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StitchStatusBadge.fromBooking(b.status),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StitchTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.medical_services_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.serviceSubtype,
                        style: StitchTheme.labelSm(
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StitchTheme.spaceMd),

            // 3. Quick Action Buttons (Run Sheet, SOS/Escalate, Audit Log)
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.print_rounded,
                    label: 'Run Sheet',
                    iconColor: StitchTheme.primaryContainer,
                    onTap: () => _showRunSheetDialog(context, b),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.warning_rounded,
                    label: 'SOS / Escalate',
                    isDanger: true,
                    onTap: () {
                      showStitchToast(
                        context,
                        'Code Red Incident Escalated to Regional Dispatch Commander.',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.history_rounded,
                    label: 'Audit Log',
                    iconColor: StitchTheme.secondary,
                    onTap: () => _showAuditLogSheet(context, b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: StitchTheme.spaceLg),

            // 4. Live Telemetry & GPS Card
            _buildTelemetryCard(b),
            const SizedBox(height: StitchTheme.spaceLg),

            // 5. Interactive 9-Stage Mission Timeline
            _buildTimelineSection(b),
            const SizedBox(height: StitchTheme.spaceLg),

            // 6. Patient Clinical Profile & Customer
            _buildPatientCustomerSection(b),
            const SizedBox(height: StitchTheme.spaceLg),

            // 7. Resource Assignment Matrix
            _buildResourceAssignmentSection(context, b),
            const SizedBox(height: StitchTheme.spaceLg),

            // 8. Financial Breakdown & Quotation
            _buildQuotationSection(b),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(AdminBooking b) {
    final hasDriverGps = b.driverLatitude != null && b.driverLongitude != null;
    final gpsAge = b.driverLocationUpdatedAt == null
        ? null
        : DateTime.now().difference(b.driverLocationUpdatedAt!);
    final gpsIsLive = gpsAge != null && gpsAge <= const Duration(seconds: 60);
    return Container(
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
              Row(
                children: [
                  const Icon(
                    Icons.satellite_alt_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text('Live Telemetry & GPS', style: StitchTheme.headlineSm()),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: StitchTheme.tertiaryFixed,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                ),
                child: Text(
                  gpsAge == null
                      ? 'GPS WAITING'
                      : gpsIsLive
                      ? 'LIVE · ${gpsAge.inSeconds}s AGO'
                      : 'STALE · ${gpsAge.inMinutes}m AGO',
                  style: StitchTheme.labelSm(
                    color: gpsAge == null
                        ? StitchTheme.onSurfaceVariant
                        : gpsIsLive
                        ? StitchTheme.onTertiaryFixed
                        : StitchTheme.error,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: hasDriverGps && gpsIsLive
                  ? StitchTheme.tertiaryFixed.withValues(alpha: 0.18)
                  : StitchTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
            ),
            child: Text(
              hasDriverGps
                  ? 'DRIVER GPS${gpsIsLive ? '' : ' · STALE'}: ${b.driverLatitude!.toStringAsFixed(5)}, ${b.driverLongitude!.toStringAsFixed(5)}'
                  : 'DRIVER GPS: waiting for the Driver app to publish location',
              style: StitchTheme.labelSm(
                color: hasDriverGps
                    ? StitchTheme.onSurface
                    : StitchTheme.onSurfaceVariant,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Simulated High-Contrast Map Card
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: StitchTheme.commandNavDark,
              borderRadius: BorderRadius.circular(StitchTheme.radiusMd),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 36,
                        color: StitchTheme.primaryFixedDim,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${b.pickupLocation}\n→ ${b.destinationLocation}',
                        textAlign: TextAlign.center,
                        style: StitchTheme.bodySm(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              size: 14,
                              color: StitchTheme.tertiaryFixed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SPEED: ${b.currentSpeedKmH} KM/H  ·  ${b.heading}',
                              style: StitchTheme.labelSm(
                                color: Colors.white,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${b.distanceRemainingKm.toStringAsFixed(1)} km Rem.',
                          style: StitchTheme.labelSm(
                            color: StitchTheme.tertiaryFixed,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(AdminBooking b) {
    return Container(
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
              Row(
                children: [
                  const Icon(
                    Icons.timeline_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text('Mission Timeline', style: StitchTheme.headlineSm()),
                ],
              ),
              Text(
                '${b.timeline.where((t) => t.completed).length} OF ${b.timeline.length} STAGES',
                style: StitchTheme.labelSm(
                  color: StitchTheme.outline,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timeline Steps
          for (int i = 0; i < b.timeline.length; i++) ...[
            _TimelineStepTile(
              step: b.timeline[i],
              isLast: i == b.timeline.length - 1,
              onComplete: () {
                setState(() {
                  widget.store.advanceBookingStage(b.id, b.timeline[i].stage);
                });
                showStitchToast(
                  context,
                  'Advanced mission stage to "${b.timeline[i].stage}".',
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCustomerSection(AdminBooking b) {
    return Container(
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
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: StitchTheme.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Patient & Clinical Acuity',
                style: StitchTheme.headlineSm(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: StitchTheme.primaryContainer,
                child: Text(
                  b.patientInitials,
                  style: StitchTheme.labelMd(
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${b.patientName} (${b.patientAge} yrs, ${b.patientGender})',
                    style: StitchTheme.headlineSm(),
                  ),
                  Text(
                    'Condition: ${b.patientCondition}',
                    style: StitchTheme.bodySm(
                      color: StitchTheme.error,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Special Clinical Requirements
          if (b.specialRequirements.isNotEmpty) ...[
            Text(
              'SPECIAL CLINICAL PROTOCOLS',
              style: StitchTheme.labelSm(
                color: StitchTheme.outline,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final req in b.specialRequirements)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: StitchTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                      border: Border.all(color: StitchTheme.borderSubtle),
                    ),
                    child: Text(
                      req,
                      style: StitchTheme.labelSm(
                        color: StitchTheme.onSurfaceVariant,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 16, color: StitchTheme.borderSubtle),

          // Customer Liaison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALLER / REQUESTING ENTITY',
                    style: StitchTheme.labelSm(
                      color: StitchTheme.outline,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.customerName,
                    style: StitchTheme.bodyMd(weight: FontWeight.w600),
                  ),
                  Text(
                    b.customerContact,
                    style: StitchTheme.bodySm(color: StitchTheme.outline),
                  ),
                ],
              ),
              IconButton.outlined(
                icon: const Icon(
                  Icons.phone_rounded,
                  size: 16,
                  color: StitchTheme.primaryContainer,
                ),
                onPressed: () => showStitchToast(
                  context,
                  'Connecting secure patch to ${b.customerContact}...',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceAssignmentSection(BuildContext context, AdminBooking b) {
    return Container(
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
              Row(
                children: [
                  const Icon(
                    Icons.badge_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resource Allocation Matrix',
                    style: StitchTheme.headlineSm(),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showReallocateDialog(context, b),
                child: Text(
                  'Reassign',
                  style: StitchTheme.labelSm(
                    color: StitchTheme.primaryContainer,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ResourceRow(
            icon: Icons.local_shipping_rounded,
            role: 'Vehicle',
            name: b.ambulanceId ?? 'Unassigned',
            detail: b.ambulanceModel ?? 'Assign unit from ready pool',
          ),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          _ResourceRow(
            icon: Icons.sports_motorsports_rounded,
            role: 'Driver',
            name: b.driverName ?? 'Unassigned',
            detail: b.driverPhone ?? '',
          ),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          _ResourceRow(
            icon: Icons.medical_services_rounded,
            role: 'EMT Paramedic',
            name: b.emtName ?? 'Unassigned',
            detail: 'NRP / Critical Flight Cert',
          ),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          _ResourceRow(
            icon: Icons.personal_injury_rounded,
            role: 'Attending Physician',
            name: b.doctorName ?? 'None required / Unassigned',
            detail: b.doctorSpecialization ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationSection(AdminBooking b) {
    return Container(
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
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: StitchTheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Quotation #${b.quotationId}',
                    style: StitchTheme.headlineSm(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: b.paymentStatus == 'PAID'
                      ? StitchTheme.tertiaryFixed
                      : StitchTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
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
          const SizedBox(height: 10),
          _PriceLine(label: 'Base Transport Fare', amount: b.baseFare),
          _PriceLine(
            label: 'Distance Charge (${b.distanceKm} km)',
            amount: b.distanceCharge,
          ),
          if (b.doctorFee > 0)
            _PriceLine(
              label: 'Attending Physician Dispatch',
              amount: b.doctorFee,
            ),
          if (b.emtFee > 0)
            _PriceLine(label: 'Critical Care Paramedic Fee', amount: b.emtFee),
          if (b.equipmentFee > 0)
            _PriceLine(
              label: 'Medical Life Support Equipment',
              amount: b.equipmentFee,
            ),
          _PriceLine(label: 'Statutory GST/PST (5%)', amount: b.tax),
          const Divider(height: 12, color: StitchTheme.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: StitchTheme.headlineSm()),
              Text(
                money(b.quotationTotal),
                style: StitchTheme.headlineMd(
                  color: StitchTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRunSheetDialog(BuildContext context, AdminBooking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StitchTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        ),
        title: Text(
          'Medical Run Sheet — #${b.id}',
          style: StitchTheme.headlineSm(),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DISPATCH RUN SHEET - CAD VERIFIED',
                style: StitchTheme.labelSm(
                  color: StitchTheme.outline,
                  weight: FontWeight.w700,
                ),
              ),
              const Divider(height: 12),
              Text(
                'Patient: ${b.patientName}, ${b.patientAge}y ${b.patientGender}',
              ),
              Text('Condition: ${b.patientCondition}'),
              Text('Pickup: ${b.pickupLocation}'),
              Text('Destination: ${b.destinationLocation}'),
              const SizedBox(height: 6),
              Text(
                'Unit: ${b.ambulanceId ?? "TBD"} (Driver: ${b.driverName ?? "TBD"})',
              ),
              Text('Doctor: ${b.doctorName ?? "N/A"}'),
              Text('EMT: ${b.emtName ?? "N/A"}'),
              const Divider(height: 12),
              Text(
                'Billing Status: ${b.quotationStatus} (${money(b.quotationTotal)})',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              showStitchToast(
                context,
                'Run Sheet queued for wireless PDF printing.',
              );
            },
            icon: const Icon(Icons.print_rounded, size: 14),
            label: const Text('Print Run Sheet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StitchTheme.primaryContainer,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAuditLogSheet(BuildContext context, AdminBooking b) {
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
                Text(
                  'Booking #${b.id} Audit History',
                  style: StitchTheme.headlineSm(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final step in b.timeline)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        step.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: step.completed
                            ? StitchTheme.tertiary
                            : StitchTheme.outline,
                        size: 18,
                      ),
                      title: Text(
                        step.stage,
                        style: StitchTheme.bodyMd(weight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${step.actor.isNotEmpty ? "${step.actor} · " : ""}${step.desc}',
                      ),
                      trailing: Text(
                        step.time,
                        style: StitchTheme.labelSm(color: StitchTheme.outline),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _ambulanceSupportsBooking(
    AdminAmbulance ambulance,
    AdminBooking booking,
  ) {
    final subtype = booking.serviceSubtype.toUpperCase();
    final requirements = booking.specialRequirements
        .map((requirement) => requirement.toLowerCase())
        .join(' ');
    final needsOxygen =
        booking.requiresOxygen || requirements.contains('oxygen');
    final needsPicu = booking.requiresPicu || subtype.contains('PICU');
    final needsIcu =
        booking.requiresIcu || (!needsPicu && subtype.contains('ICU'));
    final needsVentilator =
        booking.requiresVentilator || requirements.contains('ventilator');
    final needsCardiacMonitor =
        booking.requiresCardiacMonitor ||
        requirements.contains('cardiac monitor');
    final needsStretcher =
        booking.requiresStretcher || requirements.contains('stretcher');
    final needsWheelchair =
        booking.requiresWheelchair || requirements.contains('wheelchair');

    if (booking.serviceCategory.trim().isNotEmpty &&
        ambulance.category.trim().isNotEmpty &&
        ambulance.category.toUpperCase() !=
            booking.serviceCategory.toUpperCase()) {
      return false;
    }

    return (!needsOxygen || ambulance.hasOxygen) &&
        (!needsIcu || ambulance.hasIcu) &&
        (!needsPicu || ambulance.hasPicu) &&
        (!needsVentilator || ambulance.hasVentilator) &&
        (!needsCardiacMonitor || ambulance.hasCardiacMonitor) &&
        (!needsStretcher || ambulance.hasStretcher) &&
        (!needsWheelchair || ambulance.hasWheelchair) &&
        (booking.serviceCategory.toUpperCase() != 'DEAD_BODY' ||
            ambulance.hasFreezer);
  }

  List<AdminStaff> _driversForAmbulance(
    AdminAmbulance ambulance,
    AdminBooking booking,
  ) {
    final pairedDriverId = ambulance.assignedDriverId?.trim() ?? '';
    final vehicleNumber = ambulance.vehicleCadNo.trim().toLowerCase();
    return widget.store.drivers.where((driver) {
      final isPaired = pairedDriverId.isNotEmpty
          ? driver.id == pairedDriverId
          : driver.assignedVehicle?.trim().toLowerCase() == vehicleNumber;
      return isPaired && driver.status == StaffStatus.available;
    }).toList();
  }

  void _showReallocateDialog(BuildContext context, AdminBooking b) {
    final availableAmbs = widget.store.ambulances.where((ambulance) {
      return ambulance.status == FleetStatus.available &&
          _ambulanceSupportsBooking(ambulance, b) &&
          _driversForAmbulance(ambulance, b).isNotEmpty;
    }).toList();

    String selectedAmb = availableAmbs.any((a) => a.id == b.ambulanceId)
        ? b.ambulanceId!
        : (availableAmbs.isNotEmpty ? availableAmbs.first.id : '');
    final selectedAmbulance = availableAmbs
        .where((ambulance) => ambulance.id == selectedAmb)
        .firstOrNull;
    final selectedAmbulanceDrivers = selectedAmbulance == null
        ? <AdminStaff>[]
        : _driversForAmbulance(selectedAmbulance, b);
    String selectedDriver =
        selectedAmbulanceDrivers
            .where((driver) => driver.id == b.driverId)
            .firstOrNull
            ?.id ??
        (selectedAmbulanceDrivers.isNotEmpty
            ? selectedAmbulanceDrivers.first.id
            : '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: StitchTheme.surfaceContainerLowest,
          title: Text(
            'Reallocate Mission Resources',
            style: StitchTheme.headlineSm(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedAmb.isNotEmpty ? selectedAmb : null,
                decoration: const InputDecoration(
                  labelText: 'Assigned Ambulance',
                ),
                items: [
                  for (final a in availableAmbs)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.callSign} (${a.classification})'),
                    ),
                ],
                onChanged: (v) {
                  final ambulanceId = v ?? '';
                  final ambulance = availableAmbs
                      .where((item) => item.id == ambulanceId)
                      .firstOrNull;
                  final pairedDrivers = ambulance == null
                      ? <AdminStaff>[]
                      : _driversForAmbulance(ambulance, b);
                  setDlgState(() {
                    selectedAmb = ambulanceId;
                    selectedDriver =
                        pairedDrivers
                            .where((driver) => driver.id == b.driverId)
                            .firstOrNull
                            ?.id ??
                        (pairedDrivers.isNotEmpty
                            ? pairedDrivers.first.id
                            : '');
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('$selectedAmb:$selectedDriver'),
                initialValue: selectedDriver.isNotEmpty ? selectedDriver : null,
                decoration: const InputDecoration(labelText: 'Assigned Driver'),
                items: [
                  for (final d
                      in selectedAmb.isEmpty
                          ? <AdminStaff>[]
                          : _driversForAmbulance(
                              availableAmbs.firstWhere(
                                (ambulance) => ambulance.id == selectedAmb,
                              ),
                              b,
                            ))
                    DropdownMenuItem(
                      value: d.id,
                      child: Text('${d.name} (${d.phone})'),
                    ),
                ],
                onChanged:
                    selectedAmb.isEmpty ||
                        _driversForAmbulance(
                          availableAmbs.firstWhere(
                            (ambulance) => ambulance.id == selectedAmb,
                          ),
                          b,
                        ).isEmpty
                    ? null
                    : (driverId) =>
                          setDlgState(() => selectedDriver = driverId ?? ''),
              ),
              if (availableAmbs.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'No available ambulance with a paired available driver meets this booking’s clinical requirements.',
                  style: StitchTheme.bodySm(color: StitchTheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving || availableAmbs.isEmpty
                  ? null
                  : () async {
                      if (selectedAmb.isNotEmpty && selectedDriver.isNotEmpty) {
                        setDlgState(() => isSaving = true);
                        try {
                          await widget.store.reallocateBooking(
                            bookingId: b.id,
                            ambulanceId: selectedAmb,
                            driverId: selectedDriver,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!mounted) return;
                          setState(() {});
                          showStitchToast(
                            context,
                            'Resource reallocation saved to dispatch.',
                          );
                        } catch (error) {
                          if (!ctx.mounted) return;
                          setDlgState(() => isSaving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reassignment failed: ${error.toString().replaceFirst('Bad state: ', '')}',
                              ),
                              backgroundColor: StitchTheme.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchTheme.primaryContainer,
                foregroundColor: Colors.white,
              ),
              child: Text(isSaving ? 'Saving...' : 'Confirm Reallocation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.iconColor,
    this.isDanger = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDanger
              ? StitchTheme.error
              : StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
          border: isDanger ? null : Border.all(color: StitchTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDanger
                  ? Colors.white
                  : (iconColor ?? StitchTheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: StitchTheme.labelSm(
                color: isDanger ? Colors.white : StitchTheme.onSurface,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  const _TimelineStepTile({
    required this.step,
    required this.isLast,
    required this.onComplete,
  });

  final TimelineStep step;
  final bool isLast;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: step.completed
                    ? StitchTheme.primaryContainer
                    : StitchTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.completed ? Icons.check_rounded : Icons.circle_outlined,
                size: 14,
                color: step.completed ? Colors.white : StitchTheme.outline,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: step.completed
                    ? StitchTheme.primaryFixedDim
                    : StitchTheme.surfaceContainerHigh,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      step.stage,
                      style: StitchTheme.labelMd(weight: FontWeight.w700),
                    ),
                    Text(
                      step.time,
                      style: StitchTheme.labelSm(color: StitchTheme.outline),
                    ),
                  ],
                ),
                if (step.actor.isNotEmpty || step.desc.isNotEmpty)
                  Text(
                    '${step.actor.isNotEmpty ? "${step.actor} · " : ""}${step.desc}',
                    style: StitchTheme.bodySm(
                      color: StitchTheme.onSurfaceVariant,
                    ),
                  ),
                if (!step.completed) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onComplete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: StitchTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(
                          StitchTheme.radiusSm,
                        ),
                      ),
                      child: Text(
                        'Advance to this Stage',
                        style: StitchTheme.labelSm(
                          color: StitchTheme.onPrimaryFixed,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.icon,
    required this.role,
    required this.name,
    required this.detail,
  });
  final IconData icon;
  final String role;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: StitchTheme.primaryContainer),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: StitchTheme.labelSm(
                color: StitchTheme.outline,
                weight: FontWeight.w600,
              ),
            ),
            Text(name, style: StitchTheme.bodySm(weight: FontWeight.w700)),
          ],
        ),
        const Spacer(),
        Text(
          detail,
          style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
          ),
          Text(money(amount), style: StitchTheme.labelMd()),
        ],
      ),
    );
  }
}
