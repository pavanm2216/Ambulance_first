import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/models/booking.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/shared_booking_store.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_workflow_repository.dart';
import '../theme/ambulance_first_theme.dart';
import '../widgets/ambulance_first_button.dart';
import '../widgets/ambulance_first_card.dart';
import '../widgets/ambulance_first_input.dart';

class HomeServicesScreen extends StatefulWidget {
  const HomeServicesScreen({
    super.key,
    required this.user,
    required this.onBookingCreated,
  });

  final AuthUser user;
  final ValueChanged<Booking> onBookingCreated;

  @override
  State<HomeServicesScreen> createState() => _HomeServicesScreenState();
}

class _HomeServicesScreenState extends State<HomeServicesScreen> {
  final SupabaseWorkflowRepository _workflow = SupabaseWorkflowRepository();
  final SupabaseBookingRepository _bookingRepository = SupabaseBookingRepository();
  final LocationService _locationService = LocationService();

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _patientAgeCtrl = TextEditingController();
  final TextEditingController _conditionCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _service = 'ICU_AT_HOME';
  String _gender = '';
  String _relationship = 'Self';
  String _scheduleType = 'IMMEDIATE';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  String _city = '';
  bool _loadingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _conditionCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _serviceName {
    switch (_service) {
      case 'NURSE_AT_HOME':
        return 'Nurse at Home';
      case 'MEDICAL_ATTENDANT':
        return 'Medical Attendant at Home';
      case 'DOCTOR_HOME_VISIT':
        return 'Doctor Home Visit';
      case 'ICU_AT_HOME':
      default:
        return 'ICU at Home';
    }
  }

