import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/driver_models.dart';
import '../../../../core/services/driver_navigation_service.dart';
import '../../../../core/services/live_road_route_service.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/driver_confirm_dialog.dart';
import '../widgets/emergency_sos_modal.dart';
import '../widgets/hud_telemetry_bar.dart';
import '../widgets/live_map_viewport.dart';
import '../widgets/quick_contact_modal.dart';
import '../widgets/trip_stage_stepper.dart';

class DriverActiveTripScreen extends StatelessWidget {
  const DriverActiveTripScreen({
    super.key,
    required this.driver,
    required this.booking,
    required this.onAdvance,
    required this.onSosTriggered,
    this.lastLocationSharedAt,
    this.isLiveGpsSharing = false,
  });

  final DriverProfile driver;
  final DriverBooking? booking;
  final void Function(DriverBooking booking, String nextStatus) onAdvance;
  final VoidCallback onSosTriggered;
  final DateTime? lastLocationSharedAt;
  final bool isLiveGpsSharing;

  static final DriverNavigationService _navigationService =
      DriverNavigationService();

  bool _isHeadingToPickup(DriverBooking booking) =>
      LiveRoadRouteService.resolveLeg(
        status: booking.status,
        milestone: booking.tripMilestone,
        patientOnboardConfirmed: booking.patientOnboardConfirmed,
      ) ==
      LiveTripLeg.pickup;

