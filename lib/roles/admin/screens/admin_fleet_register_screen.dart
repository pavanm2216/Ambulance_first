import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import 'admin_shared.dart';

class AdminFleetRegisterScreen extends StatefulWidget {
  const AdminFleetRegisterScreen({
    super.key,
    required this.store,
    required this.onFinished,
  });

  final AdminStore store;
  final VoidCallback onFinished;

  @override
  State<AdminFleetRegisterScreen> createState() =>
      _AdminFleetRegisterScreenState();
}

class _AdminFleetRegisterScreenState extends State<AdminFleetRegisterScreen> {
  int _currentStep = 1;
  bool _isLoadingDrivers = false;
  String? _driverLoadError;

  // Step 1: Vehicle Info
  final _callSignCtrl = TextEditingController();
  final _cadNoCtrl = TextEditingController();
  final _platformCtrl = TextEditingController(
    text: 'Mercedes-Benz Sprinter 3500 (2024)',
  );
  // Persist the canonical service subtype used by booking allocation. The
  // dropdown renders clinician-friendly labels below.
  String _classification = 'ADVANCED_ICU';
  String _stationBase = 'Central Station (Bay 1-8)';
  final String _category = 'ROAD';

  // Step 2: Capabilities
  bool _hasO2 = true;
  bool _hasIcu = true;
  bool _hasVentilator = true;
  bool _hasPicu = false;
  bool _hasIncubator = false;
  bool _hasFreezer = false;

  // Step 3: Operations
  int _fuel = 100;
  int _o2Pressure = 200;

