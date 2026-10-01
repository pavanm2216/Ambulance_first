import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/booking.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_metrics.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_button.dart';
import '../../../shared/widgets/aeromed_page.dart';
import '../../../shared/widgets/aeromed_text_field.dart';
import '../../../shared/widgets/aeromed_ui_states.dart';
import '../../../shared/widgets/motion.dart';
import './booking_summary_sheet.dart';

typedef BookingSubmit = void Function(Booking booking);

class BookAmbulancePage extends StatefulWidget {
  const BookAmbulancePage({
    super.key,
    required this.onSubmit,
  });

  final BookingSubmit onSubmit;

  @override
  State<BookAmbulancePage> createState() =>
      _BookAmbulancePageState();
}

class _BookAmbulancePageState
    extends State<BookAmbulancePage> {
  final _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _name =
      TextEditingController(
    text: 'Kushal Kumar',
  );

  final _phone =
      TextEditingController(
    text: '+91 98765 43210',
  );

  final _email =
      TextEditingController(
    text: 'customer@aeromed.org',
  );

  final _pickup =
      TextEditingController(
    text:
        'Koramangala 4th Block, Bengaluru',
  );

  final _destination =
      TextEditingController(
    text:
        'Manipal Hospital, Old Airport Road',
  );

  final _patient =
      TextEditingController(
    text: 'Kushal Kumar',
  );

  final _age =
      TextEditingController(
    text: '42',
  );

  final _weight =
      TextEditingController(
    text: '70',
  );

  final _currentHospital =
      TextEditingController();

  final _destinationHospital =
      TextEditingController(
    text: 'Manipal Hospital',
  );

  final _summary =
      TextEditingController();

  final _instructions =
      TextEditingController();

  final _alternatePhone =
      TextEditingController();


  // ============================================================
  // STATE
  // ============================================================

  String _gender = 'Male';

  List<String> _validationErrors = [];

  String _relationship = 'Self';

  String _condition = 'Stable';

  String _isAdmittedInHospital = 'Not Sure';

  bool _conscious = true;

  bool _emergency = false;

  bool _oxygen = false;

  bool _icu = false;

  bool _ventilator = false;

  bool _cardiac = false;

  bool _stretcher = true;

  bool _wheelchair = false;

  bool _doctor = false;

  bool _emt = true;

  bool _attendant = false;

  double? _oxygenFlow;

  String _doctorSpecialization =
      'Emergency Medicine';

  String _date = 'Immediate';

  TimeOfDay? _scheduledTime;

  String _ambulance =
      'Road Ambulance';

  String _serviceSubtype = 'ADVANCED_ICU';
  String _flightType = 'Domestic';
  final _trainNumber = TextEditingController();
  final _trainName = TextEditingController();
  final _coachNumber = TextEditingController();
  final _pickupStation = TextEditingController();
  final _destinationStation = TextEditingController();
  final _pickupAirport = TextEditingController();
  final _destinationAirport = TextEditingController();
  final _airPermitNumber = TextEditingController();
  final _deathCertificateNumber = TextEditingController();
  bool _freezerRequired = true;
  bool _morgueReleaseGranted = false;
  bool _familyNocReceived = false;

  bool _isLocating = false;


  String get _serviceCategoryCode {
    switch (_ambulance) {
      case 'Railway Ambulance': return 'RAILWAY';
      case 'Air Ambulance': return 'AIR';
      case 'Dead Body Transfer': return 'DEAD_BODY';
      default: return 'ROAD';
    }
  }

  String get _ventilatorMode => _ventilatorModeValue;
  String _ventilatorModeValue = 'Transport Ventilator';

  // ============================================================
  // TRANSPORT CODE
  // ============================================================

  String get _transportModeCode {
    switch (_ambulance) {
      case 'Railway Ambulance':
        return 'RAILWAY_AMBULANCE';

      case 'Air Ambulance':
        return 'AIR_AMBULANCE';

      case 'Dead Body Transfer':
        return 'DEAD_BODY_TRANSFER';

      default:
        return 'ROAD_AMBULANCE';
    }
  }


  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pickup.dispose();
    _destination.dispose();
    _patient.dispose();
    _age.dispose();
    _weight.dispose();
    _currentHospital.dispose();
    _destinationHospital.dispose();
    _summary.dispose();
    _instructions.dispose();
    _alternatePhone.dispose();
    _trainNumber.dispose();
    _trainName.dispose();
    _coachNumber.dispose();
    _pickupStation.dispose();
    _destinationStation.dispose();
    _pickupAirport.dispose();
    _destinationAirport.dispose();
    _airPermitNumber.dispose();
    _deathCertificateNumber.dispose();

    super.dispose();
  }


  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickDate() async {
    final date =
        await showDatePicker(
      context: context,
      firstDate:
          DateTime.now(),
      lastDate:
          DateTime.now().add(
        const Duration(
          days: 365,
        ),
      ),
      initialDate:
          DateTime.now(),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _date =
          '${date.day.toString().padLeft(2, '0')} '
          '${_month(date.month)} '
          '${date.year}';
    });
  }


  // ============================================================
  // TIME
  // ============================================================

  Future<void> _pickTime() async {
    final time =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.now(),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _scheduledTime = time;
    });
  }


  String _month(
    int month,
  ) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }


  String _timeLabel() {
    return _scheduledTime?.format(
          context,
        ) ??
        'Select time';
  }


  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_isLocating) {
      return;
    }

    setState(() {
      _isLocating = true;
    });

    try {
      final enabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!enabled) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            child: AeroMedPermissionDeniedCard(
              permissionTitle: 'Device Location Disabled',
              clinicalRationale:
                  'Please enable device location services so Ambulance First can accurately detect your pickup address and route nearby ambulances.',
              manualFallbackLabel: 'Enter Address Manually',
              onGrantPermission: () async {
                Navigator.pop(c);
                await Geolocator.openLocationSettings();
              },
              onManualFallback: () => Navigator.pop(c),
            ),
          ),
        );
        return;
      }

      var permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            child: AeroMedPermissionDeniedCard(
              permissionTitle: 'Location Access Denied',
              clinicalRationale:
                  'Accurate location allows the dispatch system to identify the closest ambulance unit and route life support crew directly without verbal landmark confusion.',
              manualFallbackLabel: 'Enter Address Manually',
              onGrantPermission: () async {
                Navigator.pop(c);
                await Geolocator.openAppSettings();
              },
              onManualFallback: () => Navigator.pop(c),
            ),
          ),
        );
        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      _pickup.text =
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}';

      try {
        final places =
            await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (places.isNotEmpty) {
          final place =
              places.first;

          final parts =
              <String?>[
                place.name,
                place.subLocality,
                place.locality,
                place.administrativeArea,
              ]
                  .whereType<String>()
                  .map(
                    (value) =>
                        value.trim(),
                  )
                  .where(
                    (value) =>
                        value.isNotEmpty,
                  )
                  .toSet()
                  .toList();

          if (parts.isNotEmpty) {
            _pickup.text =
                parts.join(', ');
          }
        }
      } catch (_) {
        // GPS coordinates remain in the field.
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Pickup location updated from your current location.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }


  // ============================================================
  // REVIEW REQUEST
  // ============================================================

  void _review() {
    final errors = <String>[];
    if (_name.text.trim().isEmpty) errors.add('Requester name is required.');
    if (_phone.text.trim().isEmpty) {
      errors.add('Contact phone number is required.');
    } else if (_phone.text.trim().length < 8) {
      errors.add('Please enter a valid phone number (at least 8 digits).');
    }
    if (_pickup.text.trim().isEmpty) errors.add('Pickup location is required.');
    if (_destination.text.trim().isEmpty && _destinationHospital.text.trim().isEmpty) {
      errors.add('Destination location or hospital is required.');
    }
    if (_patient.text.trim().isEmpty) errors.add('Patient name is required.');
    final parsedAge = int.tryParse(_age.text.trim()) ?? 0;
    if (parsedAge <= 0) errors.add('Please specify a valid patient age.');
    if (_date != 'Immediate' && _scheduledTime == null) {
      errors.add('Please select a preferred transport time.');
    }
    if (_ambulance == 'Railway Ambulance' && (_trainNumber.text.trim().isEmpty || _coachNumber.text.trim().isEmpty || _pickupStation.text.trim().isEmpty || _destinationStation.text.trim().isEmpty)) {
      errors.add('Railway bookings require train/coach and station details.');
    }
    if (_ambulance == 'Air Ambulance' && (_pickupAirport.text.trim().isEmpty || _destinationAirport.text.trim().isEmpty)) {
      errors.add('Air ambulance bookings require pickup and destination airports.');
    }

    if (errors.isNotEmpty || !_formKey.currentState!.validate()) {
      setState(() => _validationErrors = errors);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted form errors before submitting.'),
          backgroundColor: AppColors.urgentRed,
        ),
      );
      return;
    }
    setState(() => _validationErrors = []);

    final age =
        int.tryParse(
              _age.text.trim(),
            ) ??
            0;

    final draft =
        Booking(
      id:
          'AMB-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',

      pickup:
          _pickup.text.trim(),

      destination:
          _destination.text.trim(),

      date:
          _date,

      time:
          _date == 'Immediate'
              ? 'Now'
              : _timeLabel(),

      ambulanceType:
          'Pending operational assignment',

      transportMode:
          _transportModeCode,

      serviceCategory:
          _serviceCategoryCode,

      serviceSubtype:
          _serviceSubtype,

      pickupCity:
          '',

      destinationCity:
          '',

      estimatedDurationMins:
          0,

      isAdmittedInHospital:
          _isAdmittedInHospital,

      ventilatorMode:
          _ventilatorMode,

      doctorSpecialization:
          _doctorSpecialization,

      trainDetails:
          _serviceCategoryCode == 'RAILWAY'
              ? RailwayTransferDetails(
                  trainNumber: _trainNumber.text.trim(),
                  trainName: _trainName.text.trim(),
                  coachNumber: _coachNumber.text.trim(),
                  pickupStation: _pickupStation.text.trim(),
                  destinationStation: _destinationStation.text.trim(),
                )
              : null,

      airDetails:
          _serviceCategoryCode == 'AIR'
              ? AirTransferDetails(
                  flightType: _flightType,
                  pickupAirport: _pickupAirport.text.trim(),
                  destinationAirport: _destinationAirport.text.trim(),
                  airPermitNumber: _airPermitNumber.text.trim().isEmpty ? null : _airPermitNumber.text.trim(),
                )
              : null,

      deadBodyDetails:
          _serviceCategoryCode == 'DEAD_BODY'
              ? DeadBodyTransferDetails(
                  deathCertificateNumber: _deathCertificateNumber.text.trim().isEmpty ? null : _deathCertificateNumber.text.trim(),
                  freezerRequired: _freezerRequired,
                  hospitalMorgueReleaseGranted: _morgueReleaseGranted,
                  familyNOCReceived: _familyNocReceived,
                )
              : null,

      status:
          'NEW',

      amount:
          0,

      customerName:
          _name.text.trim(),

      mobileNumber:
          _phone.text.trim(),

      email:
          _email.text.trim(),

      alternatePhone:
          _alternatePhone.text.trim(),

      relationshipToPatient:
          _relationship,

      patientName:
          _patient.text.trim(),

      patientAge:
          age,

      patientGender:
          _gender,

      patientWeightKg:
          double.tryParse(
        _weight.text.trim(),
      ),

      currentCondition:
          _condition,

      medicalSummary:
          _summary.text.trim(),

      isEmergency:
          _emergency ||
              _condition ==
                  'Emergency',

      isConscious:
          _conscious,

      currentHospital:
          _currentHospital.text.trim(),

      destinationHospital:
          _destinationHospital.text.trim(),

      oxygenRequired:
          _oxygen,

      oxygenFlowLpm:
          _oxygenFlow,

      icuRequired:
          _icu,

      ventilatorRequired:
          _ventilator,

      cardiacMonitorRequired:
          _cardiac,

      stretcherRequired:
          _stretcher,

      wheelchairRequired:
          _wheelchair,

      pediatricPatient:
          age > 0 && age < 14,

      doctorRequired:
          _doctor,

      emtRequired:
          _emt,

      medicalAttendantRequired:
          _attendant,

      additionalEquipment:
          const [],

      specialInstructions:
          _instructions.text.trim(),

      priority:
          (_emergency ||
                  _condition ==
                      'Emergency')
              ? 'CRITICAL_CODE_RED'
              : (_condition ==
                      'Serious'
                  ? 'HIGH'
                  : 'NORMAL'),

      customerCareStatus:
          'Pending',
    );


    showModalBottomSheet(
      context:
          context,

      isScrollControlled:
          true,

      backgroundColor:
          Colors.transparent,

      builder:
          (sheetContext) {
        return FractionallySizedBox(
          heightFactor:
              0.94,

          child:
              BookingSummarySheet(
            bookingId:
                draft.id,

            pickup:
                draft.pickup,

            destination:
                draft.destination,

            ambulanceType:
                _ambulance,

            patientName:
                draft.patientName,

            extraDetails:
                'Condition: ${draft.currentCondition}\n'
                'Priority: ${draft.priority}\n'
                'Oxygen: ${draft.oxygenRequired ? 'Yes' : 'No'}  • '
                'ICU: ${draft.icuRequired ? 'Yes' : 'No'}  • '
                'Ventilator: ${draft.ventilatorRequired ? 'Yes' : 'No'}\n'
                'Preferred: ${draft.date} • ${draft.time}',

            onConfirmDispatch:
                () {
              Navigator.pop(
                sheetContext,
              );

              widget.onSubmit(
                draft,
              );
            },
          ),
        );
      },
    );
  }


  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _section(
    String title,
    IconData icon,
    Widget child,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child:
          Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.all(
          13,
        ),

        decoration:
            BoxDecoration(
          color:
              AppColors
                  .surfaceContainer,

          borderRadius:
              BorderRadius.circular(
            AppRadius.card,
          ),

          border:
              Border.all(
            color:
                AppColors
                    .outlineVariant,
          ),
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,

          children: [

            // --------------------------------------------------
            // SECTION HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .center,

              children: [

                Container(
                  width:
                      28,

                  height:
                      28,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .primary
                            .withValues(
                          alpha: 0.09
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      9,
                    ),
                  ),

                  child:
                      Icon(
                    icon,

                    color:
                        AppColors
                            .primary,

                    size:
                        15,
                  ),
                ),

                const SizedBox(
                  width:
                      8,
                ),

                Expanded(
                  child:
                      Text(
                    title,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        AppTextStyles
                            .cardTitle
                            .copyWith(
                      fontSize:
                          12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height:
                  11,
            ),

            child,
          ],
        ),
      ),
    );
  }


  // ============================================================
  // RESPONSIVE DROPDOWN
  // ============================================================

  Widget _drop(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?>
        onChanged,
  ) {
    return DropdownButtonFormField<
        String>(
      initialValue:
          value,

      isExpanded:
          true,

      decoration:
          InputDecoration(
        labelText:
            label,

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal:
              12,

          vertical:
              12,
        ),
      ),

      items:
          values.map(
        (
          item,
        ) {
          return DropdownMenuItem<
              String>(
            value:
                item,

            child:
                Text(
              item,

              maxLines:
                  1,

              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          );
        },
      ).toList(),

      onChanged:
          onChanged,
    );
  }


  // ============================================================
  // SAFE CHECKBOX
  // ============================================================

  Widget _check(
    String title,
    bool value,
    ValueChanged<bool?>
        onChanged,
  ) {
    return InkWell(
      onTap:
          () => onChanged(
        !value,
      ),

      borderRadius:
          BorderRadius.circular(
        10,
      ),

      child:
          Padding(
        padding:
            const EdgeInsets
                .symmetric(
          vertical:
              2,
        ),

        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .center,

          children: [

            SizedBox(
              width:
                  34,

              height:
                  34,

              child:
                  Checkbox(
                value:
                    value,

                onChanged:
                    onChanged,

                visualDensity:
                    VisualDensity
                        .compact,
              ),
            ),

            const SizedBox(
              width:
                  2,
            ),

            Expanded(
              child:
                  Text(
                title,

                maxLines:
                    2,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    AppTextStyles
                        .bodyMedium
                        .copyWith(
                  fontSize:
                      10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<String> _subtypesFor(String category) {
    switch (category) {
      case 'RAILWAY': return const ['TRAIN_ICU_COACH'];
      case 'AIR': return const ['AIR_DOMESTIC_JET', 'AIR_INTERNATIONAL_HELI_OR_JET'];
      case 'DEAD_BODY': return const ['DEAD_BODY_FREEZER'];
      default: return const ['BASIC_OXYGEN', 'ADVANCED_ICU', 'PEDIATRIC_ICU'];
    }
  }

  Widget _textInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AeroMedTextField(
        label: label,
        controller: controller,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {

        final width =
            constraints.maxWidth;

        final mobile =
            width <= 480;

        return AeroMedPage(

          child:
              Form(

            key:
                _formKey,

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

              children: [

                // ==================================================
                // PAGE HEADER
                // ==================================================

                FadeSlideIn(
                  child:
                      AeroMedPageHeader(
                    title:
                        'Book an Ambulance',

                    subtitle:
                        mobile
                            ? 'Tell us who needs help and where you need to go.'
                            : 'Answer a few simple questions. We will use your answers to prepare the right crew and vehicle.',
                  ),
                ),

                const SizedBox(
                  height:
                      14,
                ),

                if (_validationErrors.isNotEmpty)
                  AeroMedFormValidationSummary(
                    errors: _validationErrors,
                  ),


                // ==================================================
                // 1. REQUESTER
                // ==================================================

                _section(
                  '1. Who is requesting the ambulance?',

                  Icons
                      .person_outline_rounded,

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [

                      AeroMedTextField(
                        label:
                            'Your name',

                        controller:
                            _name,

                        icon:
                            Icons
                                .person_outline,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter your name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      AeroMedTextField(
                        label:
                            'Mobile number',

                        controller:
                            _phone,

                        icon:
                            Icons
                                .phone_outlined,

                        keyboardType:
                            TextInputType
                                .phone,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter a mobile number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      AeroMedTextField(
                        label:
                            'Email address',

                        controller:
                            _email,

                        icon:
                            Icons
                                .email_outlined,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter an email address';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      AeroMedTextField(
                        label:
                            'Alternate phone (optional)',

                        controller:
                            _alternatePhone,

                        keyboardType:
                            TextInputType
                                .phone,
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      _drop(
                        'Relationship to the patient',
                        _relationship,
                        const [
                          'Self',
                          'Parent',
                          'Spouse',
                          'Sibling',
                          'Relative',
                          'Caregiver',
                          'Other',
                        ],
                        (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(
                            () {
                              _relationship =
                                  value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),


                // ==================================================
                // 2. PATIENT
                // ==================================================

                _section(
                  '2. Who needs help?',

                  Icons
                      .personal_injury_outlined,

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [

                      AeroMedTextField(
                        label:
                            'Patient name',

                        controller:
                            _patient,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter the patient name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Expanded(
                            child:
                                AeroMedTextField(
                              label:
                                  'Patient age',

                              controller:
                                  _age,

                              keyboardType:
                                  TextInputType
                                      .number,

                              validator:
                                  (value) {
                                if (int.tryParse(
                                      value ??
                                          '',
                                    ) ==
                                    null) {
                                  return 'Required';
                                }

                                return null;
                              },
                            ),
                          ),

                          const SizedBox(
                            width:
                                8,
                          ),

                          Expanded(
                            child:
                                AeroMedTextField(
                              label:
                                  'Weight kg',

                              controller:
                                  _weight,

                              keyboardType:
                                  TextInputType
                                      .number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      _drop(
                        'Gender',
                        _gender,
                        const [
                          'Male',
                          'Female',
                          'Other',
                        ],
                        (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(
                            () {
                              _gender =
                                  value;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      _drop(
                        'Patient condition',
                        _condition,
                        const [
                          'Stable',
                          'Needs Medical Assistance',
                          'Serious',
                          'Emergency',
                          'Not Sure',
                        ],
                        (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(
                            () {
                              _condition =
                                  value;

                              _emergency =
                                  value ==
                                      'Emergency';
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      _check(
                        'The patient is conscious',
                        _conscious,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _conscious =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'This is an emergency / Code Red request',
                        _emergency,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _emergency =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 5),

                      _drop(
                        'Currently admitted in a hospital?',
                        _isAdmittedInHospital,
                        const ['Yes', 'No', 'Not Sure'],
                        (value) => setState(() => _isAdmittedInHospital = value ?? _isAdmittedInHospital),
                      ),

                      const SizedBox(height: 5),


                      AeroMedTextField(
                        label:
                            'Current hospital or location',

                        controller:
                            _currentHospital,

                        icon:
                            Icons
                                .local_hospital_outlined,
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      AeroMedTextField(
                        label:
                            'Destination hospital',

                        controller:
                            _destinationHospital,

                        icon:
                            Icons
                                .local_hospital,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter the destination hospital';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            9,
                      ),

                      AeroMedTextField(
                        label:
                            'Medical condition summary',

                        controller:
                            _summary,

                        maxLines:
                            3,

                        hintText:
                            'Diagnosis, symptoms, recent procedure, special context...',
                      ),
                    ],
                  ),
                ),


                // ==================================================
                // 3. ROUTE
                // ==================================================

                _section(
                  '3. Where should we go?',

                  Icons
                      .route_outlined,

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [

                      AeroMedTextField(
                        label:
                            'Pickup address',

                        controller:
                            _pickup,

                        icon:
                            Icons
                                .my_location_rounded,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Pickup location is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            4,
                      ),

                      Align(
                        alignment:
                            Alignment
                                .centerLeft,

                        child:
                            TextButton.icon(
                          onPressed:
                              _isLocating
                                  ? null
                                  : _useCurrentLocation,

                          icon:
                              _isLocating
                                  ? const SizedBox(
                                      width:
                                          14,
                                      height:
                                          14,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .gps_fixed_rounded,
                                      size:
                                          15,
                                    ),

                          label:
                              Text(
                            _isLocating
                                ? 'Finding location...'
                                : 'Use my current location',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height:
                            4,
                      ),

                      AeroMedTextField(
                        label:
                            'Destination address',

                        controller:
                            _destination,

                        icon:
                            Icons
                                .location_on_outlined,

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Destination is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      // --------------------------------------------
                      // DATE / TIME
                      //
                      // On mobile, use a vertical layout.
                      // --------------------------------------------

                      if (mobile)

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,

                          children: [

                            SizedBox(
                              height:
                                  42,

                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _pickDate,

                                icon:
                                    const Icon(
                                  Icons
                                      .calendar_today_outlined,
                                  size:
                                      15,
                                ),

                                label:
                                    Text(
                                  _date,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height:
                                  7,
                            ),

                            SizedBox(
                              height:
                                  42,

                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _date ==
                                            'Immediate'
                                        ? null
                                        : _pickTime,

                                icon:
                                    const Icon(
                                  Icons
                                      .schedule_outlined,
                                  size:
                                      15,
                                ),

                                label:
                                    Text(
                                  _date ==
                                          'Immediate'
                                      ? 'Now'
                                      : _timeLabel(),
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )

                      else

                        Row(
                          children: [

                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _pickDate,

                                icon:
                                    const Icon(
                                  Icons
                                      .calendar_today_outlined,
                                  size:
                                      15,
                                ),

                                label:
                                    Text(
                                  _date,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width:
                                  10,
                            ),

                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _date ==
                                            'Immediate'
                                        ? null
                                        : _pickTime,

                                icon:
                                    const Icon(
                                  Icons
                                      .schedule_outlined,
                                  size:
                                      15,
                                ),

                                label:
                                    Text(
                                  _date ==
                                          'Immediate'
                                      ? 'Now'
                                      : _timeLabel(),
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Align(
                        alignment:
                            Alignment
                                .centerLeft,

                        child:
                            TextButton.icon(
                          onPressed:
                              () {
                            setState(
                              () {
                                _date =
                                    'Immediate';

                                _scheduledTime =
                                    null;
                              },
                            );
                          },

                          icon:
                              const Icon(
                            Icons
                                .flash_on_rounded,
                            size:
                                15,
                          ),

                          label:
                              const Text(
                            'Use immediate dispatch',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                // ==================================================
                // 4. MEDICAL SUPPORT
                // ==================================================

                _section(
                  '4. What support does the patient require?',

                  Icons
                      .medical_services_outlined,

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [

                      _check(
                        'Oxygen required',
                        _oxygen,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _oxygen =
                                  value ??
                                      false;

                              if (!_oxygen) {
                                _oxygenFlow =
                                    null;
                              }
                            },
                          );
                        },
                      ),

                      if (_oxygen) ...[

                        const SizedBox(
                          height:
                              4,
                        ),

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                10,
                            vertical:
                                4,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                AppColors
                                    .surfaceContainerHigh,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),

                          child:
                              Row(
                            children: [

                              Expanded(
                                child:
                                    Text(
                                  'Oxygen flow',
                                  style:
                                      AppTextStyles
                                          .bodyMedium
                                          .copyWith(
                                    fontSize:
                                        10,
                                  ),
                                ),
                              ),

                              DropdownButton<double>(
                                value:
                                    _oxygenFlow,

                                hint:
                                    const Text(
                                  'L/min',
                                ),

                                items:
                                    const [
                                  2,
                                  4,
                                  6,
                                  8,
                                  10,
                                  15,
                                ].map(
                                  (
                                    value,
                                  ) {
                                    return DropdownMenuItem<
                                        double>(
                                      value:
                                          value.toDouble(),

                                      child:
                                          Text(
                                        '$value L/min',
                                      ),
                                    );
                                  },
                                ).toList(),

                                onChanged:
                                    (
                                  value,
                                ) {
                                  setState(
                                    () {
                                      _oxygenFlow =
                                          value;
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      _check(
                        'ICU monitoring required',
                        _icu,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _icu =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'Ventilator required',
                        _ventilator,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _ventilator =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      if (_ventilator) ...[
                        const SizedBox(height: 4),
                        _drop(
                          'Ventilator mode',
                          _ventilatorMode,
                          const [
                            'Transport Ventilator',
                            'Pressure Controlled',
                            'Volume Controlled',
                            'CPAP / BiPAP',
                          ],
                          (value) => setState(() => _ventilatorModeValue = value ?? _ventilatorModeValue),
                        ),
                        const SizedBox(height: 5),
                      ],

                      _check(
                        'Cardiac monitor required',
                        _cardiac,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _cardiac =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'Stretcher',
                        _stretcher,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _stretcher =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'Wheelchair',
                        _wheelchair,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _wheelchair =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'Doctor required',
                        _doctor,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _doctor =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      _check(
                        'EMT / Paramedic required',
                        _emt,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _emt =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      if (_doctor) ...[

                        const SizedBox(
                          height:
                              5,
                        ),

                        _drop(
                          'Doctor specialization',
                          _doctorSpecialization,
                          const [
                            'General Physician',
                            'Cardiologist',
                            'Neurologist',
                            'Orthopedic',
                            'Pediatrician',
                            'Anesthetist',
                            'Emergency Medicine',
                            'Surgeon',
                            'Other',
                          ],
                          (
                            value,
                          ) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                _doctorSpecialization =
                                    value;
                              },
                            );
                          },
                        ),
                      ],

                      _check(
                        'Medical attendant required',
                        _attendant,
                        (
                          value,
                        ) {
                          setState(
                            () {
                              _attendant =
                                  value ??
                                      false;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height:
                            6,
                      ),

                      AeroMedTextField(
                        label:
                            'Special instructions / additional equipment',

                        controller:
                            _instructions,

                        maxLines:
                            3,

                        hintText:
                            'Suction machine, syringe pump, incubator, family instructions...',
                      ),
                    ],
                  ),
                ),


                // ==================================================
                // 5. TRANSPORT TYPE
                // ==================================================

                _section(
                  '5. Choose the transport type',

                  Icons
                      .local_shipping_outlined,

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [

                      Text(
                        'Choose the type of medical transportation you are requesting. Our operations team will determine the suitable vehicle and crew after verification.',

                        style:
                            AppTextStyles
                                .supporting
                                .copyWith(
                          fontSize:
                              mobile
                                  ? 9
                                  : null,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      _transportModeTile(
                        'Road Ambulance',
                        'City and intercity road transfer',
                        Icons
                            .local_shipping_outlined,
                      ),

                      _transportModeTile(
                        'Railway Ambulance',
                        'Train medical coach transfer',
                        Icons.train_rounded,
                      ),

                      _transportModeTile(
                        'Air Ambulance',
                        'Domestic or jet medevac transfer',
                        Icons
                            .flight_takeoff_rounded,
                      ),

                      _transportModeTile(
                        'Dead Body Transfer',
                        'Mortuary freezer transport',
                        Icons
                            .inventory_2_outlined,
                      ),
                    ],
                  ),
                ),


                // ==================================================
                // TRANSPORT-SPECIFIC DETAILS
                // ==================================================

                _section(
                    'Transport-specific details',
                    Icons.assignment_outlined,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _drop(
                          'Service subtype',
                          _serviceSubtype,
                          _subtypesFor(_serviceCategoryCode),
                          (value) => setState(() => _serviceSubtype = value ?? _serviceSubtype),
                        ),
                        const SizedBox(height: 10),
                        if (_ambulance == 'Railway Ambulance') ...[
                          _textInput(_trainNumber, 'Train number *'),
                          _textInput(_trainName, 'Train name *'),
                          _textInput(_coachNumber, 'Coach number *'),
                          _textInput(_pickupStation, 'Pickup station *'),
                          _textInput(_destinationStation, 'Destination station *'),
                        ],
                        if (_ambulance == 'Air Ambulance') ...[
                          _drop('Flight type', _flightType, const ['Domestic', 'International'], (v) => setState(() => _flightType = v ?? _flightType)),
                          const SizedBox(height: 10),
                          _textInput(_pickupAirport, 'Pickup airport *'),
                          _textInput(_destinationAirport, 'Destination airport *'),
                          _textInput(_airPermitNumber, 'Air permit number (if available)'),
                        ],
                        if (_ambulance == 'Dead Body Transfer') ...[
                          _textInput(_deathCertificateNumber, 'Death certificate number'),
                          _check('Freezer required', _freezerRequired, (v) => setState(() => _freezerRequired = v ?? _freezerRequired)),
                          _check('Hospital/morgue release granted', _morgueReleaseGranted, (v) => setState(() => _morgueReleaseGranted = v ?? _morgueReleaseGranted)),
                          _check('Family NOC received', _familyNocReceived, (v) => setState(() => _familyNocReceived = v ?? _familyNocReceived)),
                        ],
                      ],
                    ),
                  ),

                // ==================================================
                // REVIEW
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      AeroMedButton(
                    label:
                        'Review Request',

                    icon:
                        Icons
                            .arrow_forward_rounded,

                    trailingIcon:
                        Icons
                            .receipt_long_outlined,

                    height:
                        mobile
                            ? 46
                            : 50,

                    onTap:
                        _review,
                  ),
                ),

                const SizedBox(
                  height:
                      24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ============================================================
  // TRANSPORT TILE
  // ============================================================

  Widget _transportModeTile(
    String title,
    String description,
    IconData icon,
  ) {
    final selected =
        _ambulance ==
            title;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            8,
      ),

      child:
          Material(
        color:
            Colors.transparent,

        child:
            InkWell(
          onTap:
              () {
            setState(
              () {
                _ambulance = title;
                switch (title) {
                  case 'Road Ambulance':
                    _serviceSubtype = 'ADVANCED_ICU';
                    break;
                  case 'Railway Ambulance':
                    _serviceSubtype = 'TRAIN_ICU_COACH';
                    break;
                  case 'Air Ambulance':
                    _serviceSubtype = 'AIR_DOMESTIC_JET';
                    break;
                  case 'Dead Body Transfer':
                    _serviceSubtype = 'DEAD_BODY_FREEZER';
                    break;
                }
              },
            );
          },

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          child:
              Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              11,
            ),

            decoration:
                BoxDecoration(
              color:
                  selected
                      ? AppColors
                          .secondaryContainer
                      : AppColors
                          .surfaceContainerHigh,

              borderRadius:
                  BorderRadius.circular(
                15,
              ),

              border:
                  Border.all(
                color:
                    selected
                        ? AppColors
                            .primary
                        : AppColors
                            .outlineVariant,

                width:
                    selected
                        ? 1.3
                        : 1,
              ),
            ),

            child:
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .center,

              children: [

                Container(
                  width:
                      34,

                  height:
                      34,

                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? AppColors
                                .primary
                                .withValues(
                                  alpha: 0.10
                            )
                            : AppColors
                                .surfaceContainer,

                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),

                  child:
                      Icon(
                    icon,

                    color:
                        selected
                            ? AppColors
                                .primary
                            : AppColors
                                .textMuted,

                    size:
                        17,
                  ),
                ),

                const SizedBox(
                  width:
                      9,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        title,

                        maxLines:
                            1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            AppTextStyles
                                .bodyStrong
                                .copyWith(
                          fontSize:
                              10,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        description,

                        maxLines:
                            2,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            AppTextStyles
                                .supporting
                                .copyWith(
                          fontSize:
                              7.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width:
                      6,
                ),

                Icon(
                  selected
                      ? Icons
                          .radio_button_checked
                      : Icons
                          .radio_button_off,

                  color:
                      selected
                          ? AppColors
                              .primary
                          : AppColors
                              .textMuted,

                  size:
                      18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}