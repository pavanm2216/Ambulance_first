import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Single bootstrap point for the existing Ambulance First Supabase project.
///
/// The project URL is fixed to the shared backend. The public publishable
/// key is supplied with --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// The legacy SUPABASE_ANON_KEY define remains supported.
class SupabaseService {
  static bool _initialized = false;

  static String get url => SupabaseConfig.url;
  static String get publishableKey => SupabaseConfig.publishableKey;
  static bool get isConfigured => SupabaseConfig.isConfigured;
  static bool get isInitialized => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase has not been initialized. Call SupabaseService.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
    _initialized = true;
  }
}
