import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/services/doctor_repository.dart';
import '../../../shared/widgets/aeromed_role_shell.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_booking_screen.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key, required this.user, required this.onSignOut});

  final AuthUser user;
  final VoidCallback onSignOut;

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  final DoctorRepository repository = DoctorRepository();
  int index = 0;
  bool loading = true;
  String? error;
  Map<String, dynamic>? doctor;
  List<Map<String, dynamic>> bookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final resource = await repository.doctorForUser(
        userId: widget.user.id,
        email: widget.user.email,
      );
      if (resource == null) {
        setState(() {
          doctor = null;
          bookings = const [];
          loading = false;
          error = 'No doctor resource is linked to this profile email.';
        });
        return;
      }
      final rows = await repository.assignedBookings('${resource['id']}');
      if (!mounted) return;
      setState(() {
        doctor = resource;
        bookings = rows;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = '${doctor?['name'] ?? widget.user.name}'.trim();
    final pages = [
      DoctorDashboardScreen(
        loading: loading,
        error: error,
        doctor: doctor,
        bookings: bookings,
        onRefresh: _load,
        onOpenBooking: (booking) => setState(() => index = 1),
      ),
      DoctorBookingScreen(
        repository: repository,
        doctor: doctor,
        bookings: bookings,
      ),
    ];

    return AeroMedRoleShell(
      title: 'Ambulance First',
      roleLabel: 'Doctor workspace',
      userName: doctorName,
      user: widget.user,
      destinations: const [
        AeroMedRoleDestination(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
        ),
        AeroMedRoleDestination(
          label: 'Patients',
          icon: Icons.personal_injury_outlined,
        ),
      ],
      mobileDestinations: const [0, 1],
      selectedIndex: index,
      onSelect: (value) => setState(() => index = value),
      onLogout: widget.onSignOut,
      child: IndexedStack(index: index, children: pages),
    );
  }
}
