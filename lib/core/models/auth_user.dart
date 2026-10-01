class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  /// Canonical backend role.
  ///
  /// ADMIN and DOCTOR are recognized explicitly. EMT is intentionally not
  /// included because the current Supabase profile role contract does not confirm it.
  String get backendRole {
    switch (role.trim().toUpperCase()) {
      case 'CUSTOMER':
        return 'CUSTOMER';
      case 'CUSTOMER CARE':
      case 'CUSTOMER_CARE':
        return 'CUSTOMER_CARE';
      case 'TEAM LEAD':
      case 'TEAM_LEAD':
        return 'TEAM_LEAD';
      case 'DRIVER':
        return 'DRIVER';
      case 'DOCTOR':
        return 'DOCTOR';
      case 'ADMIN':
        return 'ADMIN';
      default:
        return role.trim().toUpperCase();
    }
  }
}
