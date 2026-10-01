import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import '../widgets/stitch_status_badge.dart';
import 'admin_shared.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  String _selectedRole = 'DRIVER';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final q = _searchCtrl.text.trim().toLowerCase();

        List<AdminStaff> list;
        if (_selectedRole == 'DRIVER') {
          list = store.drivers;
        } else if (_selectedRole == 'EMT') {
          list = store.emts;
        } else if (_selectedRole == 'DOCTOR') {
          list = store.doctors;
        } else if (_selectedRole == 'CUSTOMER_CARE') {
          list = store.customerCare;
        } else {
          list = store.teamLeads;
        }

        final filtered = list.where((s) {
          if (q.isNotEmpty) {
            final text =
                '${s.name} ${s.email} ${s.phone} ${s.id} ${s.assignedVehicle ?? ""} ${s.specialization ?? ""}'
                    .toLowerCase();
            if (!text.contains(q)) return false;
          }
          return true;
        }).toList();

        final availableCount = list
            .where((s) => s.status == StaffStatus.available)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.all(StitchTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: StitchTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                    border: Border.all(color: StitchTheme.borderSubtle),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 10,
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth > 520
                              ? constraints.maxWidth - 220
                              : constraints.maxWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.badge_rounded,
                                    size: 20,
                                    color: StitchTheme.primaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Staff & Responders',
                                      style: StitchTheme.headlineMd(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$availableCount of ${list.length} $_selectedRole resources ready for assignment.',
                                style: StitchTheme.bodySm(
                                  color: StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openProvisionDialog(context),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('+ Provision Staff'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StitchTheme.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                StitchTheme.radiusSm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Role Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RoleTab(
                      label: 'Drivers (${store.drivers.length})',
                      isSelected: _selectedRole == 'DRIVER',
                      onTap: () => setState(() => _selectedRole = 'DRIVER'),
                    ),
                    const SizedBox(width: 6),
                    _RoleTab(
                      label: 'EMTs (${store.emts.length})',
                      isSelected: _selectedRole == 'EMT',
                      onTap: () => setState(() => _selectedRole = 'EMT'),
                    ),
                    const SizedBox(width: 6),
                    _RoleTab(
                      label: 'Doctors (${store.doctors.length})',
                      isSelected: _selectedRole == 'DOCTOR',
                      onTap: () => setState(() => _selectedRole = 'DOCTOR'),
                    ),
                    const SizedBox(width: 6),
                    _RoleTab(
                      label: 'Customer Care (${store.customerCare.length})',
                      isSelected: _selectedRole == 'CUSTOMER_CARE',
                      onTap: () =>
                          setState(() => _selectedRole = 'CUSTOMER_CARE'),
                    ),
                    const SizedBox(width: 6),
                    _RoleTab(
                      label: 'Team Leads (${store.teamLeads.length})',
                      isSelected: _selectedRole == 'TEAM_LEAD',
                      onTap: () => setState(() => _selectedRole = 'TEAM_LEAD'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Search Bar
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, contact, license or unit...',
                  hintStyle: StitchTheme.bodySm(color: StitchTheme.outline),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                  filled: true,
                  fillColor: StitchTheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Staff Cards List
              for (final member in filtered) ...[
                _StaffCard(
                  staff: member,
                  onToggleStatus: () => _toggleStaffStatus(member),
                ),
                const SizedBox(height: StitchTheme.spaceSm),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _toggleStaffStatus(AdminStaff member) {
    if (member.status == StaffStatus.suspended) {
      final res = widget.store.setStaffStatus(
        staffId: member.id,
        newStatus: StaffStatus.available,
      );
      showStitchToast(context, res.$2);
      return;
    }

    // Attempt to suspend
    showDialog(
      context: context,
      builder: (ctx) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: StitchTheme.surfaceContainerLowest,
          title: Text(
            'Suspend ${member.name}?',
            style: StitchTheme.headlineSm(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Suspension will immediately prevent assignment to new dispatches.',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Suspension Reason / Note *',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final res = widget.store.setStaffStatus(
                  staffId: member.id,
                  newStatus: StaffStatus.suspended,
                  reason: reasonCtrl.text.trim().isNotEmpty
                      ? reasonCtrl.text.trim()
                      : 'Administrative hold',
                );
                showStitchToast(context, res.$2, isError: !res.$1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Suspension'),
            ),
          ],
        );
      },
    );
  }

  void _openProvisionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final experienceCtrl = TextEditingController(text: '0');
    final hospitalCtrl = TextEditingController();
    final departmentCtrl = TextEditingController();
    final shiftCtrl = TextEditingController(text: 'GENERAL');
    final certificationCtrl = TextEditingController();

    const provisionableRoles = {
      'DRIVER',
      'DOCTOR',
      'EMT',
      'CUSTOMER_CARE',
      'TEAM_LEAD',
    };

    String role = provisionableRoles.contains(_selectedRole)
        ? _selectedRole
        : 'DRIVER';

    String supportedCategory = 'ROAD';
    bool pediatricCapable = false;
    String crewType = 'EMT';
    bool saving = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final isDriver = role == 'DRIVER';
          final isDoctor = role == 'DOCTOR';
          final isEmt = role == 'EMT';
          final isCustomerCare = role == 'CUSTOMER_CARE';
          final isTeamLead = role == 'TEAM_LEAD';

          Future<void> submit() async {
            if (saving) return;

            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final phone = phoneCtrl.text.trim();
            final license = licenseCtrl.text.trim();
            final specialization = specCtrl.text.trim();
            final hospital = hospitalCtrl.text.trim();
            final department = departmentCtrl.text.trim();
            final shift = shiftCtrl.text.trim();
            final experience = int.tryParse(experienceCtrl.text.trim());
            final certification = certificationCtrl.text.trim();

            if (name.isEmpty || email.isEmpty || phone.isEmpty) {
              setDlgState(() {
                errorText = 'Name, email and phone number are required.';
              });
              return;
            }

            if (isDriver && license.isEmpty) {
              setDlgState(() {
                errorText = 'Driver license number is required.';
              });
              return;
            }

            if (isEmt && certification.isEmpty) {
              setDlgState(() {
                errorText = 'EMT certification is required.';
              });
              return;
            }

            if (isDoctor && specialization.isEmpty) {
              setDlgState(() {
                errorText = 'Doctor specialization is required.';
              });
              return;
            }

            if (experience == null || experience < 0 || experience > 60) {
              setDlgState(() {
                errorText = 'Experience must be between 0 and 60 years.';
              });
              return;
            }

            setDlgState(() {
              saving = true;
              errorText = null;
            });

            final res = await widget.store.provisionStaffFromDatabase(
              name: name,
              email: email,
              phone: phone,
              role: role,
              licenseNumber: isDriver || isDoctor ? license : null,
              specialization: isDoctor ? specialization : null,
              experienceYears: experience,
              pediatricCapable: pediatricCapable,
              hospital: isDoctor ? hospital : null,
              department: isCustomerCare || isTeamLead ? department : null,
              shift: isCustomerCare || isTeamLead || isEmt ? shift : null,
              certification: isEmt ? certification : null,
              crewType: isEmt ? crewType : null,
            );

            if (!ctx.mounted) return;

            if (res.$1) {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                showStitchToast(context, res.$2);
              }
            } else {
              setDlgState(() {
                saving = false;
                errorText = res.$2;
              });
            }
          }

          return AlertDialog(
            backgroundColor: StitchTheme.surfaceContainerLowest,
            title: Text(
              'Provision New Staff Member',
              style: StitchTheme.headlineSm(),
            ),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Role *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'DRIVER',
                          child: Text('Driver / Transport Operator'),
                        ),
                        DropdownMenuItem(
                          value: 'DOCTOR',
                          child: Text('Attending Physician / Doctor'),
                        ),
                        DropdownMenuItem(
                          value: 'EMT',
                          child: Text('Emergency Medical Technician / EMT'),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOMER_CARE',
                          child: Text('Customer Care Specialist'),
                        ),
                        DropdownMenuItem(
                          value: 'TEAM_LEAD',
                          child: Text('Operations Team Lead'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDlgState(() {
                                role = value;
                                errorText = null;
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailCtrl,
                      enabled: !saving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Official Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      enabled: !saving,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    if (isDriver) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: licenseCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Driving License No. *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: supportedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Primary Transport Category *',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ROAD',
                            child: Text('Road Ambulance'),
                          ),
                          DropdownMenuItem(
                            value: 'AIR',
                            child: Text('Air Medevac'),
                          ),
                          DropdownMenuItem(
                            value: 'RAIL',
                            child: Text('Rail Transport'),
                          ),
                          DropdownMenuItem(
                            value: 'DEAD_BODY',
                            child: Text('Dead Body Transport'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDlgState(() {
                                  supportedCategory = value;
                                });
                              },
                      ),
                    ],
                    if (isDriver || isDoctor) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: experienceCtrl,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Experience (Years) *',
                          prefixIcon: Icon(Icons.work_history_outlined),
                        ),
                      ),
                    ],
                    if (isEmt) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: crewType,
                        decoration: const InputDecoration(
                          labelText: 'Crew Type *',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'EMT',
                            child: Text('EMT'),
                          ),
                          DropdownMenuItem(
                            value: 'PARAMEDIC',
                            child: Text('Paramedic'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDlgState(() => crewType = value);
                              },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: certificationCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'EMT Certification *',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                      ),
                    ],
                    if (isDoctor) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: specCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Medical Specialization *',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: hospitalCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Current Hospital / Affiliation',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pediatric capability'),
                        value: pediatricCapable,
                        onChanged: saving
                            ? null
                            : (value) {
                                setDlgState(() {
                                  pediatricCapable = value;
                                });
                              },
                      ),
                    ],
                    if (isCustomerCare || isTeamLead) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: departmentCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: shiftCtrl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Shift',
                          prefixIcon: Icon(Icons.schedule_outlined),
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: StitchTheme.errorContainer,
                          borderRadius: BorderRadius.circular(
                            StitchTheme.radiusSm,
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: StitchTheme.bodySm(
                            color: StitchTheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: saving ? null : submit,
                icon: saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  saving ? 'Saving...' : 'Provision Account',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StitchTheme.primaryContainer,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      licenseCtrl.dispose();
      specCtrl.dispose();
      experienceCtrl.dispose();
      hospitalCtrl.dispose();
      departmentCtrl.dispose();
      shiftCtrl.dispose();
    });
  }

}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? StitchTheme.primaryContainer
              : StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
          border: Border.all(
            color: isSelected
                ? StitchTheme.primaryContainer
                : StitchTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: StitchTheme.labelSm(
            color: isSelected ? Colors.white : StitchTheme.onSurface,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff, required this.onToggleStatus});
  final AdminStaff staff;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final s = staff;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: s.status == StaffStatus.suspended
                        ? StitchTheme.error
                        : StitchTheme.primaryContainer,
                    child: Text(
                      s.name
                          .split(' ')
                          .map((p) => p.isEmpty ? '' : p[0])
                          .take(2)
                          .join(),
                      style: StitchTheme.labelSm(
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: StitchTheme.headlineSm()),
                      Text(s.email, style: StitchTheme.bodySm()),
                    ],
                  ),
                ],
              ),
              StitchStatusBadge.fromStaff(s.status),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.phone_rounded,
                size: 14,
                color: StitchTheme.primaryContainer,
              ),
              const SizedBox(width: 4),
              Text(s.phone, style: StitchTheme.labelSm()),
              if (s.assignedVehicle != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: StitchTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Unit: ${s.assignedVehicle}',
                    style: StitchTheme.labelSm(weight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),

          if (s.licenseNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'License: ${s.licenseNumber!}',
              style: StitchTheme.bodySm(color: StitchTheme.outline),
            ),
          ],

          if (s.specialization != null) ...[
            const SizedBox(height: 4),
            Text(
              'Specialty: ${s.specialization!}',
              style: StitchTheme.bodySm(
                color: StitchTheme.primaryContainer,
                weight: FontWeight.w600,
              ),
            ),
          ],

          if (s.suspensionReason != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: StitchTheme.errorContainer,
                borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
              ),
              child: Text(
                'Suspension Note: ${s.suspensionReason!}',
                style: StitchTheme.bodySm(color: StitchTheme.onErrorContainer),
              ),
            ),
          ],

          const Divider(height: 16, color: StitchTheme.borderSubtle),

          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${s.id}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StitchTheme.labelSm(color: StitchTheme.outline),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onToggleStatus,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: s.status == StaffStatus.suspended
                        ? StitchTheme.tertiary
                        : StitchTheme.error,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
                child: Text(
                  s.status == StaffStatus.suspended
                      ? 'Reactivate'
                      : 'Suspend Staff',
                  style: StitchTheme.labelSm(
                    color: s.status == StaffStatus.suspended
                        ? StitchTheme.tertiary
                        : StitchTheme.error,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
