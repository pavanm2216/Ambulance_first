import 'package:flutter/services.dart';

/// Runtime configuration for the existing Ambulance First Supabase project.
///
/// Configuration sources, in priority order:
/// 1. SUPABASE_ANON_KEY supplied with --dart-define.
/// 2. The bundled project-root .env file (public anon/publishable key only).
///
/// The Supabase anon/publishable key is safe to ship to a client application;
/// a service_role/secret key must NEVER be placed in this file or Flutter code.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://weyftbzqfmusimqznbwr.supabase.co';

  // SUPABASE_PUBLISHABLE_KEY is the current client-side key name.
  // SUPABASE_ANON_KEY remains supported for backwards compatibility with
  // existing local/Netlify builds.
  static const String _dartDefinePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String _dartDefineAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String _publishableKey =
      _dartDefinePublishableKey.trim().isNotEmpty
          ? _dartDefinePublishableKey
          : _dartDefineAnonKey;
  static bool _loaded = false;

  static String get publishableKey => _publishableKey;
  static bool get isConfigured => _publishableKey.trim().isNotEmpty;
  static bool get isLoaded => _loaded;

  /// Loads the public Supabase key from the bundled .env when no dart-define
  /// value was supplied. This keeps local setup simple while still allowing
  /// CI/CD and production builds to inject the key explicitly.
  static Future<void> load() async {
    if (_loaded) return;

    // --dart-define always wins over .env. Prefer the current publishable
    // key name, while retaining the legacy anon-key name for compatibility.
    if (_dartDefinePublishableKey.trim().isNotEmpty ||
        _dartDefineAnonKey.trim().isNotEmpty) {
      _publishableKey = _dartDefinePublishableKey.trim().isNotEmpty
          ? _dartDefinePublishableKey.trim()
          : _dartDefineAnonKey.trim();
      _loaded = true;
      return;
    }

    try {
      final contents = await rootBundle.loadString('.env');
      final values = _parseEnv(contents);
      final envKey = (values['SUPABASE_PUBLISHABLE_KEY']?.trim().isNotEmpty ?? false)
          ? values['SUPABASE_PUBLISHABLE_KEY']!.trim()
          : (values['SUPABASE_ANON_KEY']?.trim() ?? '');
      if (_isUsableKey(envKey)) {
        _publishableKey = envKey;
      }
    } catch (_) {
      // .env is optional. If it is absent, the app falls back to the existing
      // demo/local mode rather than crashing during startup.
    }

    _loaded = true;
  }

  static Map<String, String> _parseEnv(String contents) {
    final result = <String, String>{};

    for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final separator = line.indexOf('=');
      if (separator <= 0) continue;

      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();

      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      result[key] = value;
    }

    return result;
  }

  static bool _isUsableKey(String value) {
    if (value.isEmpty) return false;
    final normalized = value.toUpperCase();
    return !normalized.contains('YOUR_PUBLIC') &&
        !normalized.contains('YOUR-') &&
        !normalized.contains('YOUR_') &&
        value != 'your-public-anon-or-publishable-key';
  }
}
