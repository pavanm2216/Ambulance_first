import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/models/auth_user.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/customer_booking_workflow_service.dart';
import '../../../core/services/customer_portal_cache.dart';
import '../../../core/services/shared_booking_store.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_workflow_repository.dart';
import '../../../core/services/live_road_route_service.dart';
import '../../../core/services/driver_navigation_service.dart';
import '../theme/ambulance_first_theme.dart';
import '../widgets/ambulance_first_card.dart';
import '../widgets/ambulance_first_states.dart';
import '../widgets/ambulance_first_timeline.dart';
import '../widgets/booking_details_dialog.dart';
import '../widgets/customer_google_trip_map.dart';

/// Active Trip & Live Tracking Screen
class CustomerActiveTripScreen extends StatefulWidget {
  const CustomerActiveTripScreen({
    super.key,
    required this.user,
    required this.onBookNewAmbulance,
  });

  final AuthUser user;
  final VoidCallback onBookNewAmbulance;

  @override
  State<CustomerActiveTripScreen> createState() =>
      _CustomerActiveTripScreenState();
}

class _CustomerActiveTripScreenState extends State<CustomerActiveTripScreen> {
  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();
  final SupabaseWorkflowRepository _workflowRepository =
      SupabaseWorkflowRepository();
  Timer? _telemetryRefreshTimer;
  RealtimeChannel? _bookingRealtimeChannel;
  String? _realtimeBookingId;
  bool _isRefreshingTelemetry = false;
  final LiveRoadRouteService _roadRouteService = LiveRoadRouteService();
  LiveRoadRoute? _liveRoadRoute;
  bool _isRefreshingRoute = false;
  DateTime? _lastRouteRequestedAt;
  String? _lastRouteLegKey;
  String? _lastRouteOriginKey;
  int _routeRequestSequence = 0;
  bool _isConfirmingDropoff = false;
  bool _isConfirmingOnboard = false;

  List<Booking> get _activeTrips {
    final all = CustomerBookingWorkflowService.forCustomer(
      SharedBookingStore.bookings,
      widget.user.id,
    );
    return all.where((b) => b.isActive).toList();
  }

  Booking? _selectedTrip;