  Future<void> _useMyLocation() async {
    if (_loadingLocation) return;
    setState(() => _loadingLocation = true);
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _city = result.city;
        _addressCtrl.text = result.address;
      });
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_patientNameCtrl.text.trim().isEmpty ||
        _patientAgeCtrl.text.trim().isEmpty ||
        _gender.isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      _showError('Please complete patient name, age, gender and service location.');
      return;
    }

    if (!SupabaseService.isConfigured) {
      _showError('An authenticated Supabase session is required.');
      return;
    }

    final age = int.tryParse(_patientAgeCtrl.text.trim());
    if (age == null || age < 0) {
      _showError('Please enter a valid patient age.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final bookingId = await _workflow.createCustomerBooking({
        'booking_source': 'ONLINE',
        'service_category': 'HOME_SERVICE',
        'service_subtype': _service,
        'transport_mode': 'HOME_SERVICE',
        'ambulance_type': 'Home Medical Service',
        'is_home_service': true,
        'home_service_category': _service,
        'home_service_name': _serviceName,
        'service_condition': _conditionCtrl.text.trim(),
        'customer_name': widget.user.name,
        'customer_phone': widget.user.phone,
        'customer_email': widget.user.email,
        'relationship_to_patient': _relationship,
        'patient_name': _patientNameCtrl.text.trim(),
        'patient_age': age,
        'patient_gender': _gender,
        'current_condition': _conditionCtrl.text.trim(),
        'medical_summary': _notesCtrl.text.trim(),
        'pickup_address': _addressCtrl.text.trim(),
        'pickup_city': _city,
        'pickup_lat': _latitude,
        'pickup_lng': _longitude,
        // A home service does not require a transport destination.
        'destination_address': _addressCtrl.text.trim(),
        'destination_city': _city,
        'preferred_date': _scheduleType == 'IMMEDIATE'
            ? null
            : '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        'preferred_time': _scheduleType == 'IMMEDIATE'
            ? null
            : '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        'is_immediate': _scheduleType == 'IMMEDIATE',
        'is_emergency': false,
        'priority': 'NORMAL',
        'medical_attendant_required': _service == 'MEDICAL_ATTENDANT',
      });

      // Home service has one service location, so the current schema has no
      // second point from which to derive provider travel distance. The DB
      // trigger therefore persists the configured home-service base fare.
      // Keep the route call here so future provider-origin routing can be
      // added without changing the booking lifecycle.
      try {
        await _workflow.calculateBookingRoute(bookingId);
      } catch (_) {
        // Basic home-service fare does not depend on a destination route.
      }

      try {
        await _workflow.calculateBasicFare(bookingId);
      } catch (_) {
        // The route-triggered database calculation remains the fallback.
      }

      final bookings = await _bookingRepository.getCustomerBookings();
      final created = bookings.where((booking) => booking.id == bookingId).firstOrNull;
      if (created == null) {
        throw StateError('Home service was created but could not be reloaded.');
      }

      SharedBookingStore.upsert(created);
      if (!mounted) return;
      widget.onBookingCreated(created);
    } catch (error) {
      if (mounted) _showError('Home service booking failed: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AmbulanceFirstColors.medicalCrimson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: desktop
                ? AmbulanceFirstSpacing.margin
                : AmbulanceFirstSpacing.marginMobile,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Home Services',
                    style: AmbulanceFirstTypography.headlineLg(
                      color: AmbulanceFirstColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Book medical care at the patient’s home using the same Ambulance First booking backend.',
                    style: AmbulanceFirstTypography.bodyMd(
                      color: AmbulanceFirstColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _serviceSelector(),
                  const SizedBox(height: 16),
                  AmbulanceFirstCard(
                    padding: const EdgeInsets.all(AmbulanceFirstSpacing.spaceMd),
                    child: _bookingForm(desktop),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _serviceSelector() {
    final services = [
      ('ICU_AT_HOME', 'ICU at Home', Icons.local_hospital_rounded),
      ('NURSE_AT_HOME', 'Nurse at Home', Icons.medical_services_rounded),
      ('DOCTOR_HOME_VISIT', 'Doctor Home Visit', Icons.health_and_safety_rounded),
      ('MEDICAL_ATTENDANT', 'Medical Attendant', Icons.accessibility_new_rounded),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: services.map((item) {
        final selected = _service == item.$1;
        return SizedBox(
          width: 205,
          child: InkWell(
            onTap: () => setState(() => _service = item.$1),
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? AmbulanceFirstColors.primaryFixed.withValues(alpha: 0.45)
                    : AmbulanceFirstColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
                border: Border.all(
                  color: selected
                      ? AmbulanceFirstColors.clinicalCobalt
                      : AmbulanceFirstColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$3, color: AmbulanceFirstColors.clinicalCobalt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: AmbulanceFirstTypography.bodySm(
                        color: AmbulanceFirstColors.onSurface,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AmbulanceFirstColors.clinicalCobalt,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bookingForm(bool desktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_serviceName Booking',
          style: AmbulanceFirstTypography.headlineSm(
            color: AmbulanceFirstColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        AmbulanceFirstTextInput(
          label: 'Patient Name',
          controller: _patientNameCtrl,
          isRequired: true,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AmbulanceFirstTextInput(
                label: 'Patient Age',
                controller: _patientAgeCtrl,
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AmbulanceFirstDropdown<String>(
                label: 'Gender',
                value: _gender.isEmpty ? null : _gender,
                isRequired: true,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _gender = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AmbulanceFirstDropdown<String>(
          label: 'Relationship to Patient',
          value: _relationship,
          items: const [
            DropdownMenuItem(value: 'Self', child: Text('Self')),
            DropdownMenuItem(value: 'Family Guardian', child: Text('Family Guardian / Parent')),
            DropdownMenuItem(value: 'Relative', child: Text('Relative')),
            DropdownMenuItem(value: 'Friend', child: Text('Friend')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _relationship = value);
          },
        ),
        const SizedBox(height: 14),
        AmbulanceFirstTextInput(
          label: 'Clinical Condition',
          controller: _conditionCtrl,
          isRequired: true,
          hintText: 'Describe the patient condition',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        AmbulanceFirstTextInput(
          label: 'Home Service Address',
          controller: _addressCtrl,
          isRequired: true,
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
        const SizedBox(height: 10),
        AmbulanceFirstButton(
          label: _loadingLocation ? 'GETTING LOCATION...' : 'USE MY LOCATION',
          icon: Icons.my_location_rounded,
          onPressed: _loadingLocation ? null : _useMyLocation,
          variant: AmbulanceFirstButtonVariant.ghost,
          isLoading: _loadingLocation,
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 8),
          Text(
            'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
            style: AmbulanceFirstTypography.codeSm(
              color: AmbulanceFirstColors.clinicalCobalt,
            ),
          ),
        ],
        const SizedBox(height: 14),
        AmbulanceFirstTextInput(
          label: 'Additional Notes',
          controller: _notesCtrl,
          maxLines: 3,
          hintText: 'Optional care instructions',
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: RadioGroup<String>(
            groupValue: _scheduleType,
            onChanged: (value) {
              if (value != null) setState(() => _scheduleType = value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'IMMEDIATE',
                  title: const Text('Book as soon as possible'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'SCHEDULED',
                  title: const Text('Schedule a visit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        if (_scheduleType == 'SCHEDULED') ...[
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Time'),
                  subtitle: Text(_time.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked != null) setState(() => _time = picked);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: AmbulanceFirstButton(
            label: 'BOOK HOME SERVICE',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
        ),
      ],
    );
  }
}