  // Step 4: Driver Credentialing
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _driverEmailCtrl = TextEditingController();
  final _driverLicenseCtrl = TextEditingController();
  int _driverExpYears = 5;
  String? _selectedDriverId;

  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshDriverRoster();
  }

  @override
  void dispose() {
    _callSignCtrl.dispose();
    _cadNoCtrl.dispose();
    _platformCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _driverEmailCtrl.dispose();
    _driverLicenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshDriverRoster() async {
    setState(() {
      _isLoadingDrivers = true;
      _driverLoadError = null;
    });

    try {
      await widget.store.refresh();
    } catch (error) {
      debugPrint('ADMIN FLEET DRIVER ROSTER ERROR: $error');
      if (!mounted) return;
      setState(() {
        _driverLoadError = 'Unable to load available drivers. Refresh and try again.';
      });
    }

    if (!mounted) return;
    setState(() {
      _isLoadingDrivers = false;
    });
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_currentStep == 1) {
      if (_callSignCtrl.text.trim().isEmpty || _cadNoCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Call Sign and CAD Number are required.');
        return;
      }
    } else if (_currentStep == 4) {
      if (_selectedDriverId == null || _selectedDriverId!.isEmpty) {
        setState(() => _error =
            'Select an available driver who is not already allocated to an ambulance.');
        return;
      }
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _finishRegistration();
    }
  }

  Future<void> _finishRegistration() async {
    final result = await widget.store.registerAmbulance(
      callSign: _callSignCtrl.text.trim(),
      vehicleCadNo: _cadNoCtrl.text.trim(),
      platform: _platformCtrl.text.trim(),
      classification: _classification,
      category: _category,
      stationBase: _stationBase,
      hasOxygen: _hasO2,
      hasIcu: _hasIcu,
      hasVentilator: _hasVentilator,
      hasPicu: _hasPicu,
      hasIncubator: _hasIncubator,
      hasFreezer: _hasFreezer,
      fuelPercent: _fuel,
      oxygenPressureBar: _o2Pressure,
      driverId: _selectedDriverId!,
      driverName: _driverNameCtrl.text.trim(),
      driverPhone: _driverPhoneCtrl.text.trim().isNotEmpty
          ? _driverPhoneCtrl.text.trim()
          : '+1 (555) 000-0000',
      driverEmail: _driverEmailCtrl.text.trim(),
      driverLicense: _driverLicenseCtrl.text.trim(),
      driverExperience: _driverExpYears,
    );

    if (!mounted) return;

    if (result.$1) {
      showStitchToast(context, result.$2);
      widget.onFinished();
    } else {
      setState(() => _error = result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: widget.onFinished,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register Ambulance Unit', style: StitchTheme.headlineSm()),
            Text(
              'STEP $_currentStep OF 5 · CAD ENROLLMENT',
              style: StitchTheme.labelSm(color: StitchTheme.outline),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(StitchTheme.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Row(
              children: [
                for (int i = 1; i <= 5; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? StitchTheme.primaryContainer
                            : StitchTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: StitchTheme.spaceLg),

            if (_currentStep == 1) _buildStep1VehicleInfo(),
            if (_currentStep == 2) _buildStep2Capabilities(),
            if (_currentStep == 3) _buildStep3Operations(),
            if (_currentStep == 4) _buildStep4Driver(),
            if (_currentStep == 5) _buildStep5Review(),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: StitchTheme.bodySm(
                  color: StitchTheme.error,
                  weight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 1)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchTheme.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    _currentStep == 5 ? 'Enroll Ambulance' : 'Next Step →',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1VehicleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Vehicle Identity & Classification',
          style: StitchTheme.headlineSm(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _callSignCtrl,
          decoration: const InputDecoration(
            labelText: 'Call Sign * (e.g. ECHO-01)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cadNoCtrl,
          decoration: const InputDecoration(
            labelText: 'CAD Registration No. * (e.g. MED-ICU-16)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _platformCtrl,
          decoration: const InputDecoration(labelText: 'Platform & Build Year'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _classification,
          decoration: const InputDecoration(
            labelText: 'Medical Classification',
          ),
          items: const [
            DropdownMenuItem(
              value: 'ADVANCED_ICU',
              child: Text('Type-D Mobile ICU'),
            ),
            DropdownMenuItem(
              value: 'BASIC_OXYGEN',
              child: Text('Type-B Standard BLS'),
            ),
            DropdownMenuItem(
              value: 'INTERMEDIATE_ALS',
              child: Text('Type-C Intermediate ALS'),
            ),
            DropdownMenuItem(
              value: 'PEDIATRIC_ICU',
              child: Text('Type-N Neonatal PICU'),
            ),
          ],
          onChanged: (v) =>
              setState(() => _classification = v ?? _classification),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _stationBase,
          decoration: const InputDecoration(labelText: 'Home Station Base'),
          items: const [
            DropdownMenuItem(
              value: 'Central Station (Bay 1-8)',
              child: Text('Central Station (Bay 1-8)'),
            ),
            DropdownMenuItem(
              value: 'Northside Substation',
              child: Text('Northside Substation'),
            ),
            DropdownMenuItem(
              value: 'East Metro Outpost',
              child: Text('East Metro Outpost'),
            ),
          ],
          onChanged: (v) => setState(() => _stationBase = v ?? _stationBase),
        ),
      ],
    );
  }

  Widget _buildStep2Capabilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Life Support Equipment & Capabilities',
          style: StitchTheme.headlineSm(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('High-Capacity Medical Oxygen System'),
          value: _hasO2,
          onChanged: (v) => setState(() => _hasO2 = v),
        ),
        SwitchListTile(
          title: const Text('Mobile ICU Intensive Care Station'),
          value: _hasIcu,
          onChanged: (v) => setState(() => _hasIcu = v),
        ),
        SwitchListTile(
          title: const Text('Automated Transport Ventilator'),
          value: _hasVentilator,
          onChanged: (v) => setState(() => _hasVentilator = v),
        ),
        SwitchListTile(
          title: const Text('Pediatric Intensive Care Unit (PICU)'),
          value: _hasPicu,
          onChanged: (v) => setState(() => _hasPicu = v),
        ),
        SwitchListTile(
          title: const Text('Temperature Controlled Isolette Incubator'),
          value: _hasIncubator,
          onChanged: (v) => setState(() => _hasIncubator = v),
        ),
        SwitchListTile(
          title: const Text('Mortuary Cryogenic Freezer Pod'),
          value: _hasFreezer,
          onChanged: (v) => setState(() => _hasFreezer = v),
        ),
      ],
    );
  }

  Widget _buildStep3Operations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Initial Operational Telemetry',
          style: StitchTheme.headlineSm(),
        ),
        const SizedBox(height: 16),
        Text('Initial Fuel Level: $_fuel%', style: StitchTheme.labelMd()),
        Slider(
          value: _fuel.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '$_fuel%',
          activeColor: StitchTheme.primaryContainer,
          onChanged: (v) => setState(() => _fuel = v.round()),
        ),
        const SizedBox(height: 12),
        Text(
          'Medical Oxygen Pressure: $_o2Pressure Bar (Max 200)',
          style: StitchTheme.labelMd(),
        ),
        Slider(
          value: _o2Pressure.toDouble(),
          min: 0,
          max: 200,
          divisions: 20,
          label: '$_o2Pressure Bar',
          activeColor: StitchTheme.tertiary,
          onChanged: (v) => setState(() => _o2Pressure = v.round()),
        ),
      ],
    );
  }

  Widget _buildStep4Driver() {
    final availableDrivers = widget.store.drivers
        .where((driver) {
          final role = driver.role.toUpperCase();
          final status = driver.status;
          final hasCredential =
              driver.licenseNumber?.toString().trim().isNotEmpty == true;
          final isCurrentlyAssigned = widget.store.ambulances.any(
            (ambulance) => ambulance.assignedDriverId == driver.id,
          );
          // This is the canonical Admin-to-fleet pairing. A driver may still
          // have AVAILABLE duty status, but cannot be the primary driver of a
          // second ambulance.
          final hasPrimaryAmbulance =
              driver.assignedVehicle?.trim().isNotEmpty == true;
          final hasActiveMission =
              driver.assignedMission?.trim().isNotEmpty == true;

          return role == 'DRIVER' &&
              hasCredential &&
              status == StaffStatus.available &&
              !isCurrentlyAssigned &&
              !hasPrimaryAmbulance &&
              !hasActiveMission;
        })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    dynamic selectedDriver;
    if (_selectedDriverId != null) {
      for (final driver in availableDrivers) {
        if (driver.id.toString() == _selectedDriverId) {
          selectedDriver = driver;
          break;
        }
      }
    }

    if (_selectedDriverId != null && selectedDriver == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedDriverId = null;
          _driverNameCtrl.clear();
          _driverPhoneCtrl.clear();
          _driverEmailCtrl.clear();
          _driverLicenseCtrl.clear();
          _driverExpYears = 5;
        });
      });
    }

    if (_isLoadingDrivers) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4. Primary Driver / Operator Assignment',
            style: StitchTheme.headlineSm(),
          ),
          const SizedBox(height: 12),
          const Text('Loading available drivers...'),
        ],
      );
    }

    if (_driverLoadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4. Primary Driver / Operator Assignment',
            style: StitchTheme.headlineSm(),
          ),
          const SizedBox(height: 12),
          Text(
            _driverLoadError!,
            style: StitchTheme.bodySm(color: StitchTheme.error),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _refreshDriverRoster,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. Primary Driver / Operator Assignment',
          style: StitchTheme.headlineSm(),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a credentialed driver who is not currently allocated to another ambulance.',
          style: StitchTheme.bodySm(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedDriver?.id?.toString(),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Available Driver *',
            prefixIcon: Icon(Icons.person_pin_circle_rounded),
          ),
          items: availableDrivers.map((driver) {
            final label = '${driver.name} • ${driver.status.label}';
            return DropdownMenuItem<String>(
              value: driver.id.toString(),
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: availableDrivers.isEmpty
              ? null
              : (value) {
                  if (value == null) return;

                  AdminStaff? driver;
                  for (final item in availableDrivers) {
                    if (item.id.toString() == value) {
                      driver = item;
                      break;
                    }
                  }

                  if (driver == null) return;

                  final selectedDriver = driver;
                  setState(() {
                    _selectedDriverId = selectedDriver.id.toString();
                    _driverNameCtrl.text = selectedDriver.name.toString();
                    _driverPhoneCtrl.text = selectedDriver.phone.toString();
                    _driverEmailCtrl.text = selectedDriver.email.toString();
                    _driverLicenseCtrl.text =
                        selectedDriver.licenseNumber?.toString() ?? '';
                    _driverExpYears = selectedDriver.experienceYears.clamp(1, 25);
                    _error = null;
                  });
                },
        ),
        if (availableDrivers.isEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StitchTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(StitchTheme.radiusMd),
              border: Border.all(color: StitchTheme.borderSubtle),
            ),
            child: Text(
              'No unallocated drivers are available.',
              style: StitchTheme.bodySm(color: StitchTheme.error),
            ),
          ),
        ] else if (selectedDriver != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StitchTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(StitchTheme.radiusMd),
              border: Border.all(color: StitchTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedDriver.name.toString(),
                  style: StitchTheme.labelMd(weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${selectedDriver.phone.toString().isEmpty ? 'Not provided' : selectedDriver.phone}',
                ),
                Text(
                  'Email: ${selectedDriver.email.toString().isEmpty ? 'Not provided' : selectedDriver.email}',
                ),
                Text(
                  'License: ${selectedDriver.licenseNumber?.toString().isEmpty ?? true ? 'Not recorded' : selectedDriver.licenseNumber}',
                ),
                Text('Experience: ${selectedDriver.experienceYears} years'),
                const SizedBox(height: 4),
                Text(
                  'This driver will be paired with the ambulance after enrollment.',
                  style: StitchTheme.bodySm(color: StitchTheme.tertiary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep5Review() {
    return Container(
      padding: const EdgeInsets.all(StitchTheme.spaceMd),
      decoration: BoxDecoration(
        color: StitchTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        border: Border.all(color: StitchTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: StitchTheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                '5. Review & Confirm CAD Enrollment',
                style: StitchTheme.headlineSm(),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Vehicle Call Sign: ${_callSignCtrl.text}',
            style: StitchTheme.bodyMd(weight: FontWeight.w600),
          ),
          Text('CAD No: ${_cadNoCtrl.text}'),
          Text('Model: ${_platformCtrl.text}'),
          Text('Classification: $_classification'),
          Text('Base Station: $_stationBase'),
          const Divider(height: 16),
          Text(
            'Assigned Driver: ${_driverNameCtrl.text} (${_driverLicenseCtrl.text})',
            style: StitchTheme.bodyMd(weight: FontWeight.w600),
          ),
          Text('Fuel: $_fuel%  ·  O2 Pressure: $_o2Pressure Bar'),
          const Divider(height: 16),
          Text(
            'Status upon enrollment: AVAILABLE - READY',
            style: StitchTheme.labelMd(
              color: StitchTheme.tertiary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
