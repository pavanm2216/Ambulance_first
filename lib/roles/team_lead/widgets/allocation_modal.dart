
import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/supabase_resource_repository.dart';
import '../../../core/services/supabase_workflow_repository.dart';
import '../theme/team_lead_theme.dart';

/// Full-screen allocation page used from the Team Lead Allocation Queue.
///
/// All roster data comes from the live Supabase tables:
/// - public.ambulances
/// - public.drivers
/// - public.medical_crew
/// - public.doctors
///
/// Allocation itself is performed by the canonical allocate_booking RPC.
class AllocationModal extends StatefulWidget {
  const AllocationModal({
    super.key,
    required this.booking,
  });

  final Booking booking;

  static Future<bool?> show(
    BuildContext context, {
    required Booking booking,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllocationModal(
          booking: booking,
        ),
      ),
    );
  }

  @override
  State<AllocationModal> createState() => _AllocationModalState();
}

class _AllocationModalState extends State<AllocationModal> {
  final SupabaseWorkflowRepository _workflow =
      SupabaseWorkflowRepository();
  final SupabaseResourceRepository _resources =
      SupabaseResourceRepository();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _ambulances = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _medicalCrew = [];
  List<Map<String, dynamic>> _doctors = [];

  String? _ambulanceId;
  String? _medicalCrewId;
  String? _doctorId;


  Booking get booking => widget.booking;

  bool get _customerAccepted =>
      booking.status == 'CUSTOMER_ACCEPTED';

  bool get _doctorRequired => booking.doctorRequired;

  bool get _medicalCrewRequired => booking.emtRequired;

  @override
  void initState() {
    super.initState();
    _loadRosters();
  }


