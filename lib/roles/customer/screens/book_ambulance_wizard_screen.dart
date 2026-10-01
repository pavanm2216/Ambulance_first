import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

/// Customer booking wizard.
///
/// Step 1 now captures booking method + transport service type. The remaining
/// steps retain the existing clinical booking workflow.
class BookAmbulanceWizardScreen extends StatefulWidget {
  const BookAmbulanceWizardScreen({
    super.key,
    required this.user,
    required this.onBookingCreated,
    required this.onCancel,
  });

  final AuthUser user;
  final ValueChanged<Booking> onBookingCreated;
  final VoidCallback onCancel;

  @override
  State<BookAmbulanceWizardScreen> createState() =>
      _BookAmbulanceWizardScreenState();
}

class _BookAmbulanceWizardScreenState extends State<BookAmbulanceWizardScreen> {
  int _currentStep = 0;
  bool _submitting = false;
  bool _gettingLocation = false;
  bool _speechInitialized = false;
  bool _voiceListening = false;
  bool _voiceInterviewActive = false;
  bool _voiceInterviewComplete = false;
  Timer? _voiceResultTimer;
  String _voiceTranscript = '';
  String _voiceStatus = 'Start to answer the booking questions by voice.';
  String _voiceQuestion = '';
  int _voiceQuestionNumber = 0;
  int _voiceQuestionCount = 0;
  String _voiceQuestionKey = '';
  final List<({bool fromCustomer, String text})> _voiceConversation = [];
  final ScrollController _voiceChatScrollController = ScrollController();
  final ValueNotifier<int> _voiceDialogRevision = ValueNotifier<int>(0);
  final Set<String> _voiceCompletedQuestionKeys = {};
  Completer<String?>? _voiceAnswerCompleter;
  String? _voiceDraftBookingId;
  String _voiceConditionDescription = '';
  StateSetter? _refreshVoiceDialog;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _voicePrompts = FlutterTts();

  final _formKey = GlobalKey<FormState>();
  final SupabaseWorkflowRepository _workflow = SupabaseWorkflowRepository();
  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();
  final LocationService _locationService = LocationService();

  // Step 1
  String _bookingMethod = 'ONLINE';
  String _serviceCategory = 'ROAD';
  String _transportMode = 'ROAD_AMBULANCE';

  // Step 2
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _customerPhoneCtrl;
  late final TextEditingController _customerEmailCtrl;
  String _relationship = 'Self';

  // Step 3
  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _patientAgeCtrl = TextEditingController();
  String _patientGender = '';
  String _patientCondition = '';
  bool _isEmergency = false;

  // Step 4
  String _ambulanceCategory = '';
  bool _oxygenRequired = false;
  bool _icuRequired = false;
  bool _ventilatorRequired = false;
  bool _cardiacMonitorRequired = false;
  bool _pediatricPatient = false;
  bool _doctorRequired = false;
  bool _emtRequired = false;
  bool _stretcherRequired = false;
  bool _wheelchairRequired = false;
  final Set<String> _autoSelectedRequirements = {};
  final List<String> _additionalEquipment = [];
  final Set<String> _autoSelectedEquipment = {};

  // Step 5
  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _currentHospitalCtrl = TextEditingController();
  final TextEditingController _destHospitalCtrl = TextEditingController();
  double? _pickupLatitude;
  double? _pickupLongitude;
  String _pickupCity = '';

  // Step 6
  String _scheduleType = 'IMMEDIATE';
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();

  // Backend fare estimate
  String? _estimateBookingId;
  double? _estimatedFare;
  double? _estimatedDistanceKm;
  bool _estimatingFare = false;
  String? _estimateError;

  @override
  void initState() {
    super.initState();
    _customerNameCtrl = TextEditingController(text: widget.user.name);
    _customerPhoneCtrl = TextEditingController(text: widget.user.phone);
    _customerEmailCtrl = TextEditingController(text: widget.user.email);
    _voicePrompts.awaitSpeakCompletion(true);
    _voicePrompts.setLanguage('en-US');
    _voicePrompts.setSpeechRate(0.48);
  }

  @override
  void dispose() {
    _voiceInterviewActive = false;
    _voiceAnswerCompleter?.complete(null);
    _voiceResultTimer?.cancel();
    _voicePrompts.stop();
    _speech.cancel();
    _voiceChatScrollController.dispose();
    _voiceDialogRevision.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerEmailCtrl.dispose();
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _pickupCtrl.dispose();
    _destinationCtrl.dispose();
    _currentHospitalCtrl.dispose();
    _destHospitalCtrl.dispose();
    super.dispose();
  }

  static const _stepTitles = [
    'Service & Booking Method',
    'Customer Contact',
    'Patient Demographics',
    'Medical Requirements',
    'Pickup & Destination',
    'Schedule & Timing',
    'Review & Authorize',
  ];

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    // The customer must see the DB-backed route distance and basic fare
    // before the final confirmation. The estimate uses the same real
    // booking + route + fare RPCs that power the production workflow.
    if (_currentStep == 5) {
      final ready = await _prepareBackendEstimate();
      if (!ready || !mounted) return;
      setState(() => _currentStep++);
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      return;
    }

