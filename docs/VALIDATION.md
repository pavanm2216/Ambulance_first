# Release validation

- Clean portal directory structure: PASS
- Legacy duplicate lib folders removed: PASS
- Relative Dart imports resolve to existing files: PASS
- Dart delimiter/balance scan: PASS
- Build/cache artifacts removed from release: PASS
- Full `flutter analyze` / `flutter build`: not executable in the packaging environment because the Flutter SDK is not installed there.

The browser assertion shown in the supplied screenshot references Flutter framework lifecycle internals. This release removes stale build artifacts and the duplicated source-tree layout; after extracting, run `flutter clean`, `flutter pub get`, then `flutter run` (or restart the web debug session rather than hot-reloading the old tree).
