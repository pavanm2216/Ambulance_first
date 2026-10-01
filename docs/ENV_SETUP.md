# Supabase environment setup

The project-root `.env` is loaded by `SupabaseConfig` at startup and is already declared as a Flutter asset in `pubspec.yaml`.

Set:

```env
SUPABASE_URL=https://weyftbzqfmusimqznbwr.supabase.co
SUPABASE_ANON_KEY=<YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY>
```

The key must be the public anon/publishable key from Supabase Project Settings -> API / Connect.

Never put a `service_role` or secret key in Flutter.

`--dart-define=SUPABASE_ANON_KEY=...` takes priority over `.env`, so CI/release builds can inject the public key without editing the file.

After changing `.env`, restart the Flutter process so the asset is rebuilt/loaded.
