import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../theme/team_lead_theme.dart';
import 'telemetry_widget.dart';

class TelemetryModal extends StatelessWidget {
  const TelemetryModal({
    super.key,
    required this.telemetry,
    required this.bookingId,
    required this.patientName,
    required this.destination,
  });

  final LiveTelemetry telemetry;
  final String bookingId;
  final String patientName;
  final String destination;

  static void show(
    BuildContext context, {
    required LiveTelemetry telemetry,
    required String bookingId,
    required String patientName,
    required String destination,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => TelemetryModal(
        telemetry: telemetry,
        bookingId: bookingId,
        patientName: patientName,
        destination: destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg),
      ),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TeamLeadTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: TeamLeadTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operational Telemetry Stream',
                            style: TeamLeadTheme.titleMedium(
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Booking: $bookingId • Patient: $patientName',
                            style: TeamLeadTheme.small(
                              color: TeamLeadTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
              const SizedBox(height: 16),

              if (telemetry.isUnavailable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TeamLeadTheme.crimsonBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                    border: Border.all(color: TeamLeadTheme.medicalCrimson.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.signal_cellular_connected_no_internet_0_bar_rounded, color: TeamLeadTheme.medicalCrimson, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Location Unavailable',
                              style: TeamLeadTheme.body(
                                color: TeamLeadTheme.crimsonText,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'The assigned crew device is not broadcasting real-time coordinates. Last contact was logged via standard mobile check-in.',
                              style: TeamLeadTheme.small(
                                color: TeamLeadTheme.crimsonText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TeamLeadTheme.surfaceLow,
                        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusMd),
                        border: Border.all(color: TeamLeadTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TELEMETRY SIGNAL',
                                style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted),
                              ),
                              TelemetryBadge(state: telemetry.state),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _telemetryDataBlock(
                                  label: 'VEHICLE CALLSIGN',
                                  value: telemetry.callsign,
                                  isCode: true,
                                ),
                              ),
                              Expanded(
                                child: _telemetryDataBlock(
                                  label: 'GROUND SPEED',
                                  value: '${telemetry.speedKmh} km/h',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _telemetryDataBlock(
                                  label: 'ESTIMATED ETA',
                                  value: '${telemetry.etaMinutes} minutes',
                                ),
                              ),
                              Expanded(
                                child: _telemetryDataBlock(
                                  label: 'LAST PING',
                                  value: '${telemetry.lastUpdatedSecondsAgo} sec ago',
                                ),
                              ),
                            ],
                          ),
                          if (telemetry.latitude != null && telemetry.longitude != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: TeamLeadTheme.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _telemetryDataBlock(
                                    label: 'GPS LATITUDE',
                                    value: telemetry.latitude!.toStringAsFixed(5),
                                    isCode: true,
                                  ),
                                ),
                                Expanded(
                                  child: _telemetryDataBlock(
                                    label: 'GPS LONGITUDE',
                                    value: telemetry.longitude!.toStringAsFixed(5),
                                    isCode: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: TeamLeadTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vector Destination: $destination',
                            style: TeamLeadTheme.supportingBody(
                              color: TeamLeadTheme.onSurface,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: TeamLeadTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                    ),
                  ),
                  child: Text(
                    'Close Telemetry HUD',
                    style: TeamLeadTheme.body(
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryDataBlock({
    required String label,
    required String value,
    bool isCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TeamLeadTheme.telemetryMicro(color: TeamLeadTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: isCode
              ? TeamLeadTheme.telemetryPrimary(
                  color: TeamLeadTheme.primaryDark,
                  weight: FontWeight.w700,
                )
              : TeamLeadTheme.telemetryPrimary(
                  color: TeamLeadTheme.onSurface,
                  weight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