    await _submitBooking();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_bookingMethod != 'ONLINE') {
          _showCallCareDialog();
          return false;
        }
        if (_serviceCategory.isEmpty) {
          _showError('Please select a service type.');
          return false;
        }
        return true;
      case 1:
        if (_customerNameCtrl.text.trim().isEmpty ||
            _customerPhoneCtrl.text.trim().isEmpty) {
          _showError('Please provide customer name and mobile number.');
          return false;
        }
        return true;
      case 2:
        if (_patientNameCtrl.text.trim().isEmpty ||
            _patientAgeCtrl.text.trim().isEmpty ||
            _patientGender.isEmpty ||
            _patientCondition.isEmpty) {
          _showError('Please complete the patient details.');
          return false;
        }
        final age = int.tryParse(_patientAgeCtrl.text.trim());
        if (age == null || age < 0) {
          _showError('Please enter a valid patient age.');
          return false;
        }
        return true;
      case 3:
        if (_serviceCategory == 'ROAD' && _ambulanceCategory.isEmpty) {
          _showError('Please select the road ambulance category.');
          return false;
        }
        return true;
      case 4:
        if (_pickupCtrl.text.trim().isEmpty ||
            _destinationCtrl.text.trim().isEmpty) {
          _showError('Please enter both pickup and destination.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep < 6) {
          _estimateBookingId = null;
          _estimatedFare = null;
          _estimatedDistanceKm = null;
          _estimateError = null;
        }
      });
    } else {
      widget.onCancel();
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

  // ignore: unused_element
  Future<void> _showVoiceBookingDialog() async {
    _voiceTranscript = '';
    _voiceStatus = 'Start to answer the booking questions by voice.';
    _voiceQuestion = '';
    _voiceConversation.clear();
    _voiceInterviewActive = false;
    _voiceInterviewComplete = false;
    _refreshVoiceDialog = (_) {
      if (mounted) _voiceDialogRevision.value++;
    };
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder<int>(
        valueListenable: _voiceDialogRevision,
        builder: (context, revision, child) => AlertDialog(
          title: const Text('Voice booking interview'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_voiceQuestion.isNotEmpty) ...[
                  Text(
                    'Question $_voiceQuestionNumber of $_voiceQuestionCount',
                    style: AmbulanceFirstTypography.labelSm(
                      color: AmbulanceFirstColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _voiceQuestionCount == 0
                        ? 0
                        : _voiceQuestionNumber / _voiceQuestionCount,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _voiceQuestion,
                    style: AmbulanceFirstTypography.bodyMd(
                      color: AmbulanceFirstColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else
                  const Text(
                    'I will ask for each booking detail, listen to your answer, and fill the form. '
                    'Say “skip” for optional questions.',
                  ),
                Row(
                  children: [
                    Icon(
                      _voiceListening ? Icons.mic_rounded : Icons.info_outline,
                      size: 18,
                      color: _voiceListening
                          ? AmbulanceFirstColors.secondary
                          : AmbulanceFirstColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_voiceStatus)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 150,
                    maxHeight: 290,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AmbulanceFirstColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(
                      AmbulanceFirstSpacing.radiusSm,
                    ),
                  ),
                  child: ListView.builder(
                    controller: _voiceChatScrollController,
                    itemCount:
                        _voiceConversation.length +
                        (_voiceTranscript.trim().isNotEmpty &&
                                !_voiceCompletedQuestionKeys.contains(
                                  _voiceQuestionKey,
                                )
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index < _voiceConversation.length) {
                        final message = _voiceConversation[index];
                        return _buildVoiceChatBubble(
                          fromCustomer: message.fromCustomer,
                          text: message.text,
                        );
                      }
                      return _buildVoiceChatBubble(
                        fromCustomer: true,
                        text: _voiceTranscript,
                        isLive: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _stopVoiceInterview(closeDialog: true);
              },
              child: Text(
                _voiceDraftBookingId == null
                    ? 'CANCEL'
                    : 'SAVE FOR CUSTOMER CARE',
              ),
            ),
            if (_voiceTranscript.trim().isNotEmpty)
              OutlinedButton(
                onPressed: _acceptCurrentVoiceAnswer,
                child: const Text('USE ANSWER'),
              ),
            if (_voiceInterviewComplete)
              FilledButton(
                onPressed: () {
                  setState(() => _currentStep = _firstIncompleteVoiceStep());
                  Navigator.pop(dialogContext);
                },
                child: const Text('REVIEW BOOKING'),
              )
            else
              FilledButton.icon(
                onPressed: _voiceInterviewActive
                    ? () => _stopVoiceInterview(closeDialog: true)
                    : _startVoiceInterview,
                icon: Icon(
                  _voiceInterviewActive
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                ),
                label: Text(
                  _voiceInterviewActive
                      ? 'STOP & SEND TO CARE'
                      : 'START VOICE BOOKING',
                ),
              ),
          ],
        ),
      ),
    );
    _refreshVoiceDialog = null;
    if (_speech.isListening) await _speech.cancel();
  }

  Future<void> _startVoiceInterview() async {
    _voiceInterviewActive = true;
    _voiceInterviewComplete = false;
    _voiceStatus = 'Preparing voice recognition...';
    _refreshVoiceDialog?.call(() {});
    try {
      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize(
          onStatus: _onVoiceStatus,
          onError: _onVoiceError,
        );
      }
      if (!_speechInitialized) {
        _voiceStatus = 'Speech recognition is unavailable on this device.';
        _voiceInterviewActive = false;
        _refreshVoiceDialog?.call(() {});
        return;
      }
      await _voicePrompts.awaitSpeakCompletion(true);

      final questions = <({String key, String prompt, bool optional})>[
        (
          key: 'emergency',
          prompt: 'Is this an emergency? If the patient is in immediate danger, call your local emergency number now. Say yes or no.',
          optional: false,
        ),
        (
          key: 'pickup',
          prompt: 'Where should the ambulance pick up the patient? Say the full address, or say use my location after this interview.',
          optional: false,
        ),
        (
          key: 'phone',
          prompt: 'What number should Customer Care call? Say the digits one at a time.',
          optional: false,
        ),
        (
          key: 'condition',
          prompt: 'In a few words, what is happening with the patient? You do not need to diagnose.',
          optional: false,
        ),
        (
          key: 'destination',
          prompt: 'Where should the patient be taken? Say not sure if you need Customer Care to help decide.',
          optional: true,
        ),
        (
          key: 'service',
          prompt: 'If you know, which service do you need: road ambulance, air ambulance, rail ambulance, or dead body transfer? Say skip if unsure.',
          optional: true,
        ),
        (
          key: 'ambulanceType',
          prompt: 'If you know, which road ambulance type: oxygen ambulance, ICU ambulance, or NICU ambulance? Say skip if unsure.',
          optional: true,
        ),
        (
          key: 'customerName',
          prompt: 'What name should Customer Care ask for? Say skip to keep your account name.',
          optional: true,
        ),
        (
          key: 'patientName',
          prompt: 'What is the patient’s name? Say skip if you prefer not to provide it now.',
          optional: true,
        ),
        (
          key: 'age',
          prompt:
              'How old is the patient in years? Say skip if you do not know.',
          optional: true,
        ),
        (
          key: 'gender',
          prompt: 'What is the patient’s gender: male, female, or other? Say skip if you prefer.',
          optional: true,
        ),
        (
          key: 'equipment',
          prompt: 'Does the patient need oxygen, a ventilator, a cardiac monitor, a doctor, or other support? Say the items, none, or skip if unsure.',
          optional: true,
        ),
        (
          key: 'additionalEquipment',
          prompt:
              'Are any other equipment items needed? Say them, or say skip.',
          optional: true,
        ),
        (
          key: 'currentHospital',
          prompt: 'What is the current hospital? Say skip if not applicable.',
          optional: true,
        ),
        (
          key: 'destinationHospital',
          prompt:
              'What is the destination hospital? Say skip if not applicable.',
          optional: true,
        ),
        (
          key: 'relationship',
          prompt: 'What is your relationship to the patient, for example self, family, or friend? Say skip if you prefer.',
          optional: true,
        ),
        (
          key: 'email',
          prompt: 'What email address should we use? Say skip to keep your account email.',
          optional: true,
        ),
        (
          key: 'schedule',
          prompt: 'Should the ambulance come immediately or be scheduled for later? Say skip to request the soonest available ambulance.',
          optional: true,
        ),
        (
          key: 'scheduleDate',
          prompt:
              'What date is the scheduled transfer? Say day, month, and year.',
          optional: false,
        ),
        (
          key: 'scheduleTime',
          prompt: 'What time is the scheduled transfer? Say hour and minutes in 24-hour time.',
          optional: false,
        ),
      ];
      _voiceQuestionCount =
          questions.length - _voiceCompletedQuestionKeys.length;

      for (var index = 0; index < questions.length; index++) {
        if (!_voiceInterviewActive || !mounted) return;
        final question = questions[index];
        if (_voiceCompletedQuestionKeys.contains(question.key)) continue;
        if ((question.key == 'ambulanceType' && _serviceCategory != 'ROAD') ||
            (question.key.startsWith('schedule') &&
                _scheduleType != 'SCHEDULED' &&
                question.key != 'schedule')) {
          continue;
        }

        _voiceQuestionNumber = index + 1;
        _voiceQuestionKey = question.key;
        _voiceTranscript = '';
        _voiceQuestion = question.prompt;
        var accepted = false;
        while (_voiceInterviewActive && !accepted) {
          _voiceConversation.add((fromCustomer: false, text: question.prompt));
          _refreshVoiceChat();
          _voiceStatus = 'Speaking question, then listening for your answer...';
          _refreshVoiceDialog?.call(() {});
          await _speakVoicePrompt(question.prompt);
          if (!_voiceInterviewActive) return;

          final answer = await _listenForVoiceAnswer();
          if (!_voiceInterviewActive) return;
          if (answer == null || answer.trim().isEmpty) {
            _voiceConversation.add((
              fromCustomer: false,
              text: 'I did not catch that. Please try again.',
            ));
            _refreshVoiceChat();
            _voiceStatus = 'I did not hear an answer. I will ask again.';
            continue;
          }
          _voiceConversation.add((fromCustomer: true, text: answer.trim()));
          _refreshVoiceChat();
          if (question.optional && _isVoiceSkip(answer)) {
            _voiceCompletedQuestionKeys.add(question.key);
            accepted = true;
            continue;
          }
          final issue = _voiceAnswerIssue(question.key, answer);
          if (issue != null) {
            _voiceConversation.add((fromCustomer: false, text: issue));
            _refreshVoiceChat();
            _voiceStatus = issue;
            await _speakVoicePrompt(issue);
            continue;
          }
          await _applyVoiceAnswer(question.key, answer);
          _voiceCompletedQuestionKeys.add(question.key);
          accepted = true;
          try {
            await _persistVoiceDraft();
            _voiceStatus =
                'Answer saved. Customer Care can see this callback request.';
          } catch (error) {
            _voiceStatus =
                'Answer captured, but could not save to Customer Care: $error';
          }
          _refreshVoiceDialog?.call(() {});
        }
      }

      if (!_voiceInterviewActive || !mounted) return;
      _voiceInterviewActive = false;
      _voiceInterviewComplete = true;
      _voiceQuestion = 'All booking details have been recorded.';
      _voiceStatus =
          'Your answers are filled in. Review them before submitting.';
      _refreshVoiceDialog?.call(() {});
      await _speakVoicePrompt(_voiceQuestion);
    } catch (error) {
      _voiceInterviewActive = false;
      _voiceStatus = 'Voice booking could not continue: $error';
      _refreshVoiceDialog?.call(() {});
    }
  }

  Widget _buildVoiceChatBubble({
    required bool fromCustomer,
    required String text,
    bool isLive = false,
  }) {
    final bubbleColor = fromCustomer
        ? AmbulanceFirstColors.primaryFixed
        : AmbulanceFirstColors.surfaceContainerLowest;
    return Align(
      alignment: fromCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          border: Border.all(color: AmbulanceFirstColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromCustomer ? 'You' : 'Ambulance First',
              style: AmbulanceFirstTypography.labelSm(
                color: AmbulanceFirstColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              isLive ? '$text ...' : text,
              style: AmbulanceFirstTypography.bodySm(
                color: AmbulanceFirstColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshVoiceChat() {
    if (!mounted) return;
    _refreshVoiceDialog?.call(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _voiceChatScrollController.hasClients) {
        _voiceChatScrollController.animateTo(
          _voiceChatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _stopVoiceInterview({bool closeDialog = false}) async {
    _voiceInterviewActive = false;
    _voiceResultTimer?.cancel();
    final pendingAnswer = _voiceTranscript.trim();
    if (pendingAnswer.isNotEmpty &&
        _voiceQuestionKey.isNotEmpty &&
        !_voiceCompletedQuestionKeys.contains(_voiceQuestionKey)) {
      final issue = _voiceAnswerIssue(_voiceQuestionKey, pendingAnswer);
      if (issue == null && !_isVoiceSkip(pendingAnswer)) {
        await _applyVoiceAnswer(_voiceQuestionKey, pendingAnswer);
        _voiceConversation.add((fromCustomer: true, text: pendingAnswer));
        _voiceCompletedQuestionKeys.add(_voiceQuestionKey);
      } else if (_isVoiceSkip(pendingAnswer)) {
        _voiceConversation.add((fromCustomer: true, text: pendingAnswer));
        _voiceCompletedQuestionKeys.add(_voiceQuestionKey);
      }
      _refreshVoiceChat();
    }
    _voiceAnswerCompleter?.complete(null);
    await _speech.stop();
    await _voicePrompts.stop();
    _voiceListening = false;
    if (_voiceDraftBookingId != null) {
      try {
        await _persistVoiceDraft();
        _voiceStatus = 'Request saved. Customer Care can call you back.';
      } catch (error) {
        _voiceStatus = 'Could not save the request: $error';
      }
    } else {
      _voiceStatus = 'Voice interview stopped.';
    }
    _refreshVoiceDialog?.call(() {});
    if (closeDialog && mounted) {
      Navigator.of(context).pop();
      if (_voiceDraftBookingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your request is saved for Customer Care to call back.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _speakVoicePrompt(String prompt) async {
    try {
      await _voicePrompts.speak(prompt);
    } catch (_) {
      _voiceStatus = prompt;
      _refreshVoiceDialog?.call(() {});
    }
  }

  Future<String?> _listenForVoiceAnswer() async {
    _voiceTranscript = '';
    final answerCompleter = Completer<String?>();
    _voiceAnswerCompleter = answerCompleter;
    _voiceStatus = 'Listening for your answer...';
    _refreshVoiceDialog?.call(() {});
    try {
      await _speech.listen(
        onResult: _onVoiceResult,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          autoPunctuation: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
        ),
      );
      _voiceListening = _speech.isListening;
      _refreshVoiceDialog?.call(() {});
      final answer = await answerCompleter.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () => null,
      );
      if (_speech.isListening) await _speech.stop();
      _voiceResultTimer?.cancel();
      _voiceAnswerCompleter = null;
      _voiceListening = false;
      if (answer == null) {
        _voiceStatus = 'No speech was recognized. I will repeat the question.';
      }
      return answer;
    } catch (error) {
      _voiceAnswerCompleter = null;
      _voiceListening = false;
      _voiceStatus = 'Microphone error: $error';
      _refreshVoiceDialog?.call(() {});
      return null;
    }
  }

  void _onVoiceStatus(String status) {
    if (!mounted) {
      _completeVoiceAnswer(null);
      return;
    }
    _voiceListening = _speech.isListening;
    if (status == 'listening') {
      _voiceStatus = 'Listening. Speak your answer now.';
    } else if (status == 'done' || status == 'notListening') {
      _voiceResultTimer?.cancel();
      if (_voiceTranscript.trim().isEmpty) {
        _completeVoiceAnswer(null);
      } else {
        _voiceResultTimer = Timer(
          const Duration(milliseconds: 500),
          () => _completeVoiceAnswer(_voiceTranscript.trim()),
        );
      }
    }
    _refreshVoiceDialog?.call(() {});
  }

  void _onVoiceError(dynamic error) {
    if (!mounted) {
      _completeVoiceAnswer(null);
      return;
    }
    _voiceListening = false;
    _voiceStatus = 'Speech recognition stopped. Keeping any words recognized.';
    _completeVoiceAnswer(
      _voiceTranscript.trim().isEmpty ? null : _voiceTranscript.trim(),
    );
    _refreshVoiceDialog?.call(() {});
  }

  void _onVoiceResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    _voiceTranscript = result.recognizedWords;
    _refreshVoiceDialog?.call(() {});
    if (_voiceTranscript.trim().isEmpty) return;
    _voiceResultTimer?.cancel();
    if (result.finalResult) {
      _completeVoiceAnswer(_voiceTranscript.trim());
    } else {
      _voiceResultTimer = Timer(
        const Duration(seconds: 6),
        () => _completeVoiceAnswer(_voiceTranscript.trim()),
      );
    }
  }

  void _completeVoiceAnswer(String? answer) {
    final completer = _voiceAnswerCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(answer);
    }
  }

  void _acceptCurrentVoiceAnswer() {
    _voiceResultTimer?.cancel();
    _completeVoiceAnswer(_voiceTranscript.trim());
    _speech.stop();
  }

  Future<void> _persistVoiceDraft() async {
    if (!SupabaseService.isConfigured) {
      throw StateError('Connect to Customer Care to save this voice request.');
    }
    _voiceDraftBookingId ??= 'VOICE-${DateTime.now().microsecondsSinceEpoch}';
    final payload = _bookingPayload()
      ..['id'] = _voiceDraftBookingId
      ..['booking_source'] = 'VOICE_INTAKE';
    _voiceDraftBookingId = await _workflow.saveCustomerVoiceBookingDraft(
      bookingId: _voiceDraftBookingId!,
      booking: payload,
    );
  }

  bool _isVoiceSkip(String answer) => RegExp(
    r'\b(skip|none|not applicable)\b',
    caseSensitive: false,
  ).hasMatch(answer);

  String _spokenDigits(String answer) {
    const digitWords = {
      'zero': '0',
      'oh': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
    };
    final result = StringBuffer();
    for (final token in answer.toLowerCase().split(RegExp(r'[^a-z0-9+]'))) {
      if (RegExp(r'^\d+$').hasMatch(token)) {
        result.write(token);
      } else if (digitWords.containsKey(token)) {
        result.write(digitWords[token]);
      } else if (token == 'plus') {
        result.write('+');
      }
    }
    return result.toString();
  }

  String? _voiceAnswerIssue(String key, String answer) {
    final normalized = answer.toLowerCase();
    switch (key) {
      case 'service':
        return RegExp(r'road|air|rail|train|dead body').hasMatch(normalized)
            ? null
            : 'Please say road, air, rail, or dead body transfer.';
      case 'ambulanceType':
        return RegExp(r'oxygen|icu|nicu|picu').hasMatch(normalized)
            ? null
            : 'Please say oxygen ambulance, ICU ambulance, or NICU ambulance.';
      case 'phone':
        final digits = _spokenDigits(answer).replaceAll('+', '');
        return digits.length >= 10 && digits.length <= 15
            ? null
            : 'Please say a phone number with 10 to 15 digits, one digit at a time.';
      case 'email':
        final email = answer
            .toLowerCase()
            .replaceAll(RegExp(r'\s+at\s+'), '@')
            .replaceAll(RegExp(r'\s+dot\s+'), '.')
            .replaceAll(' ', '');
        return email.contains('@') && email.contains('.')
            ? null
            : 'Please say the email using “at” and “dot”, or say skip.';
      case 'age':
        final age = int.tryParse(
          RegExp(r'\d+').firstMatch(answer)?.group(0) ?? '',
        );
        return age != null && age <= 120
            ? null
            : 'Please say the patient age as a number from 0 to 120.';
      case 'gender':
        return RegExp(r'\b(male|female|other)\b').hasMatch(normalized)
            ? null
            : 'Please say male, female, or other.';
      case 'condition':
        return null;
      case 'emergency':
        return RegExp(r'\b(yes|no|urgent|emergency)\b').hasMatch(normalized)
            ? null
            : 'Please answer yes or no.';
      case 'schedule':
        return RegExp(r'immediate|now|scheduled|later').hasMatch(normalized)
            ? null
            : 'Please say immediate or scheduled.';
      case 'scheduleDate':
        final date = _parseVoiceDate(answer);
        if (date == null) {
          return 'Please say a valid future date, for example 15 October 2026.';
        }
        final today = DateUtils.dateOnly(DateTime.now());
        if (date.isBefore(today) ||
            date.isAfter(today.add(const Duration(days: 90)))) {
          return 'Please choose a date within the next 90 days.';
        }
        return null;
      case 'scheduleTime':
        return _parseVoiceTime(answer) == null
            ? 'Please say the time in 24-hour format, for example 14 30.'
            : null;
      default:
        return answer.trim().isEmpty ? 'Please say an answer.' : null;
    }
  }

  Future<void> _applyVoiceAnswer(String key, String answer) async {
    final normalized = answer.toLowerCase();
    switch (key) {
      case 'service':
        if (normalized.contains('air')) {
          _selectService('AIR', 'AIR_AMBULANCE');
        } else if (normalized.contains('rail') ||
            normalized.contains('train')) {
          _selectService('RAIL', 'RAIL_AMBULANCE');
        } else if (normalized.contains('dead')) {
          _selectService('DEAD_BODY', 'DEAD_BODY_TRANSFER');
        } else {
          _selectService('ROAD', 'ROAD_AMBULANCE');
        }
      case 'ambulanceType':
        if (normalized.contains('nicu') || normalized.contains('picu')) {
          _applyAmbulancePreset('NICU Ambulance (PICU/NICU)');
        } else if (normalized.contains('icu')) {
          _applyAmbulancePreset('ICU Ambulance (ALS)');
        } else {
          _applyAmbulancePreset('Oxygen Ambulance (BLS)');
        }
      case 'customerName':
        _customerNameCtrl.text = answer.trim();
      case 'phone':
        _customerPhoneCtrl.text = _spokenDigits(answer);
      case 'email':
        _customerEmailCtrl.text = answer
            .toLowerCase()
            .replaceAll(RegExp(r'\s+at\s+'), '@')
            .replaceAll(RegExp(r'\s+dot\s+'), '.')
            .replaceAll(' ', '');
      case 'relationship':
        _relationship = _voiceRelationship(answer);
      case 'patientName':
        _patientNameCtrl.text = answer.trim();
      case 'age':
        _patientAgeCtrl.text = RegExp(r'\d+').firstMatch(answer)!.group(0)!;
      case 'gender':
        final gender = RegExp(
          r'\b(male|female|other)\b',
          caseSensitive: false,
        ).firstMatch(answer)!.group(1)!.toLowerCase();
        _patientGender = gender[0].toUpperCase() + gender.substring(1);
      case 'condition':
        _voiceConditionDescription = answer.trim();
        _patientCondition = _voiceCondition(answer);
      case 'emergency':
        _isEmergency = RegExp(r'\b(yes|urgent|emergency)\b')
            .hasMatch(normalized);
      case 'equipment':
        _oxygenRequired =
            normalized.contains('oxygen') ||
            _autoSelectedRequirements.contains('Oxygen');
        _icuRequired =
            normalized.contains('icu kit') ||
            _autoSelectedRequirements.contains('ICU Kit');
        _ventilatorRequired = normalized.contains('ventilator');
        _cardiacMonitorRequired =
            normalized.contains('cardiac monitor') ||
            _autoSelectedRequirements.contains('Cardiac Monitor');
        _pediatricPatient =
            normalized.contains('pediatric') ||
            _autoSelectedRequirements.contains('Pediatric Care');
        _doctorRequired = normalized.contains('doctor');
        _emtRequired =
            RegExp(r'\bemt\b').hasMatch(normalized) ||
            _autoSelectedRequirements.contains('EMT');
        _stretcherRequired = normalized.contains('stretcher');
        _wheelchairRequired = normalized.contains('wheelchair');
      case 'additionalEquipment':
        _additionalEquipment
          ..clear()
          ..addAll(
            answer
                .split(RegExp(r',|\band\b'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty),
          );
      case 'pickup':
        if (RegExp(r'\b(current location|my location|use location)\b')
            .hasMatch(normalized)) {
          await _useMyLocation();
        } else {
          _pickupCtrl.text = answer.trim();
          _pickupLatitude = null;
          _pickupLongitude = null;
        }
      case 'destination':
        _destinationCtrl.text = normalized.contains('not sure')
            ? ''
            : answer.trim();
      case 'currentHospital':
        _currentHospitalCtrl.text = answer.trim();
      case 'destinationHospital':
        _destHospitalCtrl.text = answer.trim();
      case 'schedule':
        _scheduleType = normalized.contains('immediate') || normalized == 'now'
            ? 'IMMEDIATE'
            : 'SCHEDULED';
      case 'scheduleDate':
        _scheduledDate = _parseVoiceDate(answer)!;
      case 'scheduleTime':
        _scheduledTime = _parseVoiceTime(answer)!;
    }
    if (mounted) setState(() {});
  }

  int _firstIncompleteVoiceStep() {
    if (_customerNameCtrl.text.trim().isEmpty ||
        _customerPhoneCtrl.text.trim().isEmpty) {
      return 1;
    }
    if (_patientNameCtrl.text.trim().isEmpty ||
        _patientAgeCtrl.text.trim().isEmpty ||
        _patientGender.isEmpty ||
        _patientCondition.isEmpty) {
      return 2;
    }
    if (_serviceCategory == 'ROAD' && _ambulanceCategory.isEmpty) return 3;
    if (_pickupCtrl.text.trim().isEmpty ||
        _destinationCtrl.text.trim().isEmpty) {
      return 4;
    }
    return 5;
  }

  String _voiceRelationship(String answer) {
    final value = answer.toLowerCase();
    if (value.contains('self')) return 'Self';
    if (value.contains('parent') || value.contains('guardian')) {
      return 'Family Guardian';
    }
    if (value.contains('relative')) return 'Relative';
    if (value.contains('friend')) return 'Friend';
    if (value.contains('doctor') || value.contains('physician')) {
      return 'Physician / Doctor';
    }
    if (value.contains('clinical') || value.contains('coordinator')) {
      return 'Clinical Coordinator';
    }
    if (value.contains('spouse') || value.contains('partner')) {
      return 'Spouse / Partner';
    }
    return 'Self';
  }

  String _voiceCondition(String answer) {
    final value = answer.toLowerCase();
    if (value.contains('cardiac')) return 'Cardiac Monitoring Required';
    if (value.contains('ventilator')) return 'Ventilator Dependent';
    if (value.contains('neonatal') ||
        value.contains('nicu') ||
        value.contains('picu')) {
      return 'Neonatal / PICU Specialized';
    }
    if (value.contains('post')) return 'Post-Operative Transfer';
    if (value.contains('trauma') || value.contains('decompensation')) {
      return 'Trauma / Acute Decompensation';
    }
    return 'Stable';
  }

  DateTime? _parseVoiceDate(String answer) {
    final numeric = RegExp(r'\b(\d{1,2})[ /-](\d{1,2})[ /-](\d{4})\b')
        .firstMatch(answer);
    if (numeric != null) {
      return DateTime.tryParse(
        '${numeric.group(3)}-${numeric.group(2)!.padLeft(2, '0')}-${numeric.group(1)!.padLeft(2, '0')}',
      );
    }
    final monthNames = <String, int>{
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    final named = RegExp(
      r'\b(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})\b',
      caseSensitive: false,
    ).firstMatch(answer);
    if (named == null) return null;
    return DateTime.tryParse(
      '${named.group(3)}-${monthNames[named.group(2)!.toLowerCase()]!.toString().padLeft(2, '0')}-${named.group(1)!.padLeft(2, '0')}',
    );
  }

  TimeOfDay? _parseVoiceTime(String answer) {
    final match = RegExp(r'\b(\d{1,2})\s*:?\s*(\d{2})\b').firstMatch(answer);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _selectService(String category, String transportMode) {
    setState(() {
      _serviceCategory = category;
      _transportMode = transportMode;

      // Reset road-only selections when switching to another transport type.
      if (category != 'ROAD') {
        _ambulanceCategory = '';
      }
    });
  }

  void _showCallCareDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Call Customer Care'),
        content: const Text(
          'The Customer Care calling integration is reserved for the inbound-call connection. '
          'For now, choose “Book by filling details” to create the booking directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _bookingMethod = 'ONLINE');
            },
            child: const Text('BOOK ONLINE'),
          ),
        ],
      ),
    );
  }

  Future<void> _useMyLocation() async {
    if (_gettingLocation) return;

    setState(() => _gettingLocation = true);
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _pickupLatitude = result.latitude;
        _pickupLongitude = result.longitude;
        _pickupCity = result.city;
        _pickupCtrl.text = result.address;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location captured: ${result.latitude.toStringAsFixed(6)}, '
            '${result.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  String? _serviceSubtypeForFare() {
    if (_serviceCategory != 'ROAD') return null;

    if (_ambulanceCategory.contains('NICU') ||
        _ambulanceCategory.contains('Pediatric')) {
      return 'PEDIATRIC_ICU';
    }

    if (_ambulanceCategory.contains('ICU')) {
      return 'ADVANCED_ICU';
    }

    return 'BASIC_OXYGEN';
  }

  Map<String, dynamic> _bookingPayload() {
    return {
      'booking_source': 'ONLINE',
      'service_category': _serviceCategory,
      'service_subtype': _serviceSubtypeForFare(),
      'transport_mode': _transportMode,
      'ambulance_type': _ambulanceCategory.isEmpty
          ? _serviceLabel(_serviceCategory)
          : _ambulanceCategory,
      'pickup_address': _pickupCtrl.text.trim(),
      'pickup_city': _pickupCity,
      'pickup_lat': _pickupLatitude,
      'pickup_lng': _pickupLongitude,
      'destination_address': _destinationCtrl.text.trim(),
      'current_hospital': _currentHospitalCtrl.text.trim(),
      'destination_hospital': _destHospitalCtrl.text.trim(),
      'preferred_date': _scheduleType == 'IMMEDIATE'
          ? null
          : '${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}',
      'preferred_time': _scheduleType == 'IMMEDIATE'
          ? null
          : '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
      'customer_name': _customerNameCtrl.text.trim(),
      'customer_phone': _customerPhoneCtrl.text.trim(),
      'customer_email': _customerEmailCtrl.text.trim(),
      'relationship_to_patient': _relationship,
      'patient_name': _patientNameCtrl.text.trim(),
      'patient_age': int.tryParse(_patientAgeCtrl.text.trim()),
      'patient_gender': _patientGender,
      'current_condition': _patientCondition,
      'medical_summary': _voiceConditionDescription.isEmpty
          ? _patientCondition
          : _voiceConditionDescription,
      'is_emergency': _isEmergency,
      'is_immediate': _scheduleType == 'IMMEDIATE',
      'oxygen_required': _oxygenRequired,
      'icu_required': _icuRequired,
      'ventilator_required': _ventilatorRequired,
      'cardiac_monitor_required': _cardiacMonitorRequired,
      'pediatric_patient': _pediatricPatient,
      'doctor_required': _doctorRequired,
      'emt_required': _emtRequired,
      'stretcher_required': _stretcherRequired,
      'wheelchair_required': _wheelchairRequired,
      'additional_equipment': List<String>.from(_additionalEquipment),
      'priority': _isEmergency ? 'CRITICAL' : 'NORMAL',
    };
  }

  Future<bool> _prepareBackendEstimate() async {
    if (_estimatingFare) return false;
    if (!SupabaseService.isConfigured) {
      _showError(
        'An authenticated Supabase session is required to calculate the estimate.',
      );
      return false;
    }

    setState(() {
      _estimatingFare = true;
      _estimateError = null;
      _estimatedFare = null;
      _estimatedDistanceKm = null;
    });

    try {
      final bookingId = _voiceDraftBookingId == null
          ? await _workflow.createCustomerBooking(_bookingPayload())
          : await _workflow.saveCustomerVoiceBookingDraft(
              bookingId: _voiceDraftBookingId!,
              booking: _bookingPayload(),
            );
      if (_voiceDraftBookingId != null) {
        _voiceDraftBookingId = bookingId;
      }

      // The route function is authoritative for distance. Do not calculate
      // distance from the two addresses inside Flutter.
      await _workflow.calculateBookingRoute(bookingId);

      // The fare RPC reads the persisted route distance and pricing_settings.
      final fareResult = await _workflow.calculateBasicFare(bookingId);
      final fare = double.tryParse(fareResult['basic_fare']?.toString() ?? '');
      final fareDistance = double.tryParse(
        fareResult['basic_fare_distance_km']?.toString() ?? '',
      );

      final bookings = await _bookingRepository.getCustomerBookings();
      final created = bookings
          .where((booking) => booking.id == bookingId)
          .firstOrNull;
      final distance = fareDistance ?? created?.distanceKm;

      if (fare == null) {
        throw StateError(
          'Supabase returned no basic_fare for booking $bookingId.',
        );
      }

      if (distance == null || distance < 0) {
        throw StateError(
          'Supabase returned no route distance for booking $bookingId.',
        );
      }

      if (!mounted) return false;
      setState(() {
        _estimateBookingId = bookingId;
        _estimatedFare = fare;
        _estimatedDistanceKm = distance;
      });
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _estimateError = error.toString();
          _estimateBookingId = null;
        });
        _showError('Unable to calculate the live fare estimate: $error');
      }
      return false;
    } finally {
      if (mounted) setState(() => _estimatingFare = false);
    }
  }

  Future<void> _submitBooking() async {
    if (_submitting) return;
    if (!SupabaseService.isConfigured) {
      _showError(
        'An authenticated Supabase session is required to submit a booking.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Review already created and priced the real Supabase booking. Reuse it
      // so the customer does not create a duplicate booking on confirmation.
      final bookingId =
          _estimateBookingId ??
          (_voiceDraftBookingId == null
              ? await _workflow.createCustomerBooking(_bookingPayload())
              : await _workflow.saveCustomerVoiceBookingDraft(
                  bookingId: _voiceDraftBookingId!,
                  booking: _bookingPayload(),
                ));

      if (_estimateBookingId == null) {
        await _workflow.calculateBookingRoute(bookingId);
        final fareResult = await _workflow.calculateBasicFare(bookingId);
        final fare = double.tryParse(
          fareResult['basic_fare']?.toString() ?? '',
        );
        final distance = double.tryParse(
          fareResult['basic_fare_distance_km']?.toString() ?? '',
        );
        if (fare == null) {
          throw StateError(
            'Supabase returned no basic_fare for booking $bookingId.',
          );
        }
        if (!mounted) return;
        setState(() {
          _estimatedFare = fare;
          _estimatedDistanceKm = distance;
          _estimateBookingId = bookingId;
        });
      }

      final bookings = await _bookingRepository.getCustomerBookings();
      final created = bookings
          .where((booking) => booking.id == bookingId)
          .firstOrNull;
      if (created == null) {
        throw StateError(
          'Booking was created but could not be reloaded from Supabase.',
        );
      }

      SharedBookingStore.upsert(created);
      if (!mounted) return;
      widget.onBookingCreated(created);
    } catch (error) {
      if (mounted) _showError('Booking submission failed: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _serviceLabel(String category) {
    switch (category) {
      case 'AIR':
        return 'Air Ambulance';
      case 'RAIL':
        return 'Rail Ambulance';
      case 'DEAD_BODY':
        return 'Dead Body Transfer';
      case 'ROAD':
      default:
        return 'Road Ambulance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? AmbulanceFirstSpacing.margin
                : AmbulanceFirstSpacing.marginMobile,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book New Ambulance',
                              style: AmbulanceFirstTypography.headlineSm(
                                color: AmbulanceFirstColors.onSurface,
                              ),
                            ),
                            Text(
                              'Step ${_currentStep + 1} of ${_stepTitles.length}: ${_stepTitles[_currentStep]}',
                              style: AmbulanceFirstTypography.bodySm(
                                color: AmbulanceFirstColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('CANCEL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AmbulanceFirstSpacing.radiusPill,
                    ),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _stepTitles.length,
                      minHeight: 5,
                      backgroundColor:
                          AmbulanceFirstColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AmbulanceFirstColors.clinicalCobalt,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AmbulanceFirstCard(
                    padding: const EdgeInsets.all(
                      AmbulanceFirstSpacing.spaceMd,
                    ),
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStep(isDesktop),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: _currentStep > 0
                        ? WrapAlignment.spaceBetween
                        : WrapAlignment.end,
                    runSpacing: 8,
                    children: [
                      if (_currentStep > 0)
                        AmbulanceFirstButton(
                          label: 'PREVIOUS',
                          onPressed: _previousStep,
                          variant: AmbulanceFirstButtonVariant.ghost,
                        )
                      else
                        const SizedBox.shrink(),
                      AmbulanceFirstButton(
                        label: _currentStep == _stepTitles.length - 1
                            ? 'CONFIRM BOOKING'
                            : 'CONTINUE',
                        icon: _currentStep == _stepTitles.length - 1
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _submitting ? null : _nextStep,
                        isLoading: _submitting,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(bool isDesktop) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Service();
      case 1:
        return _buildStep2Customer(isDesktop);
      case 2:
        return _buildStep3Patient(isDesktop);
      case 3:
        return _buildStep4Clinical(isDesktop);
      case 4:
        return _buildStep5Route(isDesktop);
      case 5:
        return _buildStep6Schedule();
      case 6:
        return _buildStep7Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Service() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Choose Booking Method',
          'Choose online booking now, or use the Customer Care route for a future inbound-call integration.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _methodCard(
                selected: _bookingMethod == 'ONLINE',
                icon: Icons.edit_note_rounded,
                title: 'Book by filling details',
                subtitle: 'Enter patient, route and service information now.',
                onTap: () => setState(() => _bookingMethod = 'ONLINE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _methodCard(
                selected: _bookingMethod == 'CALL',
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Customer Care',
                subtitle: 'Calling integration will be connected later.',
                onTap: () {
                  setState(() => _bookingMethod = 'CALL');
                  _showCallCareDialog();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      
        _stepHeader(
          'Select Service Type',
          'Choose how the patient or body will be transported.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _serviceCard(
              'ROAD',
              'Road Ambulance',
              Icons.local_shipping_rounded,
            ),
            _serviceCard('AIR', 'Air Ambulance', Icons.flight_takeoff_rounded),
            _serviceCard('RAIL', 'Rail Ambulance', Icons.train_rounded),
            _serviceCard(
              'DEAD_BODY',
              'Dead Body Transfer',
              Icons.inventory_2_rounded,
            ),
          ],
        ),
        if (_serviceCategory == 'ROAD') ...[
          const SizedBox(height: 22),
          _stepHeader(
            'Road Ambulance Type',
            'Choose a clinical setup to preselect the matching equipment and crew requirements.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780 ? 3 : 1;
              final tileWidth =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _ambulancePresetCard(
                      title: 'Oxygen Ambulance',
                      subtitle: 'Oxygen support with BLS crew',
                      icon: Icons.air_rounded,
                      category: 'Oxygen Ambulance (BLS)',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _ambulancePresetCard(
                      title: 'ICU Ambulance',
                      subtitle: 'Critical-care monitoring and oxygen',
                      icon: Icons.monitor_heart_outlined,
                      category: 'ICU Ambulance (ALS)',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _ambulancePresetCard(
                      title: 'NICU Ambulance',
                      subtitle: 'Neonatal care with transport incubator',
                      icon: Icons.child_care_rounded,
                      category: 'NICU Ambulance (PICU/NICU)',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _ambulancePresetCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String category,
  }) {
    final selected = _ambulanceCategory == category;
    return InkWell(
      onTap: () => _applyAmbulancePreset(category),
      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 82),
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
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? AmbulanceFirstColors.clinicalCobalt
                  : AmbulanceFirstColors.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AmbulanceFirstTypography.bodyMd(
                      color: AmbulanceFirstColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AmbulanceFirstTypography.bodySm(
                      color: AmbulanceFirstColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AmbulanceFirstColors.clinicalCobalt,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(String category, String title, IconData icon) {
    final selected = _serviceCategory == category;
    return SizedBox(
      width: 195,
      child: InkWell(
        onTap: () => _selectService(category, switch (category) {
          'AIR' => 'AIR_AMBULANCE',
          'RAIL' => 'RAIL_AMBULANCE',
          'DEAD_BODY' => 'DEAD_BODY_TRANSFER',
          _ => 'ROAD_AMBULANCE',
        }),
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
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
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AmbulanceFirstColors.clinicalCobalt
                    : AmbulanceFirstColors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
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
  }

  Widget _methodCard({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, color: AmbulanceFirstColors.clinicalCobalt, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AmbulanceFirstTypography.bodyMd(
                      color: AmbulanceFirstColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AmbulanceFirstTypography.bodySm(
                      color: AmbulanceFirstColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Customer(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Customer & Guardian Details',
          'Primary authorized contact responsible for clinical handoff and dispatch.',
        ),
        const SizedBox(height: 16),
        AmbulanceFirstTextInput(
          label: 'Contact Full Name',
          controller: _customerNameCtrl,
          isRequired: true,
          hintText: 'Enter contact full name',
        ),
        const SizedBox(height: 14),
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: AmbulanceFirstTextInput(
                  label: 'Mobile Phone',
                  controller: _customerPhoneCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AmbulanceFirstTextInput(
                  label: 'Email Address',
                  controller: _customerEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              AmbulanceFirstTextInput(
                label: 'Mobile Phone',
                controller: _customerPhoneCtrl,
                isRequired: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              AmbulanceFirstTextInput(
                label: 'Email Address',
                controller: _customerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        const SizedBox(height: 14),
        AmbulanceFirstDropdown<String>(
          label: 'Relationship to Patient',
          value: _relationship,
          isRequired: true,
          items: const [
            DropdownMenuItem(value: 'Self', child: Text('Self')),
            DropdownMenuItem(
              value: 'Family Guardian',
              child: Text('Family Guardian / Parent'),
            ),
            DropdownMenuItem(value: 'Relative', child: Text('Relative')),
            DropdownMenuItem(value: 'Friend', child: Text('Friend')),
            DropdownMenuItem(
              value: 'Physician / Doctor',
              child: Text('Physician / Doctor'),
            ),
            DropdownMenuItem(
              value: 'Clinical Coordinator',
              child: Text('Clinical Coordinator'),
            ),
            DropdownMenuItem(
              value: 'Spouse / Partner',
              child: Text('Spouse / Partner'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _relationship = value);
          },
        ),
      ],
    );
  }

  Widget _buildStep3Patient(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Patient Clinical Profile',
          'Enter the actual clinical condition. It will be saved to bookings.current_condition.',
        ),
        const SizedBox(height: 16),
        AmbulanceFirstTextInput(
          label: 'Patient Full Name',
          controller: _patientNameCtrl,
          isRequired: true,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AmbulanceFirstTextInput(
                label: 'Patient Age (years)',
                controller: _patientAgeCtrl,
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AmbulanceFirstDropdown<String>(
                label: 'Gender',
                value: _patientGender.isEmpty ? null : _patientGender,
                isRequired: true,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _patientGender = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AmbulanceFirstDropdown<String>(
          label: 'Current Medical Condition',
          value: _patientCondition.isEmpty ? null : _patientCondition,
          isRequired: true,
          items: const [
            DropdownMenuItem(value: 'Stable', child: Text('Stable / Routine')),
            DropdownMenuItem(
              value: 'Cardiac Monitoring Required',
              child: Text('Cardiac Monitoring Required'),
            ),
            DropdownMenuItem(
              value: 'Ventilator Dependent',
              child: Text('Ventilator Dependent / Critical'),
            ),
            DropdownMenuItem(
              value: 'Neonatal / PICU Specialized',
              child: Text('Neonatal / PICU Specialized'),
            ),
            DropdownMenuItem(
              value: 'Post-Operative Transfer',
              child: Text('Post-Operative Transfer'),
            ),
            DropdownMenuItem(
              value: 'Trauma / Acute Decompensation',
              child: Text('Trauma / Acute Decompensation'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _patientCondition = value);
          },
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            value: _isEmergency,
            onChanged: (value) => setState(() => _isEmergency = value ?? false),
            title: const Text('Emergency Priority Dispatch (Code Red)'),
            subtitle: const Text(
              'Marks the booking as CRITICAL for operational triage.',
            ),
            contentPadding: EdgeInsets.zero,
            activeColor: AmbulanceFirstColors.medicalCrimson,
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Clinical(bool isDesktop) {
    final isRoad = _serviceCategory == 'ROAD';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          isRoad ? 'Road Ambulance & Equipment' : 'Service Requirements',
          isRoad
              ? 'Select the road ambulance capability and clinical equipment required.'
              : 'Select any additional medical support required for this service.',
        ),
        const SizedBox(height: 16),
        if (isRoad) ...[
          AmbulanceFirstDropdown<String>(
            label: 'Ambulance Category',
            value: _ambulanceCategory.isEmpty ? null : _ambulanceCategory,
            isRequired: true,
            items: const [
              DropdownMenuItem(
                value: 'Oxygen Ambulance (BLS)',
                child: Text('Oxygen Ambulance (BLS)'),
              ),
              DropdownMenuItem(
                value: 'ICU Ambulance (ALS)',
                child: Text('ICU Ambulance (ALS)'),
              ),
              DropdownMenuItem(
                value: 'NICU Ambulance (PICU/NICU)',
                child: Text('NICU Ambulance (PICU/NICU)'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              _applyAmbulancePreset(value);
            },
          ),
          const SizedBox(height: 16),
        ],
        if (isRoad && _ambulanceCategory.isNotEmpty) ...[
          _presetRequirementsSummary(),
          const SizedBox(height: 14),
        ],
        Text(
          'Clinical Capabilities Required',
          style: AmbulanceFirstTypography.labelMd(
            color: AmbulanceFirstColors.onSurface,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Oxygen', _oxygenRequired, (v) => _oxygenRequired = v),
            _chip(
              'Cardiac Monitor',
              _cardiacMonitorRequired,
              (v) => _cardiacMonitorRequired = v,
            ),
            _chip(
              'Ventilator',
              _ventilatorRequired,
              (v) => _ventilatorRequired = v,
            ),
            _chip('ICU Kit', _icuRequired, (v) => _icuRequired = v),
            _chip('Doctor', _doctorRequired, (v) => _doctorRequired = v),
            _chip('EMT', _emtRequired, (v) => _emtRequired = v),
            _chip(
              'Stretcher',
              _stretcherRequired,
              (v) => _stretcherRequired = v,
            ),
            _chip(
              'Wheelchair',
              _wheelchairRequired,
              (v) => _wheelchairRequired = v,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, ValueChanged<bool> update) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) => setState(() {
        update(value);
        _autoSelectedRequirements.remove(label);
      }),
    );
  }

  void _applyAmbulancePreset(String category) {
    setState(() {
      for (final requirement in _autoSelectedRequirements) {
        switch (requirement) {
          case 'Oxygen':
            _oxygenRequired = false;
          case 'ICU Kit':
            _icuRequired = false;
          case 'Cardiac Monitor':
            _cardiacMonitorRequired = false;
          case 'EMT':
            _emtRequired = false;
          case 'Pediatric Care':
            _pediatricPatient = false;
        }
      }
      _autoSelectedRequirements.clear();
      _additionalEquipment.removeWhere(_autoSelectedEquipment.contains);
      _autoSelectedEquipment.clear();
      _ambulanceCategory = category;

      final isIcu = category.startsWith('ICU Ambulance');
      final isNicu = category.startsWith('NICU Ambulance');
      _setPresetRequirement('Oxygen', true, (value) => _oxygenRequired = value);
      _setPresetRequirement('EMT', true, (value) => _emtRequired = value);

      if (isIcu || isNicu) {
        _setPresetRequirement('ICU Kit', true, (value) => _icuRequired = value);
        _setPresetRequirement(
          'Cardiac Monitor',
          true,
          (value) => _cardiacMonitorRequired = value,
        );
      }
      if (isNicu) {
        _setPresetRequirement(
          'Pediatric Care',
          true,
          (value) => _pediatricPatient = value,
        );
        const neonatalIncubator = 'Neonatal transport incubator';
        _additionalEquipment.add(neonatalIncubator);
        _autoSelectedEquipment.add(neonatalIncubator);
      }
    });
  }

  void _setPresetRequirement(
    String label,
    bool value,
    void Function(bool) assign,
  ) {
    assign(value);
    if (value) _autoSelectedRequirements.add(label);
  }

  Widget _presetRequirementsSummary() {
    final selections = <String>[
      if (_oxygenRequired) 'Oxygen',
      if (_icuRequired) 'ICU support',
      if (_cardiacMonitorRequired) 'Cardiac monitor',
      if (_pediatricPatient) 'Pediatric / neonatal care',
      if (_emtRequired) 'EMT crew',
      ..._additionalEquipment,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.primaryFixed.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
      ),
      child: Text(
        'Selected service defaults: ${selections.join(', ')}. Adjust any requirement below.',
        style: AmbulanceFirstTypography.bodySm(
          color: AmbulanceFirstColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildStep5Route(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Pickup & Destination',
          'Use GPS for the current pickup address or enter an address manually.',
        ),
        const SizedBox(height: 16),
        AmbulanceFirstTextInput(
          label: 'Current / Pickup Address',
          controller: _pickupCtrl,
          isRequired: true,
          hintText: 'Enter pickup address',
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: AmbulanceFirstButton(
            label: _gettingLocation ? 'GETTING LOCATION...' : 'USE MY LOCATION',
            icon: Icons.my_location_rounded,
            onPressed: _gettingLocation ? null : _useMyLocation,
            variant: AmbulanceFirstButtonVariant.ghost,
            isLoading: _gettingLocation,
          ),
        ),
        if (_pickupLatitude != null && _pickupLongitude != null) ...[
          const SizedBox(height: 8),
          Text(
            'GPS: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
            style: AmbulanceFirstTypography.codeSm(
              color: AmbulanceFirstColors.clinicalCobalt,
            ),
          ),
        ],
        const SizedBox(height: 14),
        AmbulanceFirstTextInput(
          label: _serviceCategory == 'AIR'
              ? 'Destination Airport / Address'
              : _serviceCategory == 'RAIL'
              ? 'Destination Railway Station / Address'
              : 'Destination Address / Hospital',
          controller: _destinationCtrl,
          isRequired: true,
          hintText: 'Enter destination',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AmbulanceFirstTextInput(
                label: 'Current Hospital (optional)',
                controller: _currentHospitalCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AmbulanceFirstTextInput(
                label: 'Destination Hospital (optional)',
                controller: _destHospitalCtrl,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep6Schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Dispatch Schedule',
          'Choose immediate response or schedule the service.',
        ),
        const SizedBox(height: 16),
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
                  title: const Text('Immediate'),
                  subtitle: const Text(
                    'Process as soon as the request is submitted.',
                  ),
                ),
                RadioListTile<String>(
                  value: 'SCHEDULED',
                  title: const Text('Scheduled'),
                  subtitle: const Text('Choose a future date and time.'),
                ),
              ],
            ),
          ),
        ),
        if (_scheduleType == 'SCHEDULED') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _scheduledDate = picked);
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: const Text('Time'),
                    subtitle: Text(_scheduledTime.format(context)),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _scheduledTime,
                      );
                      if (picked != null) {
                        setState(() => _scheduledTime = picked);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep7Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          'Review & Confirm',
          'Verify the details before creating the booking.',
        ),
        const SizedBox(height: 16),
        _reviewSection('Service', [
          'Booking method: ${_bookingMethod == 'ONLINE' ? 'Online form' : 'Customer Care call'}',
          'Service: ${_serviceLabel(_serviceCategory)}',
          if (_ambulanceCategory.isNotEmpty)
            'Ambulance category: $_ambulanceCategory',
        ]),
        const SizedBox(height: 12),
        _reviewSection('Customer', [
          'Name: ${_customerNameCtrl.text.trim()}',
          'Phone: ${_customerPhoneCtrl.text.trim()}',
          'Relationship: $_relationship',
        ]),
        const SizedBox(height: 12),
        _reviewSection('Patient', [
          'Patient: ${_patientNameCtrl.text.trim()} (${_patientAgeCtrl.text.trim()} / $_patientGender)',
          'Clinical condition: $_patientCondition',
        ]),
        const SizedBox(height: 12),
        _reviewSection('Route', [
          'Pickup: ${_pickupCtrl.text.trim()}',
          'Destination: ${_destinationCtrl.text.trim()}',
          if (_pickupLatitude != null && _pickupLongitude != null)
            'Pickup GPS: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
          if (_estimatedDistanceKm != null)
            'Estimated route distance: ${_estimatedDistanceKm!.toStringAsFixed(2)} km',
        ]),
        const SizedBox(height: 12),
        _buildFareEstimateCard(),
        const SizedBox(height: 12),
        _reviewSection('Schedule', [
          _scheduleType == 'IMMEDIATE'
              ? 'Immediate request'
              : 'Scheduled: ${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} at ${_scheduledTime.format(context)}',
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AmbulanceFirstColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
            border: Border.all(
              color: AmbulanceFirstColors.clinicalCobalt.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The estimated basic fare is calculated from the live route distance and Admin pricing in Supabase. Medical add-ons and the final quotation are handled later by Team Lead.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareEstimateCard() {
    final fare = _estimatedFare;
    final distance = _estimatedDistanceKm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.primaryFixed.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
        border: Border.all(
          color: AmbulanceFirstColors.clinicalCobalt.withValues(alpha: 0.45),
        ),
      ),
      child: _estimatingFare
          ? const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calculating live route distance and basic fare from Supabase...',
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: AmbulanceFirstColors.clinicalCobalt,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimated Basic Fare',
                        style: AmbulanceFirstTypography.labelMd(
                          color: AmbulanceFirstColors.onSurface,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (fare != null)
                      Text(
                        '₹${fare.toStringAsFixed(0)}',
                        style: AmbulanceFirstTypography.headlineSm(
                          color: AmbulanceFirstColors.clinicalCobalt,
                        ).copyWith(fontWeight: FontWeight.w900),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (distance != null)
                  Text(
                    'Live route distance: ${distance.toStringAsFixed(2)} km',
                    style: AmbulanceFirstTypography.bodySm(
                      color: AmbulanceFirstColors.onSurface,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Calculated by Supabase using the selected service category/subtype and the persisted route distance. Final medical add-ons are part of the later quotation.',
                  style: AmbulanceFirstTypography.bodySm(
                    color: AmbulanceFirstColors.onSurfaceVariant,
                  ),
                ),
                if (_estimateError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _estimateError!,
                    style: AmbulanceFirstTypography.bodySm(
                      color: AmbulanceFirstColors.medicalCrimson,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AmbulanceFirstTypography.headlineSm(
            color: AmbulanceFirstColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AmbulanceFirstTypography.bodySm(
            color: AmbulanceFirstColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _reviewSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
        border: Border.all(color: AmbulanceFirstColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AmbulanceFirstTypography.labelMd(
              color: AmbulanceFirstColors.clinicalCobalt,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item,
                style: AmbulanceFirstTypography.bodySm(
                  color: AmbulanceFirstColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
