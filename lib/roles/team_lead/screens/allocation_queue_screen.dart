
import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../store/team_lead_store.dart';
import '../widgets/allocation_modal.dart';

class AllocationQueueScreen extends StatefulWidget {
  const AllocationQueueScreen({
    super.key,
    this.initialSearch = '',
  });

  final String initialSearch;

  @override
  State<AllocationQueueScreen> createState() => _AllocationQueueScreenState();
}

class _AllocationQueueScreenState extends State<AllocationQueueScreen> {
  final TeamLeadStore _store = TeamLeadStore.instance;

  bool _loading = true;
  String? _error;
  String _search = '';
  String _status = 'ALL';
  bool _criticalOnly = false;
  List<Booking> _bookings = [];

  static const _statuses = <String>[
    'ALL',
    'SENT_TO_TEAM_LEAD',
    'VERIFIED',
    'ALLOCATION_PENDING',
    'CUSTOMER_ACCEPTED',
    'DRIVER_REJECTED',
    'ASSIGNED',
  ];

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch;
    _store.addListener(_onStoreChanged);
    _syncFromStore();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _syncFromStore();
  }

  void _syncFromStore() {
    setState(() {
      _bookings = List<Booking>.from(_store.allBookings);
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await _store.refreshFromBackend();
      if (!mounted) return;

      setState(() {
        _bookings = List<Booking>.from(_store.allBookings);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Booking> get _filtered {
    final q = _search.trim().toLowerCase();

    return _bookings.where((booking) {
      final status = booking.status.toUpperCase();

      if (_status != 'ALL' && status != _status) {
        return false;
      }

      if (_status == 'ALL' &&
          !{
            'SENT_TO_TEAM_LEAD',
            'VERIFIED',
            'ALLOCATION_PENDING',
            'CUSTOMER_ACCEPTED',
            'DRIVER_REJECTED',
            'ASSIGNED',
          }.contains(status)) {
        return false;
      }

      if (_criticalOnly &&
          booking.priority.toUpperCase() != 'CRITICAL') {
        return false;
      }

      if (q.isEmpty) return true;

      return booking.id.toLowerCase().contains(q) ||
          booking.patientName.toLowerCase().contains(q) ||
          booking.customerName.toLowerCase().contains(q) ||
          booking.pickup.toLowerCase().contains(q) ||
          booking.destination.toLowerCase().contains(q);
    }).toList();
  }

  String _requirements(Booking b) {
    final items = <String>[];

    if (b.oxygenRequired) items.add('OXYGEN');
    if (b.icuRequired) items.add('ICU');
    if (b.ventilatorRequired) items.add('VENTILATOR');
    if (b.cardiacMonitorRequired) items.add('CARDIAC');
    if (b.stretcherRequired) items.add('STRETCHER');
    if (b.wheelchairRequired) items.add('WHEELCHAIR');
    if (b.pediatricPatient) items.add('PEDIATRIC');
    if (b.doctorRequired) items.add('DOCTOR');
    if (b.emtRequired) items.add('EMT');
    if (b.medicalAttendantRequired) items.add('ATTENDANT');

    return items.isEmpty ? 'STANDARD' : items.join(' • ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CUSTOMER_ACCEPTED':
        return const Color(0xFF087F5B);
      case 'ASSIGNED':
        return const Color(0xFF006A9B);
      case 'DRIVER_REJECTED':
        return const Color(0xFFC92A2A);
      default:
        return const Color(0xFFB26A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Allocation Queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _filters(),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${rows.length} cases in live allocation queue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(
                              child: Text(
                                'No live bookings require allocation.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                24,
                              ),
                              itemCount: rows.length,
                              itemBuilder: (_, index) =>
                                  _bookingCard(rows[index]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) =>
                setState(() => _search = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search booking, patient, customer or route',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final value = _statuses[index];
                      return ChoiceChip(
                        label: Text(
                          value.replaceAll('_', ' '),
                        ),
                        selected: _status == value,
                        onSelected: (_) =>
                            setState(() => _status = value),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Critical'),
                selected: _criticalOnly,
                onSelected: (value) =>
                    setState(() => _criticalOnly = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(Booking booking) {
    final accepted =
        booking.status.toUpperCase() == 'CUSTOMER_ACCEPTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                _badge(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${booking.patientName} • '
              '${booking.serviceCategory}'
              '${booking.serviceSubtype == null ? '' : ' • ${booking.serviceSubtype}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              '${booking.pickup} → ${booking.destination}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '${booking.distanceKm.toStringAsFixed(2)} km • '
              '${_requirements(booking)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Basic fare ₹${booking.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (booking.amount > 0)
                  Text(
                    '₹${booking.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!accepted)
              const Text(
                'Allocation locked until customer accepts the quotation.',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result =
                        await AllocationModal.show(
                      context,
                      booking: booking,
                    );

                    if (result == true) {
                      await _load();
                    }
                  },
                  icon: const Icon(
                    Icons.local_shipping_outlined,
                  ),
                  label: const Text('Open Allocation'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Unable to load allocation queue',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
