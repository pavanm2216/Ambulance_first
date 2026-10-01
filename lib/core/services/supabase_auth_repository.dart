import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart' as app_models;
import 'supabase_service.dart';

/// Authentication adapter for the existing Supabase Auth + profiles setup.
///
/// IMPORTANT:
/// - The backend profile role is authoritative.
/// - The client never promotes a user to a role selected in the UI.
/// - ADMIN is recognized and routed to the Admin Flutter portal.
/// - EMT is not treated as a profile role because it is not confirmed by the
///   current backend contract.
class SupabaseAuthRepository {
  SupabaseClient get _db => SupabaseService.client;

  Future<app_models.AuthUser?> currentUser() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return profileForUser(user);
  }

  Future<app_models.AuthUser> signIn({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final response = trimmed.contains('@')
        ? await _db.auth.signInWithPassword(email: trimmed, password: password)
        : await _db.auth.signInWithPassword(phone: trimmed, password: password);

    final user = response.user;
    if (user == null) {
      throw const AuthException('Authentication failed.');
    }

    return profileForUser(user);
  }

  Future<app_models.AuthUser?> registerCustomer({
    required String fullName,
    required String identifier,
    required String mobile,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final metadata = <String, dynamic>{
      'full_name': fullName.trim(),
      'name': fullName.trim(),
      'phone': mobile.trim(),
      // Self-registration is CUSTOMER only. Internal roles are provisioned
      // through the existing backend/profile administration process.
      'role': 'CUSTOMER',
    };

    final response = trimmed.contains('@')
        ? await _db.auth.signUp(
            email: trimmed,
            password: password,
            data: metadata,
          )
        : await _db.auth.signUp(
            phone: trimmed,
            password: password,
            data: metadata,
          );

    final user = response.user;
    if (user == null) return null;

    // If email/phone confirmation is enabled, session can be null. In that
    // case the UI should tell the user to complete verification before login.
    if (response.session == null) return null;

    return profileForUser(user);
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<app_models.AuthUser> profileForUser(User user) async {
    Map<String, dynamic>? row;

    try {
      final result = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (result != null) {
        row = Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Some existing profile schemas use user_id rather than id. Try the
      // alternate relationship before surfacing the profile error.
      try {
        final result = await _db
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (result != null) {
          row = Map<String, dynamic>.from(result);
        }
      } catch (_) {
        rethrow;
      }
    }

    if (row == null) {
      throw StateError(
        'Authenticated user has no matching profiles row. '
        'Create/provision the profile before entering the application.',
      );
    }

    final role = _normalizeRole(row['role']?.toString());
    if (role == null) {
      throw StateError(
        'The profiles row contains an unsupported or missing role.',
      );
    }

    if (role == 'CUSTOMER') {
      final customerProfile = await _db.rpc('get_customer_profile');
      if (customerProfile is! Map) {
        throw const FormatException('get_customer_profile returned malformed data.');
      }
      final profile = Map<String, dynamic>.from(customerProfile);
      final profileRole = _normalizeRole(profile['role']?.toString());
      if (profileRole != 'CUSTOMER') {
        throw StateError('get_customer_profile returned a non-Customer profile.');
      }
      return app_models.AuthUser(
        id: _requiredProfileValue(profile, 'id', user.id),
        name: _profileValue(profile, 'full_name'),
        email: _profileValue(profile, 'email'),
        phone: _profileValue(profile, 'phone'),
        role: profileRole!,
      );
    }

    return app_models.AuthUser(
      id: user.id,
      name: _firstNonEmpty([
        row['full_name'],
        row['name'],
        user.userMetadata?['full_name'],
        user.userMetadata?['name'],
        user.email,
      ]),
      email: _firstNonEmpty([
        row['email'],
        user.email,
      ]),
      phone: _firstNonEmpty([
        row['phone'],
        user.phone,
        user.userMetadata?['phone'],
      ]),
      role: role,
    );
  }

  String _requiredProfileValue(
    Map<String, dynamic> profile,
    String key,
    String fallback,
  ) {
    final value = _profileValue(profile, key);
    if (value.isEmpty) return fallback;
    return value;
  }

  String _profileValue(Map<String, dynamic> profile, String key) {
    return profile[key]?.toString().trim() ?? '';
  }

  String? _normalizeRole(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'CUSTOMER':
        return 'CUSTOMER';
      case 'CUSTOMER_CARE':
      case 'CUSTOMER CARE':
        return 'CUSTOMER_CARE';
      case 'TEAM_LEAD':
      case 'TEAM LEAD':
        return 'TEAM_LEAD';
      case 'DRIVER':
        return 'DRIVER';
      case 'DOCTOR':
        return 'DOCTOR';
      case 'ADMIN':
        return 'ADMIN';
      default:
        return null;
    }
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
