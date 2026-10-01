import 'package:flutter/material.dart';

import 'auth/welcome_screen.dart';
import 'auth/invite_setup_screen.dart';
import 'core/models/auth_user.dart';
import 'core/config/supabase_config.dart';
import 'core/models/driver_models.dart';
import 'core/services/supabase_auth_repository.dart';
import 'core/services/supabase_booking_repository.dart';
import 'core/services/customer_portal_cache.dart';
import 'core/services/customer_care_repository.dart';
import 'core/services/supabase_resource_repository.dart';
import 'core/services/shared_booking_store.dart';
import 'core/services/supabase_service.dart';
import 'roles/customer/screens/customer_shell.dart';
import 'roles/customer_care/screens/customer_care_app.dart';
import 'roles/driver/screens/driver_app.dart';
import 'roles/team_lead/screens/team_lead_app.dart';
import 'roles/admin/screens/admin_shell.dart';
import 'roles/doctor/screens/doctor_shell.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/unsupported_role_screen.dart';

/// Ambulance First unified application.
///
/// Authentication is Supabase-backed.
///
/// All Driver profile and booking data are loaded from Supabase.
/// No demo/fake Driver data is used.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.load();
  await SupabaseService.initialize();

  runApp(const AmbulanceFirstUnifiedApp());
}

class AmbulanceFirstUnifiedApp extends StatefulWidget {
  const AmbulanceFirstUnifiedApp({super.key});

  @override
  State<AmbulanceFirstUnifiedApp> createState() =>
      _AmbulanceFirstUnifiedAppState();
}