  Future<void> _loadRosters() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        _resources.getAmbulances(),
        _resources.getDrivers(),
        _resources.getEmtProfiles(),
        _resources.getDoctors(),
      ]);
      if (!mounted) return;
      final ambulances = _maps(results[0]);
      final drivers = _maps(results[1]);
      final crew = _maps(results[2]);
      final doctors = _maps(results[3]);
      setState(() {
        // Keep every ambulance visible so unavailable or incompatible rows
        // show their actual reason instead of being silently mislabelled.
        _ambulances = ambulances;
        _drivers = drivers;
        _medicalCrew = crew;
        _doctors = doctors.where(_resourceIsAvailable).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Unable to load Team Lead resources from Supabase: $e'; });
    }
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    if (rows is! List) {
      return <Map<String, dynamic>>[];
    }

    return rows
        .whereType<Map>()
        .map(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList();
  }

  bool _isAvailable(String? value) {
    final status = (value ?? '').trim().toUpperCase();

    return status == 'AVAILABLE' ||
        status == 'READY' ||
        status == 'ON_DUTY' ||
        status == 'ONLINE';
  }

  bool _resourceIsAvailable(Map<String, dynamic> resource) {
    return _isAvailable('${resource['status'] ?? ''}');
  }

  Map<String, dynamic>? _pairedDriverForAmbulance(
    Map<String, dynamic> ambulance,
  ) {
    final currentDriverId = '${ambulance['current_driver_id'] ?? ''}'.trim();
    if (currentDriverId.isNotEmpty) {
      return _find(_drivers, currentDriverId);
    }

    final vehicleNumber = '${ambulance['vehicle_number'] ?? ''}'
        .trim()
        .toLowerCase();
    if (vehicleNumber.isEmpty) return null;

    for (final driver in _drivers) {
      final assignedVehicle =
          '${driver['assigned_ambulance_number'] ?? ''}'.trim().toLowerCase();
      if (assignedVehicle == vehicleNumber) return driver;
    }
    return null;
  }

  String? _ambulanceIneligibility(Map<String, dynamic> ambulance) {
    final status = '${ambulance['status'] ?? ''}'.trim().toUpperCase();
    if (!SupabaseResourceRepository.isAmbulanceAvailable(ambulance)) {
      return status.isEmpty
          ? 'Ambulance availability is not recorded.'
          : 'Ambulance status is ${status.replaceAll('_', ' ')}.';
    }

    // The allocation RPC requires an exact ambulance-service subtype match.
    // Compare normalized values because the operational feed may render a
    // subtype as TYPE-B while the stored value is TYPE_B.
    final requiredSubtype = _normalizedSubtype(booking.serviceSubtype);
    final ambulanceSubtype = _normalizedSubtype(
      ambulance['service_subtype'] ?? ambulance['subtype'],
    );
    if (requiredSubtype.isNotEmpty && ambulanceSubtype != requiredSubtype) {
      return 'Ambulance subtype ${_subtypeLabel(ambulanceSubtype)} does not '
          'match required ${_subtypeLabel(requiredSubtype)}.';
    }

    final pairedDriver = _pairedDriverForAmbulance(ambulance);
    if (pairedDriver == null) {
      return 'No driver is paired with this ambulance.';
    }
    if (!_resourceIsAvailable(pairedDriver) ||
        pairedDriver['assigned_booking_id'] != null) {
      final driverStatus =
          '${pairedDriver['status'] ?? 'UNKNOWN'}'.trim().toUpperCase();
      return 'Paired driver is not available (status: ${driverStatus.replaceAll('_', ' ')}).';
    }

    final missing = <String>[];
    void requireCapability(bool required, String field, String label) {
      if (required && ambulance[field] != true) missing.add(label);
    }

    requireCapability(booking.oxygenRequired, 'oxygen_capable', 'oxygen');
    requireCapability(booking.icuRequired, 'icu_capable', 'ICU');
    requireCapability(booking.ventilatorRequired, 'ventilator_capable', 'ventilator');
    requireCapability(booking.cardiacMonitorRequired, 'cardiac_monitor_capable', 'cardiac monitor');
    requireCapability(booking.stretcherRequired, 'stretcher_capable', 'stretcher');
    requireCapability(booking.wheelchairRequired, 'wheelchair_capable', 'wheelchair');
    requireCapability(booking.pediatricPatient, 'pediatric_icu_capable', 'pediatric ICU');

    return missing.isEmpty
        ? null
        : 'Missing required capability: ${missing.join(', ')}.';
  }

  String _normalizedSubtype(dynamic value) => '$value'
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  String _subtypeLabel(String value) =>
      value.isEmpty ? 'UNSPECIFIED' : value.replaceAll('_', ' ');

  Future<void> _confirmAllocation() async {
    if (!_customerAccepted) {
      _showMessage(
        'Allocation is locked until the customer accepts the quotation.',
        isError: true,
      );
      return;
    }

    if (_ambulanceId == null) {
      _showMessage(
        'Select a compatible ambulance.',
        isError: true,
      );
      return;
    }

    final selectedAmbulance = _find(_ambulances, _ambulanceId);
    final ambulanceIssue = selectedAmbulance == null
        ? 'Selected ambulance is no longer available.'
        : _ambulanceIneligibility(selectedAmbulance);
    if (ambulanceIssue != null) {
      _showMessage(ambulanceIssue, isError: true);
      return;
    }

    final selectedDriver = selectedAmbulance == null
        ? null
        : _pairedDriverForAmbulance(selectedAmbulance);
    if (selectedDriver == null ||
        !_resourceIsAvailable(selectedDriver) ||
        selectedDriver['assigned_booking_id'] != null) {
      _showMessage(
        'The selected ambulance does not have an available paired driver.',
        isError: true,
      );
      return;
    }

    final selectedCrew = _find(_medicalCrew, _medicalCrewId);
    if (_medicalCrewRequired &&
        (selectedCrew == null || !_resourceIsAvailable(selectedCrew))) {
      _showMessage(
        'Select an EMT / medical crew member.',
        isError: true,
      );
      return;
    }

    if (_doctorRequired && _doctorId == null) {
      _showMessage(
        'Select an available doctor.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _workflow.allocateBooking(
        bookingId: booking.id,
        ambulanceId: _ambulanceId!,
        driverId: '${selectedDriver['id']}',
        doctorId: _doctorId,
        emtId: _medicalCrewId,
      );

      if (!mounted) return;

      _showMessage(
        'Allocation completed successfully.',
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = error.toString();
      });

      _showMessage(
        'Allocation failed: $error',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAmbulance = _find(
      _ambulances,
      _ambulanceId,
    );
    final selectedDriver = selectedAmbulance == null
        ? null
        : _pairedDriverForAmbulance(selectedAmbulance);
    final selectedCrew = _find(
      _medicalCrew,
      _medicalCrewId,
    );
    final selectedDoctor = _find(
      _doctors,
      _doctorId,
    );

    return Scaffold(
      backgroundColor: TeamLeadTheme.surfaceLow,
      appBar: AppBar(
        title: const Text('Allocation Details'),
        backgroundColor: TeamLeadTheme.surfaceLowest,
        foregroundColor: TeamLeadTheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadRosters,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _bookingHeader(),
                    const SizedBox(height: 16),
                    if (!_customerAccepted)
                      _lockedBanner(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _errorBanner(_error!),
                    ],
                    const SizedBox(height: 16),
                    _requirementsCard(),
                    const SizedBox(height: 16),
                    _resourceSection(
                      title: '1. Ambulance',
                      subtitle:
                          'Live ambulances from Supabase are shown. Only AVAILABLE, compatible units can be selected; the allocation RPC rechecks every rule.',
                      icon: Icons.local_shipping_rounded,
                      child: _ambulanceList(),
                    ),
                    const SizedBox(height: 16),
                    _resourceSection(
                      title: '2. Driver',
                      subtitle:
                          'The driver paired with the selected ambulance is assigned automatically.',
                      icon: Icons.badge_rounded,
                      child: _assignedDriverCard(selectedAmbulance),
                    ),
                    if (_medicalCrewRequired) ...[
                      const SizedBox(height: 16),
                      _resourceSection(
                        title: '3. EMT / Medical Crew',
                        subtitle:
                            'Live available medical crew from public.medical_crew are shown.',
                        icon: Icons.medical_services_rounded,
                        child: _crewList(),
                      ),
                    ],
                    if (_doctorRequired) ...[
                      const SizedBox(height: 16),
                      _resourceSection(
                        title: '4. Attending Doctor',
                        subtitle:
                            'Live available doctors from public.doctors are shown. Specialization validation is enforced by the allocation RPC.',
                        icon: Icons.local_hospital_rounded,
                        child: _doctorList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _selectionSummary(
                      selectedAmbulance,
                      selectedDriver,
                      selectedCrew,
                      selectedDoctor,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed:
                          _saving ? null : _confirmAllocation,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            TeamLeadTheme.operationalEmerald,
                        minimumSize:
                            const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_rounded,
                            ),
                      label: Text(
                        _saving
                            ? 'Allocating...'
                            : _customerAccepted
                                ? 'Confirm Allocation & Dispatch'
                                : 'Waiting for Customer Acceptance',
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _bookingHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: TeamLeadTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                booking.id,
                style: TeamLeadTheme.telemetryPrimary(
                  color: TeamLeadTheme.primaryDark,
                  weight: FontWeight.w800,
                ),
              ),
              _statusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.patientName.isEmpty
                ? 'Emergency Patient'
                : booking.patientName,
            style: TeamLeadTheme.titleMedium(
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${booking.transportModeLabel} • '
            '${booking.serviceCategory} • '
            '${(booking.serviceSubtype ?? '').isEmpty ? 'Standard' : (booking.serviceSubtype ?? 'Standard')}',
            style: TeamLeadTheme.small(
              color: TeamLeadTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            Icons.person_outline_rounded,
            'Customer',
            booking.customerName,
          ),
          _infoRow(
            Icons.phone_outlined,
            'Phone',
            booking.mobileNumber,
          ),
          _infoRow(
            Icons.trip_origin_rounded,
            'Pickup',
            booking.pickup,
          ),
          _infoRow(
            Icons.location_on_outlined,
            'Destination',
            booking.destination,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: TeamLeadTheme.primary,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.onSurface,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TeamLeadTheme.crimsonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              TeamLeadTheme.medicalCrimson.withValues(
            alpha: .35,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: TeamLeadTheme.medicalCrimson,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resource allocation is locked. '
              'The customer must accept the quotation before '
              'ambulance, driver, medical crew or doctor can be dispatched.',
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.crimsonText,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: .25),
        ),
      ),
      child: Text(
        error,
        style: TeamLeadTheme.small(
          color: Colors.red.shade800,
        ),
      ),
    );
  }

  Widget _requirementsCard() {
    final requirements = <String>[];

    if (booking.oxygenRequired) {
      requirements.add('Oxygen');
    }
    if (booking.icuRequired) {
      requirements.add('ICU');
    }
    if (booking.ventilatorRequired) {
      requirements.add('Ventilator');
    }
    if (booking.cardiacMonitorRequired) {
      requirements.add('Cardiac Monitor');
    }
    if (booking.stretcherRequired) {
      requirements.add('Stretcher');
    }
    if (booking.wheelchairRequired) {
      requirements.add('Wheelchair');
    }
    if (booking.pediatricPatient) {
      requirements.add('Pediatric');
    }
    if (booking.emtRequired) {
      requirements.add('Medical Crew');
    }
    if (booking.doctorRequired) {
      requirements.add(
        (booking.doctorSpecialization ?? '').isEmpty
            ? 'Doctor'
            : 'Doctor: ${booking.doctorSpecialization}',
      );
    }

    return _card(
      title: 'Clinical Requirements',
      icon: Icons.fact_check_outlined,
      child: requirements.isEmpty
          ? Text(
              'No additional clinical capability requirement recorded.',
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.textMuted,
              ),
            )
          : Wrap(
              spacing: 7,
              runSpacing: 7,
              children: requirements
                  .map(
                    (item) => _requirementChip(item),
                  )
                  .toList(),
            ),
    );
  }

  Widget _resourceSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return _card(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: child,
    );
  }

  Widget _ambulanceList() {
    if (_ambulances.isEmpty) {
      return _emptyResource(
        'No ambulance is currently recorded in Supabase.',
      );
    }

    return Column(
      children: _ambulances.map((ambulance) {
        final id = '${ambulance['id']}';
        final selected = _ambulanceId == id;
        final ineligibility = _ambulanceIneligibility(ambulance);

        final vehicle =
            '${ambulance['vehicle_number'] ?? 'Vehicle'}';
        final display =
            '${ambulance['display_name'] ?? ''}'
                .trim();
        final category =
            '${ambulance['category'] ?? ''}';
        final subtype =
            '${ambulance['service_subtype'] ?? ''}';

        return _selectableTile(
          selected: selected,
          onTap: _customerAccepted && ineligibility == null
              ? () {
                  setState(() {
                    _ambulanceId = id;
                  });
                }
              : null,
          icon: Icons.local_shipping_rounded,
          title: display.isEmpty
              ? vehicle
              : display,
          subtitle:
              '$vehicle • $category${subtype.isEmpty ? '' : ' • $subtype'}',
          trailing: _ambulanceTrailing(ambulance, ineligibility),
        );
      }).toList(),
    );
  }

  Widget _ambulanceTrailing(
    Map<String, dynamic> ambulance,
    String? ineligibility,
  ) {
    final status = '${ambulance['status'] ?? 'UNKNOWN'}'.trim().toUpperCase();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBadge(status),
          const SizedBox(height: 4),
          _capabilitySummary(ambulance),
          if (ineligibility != null) ...[
            const SizedBox(height: 4),
            Text(
              ineligibility,
              textAlign: TextAlign.right,
              style: TeamLeadTheme.telemetryMicro(
                color: TeamLeadTheme.medicalCrimson,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _assignedDriverCard(Map<String, dynamic>? ambulance) {
    if (ambulance == null) {
      return _emptyResource(
        'Select an ambulance to see its paired driver.',
      );
    }

    final driver = _pairedDriverForAmbulance(ambulance);
    if (driver == null) {
      return _emptyResource(
        'No driver is paired with this ambulance in Supabase.',
      );
    }

    final status = '${driver['status'] ?? 'UNKNOWN'}'.trim().toUpperCase();
    return _selectableTile(
      selected: true,
      onTap: null,
      icon: Icons.badge_rounded,
      title: '${driver['name'] ?? driver['full_name'] ?? 'Unnamed Driver'}',
      subtitle:
          '${driver['phone'] ?? 'No phone'} • '
          'License: ${driver['license_number'] ?? 'Not provided'}',
      trailing: _statusBadge(status),
    );
  }

  Widget _crewList() {
    if (_medicalCrew.isEmpty) {
      return _emptyResource(
        'No available medical crew member is currently recorded in Supabase.',
      );
    }

    return Column(
      children: _medicalCrew.map((crew) {
        final id = '${crew['id']}';
        final selected = _medicalCrewId == id;

        return _selectableTile(
          selected: selected && _resourceIsAvailable(crew),
          onTap: _customerAccepted && _resourceIsAvailable(crew)
              ? () {
                  setState(() {
                    _medicalCrewId = id;
                  });
                }
              : null,
          icon: Icons.medical_services_rounded,
          title:
              '${crew['full_name'] ?? 'Unnamed Crew'}',
          subtitle:
              '${crew['crew_type'] ?? 'Medical Crew'} • '
              '${crew['certification'] ?? 'Certification not provided'}',
          trailing: _statusBadge(
            '${crew['status'] ?? 'UNKNOWN'}'.trim().toUpperCase(),
          ),
        );
      }).toList(),
    );
  }

  Widget _doctorList() {
    if (_doctors.isEmpty) {
      return _emptyResource(
        'No available doctor is currently recorded in Supabase.',
      );
    }

    return Column(
      children: _doctors.map((doctor) {
        final id = '${doctor['id']}';
        final selected = _doctorId == id;

        return _selectableTile(
          selected: selected,
          onTap: _customerAccepted
              ? () {
                  setState(() {
                    _doctorId = id;
                  });
                }
              : null,
          icon: Icons.local_hospital_rounded,
          title:
              'Dr. ${doctor['full_name'] ?? 'Unknown'}',
          subtitle:
              '${doctor['specialization'] ?? 'Specialization not provided'}',
          trailing: Text(
            '${doctor['phone'] ?? 'No phone'}',
            style: TeamLeadTheme.small(
              color: TeamLeadTheme.textMuted,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectableTile({
    required bool selected,
    required VoidCallback? onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? TeamLeadTheme.primaryContainer
                    .withValues(alpha: .45)
                : TeamLeadTheme.surfaceLow,
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? TeamLeadTheme.primary
                  : TeamLeadTheme.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TeamLeadTheme.primaryContainer
                      .withValues(alpha: .55),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: TeamLeadTheme.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeamLeadTheme.body(
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TeamLeadTheme.small(
                        color:
                            TeamLeadTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? TeamLeadTheme.primary
                    : TeamLeadTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capabilitySummary(
    Map<String, dynamic> ambulance,
  ) {
    final values = <String>[];

    if (ambulance['oxygen_capable'] == true) {
      values.add('O₂');
    }
    if (ambulance['icu_capable'] == true) {
      values.add('ICU');
    }
    if (ambulance['ventilator_capable'] == true) {
      values.add('VENT');
    }
    if (ambulance['pediatric_icu_capable'] == true) {
      values.add('PED');
    }
    if (ambulance['cardiac_monitor_capable'] == true) {
      values.add('CARD');
    }

    return Text(
      values.isEmpty ? 'Standard' : values.join(' • '),
      style: TeamLeadTheme.telemetryMicro(
        color: TeamLeadTheme.primaryDark,
        weight: FontWeight.w700,
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _selectionSummary(
    Map<String, dynamic>? ambulance,
    Map<String, dynamic>? driver,
    Map<String, dynamic>? crew,
    Map<String, dynamic>? doctor,
  ) {
    return _card(
      title: 'Dispatch Selection',
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        children: [
          _summaryRow(
            'Ambulance',
            ambulance == null
                ? 'Not selected'
                : '${ambulance['vehicle_number'] ?? ambulance['display_name'] ?? 'Selected'}',
          ),
          _summaryRow(
            'Driver',
            driver == null
                ? 'Not selected'
                : '${driver['full_name'] ?? 'Selected'}',
          ),
          if (_medicalCrewRequired)
            _summaryRow(
              'Medical Crew',
              crew == null
                  ? 'Not selected'
                  : '${crew['full_name'] ?? 'Selected'}',
            ),
          if (_doctorRequired)
            _summaryRow(
              'Doctor',
              doctor == null
                  ? 'Not selected'
                  : 'Dr. ${doctor['full_name'] ?? 'Selected'}',
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TeamLeadTheme.small(
              color: TeamLeadTheme.onSurface,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: TeamLeadTheme.primaryContainer
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: TeamLeadTheme.primary
              .withValues(alpha: .15),
        ),
      ),
      child: Text(
        text,
        style: TeamLeadTheme.small(
          color: TeamLeadTheme.primaryDark,
          weight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _statusColor(status)
            .withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TeamLeadTheme.telemetryMicro(
          color: _statusColor(status),
          weight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CUSTOMER_ACCEPTED':
        return TeamLeadTheme.operationalEmerald;
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
        return TeamLeadTheme.primary;
      case 'DRIVER_REJECTED':
      case 'CUSTOMER_REJECTED':
        return TeamLeadTheme.medicalCrimson;
      case 'SENT_TO_TEAM_LEAD':
      case 'ALLOCATION_PENDING':
      case 'VERIFIED':
      default:
        return TeamLeadTheme.primary;
    }
  }

  Widget _card({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TeamLeadTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: TeamLeadTheme.primaryDark,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TeamLeadTheme.body(
                        weight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TeamLeadTheme.small(
                          color: TeamLeadTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyResource(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TeamLeadTheme.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TeamLeadTheme.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: TeamLeadTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TeamLeadTheme.small(
                color: TeamLeadTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _find(
    List<Map<String, dynamic>> rows,
    String? id,
  ) {
    if (id == null) return null;

    for (final row in rows) {
      if ('${row['id']}' == id) {
        return row;
      }
    }

    return null;
  }
}
