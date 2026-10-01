import 'package:flutter/material.dart';
import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({
    super.key,
    required this.bookings,
  });

  final List<DriverBooking> bookings;

  @override
  State<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  String _searchQuery = '';

  List<DriverBooking> get _historyList {
    return widget.bookings.where((b) {
      // Historical trips
      final isHistory = b.status == 'SERVICE_COMPLETED' || b.status == 'CANCELLED';
      if (!isHistory) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.id.toLowerCase().contains(q) ||
          b.patientName.toLowerCase().contains(q) ||
          b.pickupAddress.toLowerCase().contains(q) ||
          b.destinationAddress.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _historyList;

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: DriverColors.surfaceContainerLowest,
            border: Border(
              bottom: BorderSide(color: DriverColors.surfaceContainerHigh),
            ),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search completed records by patient, ID, or route...',
              prefixIcon: const Icon(Icons.search, size: 20, color: DriverColors.primaryContainer),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: DriverColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // List View
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: DriverColors.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No Historical Trips Found', style: DriverTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Trips completed or finalized by you will be archived here.',
                          style: DriverTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = list[index];
                    return Container(
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
                              Text(b.id, style: DriverTextStyles.bookingId),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: DriverColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  b.statusLabel,
                                  style: DriverTextStyles.telemetryMicro.copyWith(
                                    color: DriverColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${b.patientName} (${b.patientAge}, ${b.patientGender})', style: DriverTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text('${b.pickupAddress} ➔ ${b.destinationAddress}', style: DriverTextStyles.bodySmall),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: DriverColors.surfaceContainerHigh),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Crew: Dr. ${b.doctorName} • ${b.emtName}',
                                style: DriverTextStyles.telemetryMicro.copyWith(color: DriverColors.onSurfaceVariant),
                              ),
                              Text(
                                '${b.estimatedDistanceKm} KM',
                                style: DriverTextStyles.telemetryMicro.copyWith(
                                  color: DriverColors.primaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
