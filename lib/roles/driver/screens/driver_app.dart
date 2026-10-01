import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/models/driver_models.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_booking_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_metrics.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_button.dart';
import '../../../shared/widgets/aeromed_card.dart';
import '../../../features/driver/theme/driver_theme.dart';
import '../../../features/driver/presentation/shell/driver_shell.dart'
    as feature_shell;

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  bool signedIn = false;
  bool loading = false;
  String? error;
  DriverProfile? driver;
  List<DriverBooking> bookings = <DriverBooking>[];
  AuthUser? user;

  Future<void> _login(String email, String password) async {
    if (!SupabaseService.isConfigured) {
      setState(() => error = 'Supabase is not configured.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final db = SupabaseService.client;

      // Real Supabase Auth login.
      final auth = await db.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final authUser = auth.user;
      if (authUser == null) {
        throw StateError(
          'Supabase login succeeded but no authenticated user was returned.',
        );
      }

      // Driver records are linked through drivers.profile_id.
      final profile = await db
          .from('profiles')
          .select('id,full_name,email,phone,role')
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile == null) {
        await db.auth.signOut();
        throw StateError('No profile was found for this Driver account.');
      }

      final role = '${profile['role'] ?? ''}'.trim().toUpperCase();
      if (role != 'DRIVER') {
        await db.auth.signOut();
        throw StateError(
          'This account is not registered with the DRIVER role.',
        );
      }

      final driverRow = await db
          .from('drivers')
          .select()
          .eq('profile_id', authUser.id)
          .maybeSingle();

      if (driverRow == null) {
        await db.auth.signOut();
        throw StateError('No driver record is linked to this account.');
      }

      final driverId = '${driverRow['id'] ?? ''}'.trim();
      if (driverId.isEmpty) {
        await db.auth.signOut();
        throw StateError('The linked driver record has no valid ID.');
      }

      // Load the assignments using the real drivers.id, not auth.uid().
      final liveBookings = await SupabaseBookingRepository()
          .getBookingsForDriver(driverId: driverId);

      final liveDriver = _driverFromRow(driverRow);

      if (!mounted) return;

      setState(() {
        driver = liveDriver;
        bookings = liveBookings;
        user = AuthUser(
          id: authUser.id,
          name: '${profile['full_name'] ?? liveDriver.name}',
          email: '${profile['email'] ?? authUser.email ?? liveDriver.email}',
          phone: '${profile['phone'] ?? liveDriver.phone}',
          role: 'Driver',
        );
        signedIn = true;
        loading = false;
      });

      debugPrint(
        'DRIVER LOGIN: driverId=$driverId, '
        'assigned bookings=${liveBookings.length}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  DriverProfile _driverFromRow(Map<String, dynamic> row) {
    int asInt(dynamic value) => int.tryParse('$value') ?? 0;
    double asDouble(dynamic value) => double.tryParse('$value') ?? 0;

    return DriverProfile(
      id: '${row['id'] ?? ''}',
      name: '${row['full_name'] ?? 'Driver'}',
      email: '${row['email'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      licenseNumber: '${row['license_number'] ?? ''}',
      licenseExpiry: '${row['license_expiry'] ?? ''}',
      experienceYears: asInt(row['experience_years']),
      supportedCategories: row['supported_category'] == null
          ? const <String>[]
          : <String>['${row['supported_category']}'],
      status: '${row['status'] ?? 'AVAILABLE'}'.toUpperCase(),
      assignedBookingId: null,
      assignedAmbulanceNumber: '',
      currentLocation: '',
      latitude: asDouble(row['latitude']),
      longitude: asDouble(row['longitude']),
      rating: 0,
      totalTrips: asInt(row['total_trips']),
      locationAccuracyMeters: asDouble(row['location_accuracy_meters']),
      locationUpdatedAt: null,
    );
  }

  Future<void> _logout() async {
    try {
      if (SupabaseService.isConfigured) {
        await SupabaseService.client.auth.signOut();
      }
    } finally {
      if (mounted) {
        setState(() {
          signedIn = false;
          driver = null;
          bookings = <DriverBooking>[];
          user = null;
          error = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDriver = driver;
    final currentUser = user;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambulance First Driver',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: signedIn && currentDriver != null && currentUser != null
          ? DriverShell(
              driver: currentDriver,
              bookings: bookings,
              onSignOut: _logout,
              user: currentUser,
            )
          : DriverLogin(loading: loading, error: error, onLogin: _login),
    );
  }
}

class DriverLogin extends StatefulWidget {
  const DriverLogin({
    super.key,
    required this.onLogin,
    this.loading = false,
    this.error,
  });

  final Future<void> Function(String email, String password) onLogin;
  final bool loading;
  final String? error;

  @override
  State<DriverLogin> createState() => _DriverLoginState();
}

class _DriverLoginState extends State<DriverLogin> {
  final id = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    id.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.appBackground,
              AppColors.secondaryContainer,
              AppColors.surfaceBright,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: AeroMedCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: mintGlow(),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ambulance First',
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '24/7 DRIVER DISPATCH NETWORK',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Ambulance Pilot Console',
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to manage assignments, navigation and patient transport.',
                      style: AppTextStyles.supporting,
                    ),
                    const SizedBox(height: 24),
                    _LoginField(
                      label: 'Email address or mobile number',
                      controller: id,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _LoginField(
                      label: 'Password',
                      controller: password,
                      icon: Icons.lock_outline_rounded,
                      obscure: obscure,
                      suffix: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AeroMedButton(
                      label: widget.loading
                          ? 'Signing in...'
                          : 'Enter Driver Workspace',
                      icon: Icons.arrow_forward_rounded,
                      onTap: widget.loading
                          ? null
                          : () => widget.onLogin(id.text, password.text),
                    ),
                    if (widget.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.bodyStrong,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

/// Presentation bridge: keeps the main project's authenticated Supabase flow
/// and delegates the driver workspace UI to the updated feature portal.
class DriverShell extends StatelessWidget {
  const DriverShell({
    super.key,
    required this.driver,
    required this.bookings,
    required this.onSignOut,
    this.user,
  });

  final DriverProfile driver;
  final List<DriverBooking> bookings;
  final VoidCallback onSignOut;
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DriverTheme.theme,
      child: feature_shell.DriverShell(
        driver: driver,
        bookings: bookings,
        onSignOut: onSignOut,
        user: user,
      ),
    );
  }
}
