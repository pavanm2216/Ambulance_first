import 'package:flutter/material.dart';
import '../models/team_lead_models.dart';
import '../store/team_lead_store.dart';
import '../theme/team_lead_theme.dart';

class ManualMilestoneOverrideDialog extends StatefulWidget {
  const ManualMilestoneOverrideDialog({
    super.key,
    required this.bookingId,
    required this.currentMilestone,
    required this.onConfirm,
  });

  final String bookingId;
  final String currentMilestone;
  final void Function(String nextMilestone, String reason) onConfirm;

  static void show(
    BuildContext context, {
    required String bookingId,
    required String currentMilestone,
    required void Function(String nextMilestone, String reason) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ManualMilestoneOverrideDialog(
        bookingId: bookingId,
        currentMilestone: currentMilestone,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ManualMilestoneOverrideDialog> createState() => _ManualMilestoneOverrideDialogState();
}

class _ManualMilestoneOverrideDialogState extends State<ManualMilestoneOverrideDialog> {
  late String _selectedMilestone;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _milestones = [
    'ASSIGNED',
    'PICKUP_STARTED',
    'PATIENT_PICKED_UP',
    'IN_TRANSIT',
    'ARRIVED',
    'SERVICE_COMPLETED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMilestone = widget.currentMilestone;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TeamLeadTheme.amberBg,
                        borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: TeamLeadTheme.urgentAmber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Team Lead Mission Override', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                        Text('Booking: ${widget.bookingId}', style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Authorize manual advancement of mission state. An operational audit record will be logged with your verified Team Lead credential.',
                  style: TeamLeadTheme.small(color: TeamLeadTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedMilestone,
                  decoration: InputDecoration(
                    labelText: 'Target Milestone',
                    labelStyle: TeamLeadTheme.small(color: TeamLeadTheme.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _milestones.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TeamLeadTheme.body()))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMilestone = val);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Operational Reason for Override (Required)',
                    hintText: 'e.g. Paramedic terminal lost network signal; verbal radio confirmation received.',
                    labelStyle: TeamLeadTheme.small(color: TeamLeadTheme.textMuted),
                    hintStyle: TeamLeadTheme.small(color: TeamLeadTheme.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please specify an operational reason' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: TeamLeadTheme.body(color: TeamLeadTheme.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          widget.onConfirm(_selectedMilestone, _reasonController.text.trim());
                          Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: TeamLeadTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                      ),
                      child: Text('Authorize Override', style: TeamLeadTheme.body(color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterAmbulanceDialog extends StatefulWidget {
  const RegisterAmbulanceDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const RegisterAmbulanceDialog());
  }

  @override
  State<RegisterAmbulanceDialog> createState() => _RegisterAmbulanceDialogState();
}

class _RegisterAmbulanceDialogState extends State<RegisterAmbulanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  String _category = 'Advanced Life Support';

  final Set<String> _capabilities = {'OXYGEN', 'CARDIAC_MONITOR', 'DEFIBRILLATOR', 'STRETCHER'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regCtrl.dispose();
    _modelCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Register Ambulance Vehicle', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Unit Call Sign (e.g. AF-AMB-125)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regCtrl,
                          decoration: InputDecoration(
                            labelText: 'Registration Plate (e.g. KA-01-EA-2030)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _modelCtrl,
                          decoration: InputDecoration(
                            labelText: 'Make & Model (e.g. Force Traveller ALS-350)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: InputDecoration(
                            labelText: 'Service Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Advanced Life Support', child: Text('Advanced Life Support (ALS)')),
                            DropdownMenuItem(value: 'Basic Life Support', child: Text('Basic Life Support (BLS)')),
                            DropdownMenuItem(value: 'Pediatric / Neonatal', child: Text('Pediatric / Neonatal (PICU/NICU)')),
                            DropdownMenuItem(value: 'Mortuary Transfer', child: Text('Mortuary Transfer (Cryo Freezer)')),
                          ],
                          onChanged: (v) { if (v != null) setState(() => _category = v); },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _stationCtrl,
                          decoration: InputDecoration(
                            labelText: 'Base Station Depot',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusSm)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('Clinical Capabilities & Medical Hardware', style: TeamLeadTheme.supportingBody(weight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _capBox('ICU', 'ICU Care'),
                            _capBox('VENTILATOR', 'Transport Ventilator'),
                            _capBox('OXYGEN', 'Medical Oxygen'),
                            _capBox('PICU', 'Pediatric ICU Equipment'),
                            _capBox('INCUBATOR', 'Transport Incubator'),
                            _capBox('FREEZER', 'Cryo Freezer (-4°C)'),
                            _capBox('CARDIAC_MONITOR', 'Cardiac Monitor'),
                            _capBox('DEFIBRILLATOR', 'Biphasic Defibrillator'),
                            _capBox('STRETCHER', 'Hydraulic Stretcher'),
                            _capBox('WHEELCHAIR', 'Transport Wheelchair'),
                            _capBox('SUCTION', 'Suction Machine'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final unit = AmbulanceUnit(
                            id: _nameCtrl.text.trim(),
                            name: _nameCtrl.text.trim(),
                            registrationNumber: _regCtrl.text.trim(),
                            model: _modelCtrl.text.trim(),
                            category: _category,
                            baseStation: _stationCtrl.text.trim(),
                            status: 'AVAILABLE',
                            capabilities: _capabilities,
                          );
                          TeamLeadStore.instance.registerAmbulance(unit);
                          Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: TeamLeadTheme.primary),
                      child: const Text('Register Vehicle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _capBox(String key, String label) {
    final active = _capabilities.contains(key);
    return FilterChip(
      label: Text(label, style: TeamLeadTheme.small(color: active ? TeamLeadTheme.primaryDark : TeamLeadTheme.onSurfaceVariant)),
      selected: active,
      selectedColor: TeamLeadTheme.primaryContainer.withValues(alpha: 0.5),
      onSelected: (val) {
        setState(() {
          if (val) {
            _capabilities.add(key);
          } else {
            _capabilities.remove(key);
          }
        });
      },
    );
  }
}

class AddDriverDialog extends StatefulWidget {
  const AddDriverDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddDriverDialog());
  }

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _expCtrl = TextEditingController(text: '5');
  final _depotCtrl = TextEditingController(text: 'Central Medical Command Depot');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenseCtrl.dispose();
    _expCtrl.dispose();
    _depotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Driver to Roster', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile Phone'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licenseCtrl,
                  decoration: const InputDecoration(labelText: 'Commercial Driving License #'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expCtrl,
                        decoration: const InputDecoration(labelText: 'Experience (Years)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _depotCtrl,
                        decoration: const InputDecoration(labelText: 'Depot Location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final item = DriverRosterItem(
                            id: 'DRV-${DateTime.now().millisecondsSinceEpoch % 1000}',
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            email: '${_nameCtrl.text.trim().toLowerCase().replaceAll(" ", ".")}@ambulancefirst.com',
                            licenseNumber: _licenseCtrl.text.trim(),
                            licenseExpiry: '2029-06-30',
                            experienceYears: int.tryParse(_expCtrl.text) ?? 5,
                            supportedCategories: ['Advanced Life Support', 'Basic Life Support'],
                            status: 'AVAILABLE',
                            depot: _depotCtrl.text.trim(),
                          );
                          TeamLeadStore.instance.addDriver(item);
                          Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: TeamLeadTheme.primary),
                      child: const Text('Add Driver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddEmtDialog extends StatefulWidget {
  const AddEmtDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddEmtDialog());
  }

  @override
  State<AddEmtDialog> createState() => _AddEmtDialogState();
}

class _AddEmtDialogState extends State<AddEmtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _qualCtrl = TextEditingController(text: 'B.Sc. Paramedical Science');
  final _depotCtrl = TextEditingController(text: 'Central Medical Command Depot');
  bool _pediatric = false;
  final Set<String> _certs = {'BLS', 'ACLS'};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _qualCtrl.dispose();
    _depotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add EMT / Paramedic', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile Phone'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _qualCtrl,
                  decoration: const InputDecoration(labelText: 'Qualification Degree'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text('Pediatric Qualified (PALS Certified)', style: TeamLeadTheme.body(weight: FontWeight.w500)),
                  value: _pediatric,
                  onChanged: (val) {
                    setState(() {
                      _pediatric = val;
                      if (val) { _certs.add('PALS'); } else { _certs.remove('PALS'); }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final item = EmtRosterItem(
                            id: 'EMT-${DateTime.now().millisecondsSinceEpoch % 1000}',
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            email: '${_nameCtrl.text.trim().toLowerCase().replaceAll(" ", ".")}@ambulancefirst.com',
                            qualification: _qualCtrl.text.trim(),
                            experienceYears: 4,
                            certifications: _certs,
                            hasPediatricCapability: _pediatric,
                            status: 'AVAILABLE',
                            depot: _depotCtrl.text.trim(),
                          );
                          TeamLeadStore.instance.addEmt(item);
                          Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: TeamLeadTheme.primary),
                      child: const Text('Add EMT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddDoctorDialog extends StatefulWidget {
  const AddDoctorDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddDoctorDialog());
  }

  @override
  State<AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<AddDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specCtrl = TextEditingController(text: 'Emergency Medicine & Trauma');
  final _hospCtrl = TextEditingController(text: 'Manipal Emergency Center');
  final _licCtrl = TextEditingController(text: 'KMC-99882-MD');
  bool _pediatric = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    _hospCtrl.dispose();
    _licCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TeamLeadTheme.radiusLg)),
      backgroundColor: TeamLeadTheme.surfaceLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add On-Call Physician', style: TeamLeadTheme.titleMedium(weight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Doctor Name (Dr. ...)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _specCtrl,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospCtrl,
                  decoration: const InputDecoration(labelText: 'Affiliated Hospital'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licCtrl,
                  decoration: const InputDecoration(labelText: 'Medical Council Reg #'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Pediatric / Neonatal Capability', style: TeamLeadTheme.body(weight: FontWeight.w500)),
                  value: _pediatric,
                  onChanged: (val) => setState(() => _pediatric = val),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final item = DoctorRosterItem(
                            id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 1000}',
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            email: '${_nameCtrl.text.trim().toLowerCase().replaceAll(" ", ".")}@ambulancefirst.com',
                            specialization: _specCtrl.text.trim(),
                            hospital: _hospCtrl.text.trim(),
                            experienceYears: 10,
                            hasPediatricCapability: _pediatric,
                            medicalLicense: _licCtrl.text.trim(),
                            licenseExpiry: '2030-12-31',
                            status: 'AVAILABLE',
                            depot: 'Central Medical Command Depot',
                          );
                          TeamLeadStore.instance.addDoctor(item);
                          Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: TeamLeadTheme.primary),
                      child: const Text('Add Doctor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
