import 'package:flutter/material.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/models/customer_care_case.dart';
import '../../../features/customer_care/presentation/shell/customer_care_shell.dart'
    as feature_shell;
import '../../../features/customer_care/theme/customer_care_theme.dart';

export '../../../core/models/customer_care_case.dart';

/// Standalone Customer Care application wrapper.
///
/// Authentication and role authorization are owned by the main Supabase
/// authentication flow. This wrapper intentionally contains no local/demo
/// credentials and never promotes a user into Customer Care locally.
class CustomerCareApp extends StatelessWidget {
  const CustomerCareApp({
    super.key,
    required this.user,
    this.onLogout,
  });

  final AuthUser user;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambulance First Customer Care Portal',
      theme: CustomerCareTheme.theme,
      home: CustomerCareShell(
        user: user,
        onLogout: onLogout,
      ),
    );
  }
}

/// Bridge widget kept for compatibility with the existing application entry
/// point while delegating presentation to the Customer Care feature shell.
class CustomerCareShell extends StatelessWidget {
  const CustomerCareShell({
    super.key,
    this.cases,
    this.user,
    this.onLogout,
  });

  final List<CustomerCareCase>? cases;
  final AuthUser? user;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CustomerCareTheme.theme,
      child: feature_shell.CustomerCareShell(
        user: user,
        onLogout: onLogout,
      ),
    );
  }
}
