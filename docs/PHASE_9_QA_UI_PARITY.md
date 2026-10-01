# Phase 9 — QA and UI Parity Baseline

Status: **static QA completed; runtime Flutter validation remains local-only**.

## Static checks performed

- Release tree inspected for duplicate legacy `lib` directories.
- Supabase service-role/secret-key literals searched in application source.
- Dart source delimiter balance checked.
- Relative Dart imports checked against files present in the release tree.
- Build/cache artifacts are excluded from the release ZIP.
- Admin navigation was made responsive: NavigationRail on desktop and NavigationDrawer on narrow layouts.
- Doctor workspace was made responsive with compact segmented navigation.
- Empty operational resources remain explicit empty states; no production seed data was added.

## Runtime limitation

The packaging environment does not contain the Flutter SDK. Therefore this phase does **not** claim that `flutter analyze`, `flutter test`, `flutter build`, or `flutter run` were executed here.

## Required local validation

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

For a Supabase-connected test, verify separately:

1. Customer can sign in and sees only their bookings.
2. Admin can open the Admin workspace.
3. Doctor can resolve the existing doctor resource and see only assigned bookings.
4. Doctor clinical writes remain blocked until the RLS migration is intentionally enabled.
5. Pricing loads only after the pricing migration is applied.
6. Empty operational tables display empty states rather than demo records.
