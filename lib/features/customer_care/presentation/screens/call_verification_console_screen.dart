import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';
import '../widgets/call_outcome_selector.dart';
import '../widgets/verification_checklist_view.dart';

class CallVerificationConsoleScreen extends StatefulWidget {
  const CallVerificationConsoleScreen({
    super.key,
    required this.caseItem,
    required this.onBack,
    required this.onVerificationComplete,
    required this.onShowToast,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onBack;
  final VoidCallback onVerificationComplete;
  final ValueChanged<String> onShowToast;

  @override
  State<CallVerificationConsoleScreen> createState() =>
      _CallVerificationConsoleScreenState();
}

class _CallVerificationConsoleScreenState
    extends State<CallVerificationConsoleScreen> {
  late String _selectedOutcome;
  late String _selectedPriority;
  late TextEditingController _notesController;

  late bool _checkPatientCondition;
  late bool _checkOxygenTherapy;
  late bool _checkVentilatorLoaded;
  late bool _checkDoctorDesignated;
  late bool _checkReceivingBedSecured;
  late bool _checkRoutePriorityCleared;

  late bool _patientConditionConfirmed;
  late bool _medicalRequirementsConfirmed;
  late bool _locationConfirmed;
  late bool _dateTimeConfirmed;

  // Equipment toggles
  late bool _oxygenActive;
  late bool _icuActive;
  late bool _ventilatorActive;
  late bool _doctorActive;
  late bool _emtActive;

  // Timer simulation
  int _secondsElapsed = 277; // 04:37
  Timer? _callTimer;
  bool _isTransmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.caseItem;
    _selectedOutcome = c.callStatus.isNotEmpty ? c.callStatus : 'In Progress';
    _selectedPriority = c.priority.isNotEmpty
        ? c.priority
        : 'CRITICAL_CODE_RED';
    _notesController = TextEditingController(
      text: c.notes.isNotEmpty ? c.notes : '',
    );

    _checkPatientCondition = c.checkPatientCondition;
    _checkOxygenTherapy = c.checkOxygenTherapy;
    _checkVentilatorLoaded = c.checkVentilatorLoaded;
    _checkDoctorDesignated = c.checkDoctorDesignated;
    _checkReceivingBedSecured = c.checkReceivingBedSecured;
    _checkRoutePriorityCleared = c.checkRoutePriorityCleared;

    _patientConditionConfirmed = c.patientConfirmed;
    _medicalRequirementsConfirmed = c.medicalConfirmed;
    _locationConfirmed = c.locationConfirmed;
    _dateTimeConfirmed = c.dateTimeConfirmed;

    _oxygenActive = c.oxygen;
    _icuActive = c.icu;
    _ventilatorActive = c.ventilator;
    _doctorActive = c.doctor;
    _emtActive = c.emt;

    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  bool get _isChecklistComplete {
    return _checkPatientCondition &&
        _checkOxygenTherapy &&
        _checkVentilatorLoaded &&
        _checkDoctorDesignated &&
        _checkReceivingBedSecured &&
        _checkRoutePriorityCleared;
  }

  bool get _businessVerificationComplete =>
      _patientConditionConfirmed &&
      _medicalRequirementsConfirmed &&
      _locationConfirmed &&
      _dateTimeConfirmed;

  bool get _isReadyForHandoff =>
      _businessVerificationComplete && _isChecklistComplete;

  Future<void> _handleSaveLogOnly() async {
    await CustomerCareRepository.instance.saveCallLogOnly(
      caseId: widget.caseItem.id,
      outcome: _selectedOutcome,
      priority: _selectedPriority,
      notes: _notesController.text,
      callDurationSeconds: _secondsElapsed,
      checkPatientCondition: _checkPatientCondition,
      checkOxygenTherapy: _checkOxygenTherapy,
      checkVentilatorLoaded: _checkVentilatorLoaded,
      checkDoctorDesignated: _checkDoctorDesignated,
      checkReceivingBedSecured: _checkReceivingBedSecured,
      checkRoutePriorityCleared: _checkRoutePriorityCleared,
    );
    widget.onShowToast('Call log saved. Case remains in verification queue.');
  }

  Future<void> _handleVerifyBooking() async {
    if (!_isReadyForHandoff) {
      widget.onShowToast(
        'Complete all 4 business confirmations and the 6/6 safety handover checklist before verification.',
      );
      return;
    }

    setState(() {
      _isTransmitting = true;
    });

    try {
      // The dashboard/repository case is sourced from the canonical
      // get_customer_care_bookings() response, whose `status` field is the
      // authoritative workflow status. Do not use the presentation/details
      // RPC as a workflow-state check.
      final currentStatus = widget.caseItem.status.trim().toUpperCase();
      if (currentStatus == 'VERIFIED') {
        widget.onShowToast('Booking is already verified.');
        widget.onVerificationComplete();
        return;
      }

      final verification = CustomerCareVerificationPayload(
        bookingId: widget.caseItem.id,
        callLogId: null,
        patientConditionConfirmed: _patientConditionConfirmed,
        medicalRequirementsConfirmed: _medicalRequirementsConfirmed,
        locationConfirmed: _locationConfirmed,
        datetimeConfirmed: _dateTimeConfirmed,
        checkPatientCondition: _checkPatientCondition,
        checkOxygenTherapy: _checkOxygenTherapy,
        checkVentilatorLoaded: _checkVentilatorLoaded,
        checkDoctorDesignated: _checkDoctorDesignated,
        checkReceivingBedSecured: _checkReceivingBedSecured,
        checkRoutePriorityCleared: _checkRoutePriorityCleared,
        priority: _selectedPriority,
        notes: _notesController.text,
      );
      debugPrint(
        'DEBUG CC: bookingId=${verification.bookingId} '
        'localStatus=${widget.caseItem.status} '
        'patientCondition=${verification.patientConditionConfirmed} '
        'medicalRequirements=${verification.medicalRequirementsConfirmed} '
        'location=${verification.locationConfirmed} '
        'datetime=${verification.datetimeConfirmed} '
        'checkPatientCondition=${verification.checkPatientCondition} '
        'checkOxygen=${verification.checkOxygenTherapy} '
        'checkVentilator=${verification.checkVentilatorLoaded} '
        'checkDoctor=${verification.checkDoctorDesignated} '
        'checkBed=${verification.checkReceivingBedSecured} '
        'checkRoute=${verification.checkRoutePriorityCleared}',
      );
      await CustomerCareRepository.instance.verifyCustomerCareBooking(
        verification: verification,
      );
      if (mounted) {
        widget.onShowToast(
          'Booking #${widget.caseItem.id} verified. Review the dashboard to send it to Team Lead.',
        );
        widget.onVerificationComplete();
      }
    } catch (error) {
      if (mounted) {
        widget.onShowToast('Customer Care verification failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isTransmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseItem;

    return Scaffold(
      backgroundColor: CustomerCareColors.background,
      appBar: AppBar(
        backgroundColor: CustomerCareColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: CustomerCareColors.onSurface,
          ),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Call & Triage Verification',
          style: CustomerCareTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CustomerCareColors.secondaryContainer.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent,
                  size: 15,
                  color: CustomerCareColors.onSecondaryFixedVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'ACTIVE SESSION',
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: CustomerCareColors.onSecondaryFixedVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Call Control & Dossier Header
            Container(
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomerCareColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.support_agent,
                            color: CustomerCareColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TRIAGE SESSION ACTIVE',
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: CustomerCareColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // Live Recording Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CustomerCareColors.error,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatTimer(_secondsElapsed),
                              style: CustomerCareTextStyles.telemetryDisplay
                                  .copyWith(
                                    fontSize: 12,
                                    color: CustomerCareColors.error,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REC',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Incident Dossier: #${c.id}',
                    style: CustomerCareTextStyles.labelMd.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Dial Patch-in Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CustomerCareColors.primaryContainer,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.customerName} (${c.relationship})',
                                  style: CustomerCareTextStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: CustomerCareColors.onSurface,
                                  ),
                                ),
                                Text(
                                  c.mobileNumber,
                                  style: CustomerCareTextStyles.telemetryDisplay
                                      .copyWith(
                                        fontSize: 12,
                                        color: CustomerCareColors.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.onShowToast(
                              'Dialing caller ${c.mobileNumber}...',
                            );
                          },
                          icon: const Icon(Icons.call, size: 14),
                          label: const Text('Re-Dial'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomerCareColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            textStyle: CustomerCareTextStyles.labelSm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Patient & Route Clinical Dossier Card
            Container(
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomerCareColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.isCodeRed
                                  ? CustomerCareColors.errorContainer
                                  : CustomerCareColors.surfaceContainerHigh,
                            ),
                            child: Center(
                              child: Text(
                                '${c.age}${c.gender.isNotEmpty ? c.gender[0].toUpperCase() : ""}',
                                style: CustomerCareTextStyles.telemetryDisplay
                                    .copyWith(
                                      fontSize: 13,
                                      color: c.isCodeRed
                                          ? CustomerCareColors.error
                                          : CustomerCareColors.primary,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.patientName,
                                style: CustomerCareTextStyles.headlineSm
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${c.mrn.isNotEmpty ? c.mrn : "MRN-PENDING"} • Critical Transfer',
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: CustomerCareColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          c.serviceCategory == 'AIR'
                              ? 'AIR MEDEVAC'
                              : 'ACLS GROUND',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Live Telemetry Strip
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryCell(
                            'BP SYS/DIA',
                            c.bloodPressure,
                            'Unavailable',
                            isAlert: c.bloodPressure.isNotEmpty,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTelemetryCell(
                            'SpO2 (O2)',
                            c.spO2,
                            'Unavailable',
                            isAlert: c.spO2.isNotEmpty,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTelemetryCell(
                            'DIAGNOSIS',
                            c.diagnosis,
                            'Unavailable',
                            isAlert: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Waypoint Route Strip
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CustomerCareColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_hospital,
                              size: 15,
                              color: CustomerCareColors.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORIGIN FACILITY',
                                    style: CustomerCareTextStyles.labelSm
                                        .copyWith(fontSize: 9),
                                  ),
                                  Text(
                                    c.pickupAddress,
                                    style: CustomerCareTextStyles.bodySm
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: CustomerCareColors.onSurface,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 7,
                            top: 2,
                            bottom: 2,
                          ),
                          child: Container(
                            height: 14,
                            width: 1.5,
                            color: CustomerCareColors.outlineVariant,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_drop,
                              size: 15,
                              color: CustomerCareColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECEIVING TARGET',
                                    style: CustomerCareTextStyles.labelSm
                                        .copyWith(fontSize: 9),
                                  ),
                                  Text(
                                    '${c.destinationHospital.isNotEmpty ? c.destinationHospital : c.destinationAddress} • ${c.receivingDepartment}',
                                    style: CustomerCareTextStyles.bodySm
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: CustomerCareColors.onSurface,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Call Outcome Selector
            CallOutcomeSelector(
              selectedOutcome: _selectedOutcome,
              onSelectOutcome: (val) {
                setState(() => _selectedOutcome = val);
                widget.onShowToast('Call Outcome: $val');
              },
            ),
            const SizedBox(height: 12),

            // 4. Dispatch Priority Level
            Container(
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomerCareColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispatch Priority Level',
                        style: CustomerCareTextStyles.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'IMMEDIATE ACLS',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildPriorityBtn(
                          'Critical • Red',
                          'CRITICAL_CODE_RED',
                          CustomerCareColors.error,
                          icon: Icons.emergency,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPriorityBtn(
                          'High',
                          'HIGH',
                          CustomerCareColors.warning,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPriorityBtn(
                          'Normal',
                          'NORMAL',
                          CustomerCareColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _buildBusinessVerificationSection(),
            const SizedBox(height: 12),

            // 5. Allocated Clinical Assets
            Container(
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomerCareColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allocated Clinical Assets',
                    style: CustomerCareTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildAssetChip(
                        'O2 Therapy: Active',
                        Icons.air,
                        _oxygenActive,
                        () {
                          setState(() => _oxygenActive = !_oxygenActive);
                        },
                      ),
                      _buildAssetChip(
                        'ICU Monitor: Active',
                        Icons.monitor_heart,
                        _icuActive,
                        () {
                          setState(() => _icuActive = !_icuActive);
                        },
                      ),
                      _buildAssetChip(
                        'Transport Vent: Active',
                        Icons.air,
                        _ventilatorActive,
                        () {
                          setState(
                            () => _ventilatorActive = !_ventilatorActive,
                          );
                        },
                      ),
                      _buildAssetChip(
                        'MD Escort: Active',
                        Icons.medication,
                        _doctorActive,
                        () {
                          setState(() => _doctorActive = !_doctorActive);
                        },
                      ),
                      _buildAssetChip(
                        'Lead EMT: Active',
                        Icons.badge,
                        _emtActive,
                        () {
                          setState(() => _emtActive = !_emtActive);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Safety Handover Protocol Checklist
            VerificationChecklistView(
              checkPatientCondition: _checkPatientCondition,
              checkOxygenTherapy: _checkOxygenTherapy,
              checkVentilatorLoaded: _checkVentilatorLoaded,
              checkDoctorDesignated: _checkDoctorDesignated,
              checkReceivingBedSecured: _checkReceivingBedSecured,
              checkRoutePriorityCleared: _checkRoutePriorityCleared,
              businessVerificationComplete: _businessVerificationComplete,
              onTogglePatientCondition: (v) =>
                  setState(() => _checkPatientCondition = v ?? false),
              onToggleOxygenTherapy: (v) =>
                  setState(() => _checkOxygenTherapy = v ?? false),
              onToggleVentilatorLoaded: (v) =>
                  setState(() => _checkVentilatorLoaded = v ?? false),
              onToggleDoctorDesignated: (v) =>
                  setState(() => _checkDoctorDesignated = v ?? false),
              onToggleReceivingBedSecured: (v) =>
                  setState(() => _checkReceivingBedSecured = v ?? false),
              onToggleRoutePriorityCleared: (v) =>
                  setState(() => _checkRoutePriorityCleared = v ?? false),
            ),
            const SizedBox(height: 12),

            // 7. Clinical & Operations Handover Directives / Notes
            Container(
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomerCareColors.outlineVariant,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Call & Handover Directives',
                        style: CustomerCareTextStyles.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Logged by Customer Care',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: CustomerCareTextStyles.bodyMd,
                    decoration: InputDecoration(
                      hintText: 'Enter clinical handover directives...',
                      fillColor: CustomerCareColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 13,
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HIPAA Encrypted Ops Record',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 8. Dual Action Tactical Footer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CustomerCareColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Forward Handoff Button
                  InkWell(
                    onTap: _isTransmitting ? null : _handleVerifyBooking,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isReadyForHandoff
                            ? CustomerCareColors.primaryContainer
                            : CustomerCareColors.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  child: _isTransmitting
                                      ? const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'VERIFY BOOKING',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CustomerCareTextStyles.headlineSm.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _isReadyForHandoff
                                            ? 'Persists verification and refreshes the queue'
                                            : 'Requires 4/4 business and 6/6 safety confirmations',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: CustomerCareTextStyles.labelSm.copyWith(
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary Save Local
                  OutlinedButton.icon(
                    onPressed: _handleSaveLogOnly,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text(
                      'Save Call Log Only (Remain In Verification)',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: CustomerCareColors.onSurface,
                      side: const BorderSide(
                        color: CustomerCareColors.outlineVariant,
                      ),
                      textStyle: CustomerCareTextStyles.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessVerificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CustomerCareColors.outlineVariant,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business Verification',
                style: CustomerCareTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${[_patientConditionConfirmed, _medicalRequirementsConfirmed, _locationConfirmed, _dateTimeConfirmed].where((value) => value).length}/4',
                style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                  fontSize: 14,
                  color: _businessVerificationComplete
                      ? CustomerCareColors.secondary
                      : CustomerCareColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBusinessCheckItem(
            'Patient condition confirmed',
            _patientConditionConfirmed,
            (value) => setState(() => _patientConditionConfirmed = value),
          ),
          _buildBusinessCheckItem(
            'Medical requirements confirmed',
            _medicalRequirementsConfirmed,
            (value) => setState(() => _medicalRequirementsConfirmed = value),
          ),
          _buildBusinessCheckItem(
            'Pickup and destination confirmed',
            _locationConfirmed,
            (value) => setState(() => _locationConfirmed = value),
          ),
          _buildBusinessCheckItem(
            'Date and time confirmed',
            _dateTimeConfirmed,
            (value) => setState(() => _dateTimeConfirmed = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCheckItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CustomerCareColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: CustomerCareColors.secondary,
              ),
              Expanded(
                child: Text(
                  label,
                  style: CustomerCareTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CustomerCareColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCell(
    String label,
    String value,
    String sub, {
    required bool isAlert,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: CustomerCareTextStyles.labelSm.copyWith(
              color: CustomerCareColors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: CustomerCareTextStyles.telemetryDisplay.copyWith(
              fontSize: 12.5,
              color: isAlert
                  ? CustomerCareColors.error
                  : CustomerCareColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub.toUpperCase(),
            style: CustomerCareTextStyles.labelSm.copyWith(
              fontSize: 8.5,
              color: isAlert
                  ? CustomerCareColors.error
                  : CustomerCareColors.primaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBtn(
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    final isSelected = _selectedPriority == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedPriority = value);
        widget.onShowToast('Priority updated: $label');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : CustomerCareColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : CustomerCareColors.outlineVariant,
            width: isSelected ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: CustomerCareTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : CustomerCareColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetChip(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? CustomerCareColors.secondaryContainer
              : CustomerCareColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? CustomerCareColors.onSecondaryContainer
                  : CustomerCareColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: CustomerCareTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: active
                    ? CustomerCareColors.onSecondaryContainer
                    : CustomerCareColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
