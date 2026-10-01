import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/models/auth_user.dart';
import '../../../../core/models/driver_models.dart';
import '../../../../core/services/driver_location_service.dart';
import '../../../../core/services/driver_location_store.dart';
import '../../../../core/services/shared_booking_store.dart';
import '../../../../core/services/supabase_booking_repository.dart';
import '../../../../core/services/supabase_resource_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/supabase_workflow_repository.dart';
import '../screens/driver_active_trip_screen.dart';
import '../screens/driver_assignments_screen.dart';
import '../screens/driver_dashboard_screen.dart';
import '../screens/driver_profile_screen.dart';
import '../screens/driver_trip_history_screen.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import 'driver_top_bar.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({
    super.key,
    required this.driver,
    required this.bookings,
    required this.onSignOut,
    this.user,
  });

  final DriverProfile driver;
  final List<DriverBooking> bookings;
  final VoidCallback onSignOut;
  final AuthUser? user;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;
  final DriverLocationService _locationService = DriverLocationService.instance;
  final SupabaseWorkflowRepository _workflowRepository =
      SupabaseWorkflowRepository();
  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();
  final SupabaseResourceRepository _resourceRepository =
      SupabaseResourceRepository();

  late List<DriverBooking> _bookings;
  bool _refreshingPortal = false;
  String? _openedBookingId;
  bool _disposed = false;

  // ── GPS State Machine ──────────────────────────────────────────────────────
  _GpsState _gpsState = _GpsState.loading;
  DateTime? _lastSharedAt;
  bool _publishingLocation = false;
  int _publishSequence = 0;
  Position? _latestPosition;
  Timer? _freshnessTicker;
  Timer? _bookingRefreshTicker;
  String? _trackedBookingId;

  @override
  void initState() {
    super.initState();
    _bookings = List<DriverBooking>.from(widget.bookings);

    // Periodic freshness check every 5 seconds to transition from liveShared to sharingDelayed if > 15s elapsed
    _freshnessTicker = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkFreshness(),
    );
    _bookingRefreshTicker = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshPortalData()),
    );

    // State 1: Authenticate driver, load authoritative driver profile & bookings first
    unawaited(_initializeDriverPortal());
  }

  @override
  void didUpdateWidget(covariant DriverShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bookings, widget.bookings)) {
      _bookings = List<DriverBooking>.from(widget.bookings);
    }
    if (oldWidget.driver.id != widget.driver.id) {
      unawaited(
        _refreshPortalData().then((_) => _resolveAndApplyGpsLifecycle()),
      );
    }
  }

  /// Refreshes the Driver workspace from the canonical resource and booking
  /// rows. Allocation stores `drivers.id` in `bookings.assigned_driver_id`;
  /// it is intentionally not queried with the auth/profile ID.
  Future<void> _refreshPortalData() async {
    final driverId = widget.driver.id.trim();
    if (!SupabaseService.isConfigured ||
        driverId.isEmpty ||
        _refreshingPortal) {
      return;
    }

    if (mounted) setState(() => _refreshingPortal = true);
    try {
      final results = await Future.wait<Object?>([
        _resourceRepository.getCurrentDriver(),
        _bookingRepository.getCurrentDriverBookings(fallbackDriverId: driverId),
      ]);
      final liveDriver = results[0] as DriverProfile?;
      final liveBookings = results[1] as List<DriverBooking>;

      if (_disposed || !mounted) return;
      setState(() {
        if (liveDriver != null) widget.driver.applyFrom(liveDriver);
        _bookings = liveBookings;
      });
    } catch (error) {
      debugPrint('Driver portal refresh failed: $error');
    } finally {
      if (!_disposed && mounted) setState(() => _refreshingPortal = false);
    }
  }

  // ---------------------------------------------------------------------------
  // STATE-DRIVEN GPS LIFECYCLE
  // ---------------------------------------------------------------------------

  Future<void> _initializeDriverPortal() async {
    setState(() => _gpsState = _GpsState.loading);
    await _refreshPortalData();
    if (_disposed || !mounted) return;
    await _resolveAndApplyGpsLifecycle();
  }

  Future<void> _resolveAndApplyGpsLifecycle() async {
    if (_disposed || !mounted) return;

    final driverId = widget.driver.id.trim();
    if (driverId.isEmpty) {
      setState(() => _gpsState = _GpsState.loading);
      return;
    }

    final active = activeTrip;

    // State 2: No active trip assigned
    if (active == null) {
      _trackedBookingId = null;
      setState(() => _gpsState = _GpsState.waitingForAssignment);
      await _startPresenceTracking();
      return;
    }

    // State 3: Active trip found
    if (_trackedBookingId == active.id && _locationService.isTracking) {
      return;
    }

    _trackedBookingId = active.id;
    await _startTripTelemetryTracking(active.id);
  }

  Future<void> _startPresenceTracking() async {
    try {
      await _locationService.startTracking(
        onPosition: _onPresencePositionUpdate,
        onError: _onLocationError,
      );

      // Presence in Supabase (AVAILABLE duty status)
      if (SupabaseService.isConfigured && widget.driver.id.isNotEmpty) {
        unawaited(
          _workflowRepository
              .setDriverDutyStatus(
                driverId: widget.driver.id,
                status: 'AVAILABLE',
              )
              .catchError((_) => <String, dynamic>{}),
        );
      }

      if (!_disposed && mounted && _gpsState == _GpsState.loading) {
        setState(() => _gpsState = _GpsState.waitingForAssignment);
      }
    } on DriverLocationException catch (e) {
      _onLocationError(e);
    } catch (e) {
      _onLocationError(
        DriverLocationException(
          e.toString(),
          category: DriverLocationErrorCategory.unavailable,
        ),
      );
    }
  }

  void _onPresencePositionUpdate(Position position) {
    _latestPosition = position;
    final now = DateTime.now();
    widget.driver.latitude = position.latitude;
    widget.driver.longitude = position.longitude;
    widget.driver.locationAccuracyMeters = position.accuracy;
    widget.driver.locationUpdatedAt = now;
    widget.driver.currentLocation =
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    DriverLocationStore.instance.update(
      driverId: widget.driver.id,
      bookingId: null,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedKmh: position.speed > 0 ? position.speed * 3.6 : 0,
      heading: position.heading,
      updatedAt: now,
      ambulanceUnit: widget.driver.assignedAmbulanceNumber,
    );

    if (!_disposed && mounted) {
      if (_gpsState != _GpsState.waitingForAssignment) {
        setState(() => _gpsState = _GpsState.waitingForAssignment);
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _startTripTelemetryTracking(String bookingId) async {
    try {
      await _locationService.startTracking(
        onPosition: (pos) => _onTripPositionUpdate(pos, bookingId),
        onError: _onLocationError,
      );
    } on DriverLocationException catch (e) {
      _onLocationError(e);
    } catch (e) {
      _onLocationError(
        DriverLocationException(
          e.toString(),
          category: DriverLocationErrorCategory.unavailable,
        ),
      );
    }
  }

  void _onTripPositionUpdate(Position position, String bookingId) {
    _latestPosition = position;
    final now = DateTime.now();
    final active = activeTrip;
    final unit = active?.vehicleNumber.isNotEmpty == true
        ? active!.vehicleNumber
        : widget.driver.assignedAmbulanceNumber;

    widget.driver.latitude = position.latitude;
    widget.driver.longitude = position.longitude;
    widget.driver.locationAccuracyMeters = position.accuracy;
    widget.driver.locationUpdatedAt = now;
    widget.driver.currentLocation =
        '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    if (widget.driver.status != 'OFF_DUTY' && widget.driver.status != 'LEAVE') {
      widget.driver.status = 'ON_TRIP';
    }

    // In-memory bus updates
    DriverLocationStore.instance.update(
      driverId: widget.driver.id,
      bookingId: bookingId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedKmh: position.speed > 0
          ? position.speed * 3.6
          : (active?.speedKmh.toDouble() ?? 0),
      heading: position.heading,
      updatedAt: now,
      ambulanceUnit: unit,
    );

    SharedBookingStore.updateDriverLocation(
      bookingId: bookingId,
      driverName: widget.driver.name,
      driverPhone: widget.driver.phone,
      vehicleNumber: unit,
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: position.speed > 0
          ? position.speed * 3.6
          : (active?.speedKmh.toDouble() ?? 0),
      heading: position.heading,
      accuracyMeters: position.accuracy,
      updatedAt: now,
    );

    // Persist to Supabase if configured & valid
    if (SupabaseService.isConfigured &&
        widget.driver.id.isNotEmpty &&
        !_publishingLocation) {
      final seq = ++_publishSequence;
      unawaited(_publishTripLocation(position, bookingId, seq));
    }

    if (!_disposed && mounted) setState(() {});
  }

  Future<void> _publishTripLocation(
    Position position,
    String bookingId,
    int seq,
  ) async {
    _publishingLocation = true;
    try {
      await _workflowRepository.publishDriverLocation(
        driverId: widget.driver.id,
        latitude: position.latitude,
        longitude: position.longitude,
        bookingId: bookingId,
        accuracyMeters: position.accuracy,
        speedKmh: position.speed > 0 ? position.speed * 3.6 : 0,
        heading: position.heading,
      );

      if (_disposed || !mounted || seq < _publishSequence) return;
      setState(() {
        _lastSharedAt = DateTime.now();
        _gpsState = _GpsState.liveShared;
      });
    } catch (error) {
      debugPrint(
        '[GPS Diagnostics] Operation: publishDriverLocation | Trip: $bookingId | Driver: ${widget.driver.id} | Error: $error',
      );

      if (_disposed || !mounted || seq < _publishSequence) return;

      setState(() {
        if (_lastSharedAt != null) {
          _gpsState = _GpsState.sharingDelayed;
        } else {
          _gpsState = _GpsState.persistFailed;
        }
      });
    } finally {
      _publishingLocation = false;
    }
  }

  void _checkFreshness() {
    if (_disposed || !mounted) return;
    if (_lastSharedAt != null && _gpsState == _GpsState.liveShared) {
      final elapsed = DateTime.now().difference(_lastSharedAt!).inSeconds;
      if (elapsed > 15) {
        setState(() => _gpsState = _GpsState.sharingDelayed);
      }
    }
  }

  void _onLocationError(DriverLocationException ex) {
    if (_disposed || !mounted) return;
    setState(() {
      switch (ex.category) {
        case DriverLocationErrorCategory.permissionDenied:
          _gpsState = _GpsState.permissionRequired;
        case DriverLocationErrorCategory.permissionPermanentlyDenied:
          _gpsState = _GpsState.permissionPermanentlyDenied;
        case DriverLocationErrorCategory.serviceDisabled:
          _gpsState = _GpsState.deviceDisabled;
        case DriverLocationErrorCategory.unavailable:
          _gpsState = _GpsState.waitingForFix;
      }
    });
  }

  void _retryPublish() {
    if (_latestPosition != null && activeTrip != null) {
      final seq = ++_publishSequence;
      unawaited(_publishTripLocation(_latestPosition!, activeTrip!.id, seq));
    } else {
      _resolveAndApplyGpsLifecycle();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _freshnessTicker?.cancel();
    _bookingRefreshTicker?.cancel();
    _locationService.stopTracking();
    if (SupabaseService.isConfigured && widget.driver.id.isNotEmpty) {
      _workflowRepository
          .setDriverDutyStatus(driverId: widget.driver.id, status: 'OFF_DUTY')
          .catchError((_) => <String, dynamic>{});
    }
    DriverLocationStore.instance.clearDriver(widget.driver.id);
    super.dispose();
  }

  DriverBooking? get activeTrip {
    for (final b in _bookings) {
      if (b.isActive) return b;
    }
    return null;
  }

  DriverBooking? get _bookingInTripConsole {
    final active = activeTrip;
    if (active != null) return active;
    final openedId = _openedBookingId;
    if (openedId == null) return null;
    for (final booking in _bookings) {
      if (booking.id == openedId &&
          !booking.isCompleted &&
          booking.status != 'DRIVER_REJECTED') {
        return booking;
      }
    }
    return null;
  }

  void _advance(DriverBooking booking, String nextStatus) {
    () async {
      try {
        if (SupabaseService.isConfigured && widget.driver.id.isNotEmpty) {
          if (booking.status == 'ASSIGNED' && nextStatus == 'PICKUP_STARTED') {
            await _workflowRepository.driverRespondToAssignment(
              bookingId: booking.id,
              accept: true,
            );
            await _workflowRepository.driverAdvanceBooking(
              bookingId: booking.id,
              nextStatus: 'PICKUP_STARTED',
            );
          } else {
            await _workflowRepository.driverAdvanceBooking(
              bookingId: booking.id,
              nextStatus: nextStatus,
            );
          }
        }

        final shared = SharedBookingStore.byId(booking.id);
        if (shared != null) {
          shared.status = nextStatus;
          shared.driverName = widget.driver.name;
          shared.vehicleNumber = booking.vehicleNumber;
          shared.emtName = booking.emtName;
          shared.doctorName = booking.doctorName;
          shared.tripMilestone = nextStatus.replaceAll('_', ' ');
        }

        if (nextStatus == 'SERVICE_COMPLETED') {
          await _locationService.stopTracking();
          _trackedBookingId = null;
          _lastSharedAt = null;
          setState(() => _gpsState = _GpsState.waitingForAssignment);
        }

        await _refreshPortalData();
        await _resolveAndApplyGpsLifecycle();
      } catch (error) {
        await _refreshPortalData();
        await _resolveAndApplyGpsLifecycle();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Could not update trip status. Refresh the trip and try again.',
              ),
              backgroundColor: DriverColors.tertiary,
            ),
          );
        }
      }
    }();
  }

  void _rejectAssignment(DriverBooking booking) {
    () async {
      try {
        if (SupabaseService.isConfigured && widget.driver.id.isNotEmpty) {
          await _workflowRepository.driverRespondToAssignment(
            bookingId: booking.id,
            accept: false,
            reason: 'Driver declined assignment',
          );
        }

        await _locationService.stopTracking();
        _trackedBookingId = null;
        setState(() => _gpsState = _GpsState.waitingForAssignment);

        await _refreshPortalData();
        await _resolveAndApplyGpsLifecycle();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment rejected and dispatch notified.'),
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not reject the assignment. Refresh and try again.',
              ),
            ),
          );
        }
      }
    }();
  }

  void _onStatusChanged(String newStatus) {
    () async {
      try {
        if (SupabaseService.isConfigured && widget.driver.id.isNotEmpty) {
          await _workflowRepository.setDriverDutyStatus(
            driverId: widget.driver.id,
            status: newStatus,
          );
        }
        if (newStatus == 'OFF_DUTY' || newStatus == 'LEAVE') {
          await _locationService.stopTracking();
          _trackedBookingId = null;
          if (mounted) {
            setState(() {
              widget.driver.status = newStatus;
              _gpsState = _GpsState.waitingForAssignment;
            });
          }
        } else {
          if (mounted) setState(() => widget.driver.status = newStatus);
          await _resolveAndApplyGpsLifecycle();
        }
        await _refreshPortalData();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duty status update failed: $error')),
          );
        }
      }
    }();
  }

  void _openPage(int index) {
    if (_currentIndex != index) setState(() => _currentIndex = index);
    unawaited(_refreshPortalData());
  }

  void _openTripConsole(DriverBooking booking) {
    setState(() {
      _openedBookingId = booking.id;
      _currentIndex = 2;
    });
    unawaited(_refreshPortalData());
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget? _gpsBanner() {
    String label;
    Color bg;
    Color fg = Colors.white;
    IconData icon;
    String? actionText;
    VoidCallback? onAction;

    switch (_gpsState) {
      case _GpsState.loading:
        return null;

      case _GpsState.waitingForAssignment:
        label = 'Waiting for assigned trip.';
        bg = DriverColors.surfaceContainerHigh;
        fg = DriverColors.onSurface;
        icon = Icons.schedule_rounded;

      case _GpsState.waitingForFix:
        label = 'Unable to obtain a valid GPS fix. Waiting for location.';
        bg = DriverColors.primaryFixedDim;
        fg = DriverColors.onPrimaryFixed;
        icon = Icons.location_searching_rounded;
        actionText = 'RETRY';
        onAction = _resolveAndApplyGpsLifecycle;

      case _GpsState.permissionRequired:
        label = 'Location permission required. Enable location access to share your position.';
        bg = DriverColors.tertiary;
        icon = Icons.location_off_rounded;
        actionText = 'ENABLE';
        onAction = _resolveAndApplyGpsLifecycle;

      case _GpsState.permissionPermanentlyDenied:
        label = 'Location permission is permanently denied. Enable it from device settings and retry.';
        bg = DriverColors.tertiary;
        icon = Icons.location_disabled_rounded;
        actionText = 'RETRY';
        onAction = _resolveAndApplyGpsLifecycle;

      case _GpsState.deviceDisabled:
        label =
            'Device location is disabled. Enable location services and retry.';
        bg = DriverColors.tertiary;
        icon = Icons.location_off_rounded;
        actionText = 'RETRY';
        onAction = _resolveAndApplyGpsLifecycle;

      case _GpsState.persistFailed:
        if (_lastSharedAt != null) {
          label =
              'GPS sharing is delayed. Last successful update: ${_formatTime(_lastSharedAt!)}.';
          bg = DriverColors.tertiary;
          icon = Icons.sync_problem_rounded;
        } else {
          label = 'Location update could not be saved. Retrying connection.';
          bg = DriverColors.tertiary;
          icon = Icons.cloud_off_rounded;
        }
        actionText = 'RETRY';
        onAction = _retryPublish;

      case _GpsState.sharingDelayed:
        final timeStr = _lastSharedAt != null
            ? _formatTime(_lastSharedAt!)
            : '--:--';
        label = 'GPS sharing is delayed. Last successful update: $timeStr.';
        bg = DriverColors.warningContainer;
        fg = DriverColors.onWarningContainer;
        icon = Icons.timer_outlined;
        actionText = 'RETRY';
        onAction = _retryPublish;

      case _GpsState.liveShared:
        final timeStr = _lastSharedAt != null
            ? _formatTime(_lastSharedAt!)
            : '--:--';
        label = 'Live location shared. Last update: $timeStr.';
        bg = DriverColors.secondaryContainer;
        fg = DriverColors.secondary;
        icon = Icons.check_circle_rounded;
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: DriverTextStyles.telemetryMicro.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionText,
                  style: DriverTextStyles.telemetryMicro.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = activeTrip;
    final bookingInTripConsole = _bookingInTripConsole;
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 768;
    final isLiveGps = _gpsState == _GpsState.liveShared;
    final banner = _gpsBanner();

    final pages = [
      DriverDashboardScreen(
        driver: widget.driver,
        bookings: _bookings,
        onAdvance: _advance,
        onOpenActiveTrip: () {
          if (active != null) _openTripConsole(active);
        },
        onOpenAssignments: () => _openPage(1),
        onStatusChanged: _onStatusChanged,
        lastLocationSharedAt: _lastSharedAt,
        isLiveGpsSharing: isLiveGps,
      ),
      DriverAssignmentsScreen(
        driver: widget.driver,
        bookings: _bookings,
        onAdvance: _advance,
        onRejectAssignment: _rejectAssignment,
        onOpenTrip: _openTripConsole,
      ),
      DriverActiveTripScreen(
        driver: widget.driver,
        booking: bookingInTripConsole,
        onAdvance: _advance,
        lastLocationSharedAt: _lastSharedAt,
        isLiveGpsSharing: isLiveGps,
        onSosTriggered: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Priority Emergency SOS broadcasted to CAD Dispatch Team Lead.',
              ),
              backgroundColor: DriverColors.tertiary,
            ),
          );
        },
      ),
      DriverTripHistoryScreen(bookings: _bookings),
      DriverProfileScreen(
        driver: widget.driver,
        onStatusChanged: _onStatusChanged,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      appBar: DriverTopBar(
        driver: widget.driver,
        activeBooking: active,
        onSosTriggered: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Priority Emergency SOS broadcasted to CAD Dispatch.',
              ),
              backgroundColor: DriverColors.tertiary,
            ),
          );
        },
        onProfileTap: () => _openPage(4),
      ),
      body: isTabletOrDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _openPage,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: DriverColors.surfaceContainerLowest,
                  indicatorColor: DriverColors.primaryFixedDim,
                  selectedLabelTextStyle: DriverTextStyles.telemetryMicro
                      .copyWith(
                        color: DriverColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                  unselectedLabelTextStyle: DriverTextStyles.telemetryMicro
                      .copyWith(color: DriverColors.onSurfaceVariant),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                        color: DriverColors.primaryContainer,
                      ),
                      label: Text('Dashboard'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(
                        Icons.assignment_rounded,
                        color: DriverColors.primaryContainer,
                      ),
                      label: Text('Assignments'),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: active != null,
                        backgroundColor: DriverColors.tertiary,
                        child: const Icon(Icons.navigation_outlined),
                      ),
                      selectedIcon: const Icon(
                        Icons.navigation_rounded,
                        color: DriverColors.primaryContainer,
                      ),
                      label: const Text('Active Trip'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(
                        Icons.history_rounded,
                        color: DriverColors.primaryContainer,
                      ),
                      label: Text('History'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                        color: DriverColors.primaryContainer,
                      ),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  color: DriverColors.surfaceContainerHigh,
                ),
                Expanded(
                  child: Column(
                    children: [
                      ?banner,
                      Expanded(child: pages[_currentIndex]),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                ?banner,
                Expanded(child: pages[_currentIndex]),
              ],
            ),
      bottomNavigationBar: isTabletOrDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: DriverColors.surfaceContainerHigh,
                    width: 1.2,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _openPage,
                backgroundColor: DriverColors.surfaceContainerLowest,
                indicatorColor: DriverColors.primaryFixedDim,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(
                      Icons.dashboard_rounded,
                      color: DriverColors.primaryContainer,
                    ),
                    label: 'Dashboard',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(
                      Icons.assignment_rounded,
                      color: DriverColors.primaryContainer,
                    ),
                    label: 'Assignments',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: active != null,
                      backgroundColor: DriverColors.tertiary,
                      child: const Icon(Icons.navigation_outlined),
                    ),
                    selectedIcon: const Icon(
                      Icons.navigation_rounded,
                      color: DriverColors.primaryContainer,
                    ),
                    label: 'Active Trip',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(
                      Icons.history_rounded,
                      color: DriverColors.primaryContainer,
                    ),
                    label: 'History',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(
                      Icons.person_rounded,
                      color: DriverColors.primaryContainer,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
    );
  }
}

/// GPS lifecycle state machine for [_DriverShellState].
enum _GpsState {
  /// Waiting for driver profile and authoritative assignment to be loaded.
  loading,

  /// No active trip is assigned; presence-only tracking or standby mode.
  waitingForAssignment,

  /// Active assignment found, waiting for the first valid GPS coordinate.
  waitingForFix,

  /// Location permission was denied by the user.
  permissionRequired,

  /// Location permission is permanently denied in browser/OS settings.
  permissionPermanentlyDenied,

  /// Device location hardware or browser geolocation service is disabled.
  deviceDisabled,

  /// GPS fix acquired, but saving to Supabase telemetry failed.
  persistFailed,

  /// Telemetry is currently delayed / stale (> 15 seconds since last successful write).
  sharingDelayed,

  /// Telemetry successfully persisted to Supabase and is fresh.
  liveShared,
}