class _AmbulanceFirstUnifiedAppState
    extends State<AmbulanceFirstUnifiedApp> {
  final SupabaseAuthRepository _authRepository =
      SupabaseAuthRepository();

  final SupabaseBookingRepository _bookingRepository =
      SupabaseBookingRepository();

  final SupabaseResourceRepository _resourceRepository =
      SupabaseResourceRepository();

  bool _signedIn = false;
  bool _inviteFlow = false;
  bool _loadingSession = true;
  String? _startupError;

  bool get _isInviteRoute {
    final path = Uri.base.path.replaceFirst(RegExp(r'/$'), '');
    return path == '/invite';
  }

  AuthUser _user = const AuthUser(
    id: '',
    name: 'Customer',
    email: '',
    phone: '',
    role: 'CUSTOMER',
  );

  // Driver profile is populated from Supabase after authentication.
  //
  // This is only an empty state object. It contains NO fake Driver data.
  final DriverProfile _driver = DriverProfile(
    id: '',
    name: '',
    phone: '',
    email: '',
    licenseNumber: '',
    licenseExpiry: '',
    experienceYears: 0,
    supportedCategories: <String>[],
    currentLocation: '',
    latitude: null,
    longitude: null,
    locationAccuracyMeters: 0,
    locationUpdatedAt: null,
    assignedAmbulanceNumber: '',
    status: 'UNAVAILABLE',
    totalTrips: 0,
    rating: 0,
    assignedBookingId: null,
  );

  // Driver assignments are loaded from:
  //
  // bookings.assigned_driver_id = authenticated Driver ID
  //
  // No demo bookings are created.
  final List<DriverBooking> _driverBookings = <DriverBooking>[];

  final List<CustomerCareCase> _careCases =
      <CustomerCareCase>[];

  @override
  void initState() {
    super.initState();

    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!SupabaseService.isConfigured) {
      if (!mounted) return;

      setState(() {
        _loadingSession = false;
        _startupError =
            'Supabase is not configured. Please configure the Supabase URL and publishable key.';
      });

      return;
    }

    try {
      final user = await _authRepository.currentUser();

      if (user != null) {
        await _syncBookings(user);
      }

      if (!mounted) return;

      setState(() {
        _loadingSession = false;

        if (user != null) {
          _user = user;

          // Supabase invitation establishes an authenticated session
          // before redirecting to /invite.
          if (_isInviteRoute) {
            _inviteFlow = true;
            _signedIn = false;
          } else {
            _signedIn = true;
          }
        } else if (_isInviteRoute) {
          _startupError =
              'This invitation session is unavailable or has expired. '
              'Please ask an administrator to send a new invitation.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingSession = false;
        _startupError = error.toString();
      });
    }
  }

  Future<void> _syncBookings(AuthUser user) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    /*
     * CUSTOMER CARE
     */
    if (user.backendRole == 'CUSTOMER_CARE') {
      await CustomerCareRepository.instance.load();
      return;
    }

    /*
     * CUSTOMER
     */
    if (user.backendRole == 'CUSTOMER') {
      CustomerPortalCache.clear();

      CustomerPortalCache.profile =
          await _bookingRepository.getCustomerProfile();

      CustomerPortalCache.quotations =
          await _bookingRepository.getCustomerQuotations();

      CustomerPortalCache.notifications =
          await _bookingRepository.getCustomerNotifications();
    }

    /*
     * COMMON BOOKING LOAD
     */
    final bookings = await _bookingRepository.getBookingsForUser(
      userId: user.id,
      role: user.backendRole,
    );

    SharedBookingStore.replaceAll(bookings);

    /*
     * CUSTOMER BOOKING HISTORY
     */
    if (user.backendRole == 'CUSTOMER') {
      for (final booking in bookings) {
        CustomerPortalCache.bookingHistory[booking.id] =
            await _bookingRepository.getCustomerBookingHistory(
          booking.id,
        );
      }
    }

    /*
     * DRIVER
     *
     * Everything comes from Supabase.
     */
    if (user.backendRole == 'DRIVER') {
      /*
       * Load Driver profile from the resources tables through
       * the existing repository.
       */
      final resource =
          await _resourceRepository.getDriverForUser(user.id);

      if (resource != null) {
        _copyDriver(resource);
      }

      // `bookings.assigned_driver_id` references the canonical drivers.id,
      // which can differ from the authenticated profile/auth ID.
      final driverBookings =
          await _bookingRepository.getCurrentDriverBookings(
        fallbackDriverId: _driver.id,
      );

      _driverBookings
        ..clear()
        ..addAll(driverBookings);
    }
  }

  Future<void> _authenticate(AuthUser user) async {
    try {
      if (SupabaseService.isConfigured) {
        await _syncBookings(user);
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _signedIn = true;
        _startupError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _startupError =
            'Signed in, but bookings could not be loaded: $error';

        _user = user;
        _signedIn = true;
      });
    }
  }

  void _completeInviteSetup() {
    if (!mounted) return;

    setState(() {
      _inviteFlow = false;
      _signedIn = true;
      _startupError = null;
    });
  }

  Future<void> _logout() async {
    if (SupabaseService.isConfigured) {
      try {
        await _authRepository.signOut();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $error'),
            ),
          );
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _signedIn = false;

      CustomerPortalCache.clear();

      _driverBookings.clear();

      _user = const AuthUser(
        id: '',
        name: 'Customer',
        email: '',
        phone: '',
        role: 'CUSTOMER',
      );
    });
  }

  void _copyDriver(DriverProfile source) {
    _driver.applyFrom(source);
  }

  Widget _authenticatedHome() {
    switch (_user.backendRole) {
      case 'CUSTOMER_CARE':
        return CustomerCareShell(
          cases: _careCases,
          user: _user,
          onLogout: _logout,
        );

      case 'TEAM_LEAD':
        return TeamLeadShell(
          user: _user,
          onLogout: _logout,
        );

      case 'DRIVER':
        return DriverShell(
          driver: _driver,
          bookings: _driverBookings,
          user: _user,
          onSignOut: _logout,
        );

      case 'CUSTOMER':
        return CustomerShell(
          user: _user,
          onLogout: _logout,
        );

      case 'ADMIN':
        return AdminShell(
          user: _user,
          onSignOut: _logout,
        );

      case 'DOCTOR':
        return DoctorShell(
          user: _user,
          onSignOut: _logout,
        );

      default:
        return UnsupportedRoleScreen(
          user: _user,
          onSignOut: _logout,
          message:
              'This profile role is not supported by the current Flutter application.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambulance First',
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: _loadingSession
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _inviteFlow
              ? InviteSetupScreen(
                  user: _user,
                  onComplete: _completeInviteSetup,
                )
              : _signedIn
                  ? _authenticatedHome()
                  : WelcomeScreen(
                      onContinue: _authenticate,
                      initialError: _startupError,
                    ),
    );
  }
}