  Future<void> _openNavigation(
    BuildContext context,
    DriverBooking booking,
  ) async {
    try {
      final uri = await _navigationService.directionsForBooking(booking);
      if (!context.mounted) return;
      if (await launchUrl(uri, mode: LaunchMode.externalApplication) ||
          !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open navigation on this device.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation not started: $error')));
    }
  }

  void _advanceAndNavigate(
    BuildContext context,
    DriverBooking booking,
    String nextStatus,
  ) {
    onAdvance(booking, nextStatus);
    if (nextStatus == 'PICKUP_STARTED' || nextStatus == 'IN_TRANSIT') {
      _openNavigation(context, booking);
    }
  }

  bool get _isCodeRed =>
      booking != null &&
      (booking!.icuRequired ||
          booking!.ventilatorRequired ||
          booking!.cardiacMonitorRequired);

  void _handlePrimaryAction(BuildContext context, DriverBooking b) {
    switch (b.status) {
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        _advanceAndNavigate(context, b, 'PICKUP_STARTED');
        break;

      case 'PICKUP_STARTED':
        // Mandatory confirmation before boarding
        showDialog(
          context: context,
          builder: (ctx) => DriverConfirmDialog(
            actionType: DriverActionType.boardPatient,
            bookingId: b.id,
            patientName: b.patientName,
            onConfirm: () => onAdvance(b, 'PATIENT_PICKED_UP'),
          ),
        );
        break;

      case 'PATIENT_PICKED_UP':
        if (b.patientOnboardConfirmed) {
          _advanceAndNavigate(context, b, 'IN_TRANSIT');
        }
        break;

      case 'IN_TRANSIT':
        // Mandatory confirmation before destination arrival
        showDialog(
          context: context,
          builder: (ctx) => DriverConfirmDialog(
            actionType: DriverActionType.arriveAtDestination,
            bookingId: b.id,
            patientName: b.patientName,
            onConfirm: () => onAdvance(b, 'ARRIVED'),
          ),
        );
        break;

      case 'ARRIVED':
        break;

      default:
        break;
    }
  }

  String _getPrimaryButtonLabel(DriverBooking booking) {
    switch (booking.status) {
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return 'START PICKUP EN ROUTE';
      case 'PICKUP_STARTED':
        return 'PATIENT BOARDED & SECURED';
      case 'PATIENT_PICKED_UP':
        return booking.patientOnboardConfirmed
            ? 'START TRANSIT TO HOSPITAL'
            : 'AWAITING CUSTOMER ONBOARD CONFIRMATION';
      case 'IN_TRANSIT':
        return 'ARRIVED AT DESTINATION ER';
      case 'ARRIVED':
        return 'AWAITING CUSTOMER DROP-OFF CONFIRMATION';
      case 'SERVICE_COMPLETED':
        return 'HANDOVER COMPLETE';
      default:
        return 'NEXT STAGE';
    }
  }

  IconData _getPrimaryButtonIcon(String status) {
    switch (status) {
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return Icons.directions_car_rounded;
      case 'PICKUP_STARTED':
        return Icons.airline_seat_flat_rounded;
      case 'PATIENT_PICKED_UP':
        return Icons.local_hospital_rounded;
      case 'IN_TRANSIT':
        return Icons.place_rounded;
      case 'ARRIVED':
        return Icons.hourglass_top_rounded;
      case 'SERVICE_COMPLETED':
        return Icons.check_circle_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;

    if (b == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  size: 48,
                  color: DriverColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text('No Active Trip', style: DriverTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'You currently have no active patient transport in progress. Acknowledge a pending dispatch order from Assignments to start.',
                style: DriverTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final headingToPickup = _isHeadingToPickup(b);
    final targetAddress = headingToPickup
        ? b.pickupAddress
        : b.destinationAddress;
    final targetLabel = headingToPickup ? 'PICKUP' : 'DROP-OFF';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Incident Badge Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isCodeRed
                          ? DriverColors.tertiary
                          : DriverColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCodeRed
                              ? Icons.warning_amber_rounded
                              : Icons.local_hospital_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCodeRed ? 'CODE RED' : 'ACTIVE TRANSPORT',
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    b.id,
                    style: DriverTextStyles.bookingId.copyWith(
                      color: DriverColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: b.status == 'SERVICE_COMPLETED'
                      ? DriverColors.secondaryContainer
                      : DriverColors.primaryFixedDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  b.statusLabel,
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: b.status == 'SERVICE_COMPLETED'
                        ? DriverColors.secondary
                        : DriverColors.primaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5-Stage Stepper
          TripStageStepper(status: b.status),

          const SizedBox(height: 14),

          // Dark Inverse HUD Telemetry Bar
          _DriverLiveRouteTelemetry(
            driver: driver,
            booking: b,
            leg: headingToPickup ? LiveTripLeg.pickup : LiveTripLeg.hospital,
            isLiveGpsSharing: isLiveGpsSharing,
            lastLocationSharedAt: lastLocationSharedAt,
          ),

          const SizedBox(height: 14),

          // Live Map Viewport
          LiveMapViewport(
            pickupAddress: b.pickupAddress,
            destinationAddress: targetAddress,
            latitude: driver.latitude,
            longitude: driver.longitude,
            isLocationAvailable:
                driver.latitude != null && driver.longitude != null,
            corridorName: b.routeProvider.isEmpty
                ? 'ROUTE PROVIDER NOT RECORDED'
                : b.routeProvider.replaceAll('_', ' '),
            nextTurnInstruction: targetAddress.isEmpty
                ? '$targetLabel details are not recorded for this booking.'
                : 'Navigate to $targetLabel: $targetAddress',
            targetLabel: targetLabel,
            onNavigate: () => _openNavigation(context, b),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () => _openNavigation(context, b),
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: Text('OPEN NAVIGATION TO $targetLabel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DriverColors.primaryContainer,
              side: const BorderSide(color: DriverColors.primaryContainer),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 10),

          // Primary Active-Trip Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  b.status == 'SERVICE_COMPLETED' ||
                      b.status == 'ARRIVED' ||
                      (b.status == 'PATIENT_PICKED_UP' &&
                          !b.patientOnboardConfirmed)
                  ? null
                  : () => _handlePrimaryAction(context, b),
              icon: Icon(_getPrimaryButtonIcon(b.status), size: 20),
              label: Text(_getPrimaryButtonLabel(b)),
              style: ElevatedButton.styleFrom(
                backgroundColor: b.status == 'ARRIVED'
                    ? DriverColors.secondary
                    : (_isCodeRed
                          ? DriverColors.tertiary
                          : DriverColors.primaryContainer),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if ((b.status == 'PATIENT_PICKED_UP' && !b.patientOnboardConfirmed) ||
              b.status == 'ARRIVED') ...[
            const SizedBox(height: 8),
            Text(
              b.status == 'ARRIVED'
                  ? 'The customer must confirm drop-off before this assignment and its resources are released.'
                  : 'Waiting for the customer to confirm the patient is onboard before starting the destination leg.',
              textAlign: TextAlign.center,
              style: DriverTextStyles.bodySmall.copyWith(
                color: DriverColors.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Quick Operational Action Row (Contacts & SOS)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => QuickContactModal(
                        bookingId: b.id,
                        doctorName: b.doctorName,
                        doctorPhone: b.doctorPhone,
                        emtName: b.emtName,
                        emtPhone: b.emtPhone,
                        customerName: b.customerName,
                        customerPhone: b.customerMobile,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                  label: const Text('CONTACTS'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => EmergencySosModal(
                        driverId: driver.id,
                        driverName: driver.name,
                        bookingId: b.id,
                        ambulanceUnit: driver.assignedAmbulanceNumber,
                        latitude: driver.latitude,
                        longitude: driver.longitude,
                        onSosTriggered: onSosTriggered,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('SOS CAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.tertiary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Patient Information & Medical Equipment Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PATIENT & CLINICAL PROFILE',
                      style: DriverTextStyles.titleSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DriverColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b.currentCondition,
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: DriverColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${b.patientName} (${b.patientAge} years, ${b.patientGender})',
                  style: DriverTextStyles.headlineSmall.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  b.medicalConditionSummary,
                  style: DriverTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (b.oxygenRequired)
                      _Badge(icon: Icons.air, label: 'Oxygen Required'),
                    if (b.stretcherRequired)
                      _Badge(
                        icon: Icons.airline_seat_flat,
                        label: 'Stretcher Boarded',
                      ),
                    if (b.cardiacMonitorRequired)
                      _Badge(
                        icon: Icons.monitor_heart,
                        label: 'Cardiac Monitored',
                        isAlert: true,
                      ),
                    if (b.icuRequired)
                      _Badge(
                        icon: Icons.local_hospital,
                        label: 'ICU Rig',
                        isAlert: true,
                      ),
                    if (b.ventilatorRequired)
                      _Badge(
                        icon: Icons.masks,
                        label: 'Ventilator Active',
                        isAlert: true,
                      ),
                  ],
                ),
                if (b.specialInstructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DriverColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: DriverColors.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dispatch: ${b.specialInstructions}',
                            style: DriverTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Crew Onboard Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ONBOARD CLINICAL CREW',
                  style: DriverTextStyles.titleSmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: DriverColors.primaryContainer
                                .withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.medical_services_outlined,
                              size: 18,
                              color: DriverColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DOCTOR',
                                  style: DriverTextStyles.telemetryMicro
                                      .copyWith(fontSize: 8.5),
                                ),
                                Text(
                                  b.doctorName,
                                  style: DriverTextStyles.titleSmall,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: DriverColors.secondaryContainer
                                .withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              size: 18,
                              color: DriverColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMT',
                                  style: DriverTextStyles.telemetryMicro
                                      .copyWith(fontSize: 8.5),
                                ),
                                Text(
                                  b.emtName,
                                  style: DriverTextStyles.titleSmall,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DriverLiveRouteTelemetry extends StatefulWidget {
  const _DriverLiveRouteTelemetry({
    required this.driver,
    required this.booking,
    required this.leg,
    required this.isLiveGpsSharing,
    required this.lastLocationSharedAt,
  });

  final DriverProfile driver;
  final DriverBooking booking;
  final LiveTripLeg leg;
  final bool isLiveGpsSharing;
  final DateTime? lastLocationSharedAt;

  @override
  State<_DriverLiveRouteTelemetry> createState() =>
      _DriverLiveRouteTelemetryState();
}

class _DriverLiveRouteTelemetryState extends State<_DriverLiveRouteTelemetry> {
  final LiveRoadRouteService _routeService = LiveRoadRouteService();
  Timer? _refreshTimer;
  LiveRoadRoute? _route;
  DateTime? _lastRequestAt;
  String? _lastLegKey;
  String? _lastOriginKey;
  bool _refreshing = false;

  String get _legKey => '${widget.booking.id}:${widget.leg.name}';

  @override
  void initState() {
    super.initState();
    unawaited(_refreshRoute(force: true));
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshRoute()),
    );
  }

  @override
  void didUpdateWidget(covariant _DriverLiveRouteTelemetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.leg != widget.leg) {
      unawaited(_refreshRoute(force: true));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshRoute({bool force = false}) async {
    final driver = widget.driver;
    final booking = widget.booking;
    final legKey = _legKey;
    final legChanged = _lastLegKey != legKey;
    final latitude = driver.latitude;
    final longitude = driver.longitude;
    final targetLatitude = widget.leg == LiveTripLeg.pickup
        ? booking.pickupLatitude
        : booking.destinationLatitude;
    final targetLongitude = widget.leg == LiveTripLeg.pickup
        ? booking.pickupLongitude
        : booking.destinationLongitude;

    final canRoute =
        LiveRoadRouteService.hasActiveNavigation(
          status: booking.status,
          milestone: booking.tripMilestone,
        ) &&
        DriverNavigationService.hasValidCoordinates(latitude, longitude) &&
        DriverNavigationService.hasValidCoordinates(
          targetLatitude,
          targetLongitude,
        ) &&
        LiveRoadRouteService.hasFreshDriverLocation(driver.locationUpdatedAt);

    if (!canRoute) {
      if (_route != null && mounted) setState(() => _route = null);
      return;
    }

    final originKey =
        '$latitude,$longitude:${driver.locationUpdatedAt?.millisecondsSinceEpoch}';
    final elapsed = _lastRequestAt == null
        ? null
        : DateTime.now().difference(_lastRequestAt!);
    if (_refreshing ||
        (!force && !legChanged && _lastOriginKey == originKey) ||
        (!force &&
            !legChanged &&
            elapsed != null &&
            elapsed < const Duration(seconds: 30))) {
      return;
    }

    final targetAddress = widget.leg == LiveTripLeg.pickup
        ? booking.pickupAddress
        : booking.destinationAddress;
    _refreshing = true;
    _lastRequestAt = DateTime.now();
    _lastLegKey = legKey;
    _lastOriginKey = originKey;
    if (legChanged && _route != null && mounted) {
      setState(() => _route = null);
    }

    try {
      final route = await _routeService.calculate(
        originLatitude: latitude!,
        originLongitude: longitude!,
        destinationLatitude: targetLatitude!,
        destinationLongitude: targetLongitude!,
        originAddress: 'Ambulance live GPS',
        destinationAddress: targetAddress,
        legKey: legKey,
        includeGeometry: false,
      );
      if (!mounted || _legKey != legKey || _lastOriginKey != originKey) {
        return;
      }
      setState(() => _route = route);
    } catch (error) {
      debugPrint('DRIVER LIVE ROUTE ERROR [$legKey]: $error');
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final freshness = widget.isLiveGpsSharing
        ? TelemetryFreshness.live
        : (widget.lastLocationSharedAt != null
              ? TelemetryFreshness.stale
              : TelemetryFreshness.unavailable);
    return HudTelemetryBar(
      speedKmh: widget.booking.speedKmh.toDouble(),
      etaMinutes: _route?.etaMinutes,
      remainingKm: _route?.distanceKm,
      heading: 0,
      gpsAccuracyMeters: widget.driver.locationAccuracyMeters,
      freshness: freshness,
      networkStatus: widget.isLiveGpsSharing
          ? 'LIVE TELEMETRY SHARED'
          : (widget.lastLocationSharedAt != null
                ? 'TELEMETRY DELAYED'
                : 'GPS NOT SHARED'),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, this.isAlert = false});

  final IconData icon;
  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert
            ? DriverColors.tertiary.withValues(alpha: 0.1)
            : DriverColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert
              ? DriverColors.tertiary.withValues(alpha: 0.3)
              : DriverColors.surfaceContainerHighest,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isAlert
                ? DriverColors.tertiary
                : DriverColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DriverTextStyles.telemetryMicro.copyWith(
              color: isAlert
                  ? DriverColors.tertiaryDark
                  : DriverColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
