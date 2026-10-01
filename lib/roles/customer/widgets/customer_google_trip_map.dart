import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/driver_navigation_service.dart';
import '../../../core/services/live_road_route_service.dart';
import '../theme/ambulance_first_theme.dart';

/// Google Maps surface for a customer trip. It never substitutes a line for a
/// road route: polylines are rendered only from routing-provider geometry.
class CustomerGoogleTripMap extends StatefulWidget {
  const CustomerGoogleTripMap({
    super.key,
    required this.booking,
    required this.route,
    required this.isPickupLeg,
  });

  final Booking booking;
  final LiveRoadRoute? route;
  final bool isPickupLeg;

  @override
  State<CustomerGoogleTripMap> createState() => _CustomerGoogleTripMapState();
}

class _CustomerGoogleTripMapState extends State<CustomerGoogleTripMap> {
  GoogleMapController? _controller;
  bool _initialBoundsFitted = false;

  bool _valid(double? latitude, double? longitude) =>
      DriverNavigationService.hasValidCoordinates(latitude, longitude);

  List<LatLng> get _allLocations => [
        if (_valid(widget.booking.driverLatitude, widget.booking.driverLongitude))
          LatLng(widget.booking.driverLatitude!, widget.booking.driverLongitude!),
        LatLng(widget.booking.pickupLatitude!, widget.booking.pickupLongitude!),
        LatLng(
          widget.booking.destinationLatitude!,
          widget.booking.destinationLongitude!,
        ),
      ];

  @override
  void didUpdateWidget(covariant CustomerGoogleTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id) _initialBoundsFitted = false;
  }

  Future<void> _focus(List<LatLng> points, {double padding = 56}) async {
    final controller = _controller;
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        padding,
      ),
    );
  }

  Future<void> _fitAll() => _focus(_allLocations);

  Future<void> _recenterActiveRoute() {
    final booking = widget.booking;
    if (!_valid(booking.driverLatitude, booking.driverLongitude)) return Future.value();
    final targetLatitude = widget.isPickupLeg
        ? booking.pickupLatitude
        : booking.destinationLatitude;
    final targetLongitude = widget.isPickupLeg
        ? booking.pickupLongitude
        : booking.destinationLongitude;
    if (!_valid(targetLatitude, targetLongitude)) return Future.value();
    return _focus([
      LatLng(booking.driverLatitude!, booking.driverLongitude!),
      LatLng(targetLatitude!, targetLongitude!),
    ], padding: 72);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    if (!_valid(booking.pickupLatitude, booking.pickupLongitude) ||
        !_valid(booking.destinationLatitude, booking.destinationLongitude)) {
      return _unavailable('Confirmed pickup or hospital coordinates are unavailable.');
    }

    final hasAmbulance = _valid(booking.driverLatitude, booking.driverLongitude);
    final isLive = hasAmbulance &&
        LiveRoadRouteService.hasFreshDriverLocation(booking.driverLocationUpdatedAt);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(booking.pickupLatitude!, booking.pickupLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'PICKUP', snippet: booking.pickup),
      ),
      Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(
          booking.destinationLatitude!,
          booking.destinationLongitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'HOSPITAL', snippet: booking.destination),
      ),
      if (hasAmbulance)
        Marker(
          markerId: const MarkerId('ambulance'),
          position: LatLng(booking.driverLatitude!, booking.driverLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: isLive ? 'LIVE AMBULANCE' : 'LAST KNOWN AMBULANCE LOCATION',
            snippet: booking.vehicleNumber,
          ),
          zIndexInt: 3,
        ),
    };
    final geometry = widget.route?.geometry ?? const <RoutePoint>[];
    final polylines = geometry.length < 2
        ? const <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('active-road-route'),
              points: geometry
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(growable: false),
              color: AmbulanceFirstColors.clinicalCobalt,
              width: 5,
            ),
          };

    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(booking.pickupLatitude!, booking.pickupLongitude!),
              zoom: 13,
            ),
            markers: markers,
            polylines: polylines,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              if (!_initialBoundsFitted) {
                _initialBoundsFitted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitAll());
              }
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _statusChip(
              isLive ? 'GPS LIVE' : hasAmbulance ? 'GPS STALE' : 'GPS UNAVAILABLE',
              isLive
                  ? AmbulanceFirstColors.telemetryLive
                  : AmbulanceFirstColors.telemetryUnavailable,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'trip-map-recenter-${booking.id}',
                  onPressed: _recenterActiveRoute,
                  tooltip: 'Recenter active route',
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'trip-map-fit-${booking.id}',
                  onPressed: _fitAll,
                  tooltip: 'Show ambulance, pickup, and hospital',
                  child: const Icon(Icons.fit_screen_rounded),
                ),
              ],
            ),
          ),
          if (geometry.length < 2)
            Positioned(
              left: 12,
              bottom: 12,
              child: _statusChip(
                'Road route unavailable',
                AmbulanceFirstColors.telemetryUnavailable,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: AmbulanceFirstTypography.codeSm(
            color: color,
            weight: FontWeight.w700,
          ),
        ),
      );

  Widget _unavailable(String message) => Container(
        height: 360,
        color: AmbulanceFirstColors.surfaceContainerHigh,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AmbulanceFirstTypography.bodySm(
            color: AmbulanceFirstColors.onSurfaceVariant,
          ),
        ),
      );
}
