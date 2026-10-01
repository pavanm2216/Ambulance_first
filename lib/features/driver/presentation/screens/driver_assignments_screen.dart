import 'package:flutter/material.dart';
import '../../../../core/models/driver_models.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/assignment_card.dart';

class DriverAssignmentsScreen extends StatefulWidget {
  const DriverAssignmentsScreen({
    super.key,
    required this.driver,
    required this.bookings,
    required this.onAdvance,
    this.onRejectAssignment,
    required this.onOpenTrip,
  });

  final DriverProfile driver;
  final List<DriverBooking> bookings;
  final void Function(DriverBooking booking, String nextStatus) onAdvance;
  final ValueChanged<DriverBooking>? onRejectAssignment;
  final ValueChanged<DriverBooking> onOpenTrip;

  @override
  State<DriverAssignmentsScreen> createState() => _DriverAssignmentsScreenState();
}

class _DriverAssignmentsScreenState extends State<DriverAssignmentsScreen> {
  String _filter = 'ALL';
  String _searchQuery = '';

  List<DriverBooking> get _filteredBookings {
    return widget.bookings.where((b) {
      // Driver assignment scoping (authenticated driver)
      final matchesSearch = _searchQuery.isEmpty ||
          b.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.destinationAddress.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final isCodeRed = b.icuRequired || b.ventilatorRequired || b.cardiacMonitorRequired;
      switch (_filter) {
        case 'CODE_RED':
          return isCodeRed;
        case 'ACTIVE':
          return b.isActive;
        case 'PENDING':
          return b.status == 'ASSIGNED' || b.status == 'DRIVER_ASSIGNED';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBookings;
    final isOffDuty = widget.driver.status == 'OFF_DUTY' || widget.driver.status == 'LEAVE';

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            color: DriverColors.surfaceContainerLowest,
            border: Border(
              bottom: BorderSide(color: DriverColors.surfaceContainerHigh),
            ),
          ),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by Booking ID, patient, hospital...',
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
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(label: 'ALL ASSIGNMENTS', isSelected: _filter == 'ALL', onSelected: () => setState(() => _filter = 'ALL')),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'PENDING ACKNOWLEDGEMENT', isSelected: _filter == 'PENDING', onSelected: () => setState(() => _filter = 'PENDING')),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'CODE RED PRIORITY', isSelected: _filter == 'CODE_RED', onSelected: () => setState(() => _filter = 'CODE_RED')),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'CURRENTLY ACTIVE', isSelected: _filter == 'ACTIVE', onSelected: () => setState(() => _filter = 'ACTIVE')),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Off Duty Safety Warning Banner
        if (isOffDuty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: DriverColors.warningContainer,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: DriverColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are currently ${widget.driver.status.replaceAll('_', ' ')}. Switch to AVAILABLE on the Dashboard to acknowledge and start trips.',
                    style: DriverTextStyles.telemetryMicro.copyWith(
                      color: DriverColors.onWarningContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Assignments List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 48, color: DriverColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No Matching Assignments', style: DriverTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text('All assignments for this filter are completed or unavailable.', style: DriverTextStyles.bodySmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final booking = list[index];
                    return AssignmentCard(
                      booking: booking,
                      isDriverOffDuty: isOffDuty,
                      onAcknowledge: () {
                        widget.onAdvance(booking, 'PICKUP_STARTED');
                        widget.onOpenTrip(booking);
                      },
                      onReject: widget.onRejectAssignment == null ? null : () => widget.onRejectAssignment!(booking),
                      onViewDetails: () => widget.onOpenTrip(booking),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DriverColors.primaryContainer : DriverColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: DriverTextStyles.telemetryMicro.copyWith(
            color: isSelected ? Colors.white : DriverColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 9.5,
          ),
        ),
      ),
    );
  }
}
