import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/booking.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';
import 'case_details_dialog.dart';
import 'status_badge.dart';
import 'telemetry_modal.dart';
import 'telemetry_widget.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.booking,
  });

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final store = TeamLeadStore.instance;
    final telemetry = store.getTelemetryForBooking(booking);

    return Container(
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
        border: Border.all(
          color: booking.priority == 'CRITICAL'
              ? TeamLeadTheme.medicalCrimson.withValues(alpha: 0.5)
              : TeamLeadTheme.borderSubtle,
          width: booking.priority == 'CRITICAL' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TeamLeadTheme.surfaceLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(TeamLeadTheme.radiusMd)),
              border: const Border(bottom: BorderSide(color: TeamLeadTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TeamLeadTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                      ),
                      child: const Icon(Icons.emergency_rounded, color: TeamLeadTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TeamLeadTheme.telemetryPrimary(
                                  color: TeamLeadTheme.primaryDark,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: StatusBadge(status: booking.status),
                              ),
                            ),
                            if (booking.priority == 'CRITICAL') ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TeamLeadTheme.crimsonBg,
                                      borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                                    ),
                                    child: Text('CODE RED', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.medicalCrimson, weight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${booking.transportModeLabel} • ${booking.pickupCity.isNotEmpty ? booking.pickupCity : "City Corridor"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                        ),
                      ],
                      ),
                    ),
                  ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => CaseDetailsDialog.show(context, booking),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TeamLeadTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: Text('View Case', style: TeamLeadTheme.small(color: TeamLeadTheme.onSurface)),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient & Route Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PATIENT & CLINICAL STATUS', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                          const SizedBox(height: 3),
                          Text(
                            booking.patientName.isNotEmpty ? booking.patientName : 'Emergency Patient',
                            style: TeamLeadTheme.body(weight: FontWeight.w700),
                          ),
                          Text(
                            'Condition: ${booking.currentCondition} • Age: ${booking.patientAge > 0 ? booking.patientAge : "—"}',
                            style: TeamLeadTheme.supportingBody(color: TeamLeadTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACTIVE ROUTE VECTOR', style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.trip_origin_rounded, color: TeamLeadTheme.primary, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(booking.pickup, style: TeamLeadTheme.supportingBody(), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: TeamLeadTheme.operationalEmerald, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(booking.destination, style: TeamLeadTheme.supportingBody(weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Assigned Crew & Vehicle Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeamLeadTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    border: Border.all(color: TeamLeadTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _crewItem(
                          'VEHICLE',
                          booking.vehicleNumber.isNotEmpty ? booking.vehicleNumber : 'Pending',
                          isCode: true,
                        ),
                      ),
                      Expanded(
                        child: _crewItem(
                          'DRIVER',
                          booking.driverName.isNotEmpty ? booking.driverName : 'Pending',
                        ),
                      ),
                      Expanded(
                        child: _crewItem(
                          'EMT / PARAMEDIC',
                          booking.emtName.isNotEmpty ? booking.emtName : (booking.emtRequired ? 'Pending' : 'Not Required'),
                        ),
                      ),
                      Expanded(
                        child: _crewItem(
                          'DOCTOR',
                          booking.doctorName.isNotEmpty ? booking.doctorName : (booking.doctorRequired ? 'Pending' : 'None'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Live Telemetry Bar
                TelemetrySummaryStrip(
                  telemetry: telemetry,
                  onTapDetails: () {
                    TelemetryModal.show(
                      context,
                      telemetry: telemetry,
                      bookingId: booking.id,
                      patientName: booking.patientName.isNotEmpty ? booking.patientName : 'Emergency Patient',
                      destination: booking.destination,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 15, color: TeamLeadTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Live route: driver location → pickup → receiving facility. Status is updated automatically from GPS.',
                        style: TeamLeadTheme.micro(color: TeamLeadTheme.onSurfaceVariant),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openGoogleMaps(context, booking),
                      icon: const Icon(Icons.map_rounded, size: 14),
                      label: Text('Google Maps', style: TeamLeadTheme.micro(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                        side: const BorderSide(color: TeamLeadTheme.borderSubtle),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Automatic location-driven trip progress. Team Lead is read-only here;
                // the Driver GPS stream and backend update the milestone automatically.
                _automaticProgress(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _crewItem(String label, String name, {bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          name,
          style: isCode
              ? TeamLeadTheme.telemetrySecondary(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700)
              : TeamLeadTheme.supportingBody(color: TeamLeadTheme.onSurface, weight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(BuildContext context, Booking booking) async {
    final origin = booking.driverLatitude != null && booking.driverLongitude != null
        ? '${booking.driverLatitude},${booking.driverLongitude}'
        : booking.pickup;
    final destination = booking.destinationLatitude != null && booking.destinationLongitude != null
        ? '${booking.destinationLatitude},${booking.destinationLongitude}'
        : booking.destination;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&travelmode=driving',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  Widget _automaticProgress(Booking booking) {
    const steps = <String>[
      'ASSIGNED',
      'PICKUP_STARTED',
      'PATIENT_PICKED_UP',
      'IN_TRANSIT',
      'ARRIVED',
    ];
    final labels = <String>[
      'Assigned & Prepared',
      'En Route to Pickup',
      'Patient Onboard',
      'In Transit Corridor',
      'Arrived at Facility',
    ];
    final index = booking.status == 'DRIVER_ASSIGNED'
        ? 0
        : steps.indexOf(booking.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLow,
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
        border: Border.all(color: TeamLeadTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AUTOMATIC LOCATION-DRIVEN PROGRESS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  booking.driverLocationSharing ? 'GPS LIVE' : 'WAITING FOR DRIVER GPS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TeamLeadTheme.telemetryMicro(color: booking.driverLocationSharing ? TeamLeadTheme.operationalEmerald : TeamLeadTheme.textMuted, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (i) {
              final done = index >= i;
              final current = index == i;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: done ? TeamLeadTheme.operationalEmerald : TeamLeadTheme.surfaceLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: done ? TeamLeadTheme.operationalEmerald : TeamLeadTheme.borderSubtle),
                      ),
                      child: done ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(labels[i], maxLines: 2, overflow: TextOverflow.ellipsis, style: TeamLeadTheme.micro(color: current ? TeamLeadTheme.primaryDark : TeamLeadTheme.textMuted, weight: current ? FontWeight.w700 : FontWeight.w500)),
                    ),
                    if (i < steps.length - 1)
                      Container(width: 14, height: 1, color: index > i ? TeamLeadTheme.operationalEmerald : TeamLeadTheme.borderSubtle),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 14, color: TeamLeadTheme.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  booking.driverLatitude != null && booking.driverLongitude != null
                      ? 'Driver: ${booking.driverLatitude!.toStringAsFixed(5)}, ${booking.driverLongitude!.toStringAsFixed(5)}'
                      : 'Driver location will appear automatically when GPS is publishing.',
                  style: TeamLeadTheme.micro(color: TeamLeadTheme.onSurfaceVariant),
                ),
              ),
              if (booking.driverLocationSharing)
                Text('${booking.driverSpeedKmh.toStringAsFixed(0)} km/h', style: TeamLeadTheme.telemetrySecondary(color: TeamLeadTheme.primaryDark, weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
