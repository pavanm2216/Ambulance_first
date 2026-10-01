import 'package:flutter/material.dart';

import '../shared/theme/app_colors.dart';
import '../shared/theme/app_metrics.dart';
import '../shared/theme/app_text_styles.dart';
import '../core/models/auth_user.dart';
import '../core/services/supabase_auth_repository.dart';
import '../core/services/supabase_service.dart';
import '../shared/widgets/aeromed_button.dart';
import '../shared/widgets/motion.dart';

/// Ambulance First Authentication
///
/// IMPORTANT:
/// This screen intentionally does NOT use OTP authentication.
///
/// Login:
///   Email / Mobile + Password
///
/// Register:
///   Full Name
///   Email / Mobile
///   Mobile Number
///   Password
///   Account Type
///
/// The original glass/neumorphic visual design is preserved.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue, this.initialError});

  final ValueChanged<AuthUser> onContinue;
  final String? initialError;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final SupabaseAuthRepository _authRepository = SupabaseAuthRepository();
  bool _isBusy = false;
  // ---------------------------------------------------------------------------
  // Authentication mode
  // ---------------------------------------------------------------------------

  bool _isLogin = true;

  // ---------------------------------------------------------------------------
  // Password visibility
  // ---------------------------------------------------------------------------

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;

  // ---------------------------------------------------------------------------
  // Remember device
  // ---------------------------------------------------------------------------

  bool _rememberDevice = true;

  // ---------------------------------------------------------------------------
  // Login controllers
  // ---------------------------------------------------------------------------

  final TextEditingController _loginIdentifierController =
      TextEditingController();

  final TextEditingController _loginPasswordController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // Register controllers
  // ---------------------------------------------------------------------------

  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _registerIdentifierController =
      TextEditingController();

  final TextEditingController _registerMobileController =
      TextEditingController();

  final TextEditingController _registerPasswordController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // Account type
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _loginError;
  String? _registerError;

  @override
  void initState() {
    super.initState();
    _loginError = widget.initialError;
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();

    _fullNameController.dispose();
    _registerIdentifierController.dispose();
    _registerMobileController.dispose();
    _registerPasswordController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    setState(() {
      _loginError = null;
      _isBusy = true;
    });

    if (identifier.isEmpty) {
      setState(() {
        _loginError = 'Please enter your email address or mobile number.';
        _isBusy = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _loginError = 'Please enter your password.';
        _isBusy = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _loginError = 'Password must contain at least 6 characters.';
        _isBusy = false;
      });
      return;
    }

    try {
      if (SupabaseService.isConfigured) {
        // The backend profile role is authoritative. The "Continue as"
        // selector is never used to grant permissions.
        final user = await _authRepository.signIn(
          identifier: identifier,
          password: password,
        );
        if (!mounted) return;
        setState(() => _isBusy = false);
        widget.onContinue(user);
        return;
      }

      // Explicit development-only fallback when no public Supabase key has
      // been supplied. This keeps the existing UI usable before credentials
      // are configured; it is never used when the DB connection is enabled.
      final normalizedIdentifier = identifier.toLowerCase();
      const demoCredentials = <String, Map<String, String>>{
        'admin@ambulancefirst.com': {'password': 'Admin@123', 'role': 'ADMIN'},
        'admin@aeromed.com': {'password': 'Admin@123', 'role': 'ADMIN'},
        'customer@aeromed.com': {
          'password': 'Customer@123',
          'role': 'Customer',
        },
        'care@aeromed.com': {'password': 'Care@123', 'role': 'Customer Care'},
        'teamlead@ambulancefirst.com': {
          'password': 'TeamLead@123',
          'role': 'Team Lead',
        },
        'driver@aeromed.com': {'password': 'Driver@123', 'role': 'Driver'},
        'customer@aeromed.org': {
          'password': 'Customer@123',
          'role': 'Customer',
        },
        'cc001': {'password': 'CC@12345', 'role': 'Customer Care'},
        'driver@aeromed.org': {'password': 'DRIVER@123', 'role': 'Driver'},
      };

      final account = demoCredentials[normalizedIdentifier];
      if (account == null) {
        setState(() {
          _loginError =
              'Supabase is not configured. Add SUPABASE_ANON_KEY to connect '
              'this app to the shared database.';
          _isBusy = false;
        });
        return;
      }

      if (password != account['password']) {
        setState(() {
          _loginError = 'Incorrect password for this demo account.';
          _isBusy = false;
        });
        return;
      }

      final user = _demoUser(
        identifier: normalizedIdentifier,
        role: account['role']!,
      );
      if (!mounted) return;
      setState(() => _isBusy = false);
      widget.onContinue(user);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loginError = _friendlyAuthError(error);
        _isBusy = false;
      });
    }
  }

  String _friendlyAuthError(Object error) {
    final text = error.toString();
    if (text.contains('Invalid login credentials')) {
      return 'Invalid email/mobile number or password.';
    }
    if (text.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (text.contains('no matching profiles row')) {
      return 'Your account is authenticated, but no profiles record exists yet. '
          'Ask the backend administrator to provision your profile.';
    }
    if (text.contains('unsupported or missing role')) {
      return 'Your profile has no supported application role.';
    }
    return text.replaceFirst('AuthException: ', '');
  }

  AuthUser _demoUser({required String identifier, required String role}) {
    switch (identifier) {
      case 'admin@ambulancefirst.com':
      case 'admin@aeromed.com':
        return const AuthUser(
          id: 'ADMIN-OPS-001',
          name: 'Central Command Admin',
          email: 'admin@ambulancefirst.com',
          phone: '+1 (555) 019-9000',
          role: 'ADMIN',
        );
      case 'customer@aeromed.com':
        return const AuthUser(
          id: 'CUST-DEMO-001',
          name: 'Kushal Kumar',
          email: 'customer@aeromed.com',
          phone: '+91 98765 43210',
          role: 'Customer',
        );
      case 'customer@aeromed.org':
        return const AuthUser(
          id: 'CUST-DEMO-002',
          name: 'Customer Account',
          email: 'customer@aeromed.org',
          phone: '+91 90000 00001',
          role: 'Customer',
        );
      case 'care@aeromed.com':
        return const AuthUser(
          id: 'CARE-DEMO-001',
          name: 'Customer Care Agent',
          email: 'care@aeromed.com',
          phone: '+91 90000 00002',
          role: 'Customer Care',
        );
      case 'care@aeromed.org':
        return const AuthUser(
          id: 'CARE-DEMO-002',
          name: 'Customer Care Agent 2',
          email: 'care@aeromed.org',
          phone: '+91 90000 00003',
          role: 'Customer Care',
        );
      case 'cc001':
        return const AuthUser(
          id: 'CC001',
          name: 'Customer Care Agent',
          email: 'cc001',
          phone: '+91 90000 00004',
          role: 'Customer Care',
        );
      case 'driver@aeromed.com':
        return const AuthUser(
          id: 'DRV-DEMO-001',
          name: 'Rajesh Kumar',
          email: 'driver@aeromed.com',
          phone: '+91 98765 10020',
          role: 'Driver',
        );
      case 'driver@aeromed.org':
        return const AuthUser(
          id: 'DRV-DEMO-002',
          name: 'Driver Account 2',
          email: 'driver@aeromed.org',
          phone: '+91 90000 00005',
          role: 'Driver',
        );
      case 'teamlead@ambulancefirst.com':
        return const AuthUser(
          id: 'TL-DEMO-001',
          name: 'Team Lead',
          email: 'teamlead@ambulancefirst.com',
          phone: '+91 90000 00006',
          role: 'Team Lead',
        );
      case 'teamlead@aeromed.com':
        return const AuthUser(
          id: 'TL-DEMO-002',
          name: 'Team Lead 2',
          email: 'teamlead@aeromed.com',
          phone: '+91 90000 00007',
          role: 'Team Lead',
        );
      default:
        return AuthUser(
          id: _accountIdFor(identifier, role),
          name: _displayNameFor(identifier, role),
          email: identifier,
          phone: '',
          role: role,
        );
    }
  }

  String _accountIdFor(String identifier, String role) {
    final prefix = role.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    final suffix = identifier.hashCode
        .abs()
        .toString()
        .padLeft(6, '0')
        .substring(0, 6);
    return '$prefix-$suffix';
  }

  String _displayNameFor(String identifier, String role) {
    if (identifier.isEmpty) return '$role Account';
    final raw = identifier.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    if (raw.isEmpty) return '$role Account';
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final fullName = _fullNameController.text.trim();
    final identifier = _registerIdentifierController.text.trim();
    final mobile = _registerMobileController.text.trim();
    final password = _registerPasswordController.text;

    setState(() {
      _registerError = null;
      _isBusy = true;
    });

    if (fullName.isEmpty) {
      setState(() {
        _registerError = 'Please enter your full name.';
        _isBusy = false;
      });
      return;
    }

    if (identifier.isEmpty) {
      setState(() {
        _registerError = 'Please enter your email address or mobile number.';
        _isBusy = false;
      });
      return;
    }

    if (mobile.isEmpty) {
      setState(() {
        _registerError = 'Please enter your mobile number.';
        _isBusy = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _registerError = 'Password must contain at least 6 characters.';
        _isBusy = false;
      });
      return;
    }

    try {
      if (!SupabaseService.isConfigured) {
        setState(() {
          _registerError =
              'Supabase is not configured. Add SUPABASE_ANON_KEY before '
              'creating a real account.';
          _isBusy = false;
        });
        return;
      }

      final user = await _authRepository.registerCustomer(
        fullName: fullName,
        identifier: identifier,
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLogin = true;
          _loginIdentifierController.text = identifier;
          _loginPasswordController.clear();
          _registerError = null;
          _loginError =
              'Account created. Complete the required email/phone verification '
              'then sign in.';
          _isBusy = false;
        });
        return;
      }

      setState(() => _isBusy = false);
      widget.onContinue(user);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _registerError = _friendlyAuthError(error);
        _isBusy = false;
      });
    }
  }

  // ===========================================================================
  // SWITCH AUTH MODE
  // ===========================================================================

  void _showLogin() {
    setState(() {
      _isLogin = true;
      _loginError = null;
      _registerError = null;
    });
  }

  void _showRegister() {
    setState(() {
      _isLogin = false;
      _loginError = null;
      _registerError = null;
    });
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceContainerLowest,
              AppColors.surfaceContainerLow,
              AppColors.tactileCardOffWhite,
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 480
                  ? 440.0
                  : double.infinity;

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeSlideIn(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildLanguageSelector(), _buildSosButton()],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _buildBrandHeader(),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _buildAuthCard(),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: _buildEmergencyCard(),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'All medical transport adheres to ISO 9001 & HIPAA-Compliant standards.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SizedBox(
                      width: maxWidth == double.infinity
                          ? constraints.maxWidth
                          : maxWidth,
                      child: content,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LANGUAGE SELECTOR
  // ===========================================================================

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'EN / IN',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SOS BUTTON
  // ===========================================================================

  Widget _buildSosButton() {
    return Material(
      color: AppColors.errorSoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => widget.onContinue(
          _demoUser(identifier: 'customer@aeromed.com', role: 'Customer'),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.urgentRed.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PulseDot(size: 6, color: AppColors.urgentRed),
              const SizedBox(width: 8),
              Text(
                'SOS 112',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.urgentRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BRAND HEADER
  // ===========================================================================

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child: Icon(
              Icons.local_hospital_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _isLogin ? 'Welcome to Ambulance First' : 'Join Ambulance First',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _isLogin
                ? 'Book safe, verified medical transit and rapid critical care transport when every second counts.'
                : 'Create your Ambulance First account and start coordinating safer medical journeys.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // AUTH CARD
  // ===========================================================================

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===============================================================
          // LOGIN / REGISTER TABS
          // ===============================================================

          _buildAuthTabs(),

          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIN / REGISTER TABS
  // ===========================================================================

  Widget _buildAuthTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTabButton(
              label: 'Login',
              icon: Icons.login_rounded,
              selected: _isLogin,
              onTap: _showLogin,
            ),
          ),

          Expanded(
            child: _AuthTabButton(
              label: 'Register',
              icon: Icons.person_add_alt_1_rounded,
              selected: !_isLogin,
              onTap: _showRegister,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIN FORM
  // ===========================================================================

  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey('login-form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------------------------------------------------------
          // EMAIL / MOBILE
          // ---------------------------------------------------------------

          Text(
            'Email address or mobile number',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _loginIdentifierController,
            hintText: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // PASSWORD
          // ---------------------------------------------------------------
          Text(
            'Password',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _loginPasswordController,
            hintText: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                });
              },
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your Supabase profile determines your application role. '
                    'Role selection cannot grant access.',
                    style: AppTextStyles.supporting,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // ERROR
          // ---------------------------------------------------------------
          if (_loginError != null) ...[
            const SizedBox(height: 10),
            _buildError(_loginError!),
          ],

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // REMEMBER DEVICE
          // ---------------------------------------------------------------
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _rememberDevice,
                  onChanged: (value) {
                    setState(() {
                      _rememberDevice = value ?? true;
                    });
                  },
                  activeColor: AppColors.primary,
                  checkColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text('Remember device', style: AppTextStyles.bodySmall),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  _showMessage(
                    'Password recovery will be connected to the backend.',
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------------------
          // LOGIN BUTTON
          // ---------------------------------------------------------------
          AeroMedButton(
            label: _isBusy ? 'Connecting…' : 'Enter workspace',
            icon: Icons.login_rounded,
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: _isBusy
                ? null
                : () {
                    _login();
                  },
          ),

          const SizedBox(height: 18),

          Center(
            child: _buildBottomSwitch(
              firstText: "Don't have an account?",
              actionText: 'Register',
              onTap: _showRegister,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REGISTER FORM
  // ===========================================================================

  Widget _buildRegisterForm() {
    return Container(
      key: const ValueKey('register-form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------------------------------------------------------
          // FULL NAME
          // ---------------------------------------------------------------

          Text(
            'Full name',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _fullNameController,
            hintText: 'Your full name',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // EMAIL / MOBILE
          // ---------------------------------------------------------------
          Text(
            'Email address or mobile number',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _registerIdentifierController,
            hintText: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // MOBILE
          // ---------------------------------------------------------------
          Text(
            'Mobile number',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _registerMobileController,
            hintText: '+91 98765 43210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          // ---------------------------------------------------------------
          // PASSWORD
          // ---------------------------------------------------------------
          Text(
            'Password',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          _buildInputField(
            controller: _registerPasswordController,
            hintText: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureRegisterPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureRegisterPassword = !_obscureRegisterPassword;
                });
              },
              icon: Icon(
                _obscureRegisterPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------------------------------------------------------
          // ACCOUNT TYPE
          // ---------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New self-registered accounts are created as CUSTOMER. '
                    'Operational roles are provisioned through the existing backend.',
                    style: AppTextStyles.supporting,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // ERROR
          // ---------------------------------------------------------------
          if (_registerError != null) ...[
            const SizedBox(height: 10),
            _buildError(_registerError!),
          ],

          const SizedBox(height: 20),

          // ---------------------------------------------------------------
          // REGISTER BUTTON
          // ---------------------------------------------------------------
          AeroMedButton(
            label: 'Create account',
            icon: Icons.person_add_alt_1_rounded,
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: _isBusy
                ? null
                : () {
                    _register();
                  },
          ),

          const SizedBox(height: 18),

          Center(
            child: _buildBottomSwitch(
              firstText: 'Already have an account?',
              actionText: 'Login',
              onTap: _showLogin,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INPUT FIELD
  // ===========================================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,

          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 19),

          suffixIcon: suffixIcon,

          hintText: hintText,

          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.urgentRed,
            size: 17,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.urgentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM LOGIN / REGISTER SWITCH
  // ===========================================================================

  Widget _buildBottomSwitch({
    required String firstText,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          firstText,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),

        const SizedBox(width: 5),

        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // EMERGENCY CARD
  // ===========================================================================

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.errorContainer, AppColors.errorSoft],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.urgentRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.urgentRed.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need immediate dispatch?',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 15,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Skip sign-in for life-threatening crisis',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgentRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => widget.onContinue(
              _demoUser(identifier: 'customer@aeromed.com', role: 'Customer'),
            ),
            child: Text(
              '112 SOS',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AUTH TAB BUTTON
// ============================================================================

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: selected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),

              const SizedBox(width: 7),

              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
