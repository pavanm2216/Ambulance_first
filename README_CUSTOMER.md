# AeroMed Customer Flutter App

This build focuses only on the **Customer** workspace from the ambulance-booking project,
redesigned around an original **AeroMed** design system (medical green branding, map-first
booking, clean healthcare-consumer UX).

## Customer modules
1. Dashboard
2. Book Ambulance
3. My Bookings
4. Active Trip & Tracker
5. Quotations & Invoices
6. Booking History
7. Public Services

## Design system
- `lib/theme/app_colors.dart` — AeroMed green palette + status color mapping
- `lib/theme/app_text_styles.dart` — type scale (display → caption)
- `lib/theme/app_metrics.dart` — shape radii, spacing, shadow helper
- `lib/theme/app_theme.dart` — assembles the above into the app's `ThemeData`

## Reusable components (`lib/widgets/`)
`AeroMedButton`, `AeroMedCard`, `AeroMedTextField`, `AeroMedStatusBadge`,
`AeroMedBottomSheet` (`showAeroMedBottomSheet`), `AeroMedAppBar`, `AeroMedServiceCard`
(+ `AeroMedSelectableCard`), `AeroMedBookingCard` (+ `AeroMedLocationCard`),
`AeroMedSectionHeader`, `AeroMedPage`/`AeroMedPageHeader`/`AeroMedEmptyState`,
`AeroMedMapPreview` (polished map-style route visual), and small motion helpers
(`FadeSlideIn`, `PulseDot`).

## Architecture
```
lib/
  main.dart
  theme/        design tokens + ThemeData
  models/       Booking, AmbulanceOption
  widgets/      reusable AeroMed component library
  screens/      one file per Customer section + customer_shell.dart (nav + state)
```

## Current implementation
- Flutter Material 3 UI, AeroMed green design system
- Responsive customer workspace (drawer + bottom nav + "More" sheet)
- Map-centric Book Ambulance flow (pickup → destination → patient info →
  ambulance type → timing → fare estimate → confirm)
- Local in-memory booking state, carried through Dashboard, My Bookings,
  Active Trip, and Booking History
- Quotation approval UI, invoice list UI
- Public service catalogue
- Notification sheet
- No external packages required beyond the default Flutter setup

## Backend note
The current customer UI uses local demo data so the project can run immediately.
A real backend/API can be wired into `CustomerShell`'s booking list and the
`BookAmbulancePage.onSubmit` callback without changing any screen's UI code.

## Typography note
Type styling uses the platform default sans-serif (zero extra downloads,
guaranteed to build offline). To switch to Inter/Poppins, add `google_fonts`
to `pubspec.yaml` and wrap the styles in `lib/theme/app_text_styles.dart` with
`GoogleFonts.inter(textStyle: ...)`.
