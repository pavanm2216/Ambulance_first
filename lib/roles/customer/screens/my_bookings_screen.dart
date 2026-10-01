import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_card.dart';
import '../../../shared/widgets/aeromed_page.dart' hide AeroMedEmptyState;
import '../../../shared/widgets/aeromed_ui_states.dart';
import 'active_trip_screen.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({
    super.key,
    required this.bookings,
    required this.onOpenTrip,
    required this.onCancel,
    required this.onBookAgain,
    required this.onAdvance,
    required this.onViewQuotation,
  });

  final List<Booking> bookings;
  final void Function(Booking booking) onOpenTrip;
  final void Function(Booking booking, String reason) onCancel;
  final void Function(Booking booking) onBookAgain;
  final void Function(Booking booking) onAdvance;
  final void Function(Booking booking) onViewQuotation;

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  String _tab = 'all';
  String _query = '';

  List<Booking> get _filtered {
    final q = _query.toLowerCase();
    return widget.bookings.where((booking) {
      final matchesTab = switch (_tab) {
        'active' => booking.isActive,
        'upcoming' => !booking.isCompleted && !booking.isCancelled,
        'completed' => booking.isCompleted,
        _ => true,
      };
      final matchesQuery = q.isEmpty ||
          booking.id.toLowerCase().contains(q) ||
          booking.patientName.toLowerCase().contains(q) ||
          booking.pickup.toLowerCase().contains(q) ||
          booking.destination.toLowerCase().contains(q);
      return matchesTab && matchesQuery;
    }).toList();
  }

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _simulateRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AeroMedPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AeroMedPageHeader(
                  title: 'My Bookings',
                  subtitle: 'View your ambulance requests, quotations and completed trips.',
                ),
              ),
              IconButton(
                tooltip: 'Refresh bookings',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: _isLoading ? null : _simulateRefresh,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText: 'Search Booking ID, patient, pickup or destination',
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tabPill('All (${widget.bookings.length})', 'all'),
              _tabPill('Active (${widget.bookings.where((b) => b.isActive).length})', 'active'),
              _tabPill('Upcoming (${widget.bookings.where((b) => !b.isCompleted && !b.isCancelled).length})', 'upcoming'),
              _tabPill('Completed (${widget.bookings.where((b) => b.isCompleted).length})', 'completed'),
            ]),
          ),
          const SizedBox(height: 14),
          if (_isLoading) ...[
            const AeroMedSkeletonCard(),
            const AeroMedSkeletonCard(),
          ] else if (_query.isNotEmpty && _filtered.isEmpty)
            AeroMedNoSearchResultsState(
              query: _query,
              onClearSearch: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            )
          else if (_filtered.isEmpty)
            AeroMedEmptyState(
              title: _tab == 'active'
                  ? 'No Active Trips'
                  : _tab == 'completed'
                      ? 'No Completed Trips'
                      : 'No Bookings Yet',
              message: _tab == 'active'
                  ? 'You do not have any ambulances en route right now.'
                  : _tab == 'completed'
                      ? 'Your past ambulance and medical transport records will appear here.'
                      : 'Submit an emergency or scheduled ambulance booking request to get started.',
              icon: _tab == 'active'
                  ? Icons.near_me_disabled_outlined
                  : Icons.medical_services_outlined,
            )
          else
            ..._filtered.map((booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BookingTile(
                    booking: booking,
                    onDetails: () => _details(context, booking),
                    onViewQuotation: () => widget.onViewQuotation(booking),
                    onCancel: () => _cancel(context, booking),
                    onBookAgain: () => widget.onBookAgain(booking),
                    onAdvance: () => widget.onAdvance(booking),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _tabPill(String label, String value) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(label: Text(label), selected: _tab == value, onSelected: (_) => setState(() => _tab = value)),
      );

  void _cancel(BuildContext context, Booking booking) {
    if (!booking.canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This booking can no longer be cancelled because the trip has progressed.')));
      return;
    }
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel ${booking.id}?'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Cancellation reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep booking')),
          ElevatedButton(onPressed: () { if (controller.text.trim().isEmpty) return; Navigator.pop(context); widget.onCancel(booking, controller.text.trim()); }, child: const Text('Cancel booking')),
        ],
      ),
    );
  }

  void _details(BuildContext context, Booking booking) {
    final requirements = [
      if (booking.oxygenRequired) 'Oxygen',
      if (booking.icuRequired) 'ICU',
      if (booking.ventilatorRequired) 'Ventilator',
      if (booking.cardiacMonitorRequired) 'Cardiac monitoring',
      if (booking.stretcherRequired) 'Stretcher',
      if (booking.wheelchairRequired) 'Wheelchair',
      if (booking.doctorRequired) 'Doctor',
      if (booking.emtRequired) 'EMT',
    ];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(booking.id),
        content: SingleChildScrollView(child: Text(
          'Status: ${booking.customerStatusLabel}\n'
          'Transport: ${booking.transportModeLabel}\n'
          'Patient: ${booking.patientName} (${booking.patientAge} yrs, ${booking.patientGender})\n\n'
          'Pickup: ${booking.pickup}\nDestination: ${booking.destination}\n'
          'Preferred: ${booking.date} • ${booking.time}\n\n'
          'Medical support: ${requirements.isEmpty ? 'None specified' : requirements.join(', ')}\n'
          'Quotation: ${booking.quotation?.id ?? 'Not generated yet'}\nInvoice: ${booking.invoice?.id ?? 'Not generated yet'}'
          '${booking.isHomeService ? '\n\nHome Service Billing\n'
              'Service: ${booking.homeServiceName}\n'
              'Visit charge: ${booking.visitCharge.toStringAsFixed(0)}\n'
              'Hourly rate: ${booking.hourlyRate.toStringAsFixed(0)}/hr after first hour\n'
              'Hours completed: ${booking.serviceHours > 0 ? booking.serviceHours.toStringAsFixed(1) : 'Pending'}\n'
              'Condition: ${booking.serviceCondition}\n'
              'Billing status: ${booking.homeServiceBillingStatus}\n'
              'Current total: ${booking.formattedAmount}' : ''}',
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onDetails, required this.onViewQuotation, required this.onCancel, required this.onBookAgain, required this.onAdvance});

  final Booking booking;
  final VoidCallback onDetails;
  final VoidCallback onViewQuotation;
  final VoidCallback onCancel;
  final VoidCallback onBookAgain;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final status = AppColors.statusColors(booking.isCompleted ? 'Completed' : booking.isCancelled ? 'Cancelled' : booking.customerStatusLabel);
    return AeroMedCard(
      shadow: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(booking.id, style: AppTextStyles.cardTitle)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: status.$1, borderRadius: BorderRadius.circular(18)), child: Text(booking.customerStatusLabel, style: AppTextStyles.caption.copyWith(color: status.$2, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        _locationLine(Icons.radio_button_checked_rounded, booking.pickup),
        _locationLine(Icons.location_on_rounded, booking.destination),
        const SizedBox(height: 4),
        Text(
          booking.isHomeService
              ? '${booking.homeServiceName} • ${booking.date} • ${booking.time}'
              : '${booking.patientName} • ${booking.date} • ${booking.time}',
          style: AppTextStyles.supporting,
        ),
        if (booking.isHomeService) ...[
          const SizedBox(height: 5),
          Text(
            'Visit ₹${booking.visitCharge.toStringAsFixed(0)} • ${booking.hourlyRate.toStringAsFixed(0)}/hr after first hour',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 3),
          Text(
            booking.homeServiceBillingStatus,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(children: [Text(booking.transportModeLabel, style: AppTextStyles.supportingStrong), const Spacer(), if (booking.amount > 0 || booking.quotation != null || booking.invoice != null) Text(booking.formattedAmount, style: AppTextStyles.cardTitle)]),
        if (booking.status == 'CUSTOMER_ACCEPTED')
          _responseNote('Quotation accepted. Waiting for ambulance allocation.', Icons.check_circle_outline_rounded),
        if (booking.status == 'CUSTOMER_REJECTED')
          _responseNote('Quotation cancelled. Reason: ${booking.quotation?.rejectionReason.isEmpty ?? true ? 'No reason provided' : booking.quotation!.rejectionReason}', Icons.info_outline_rounded),
        const Divider(height: 18),
        Wrap(spacing: 7, runSpacing: 7, children: [
          OutlinedButton.icon(onPressed: onDetails, icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('Details')),
          if (booking.quotation != null && booking.hasPendingQuotation) OutlinedButton.icon(onPressed: onViewQuotation, icon: const Icon(Icons.receipt_long_outlined, size: 16), label: const Text('View Quotation')),
          if (booking.quotation != null && booking.hasPendingQuotation) ElevatedButton.icon(onPressed: onAdvance, icon: const Icon(Icons.check_rounded, size: 16), label: const Text('Accept')),
          if (booking.canTrack)
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ActiveTripPage(booking: booking)),
              ),
              icon: const Icon(Icons.gps_fixed_rounded, size: 16),
              label: const Text('Track'),
            ),
          if (booking.isCompleted) OutlinedButton.icon(onPressed: onDetails, icon: const Icon(Icons.receipt_long_outlined, size: 16), label: const Text('View Invoice')),
          if (booking.canCancel) TextButton.icon(onPressed: onCancel, icon: const Icon(Icons.close_rounded, size: 16), label: const Text('Cancel')),
          if (booking.isCompleted) TextButton.icon(onPressed: onBookAgain, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Book Again')),
          if (booking.isHomeService && booking.status == 'HOME_SERVICE_BOOKED')
            TextButton.icon(
              onPressed: onAdvance,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Start Visit'),
            ),
          if (booking.isHomeService && booking.status == 'HOME_SERVICE_IN_PROGRESS')
            ElevatedButton.icon(
              onPressed: onAdvance,
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text('Complete & Bill'),
            ),
        ]),
      ]),
    );
  }

  Widget _responseNote(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 7),
            Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700))),
          ],
        ),
      );

  Widget _locationLine(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [Icon(icon, size: 13, color: AppColors.primary), const SizedBox(width: 6), Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.supporting))]),
      );
}