  @override
  void initState() {
    super.initState();
    final trips = _activeTrips;
    if (trips.isNotEmpty) {
      _selectedTrip = trips.first;
      _subscribeToBookingTelemetry(trips.first.id);
    }
    // Driver GPS pings are persisted on the canonical booking row. Keep this
    // page current while it remains mounted inside the customer shell.
    unawaited(_refreshTripTelemetry());
    _telemetryRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshTripTelemetry()),
    );
  }

  @override
  void dispose() {
    _telemetryRefreshTimer?.cancel();
    final channel = _bookingRealtimeChannel;
    if (channel != null) {
      unawaited(SupabaseService.client.removeChannel(channel));
    }
    super.dispose();
  }

  /// The customer subscribes only to the already-authorized booking row.
  /// RLS remains the source of authorization; polling below stays available
  /// when realtime is unavailable or reconnecting.
  void _subscribeToBookingTelemetry(String bookingId) {
    if (!SupabaseService.isConfigured ||
        !SupabaseService.isInitialized ||
        bookingId.isEmpty ||
        _realtimeBookingId == bookingId) {
      return;
    }
    final oldChannel = _bookingRealtimeChannel;
    if (oldChannel != null) {
      unawaited(SupabaseService.client.removeChannel(oldChannel));
    }
    _realtimeBookingId = bookingId;
    _bookingRealtimeChannel = SupabaseService.client
        .channel('customer-booking-telemetry-$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bookingId,
          ),
          callback: (_) => unawaited(_refreshTripTelemetry()),
        )
        .subscribe();
  }

  Future<void> _refreshTripTelemetry() async {
    if (_isRefreshingTelemetry) return;
    _isRefreshingTelemetry = true;
    try {
      final bookings = await _bookingRepository.getCustomerBookings();
      for (final booking in bookings) {
        SharedBookingStore.upsert(booking);
      }
      if (!mounted) return;
      Booking? refreshedTrip;
      final previousStatus = _selectedTrip?.status;
      setState(() {
        final selectedId = _selectedTrip?.id;
        refreshedTrip = selectedId != null
            ? bookings
                  .where(
                    (booking) => booking.id == selectedId && booking.isActive,
                  )
                  .firstOrNull
            : null;
        refreshedTrip ??= bookings
            .where((booking) => booking.isActive)
            .firstOrNull;
        _selectedTrip = refreshedTrip;
      });
      if (refreshedTrip != null) {
        _subscribeToBookingTelemetry(refreshedTrip!.id);
        const onboardConfirmationStatuses = {
          'PATIENT_PICKED_UP',
          'IN_TRANSIT',
          'ARRIVED',
        };
        if (!refreshedTrip!.patientOnboardConfirmed &&
            onboardConfirmationStatuses.contains(refreshedTrip!.status) &&
            previousStatus != refreshedTrip!.status &&
            mounted) {
          unawaited(_confirmPatientOnboard(refreshedTrip!));
        }
        await _refreshRoadRoute(refreshedTrip!);
      }
    } catch (_) {
      // Preserve the last known point during a temporary network failure.
    } finally {
      _isRefreshingTelemetry = false;
    }
  }

  bool _isPickupLeg(Booking booking) =>
      LiveRoadRouteService.resolveLeg(
        status: booking.status,
        milestone: booking.tripMilestone,
        patientOnboardConfirmed: booking.patientOnboardConfirmed,
      ) ==
      LiveTripLeg.pickup;

  Future<void> _refreshRoadRoute(Booking booking, {bool force = false}) async {
    // Invalidate an older response whenever a newer telemetry refresh arrives;
    // the next refresh will calculate using the newest GPS point.
    if (_isRefreshingRoute) {
      _routeRequestSequence++;
      return;
    }
    final canRoute =
        LiveRoadRouteService.hasActiveNavigation(
          status: booking.status,
          milestone: booking.tripMilestone,
        ) &&
        DriverNavigationService.hasValidCoordinates(
          booking.driverLatitude,
          booking.driverLongitude,
        ) &&
        LiveRoadRouteService.hasFreshDriverLocation(
          booking.driverLocationUpdatedAt,
        );
    if (!canRoute) {
      if (mounted &&
          _selectedTrip?.id == booking.id &&
          _liveRoadRoute != null) {
        setState(() => _liveRoadRoute = null);
      }
      return;
    }

    final isPickupLeg = _isPickupLeg(booking);
    final legKey = '${booking.id}:${isPickupLeg ? 'PICKUP' : 'HOSPITAL'}';
    final now = DateTime.now();
    final legChanged = _lastRouteLegKey != legKey;
    final originKey =
        '${booking.driverLatitude},${booking.driverLongitude}:'
        '${booking.driverLocationUpdatedAt?.millisecondsSinceEpoch}';
    final originChanged = _lastRouteOriginKey != originKey;
    final elapsed = _lastRouteRequestedAt == null
        ? null
        : now.difference(_lastRouteRequestedAt!);
    if (!force &&
        !legChanged &&
        !originChanged &&
        elapsed != null &&
        elapsed < const Duration(seconds: 30)) {
      return;
    }

    final targetLatitude = isPickupLeg
        ? booking.pickupLatitude
        : booking.destinationLatitude;
    final targetLongitude = isPickupLeg
        ? booking.pickupLongitude
        : booking.destinationLongitude;
    if (targetLatitude == null || targetLongitude == null) return;

    _isRefreshingRoute = true;
    _lastRouteRequestedAt = now;
    _lastRouteLegKey = legKey;
    _lastRouteOriginKey = originKey;
    final requestSequence = ++_routeRequestSequence;
    if (legChanged && mounted) {
      setState(() => _liveRoadRoute = null);
    }

    try {
      final route = await _roadRouteService.calculate(
        originLatitude: booking.driverLatitude!,
        originLongitude: booking.driverLongitude!,
        destinationLatitude: targetLatitude,
        destinationLongitude: targetLongitude,
        originAddress: 'Ambulance live GPS',
        destinationAddress: isPickupLeg ? booking.pickup : booking.destination,
        legKey: legKey,
      );
      if (!mounted ||
          _selectedTrip?.id != booking.id ||
          requestSequence != _routeRequestSequence ||
          _lastRouteOriginKey != originKey ||
          _lastRouteLegKey != legKey) {
        return;
      }
      setState(() {
        _liveRoadRoute = route;
      });
    } catch (error) {
      debugPrint('CUSTOMER LIVE ROUTE ERROR [$legKey]: $error');
      if (mounted && _selectedTrip?.id == booking.id && legChanged) {
        setState(() => _liveRoadRoute = null);
      }
    } finally {
      _isRefreshingRoute = false;
    }
  }

  Future<void> _confirmDropoff(Booking booking) async {
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

    setState(() => _isConfirmingDropoff = true);
    try {
      if (!SupabaseService.isConfigured) {
        throw StateError('An authenticated customer session is required.');
      }
      await _workflowRepository.confirmCustomerDropoff(bookingId: booking.id);
      await _refreshTripTelemetry();
      if (!mounted) return;
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
        await _refreshTripTelemetry();
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
      if (mounted) setState(() => _isConfirmingDropoff = false);
    }
  }

  Future<void> _confirmPatientOnboard(Booking booking) async {
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

    setState(() => _isConfirmingOnboard = true);
    try {
      await _workflowRepository.confirmCustomerPatientOnboard(
        bookingId: booking.id,
      );
      booking.patientOnboardConfirmed = true;
      SharedBookingStore.upsert(booking);
      if (!mounted) return;
      setState(() {});
      unawaited(_refreshTripTelemetry());
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
      if (mounted) setState(() => _isConfirmingOnboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = _activeTrips;

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceXl),
          child: AmbulanceFirstEmptyState(
            icon: Icons.airport_shuttle_outlined,
            heading: 'No Active Transports',
            description: 'You currently have no active ambulance journeys in transit or en route.',
            ctaLabel: 'BOOK NEW AMBULANCE',
            onCtaPressed: widget.onBookNewAmbulance,
          ),
        ),
      );
    }

    // Ensure selected trip exists in active trips
    final currentTrip = _selectedTrip ?? trips.first;

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
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Mission Tracking',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AmbulanceFirstTypography.headlineMd(
                                color: AmbulanceFirstColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Live GPS vector telemetry, patient telemetry, and crew communication',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AmbulanceFirstTypography.bodySm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trips.length > 1)
                        DropdownButton<Booking>(
                          value: currentTrip,
                          items: trips
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    'Trip #${t.id} (${t.patientName})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTrip = val;
                                _liveRoadRoute = null;
                              });
                              _subscribeToBookingTelemetry(val.id);
                              unawaited(_refreshRoadRoute(val, force: true));
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Responsive Split: Live Map Canvas on Left (Desktop) or Top (Mobile)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildLiveMapCanvas(currentTrip),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildMissionSidebar(currentTrip),
                        ),
                      ],
                    )
                  else ...[
                    _buildLiveMapCanvas(currentTrip),
                    const SizedBox(height: 16),
                    _buildMissionSidebar(currentTrip),
                  ],
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
  // Live Map & Visual Vector Board
  // ---------------------------------------------------------------------------
  Widget _buildLiveMapCanvas(Booking booking) {
    final isPickupLeg = _isPickupLeg(booking);
    final route =
        _liveRoadRoute?.legKey ==
            '${booking.id}:${isPickupLeg ? 'PICKUP' : 'HOSPITAL'}'
        ? _liveRoadRoute
        : null;
    return CustomerGoogleTripMap(
      key: ValueKey('${booking.id}:${isPickupLeg ? 'pickup' : 'hospital'}'),
      booking: booking,
      route: route,
      isPickupLeg: isPickupLeg,
    );
  }

  // ---------------------------------------------------------------------------
  // Mission Sidebar: Patient Demographics, Crew, and Milestone Timeline
  // ---------------------------------------------------------------------------
  Widget _buildMissionSidebar(Booking b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (const {
              'PATIENT_PICKED_UP',
              'IN_TRANSIT',
              'ARRIVED',
            }.contains(b.status) &&
            !b.patientOnboardConfirmed) ...[
          AmbulanceFirstCard(
            padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirm patient onboard',
                  style: AmbulanceFirstTypography.labelMd(
                    color: AmbulanceFirstColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  b.status == 'PATIENT_PICKED_UP'
                      ? 'The driver reports that ${b.patientName} has boarded at ${b.pickup}. Confirm before the driver starts toward ${b.destination}.'
                      : 'Onboard confirmation is still needed. Confirm only if ${b.patientName} boarded at ${b.pickup}.',
                  style: AmbulanceFirstTypography.bodySm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _isConfirmingOnboard
                      ? null
                      : () => _confirmPatientOnboard(b),
                  icon: _isConfirmingOnboard
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.airline_seat_recline_extra_rounded),
                  label: Text(
                    _isConfirmingOnboard
                        ? 'CONFIRMING...'
                        : 'CONFIRM PATIENT ONBOARD',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (b.status == 'ARRIVED') ...[
          AmbulanceFirstCard(
            padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirm patient drop-off',
                  style: AmbulanceFirstTypography.labelMd(
                    color: AmbulanceFirstColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'The driver reports arrival at ${b.destination}. Confirm the patient was dropped off to complete the booking and release assigned resources.',
                  style: AmbulanceFirstTypography.bodySm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _isConfirmingDropoff
                      ? null
                      : () => _confirmDropoff(b),
                  icon: _isConfirmingDropoff
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt_rounded),
                  label: Text(
                    _isConfirmingDropoff
                        ? 'CONFIRMING...'
                        : 'CONFIRM PATIENT DROP-OFF',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Patient & Transport Protocol Card
        AmbulanceFirstCard(
          padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Patient Clinical Dossier',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmbulanceFirstTypography.labelMd(
                      color: AmbulanceFirstColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          BookingDetailsDialog.show(context, booking: b),
                      child: const Text('FULL DOSSIER'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${b.patientName} (${b.patientAge > 0 ? "${b.patientAge}y" : "Age unavailable"} / ${b.patientGender})',
                style: AmbulanceFirstTypography.headlineSm(
                  color: AmbulanceFirstColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b.currentCondition,
                style: AmbulanceFirstTypography.bodySm(
                  color: AmbulanceFirstColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (b.pediatricPatient)
                    _pillTag(
                      'PICU PROTOCOL',
                      AmbulanceFirstColors.tertiaryContainer,
                    ),
                  if (b.icuRequired)
                    _pillTag(
                      'ICU MOBILE PACK',
                      AmbulanceFirstColors.medicalCrimson,
                    ),
                  if (b.ventilatorRequired)
                    _pillTag(
                      'VENTILATOR ACTIVE',
                      AmbulanceFirstColors.clinicalCobalt,
                    ),
                  if (b.oxygenRequired)
                    _pillTag(
                      b.oxygenFlowLpm != null
                          ? 'OXYGEN AT ${b.oxygenFlowLpm} LPM'
                          : 'OXYGEN REQUIRED',
                      AmbulanceFirstColors.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Assigned Medical Crew Contact Card
        AmbulanceFirstCard(
          padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Response Team',
                style: AmbulanceFirstTypography.labelMd(
                  color: AmbulanceFirstColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _crewTile(
                role: 'Primary Paramedic',
                name: b.emtName.isNotEmpty ? b.emtName : 'Unavailable',
                icon: Icons.health_and_safety_rounded,
                phone: b.emtPhone,
              ),
              const Divider(height: 14),
              _crewTile(
                role: 'Attending Doctor',
                name: b.doctorName.trim().isEmpty
                    ? 'Doctor details unavailable'
                    : b.doctorName,
                icon: Icons.medical_services_rounded,
                phone: b.doctorPhone,
              ),
              const Divider(height: 14),
              _crewTile(
                role: 'Ambulance Driver',
                name: b.driverName.trim().isEmpty
                    ? 'Driver details unavailable'
                    : b.driverName,
                icon: Icons.drive_eta_rounded,
                phone: b.driverPhone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _buildVitalsCard(b),
        const SizedBox(height: 12),

        // Milestone Progression Timeline
        AmbulanceFirstCard(
          padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mission Milestones',
                style: AmbulanceFirstTypography.labelMd(
                  color: AmbulanceFirstColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AmbulanceFirstTimeline(steps: _timelineSteps(b)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _crewTile({
    required String role,
    required String name,
    required IconData icon,
    required String phone,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AmbulanceFirstColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AmbulanceFirstColors.clinicalCobalt,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: AmbulanceFirstTypography.bodySm(
                  color: AmbulanceFirstColors.onSurfaceVariant,
                ).copyWith(fontSize: 10),
              ),
              Text(
                name,
                style: AmbulanceFirstTypography.bodyMd(
                  color: AmbulanceFirstColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: phone.isEmpty
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling $name ($phone)...')),
                  );
                },
          icon: const Icon(
            Icons.phone,
            size: 16,
            color: AmbulanceFirstColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsCard(Booking booking) {
    final latest = booking.vitals.isEmpty ? null : booking.vitals.last;
    return AmbulanceFirstCard(
      padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Patient Vitals',
            style: AmbulanceFirstTypography.labelMd(
              color: AmbulanceFirstColors.onSurface,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (latest == null)
            Text(
              'Vitals unavailable',
              style: AmbulanceFirstTypography.bodySm(
                color: AmbulanceFirstColors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('HR ${latest.heartRate} bpm'),
                Text('SpO2 ${latest.spo2}%'),
                Text('BP ${latest.bp}'),
                Text('RR ${latest.respiratoryRate}'),
                Text('Temp ${latest.temperature} C'),
                if (latest.glucoseMgDl != null)
                  Text('Glucose ${latest.glucoseMgDl}'),
              ],
            ),
          if (latest != null && latest.clinicalNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latest.clinicalNotes,
              style: AmbulanceFirstTypography.bodySm(
                color: AmbulanceFirstColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<MilestoneStep> _timelineSteps(Booking booking) {
    final history = CustomerPortalCache.bookingHistory[booking.id] ?? const [];
    if (history.isEmpty) {
      return const [
        MilestoneStep(
          title: 'History unavailable',
          subtitle: 'Persisted booking history is not available.',
          isCompleted: false,
          isCurrent: false,
        ),
      ];
    }
    return history.map((entry) {
      final status = entry['status']?.toString() ?? 'Status unavailable';
      final milestone = entry['milestone']?.toString();
      final description = entry['description']?.toString();
      final notes = entry['notes']?.toString();
      final changedBy = entry['changed_by_role']?.toString();
      final subtitle = [
        if (description != null && description.isNotEmpty) description,
        if (notes != null && notes.isNotEmpty) notes,
        if (changedBy != null && changedBy.isNotEmpty) 'Changed by $changedBy',
      ].join(' · ');
      return MilestoneStep(
        title: milestone != null && milestone.isNotEmpty ? milestone : status,
        subtitle: subtitle.isNotEmpty ? subtitle : 'Details unavailable',
        isCompleted: status == booking.status || booking.isCompleted,
        isCurrent: status == booking.status,
        timestamp:
            entry['timestamp']?.toString() ?? entry['created_at']?.toString(),
      );
    }).toList();
  }

  Widget _pillTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AmbulanceFirstTypography.codeSm(
          color: color,
          weight: FontWeight.w700,
        ).copyWith(fontSize: 9),
      ),
    );
  }
}


