# Ambulance First — Website Parity Update

This Flutter update aligns the customer/operational domain models with the existing Ambulance First website model definitions without building the Admin role.

## Implemented

- Added `serviceCategory` and `serviceSubtype` to `Booking`.
- Added pickup/destination city and coordinate fields plus estimated duration.
- Added hospital admission state.
- Added ventilator mode and doctor specialization.
- Added railway transfer details: train number/name, coach, pickup and destination stations.
- Added air transfer details: domestic/international type, airports, permit number.
- Added dead-body transfer details: death certificate, freezer, morgue release and family NOC.
- Expanded `Quotation` with pediatric ICU, railway, air ambulance and airport charges.
- Expanded `VitalSign` with glucose, oxygen flow, ventilator pressure, clinical notes and recorder.
- Customer booking UI now exposes transport subtype and conditional railway/air/dead-body fields.
- Customer booking UI now captures hospital admission state and ventilator mode.
- Pediatric threshold aligned with the website's `<14` rule.
- Added optional Supabase bootstrap using `--dart-define`, without hardcoding the senior-provided secret key.
- Added read-only adapters for the website's existing `ambulances`, `drivers`, `doctors`, `customer_care`, and EMT `profiles` tables.

## Intentionally not implemented in this pass

- Admin role.
- A new duplicate resource schema.
- Booking/quotation tables without first verifying the actual shared Supabase schema.
- Payment gateway.
- Production GPS/realtime persistence.

## Supabase startup

Run with the senior-provided public/publishable key only:

```text
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
```

Never put the service-role key in the Flutter application.
