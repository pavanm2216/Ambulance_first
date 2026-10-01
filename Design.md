# Design.md — Ambulance First
### Emergency Medical Transport Platform — UI/UX Design Specification

> **Scope:** Admin · Customer · Customer Care · Driver · Team Lead · Doctor portals
> **Framework:** Flutter (Material 3, useMaterial3: true)
> **Last Updated:** September 30, 2026

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Shared Design System Tokens](#2-shared-design-system-tokens)
3. [Admin Portal Design](#3-admin-portal-design)
4. [Customer Portal Design](#4-customer-portal-design)
5. [Driver Console Design](#5-driver-console-design)
6. [Customer Care Portal Design](#6-customer-care-portal-design)
7. [Team Lead Portal Design](#7-team-lead-portal-design)
8. [Doctor Workspace Design](#8-doctor-workspace-design)
9. [Cross-Portal Design Patterns](#9-cross-portal-design-patterns)
10. [Semantic Color Usage](#10-semantic-color-usage)
11. [Accessibility, Responsiveness & Gaps](#11-accessibility-responsiveness--gaps)

---

## 1. Design Philosophy

Ambulance First is a **clinical-grade, high-stakes emergency transport platform**. The six role experiences share emergency-status semantics and a light clinical foundation, but do not yet use one unified theme or component library. Each experience is optimized for a different operational task:

| Principle | Description |
|---|---|
| **Operational Clarity** | Critical information must be immediately scannable at a glance — no visual clutter. |
| **Trust & Authority** | Clinical Cobalt (#0369A1) is the primary brand identity — professional, reliable, calm under pressure. |
| **High-Density Data** | Screens carry real-time telemetry, booking IDs, patient vitals, GPS coordinates, and queue metrics — displayed without cognitive overload. |
| **Role Specificity** | Each portal is tailored to its operator's mental model: Admin = oversight, Customer = booking visibility, Customer Care = triage, Driver = trip execution, Team Lead = allocation, Doctor = clinical review. |
| **Zero Ambiguity** | Status badges, urgency pips, semantic colors, and JetBrains Mono numerics provide unambiguous state communication. |
| **Light-Mode First** | Operations portals generally use a light clinical canvas. Customer and Doctor also consume a separate pale-green AeroMed palette; see the theme matrix for current inconsistencies. |

---

## 2. Shared Design System Tokens

### 2.1 Color Palette

There is no single color contract across all roles. Admin, Driver, and Customer Care use closely related cobalt/slate tokens; Team Lead uses a related but separately defined palette; Customer and Doctor use the AeroMed/AppColors green system in parts of the UI while the Customer shell also applies a cobalt theme. The role matrix below records the implementation as it exists, not a promise that every widget uses one token source.

#### Clinical Cobalt Family — Admin, Driver, Customer Care, Team Lead

| Token | Hex | Usage |
|---|---|---|
| primary | #00507D | Deep brand blue; text on light bg |
| primaryContainer | #0369A1 | Primary interactive elements, CTA buttons, app bars |
| onPrimary | #FFFFFF | Text on primary-filled surfaces |
| onPrimaryContainer | #CBE4FF | Text on dark primary containers |
| primaryFixed | #CDE5FF | Light tint for badges, chips bg |
| primaryFixedDim | #94CCFF | Hovered/dimmed primary state |
| onPrimaryFixed | #001D32 | Text on primaryFixed surfaces |
| inversePrimary | #94CCFF | Inverse primary — defined in Driver and Customer Care tokens |

#### Operational Emerald — Role-Specific Secondary / Readiness

| Token | Hex | Usage |
|---|---|---|
| secondary | #006C4A | Available/on-duty status, verified state |
| secondaryContainer | #82F5C1–#9AF1C6 | Verified badge / chip; exact values differ by role |
| onSecondary | #FFFFFF | Text on secondary |
| secondaryFixed | #85F8C4 | Fixed emerald tint |

#### Error / Alert — Code Red (Crimson)

| Token | Hex | Usage |
|---|---|---|
| error | #DC2626 | Critical alerts, Code Red badges, ETA labels, CRITICAL urgency pips |
| errorContainer | #FFDAD6 | Code Red background chips |
| onError | #FFFFFF | Text on error |
| onErrorContainer | #93000A | Text on errorContainer |

#### Warning — Urgent Amber

| Token | Hex | Usage |
|---|---|---|
| warning | #D97706 | In-transit, pending, follow-up badges |
| warningContainer | #FEF3C7–#FFFBEB | Warning chip backgrounds |
| onWarning | #92400E | Text on warningContainer |

#### Surface Hierarchy (Light-Mode Canvas)

| Token | Hex | Usage |
|---|---|---|
| background / surface | #F8F9FF | Scaffold background |
| surfaceContainerLowest | #FFFFFF | Cards, modals, form panels |
| surfaceContainerLow | #EFF4FF | Input fill, hover states |
| surfaceContainer | #E5EEFF | Chip bg, divider areas |
| surfaceContainerHigh | #DCE9FF | Triage ticker bg, selected states |
| surfaceContainerHighest | #D3E4FE | Deepest container for dense grids |
| surfaceDim | #CBDBF5–#D3E4FE | Muted surface, radar card bg |

#### Inverse — Dark Chrome (HUDs & Nav)

| Token | Hex | Usage |
|---|---|---|
| inverseSurface | #213145 | Drawer overlays, dark telemetry bg |
| inverseSurfaceDark | #131D2A | Driver HUD bar |
| inverseOnSurface | #EAF1FF | Text on inverse surfaces |
| commandNavDark | #0B132B | Admin command drawer bg, CC tactical nav |
| commandNavMarine | #1C2541 | Admin nav accent |

#### Customer Care — Tertiary Lavender (Specialist / Pediatric)

| Token | Hex | Usage |
|---|---|---|
| tertiary | #392CD1 | Customer Care specialist / PICU indicator; Customer uses a related but different violet |
| tertiaryContainer | #534BE9 | Lavender badge bg |
| tertiaryFixed | #E2DFFF | Light lavender tint |

#### Status / Telemetry Indicators (Driver)

| Token | Hex | Usage |
|---|---|---|
| liveTelemetry | #10B981 | Live GPS ping indicator |
| staleTelemetry | #F59E0B | Stale / delayed telemetry |
| unavailableTelemetry | #EF4444 | GPS unavailable |

#### Content / Outline Colors

| Token | Hex | Usage |
|---|---|---|
| onSurface | #0B1C30 | Primary text in Admin, Driver, and Customer Care; other roles differ |
| onSurfaceVariant | #40474F | Secondary text, labels, subtitles |
| outline | #707881 | Timestamps, muted labels |
| outlineVariant | #C0C7D1 | Card borders, divider lines |
| borderSubtle | #E2E8F0 | Hairline card edges (Admin) |

#### Role Theme Matrix (Observed)

| Role | Theme source | Canvas / brand | Semantic accents | UI / data typefaces | Implementation note |
|---|---|---|---|---|---|
| Admin | `StitchTheme` | #F8F9FF / #0369A1 | Emerald #00573B, error #DC2626, amber #D97706 | Inter / JetBrains Mono | Consistent role-local tokens; flat cards and subtle borders. |
| Customer | `AmbulanceFirstTheme` + shared `AppColors` | Theme #F8F9FF and cobalt #00507D; shared palette #F6F8F7 and green #3FAF6A | Theme crimson #DC2626; shared alert #D95353; amber #D99A32 | Inter + JetBrains Mono in role theme; Plus Jakarta Sans + Space Grotesk in shared text styles | Current screens mix both theme/token families. |
| Customer Care | `CustomerCareTheme` / `CustomerCareColors` | #F8F9FF / #0369A1 | Emerald #006C4A, violet #392CD1, error #DC2626, amber #D97706 | Inter / JetBrains Mono | Violet tertiary is reserved for specialist/pediatric meaning. |
| Driver | `DriverTheme` / `DriverColors` | #F8F9FF / #0369A1 | Emerald #006C4A, emergency red #DC2626, amber #D97706 | Public Sans / JetBrains Mono | Inverse colors are used for HUD and map overlays. |
| Team Lead | `TeamLeadTheme` | #F8F9FF / #00507D; some screens use #F6F8FB | Emerald #006C4A, crimson #DC2626, amber #D97706 | Inter / JetBrains Mono tokens | Some screens use literal colors and styles instead of role tokens. |
| Doctor | Shared `AeroMedRoleShell`, `AppTheme`, `AppColors` | Shared #F6F8F7 / #3FAF6A palette | Shared alert #D95353, warning #D99A32 | Plus Jakarta Sans / Space Grotesk via shared text theme | No doctor-specific theme exists. |

The same token name can mean different things by role: Admin tertiary is readiness green, Driver tertiary is emergency red, and Customer Care tertiary is specialist violet. Always use the owning role's token.

---

### 2.2 Typography

Several portals use two typefaces, but the font families differ by role. IDs, coordinates, timestamps, and telemetry are generally monospaced where a role-specific data style exists; do not assume every role uses JetBrains Mono.

#### Admin Portal (StitchTheme)
- **UI Font:** Inter (Google Fonts) — used for all headlines, body, and buttons
- **Telemetry Font:** JetBrains Mono — used for booking IDs, timestamps, CAD codes

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| displayLg | Inter | 30px | 700 | Hero stats on dashboard |
| displayLgMobile | Inter | 24px | 700 | Mobile dashboard headings |
| headlineLg | Inter | 22px | 600 | Section titles |
| headlineMd | Inter | 18px | 600 | Card headings |
| headlineSm | Inter | 15px | 600 | Sub-section headers |
| bodyLg | Inter | 15px | 400 | Primary narrative |
| bodyMd | Inter | 13px | 400 | Supporting content |
| bodySm | Inter | 12px | 400 | Captions, audit log details |
| labelLg | JetBrains Mono | 13px | 600 | Booking IDs, CAD codes |
| labelMd | JetBrains Mono | 11px | 500 | Operational labels |
| labelSm | JetBrains Mono | 10px | 500 | Timestamps, sub-codes |

#### Driver Console (DriverTextStyles)
- **UI Font:** Public Sans (Google Fonts)
- **Telemetry Font:** JetBrains Mono

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| headlineLarge | Public Sans | 24px | 700 | Large driver headings |
| headlineMedium | Public Sans | 20px | 700 | Section headings |
| headlineSmall | Public Sans | 16px | 700 | Mission sub-headers |
| titleMedium | Public Sans | 15px | 600 | Patient name labels |
| bodyLarge | Public Sans | 15px | 400 | Route descriptions |
| bodyMedium | Public Sans | 13px | 400 | Supporting content |
| bodySmall | Public Sans | 11px | 400 | Captions |
| button | Public Sans | 14px | 700 | All CTA labels |
| telemetryLarge | JetBrains Mono | 24px | 800 | Speed, ETA primary displays |
| telemetryMedium | JetBrains Mono | 18px | 700 | KPI values |
| telemetrySmall | JetBrains Mono | 13px | 600 | Secondary telemetry |
| telemetryMicro | JetBrains Mono | 10px | 600 | HUD micro-labels, pilot IDs |
| bookingId | JetBrains Mono | 12px | 700 | Booking ID display |
| timestamp | JetBrains Mono | 11px | 500 | Time readouts |

#### Customer Care Portal (CustomerCareTextStyles)
- **UI Font:** Inter (Google Fonts)
- **Telemetry Font:** JetBrains Mono

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| headlineLg | Inter | 28px | 700 | Portal header, login title |
| headlineLgMobile | Inter | 22px | 700 | Mobile dashboard headings |
| headlineMd | Inter | 20px | 600 | Section titles |
| headlineSm | Inter | 16px | 600 | Card headings, queue labels |
| bodyLg | Inter | 15px | 400 | Clinical narrative |
| bodyMd | Inter | 13px | 400 | Form fields, descriptions |
| bodySm | Inter | 12px | 400 | Captions, empty state messages |
| telemetryDisplay | JetBrains Mono | 18px | 700 | Live radar / telemetry values |
| labelLg | JetBrains Mono | 13px | 600 | Booking IDs, CC codes |
| labelMd | JetBrains Mono | 11px | 600 | Operational labels |
| labelSm | JetBrains Mono | 10px | 500 | Timestamps, sub-codes |

---

### 2.3 Spacing & Border Radii

#### Spacing Scales

Spacing is role-local rather than one shared scale. `AppSpacing` uses a 4px base, steps of 8/12/16/20/24/28/32/40/48/64px, and 20px standard margin (12px mobile). `StitchTheme` uses 4/8/12/20/32px named steps and a 16px margin. Customer Care and Team Lead define their own scales.

| Token | Value | Usage |
|---|---|---|
| spaceXs | 4px | Icon-to-text gaps, tight badge padding |
| spaceSm | 8px | Between card rows, between small chips |
| spaceMd | 12px | Card internal padding, between sections |
| spaceLg | 20px | Between major sections on a screen |
| spaceXl | 32px | Hero section spacing |
| margin | 16px | Standard horizontal screen padding |

#### Border Radii

| Token | Value | Usage |
|---|---|---|
| radiusSm | 4px | Finance boxes, tight chips |
| radiusMd | 8px | Tags, compact chips |
| radiusLg | 12px | Standard cards, standard containers |
| radiusXl | 16px | Large cards, login panels |
| radiusPill | 9999px | Status badges, filter pills |

> Driver-specific: Cards use 18–22px radius for a more rounded mobile feel.

---

### 2.4 Elevation & Shadows

Elevation is role-specific. Admin, Driver, Customer Care, and Team Lead generally use zero-elevation cards with tonal surfaces and borders. AeroMed/Customer shared widgets include layered, soft shadows on selected tactile cards and controls. Avoid describing the whole product as either shadowless or glass-based.

---

## 3. Admin Portal Design

### 3.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | StitchTheme |
| Design system name | Emergency Medical Fleet Operations Portal |
| Scaffold background | #F8F9FF |
| Card style | Zero elevation, borderSubtle hairline border (#E2E8F0), 12px radius |
| AppBar | Flat, background-colored, no elevation |
| Font | Inter (UI) + JetBrains Mono (telemetry) |
| Primary color | #0369A1 (Clinical Cobalt) |
| Nav chrome | #0B132B (Command Dark) / #1C2541 (Command Marine) |
| Target platform | Web, tablet, and mobile |

### 3.2 Navigation Shell

Shell class: AdminShell (lib/roles/admin/screens/admin_shell.dart)

Layout:
- Fixed top: StitchHeader [Title] [User] [Sync] [Drawer Menu]
- Contextual: LinearProgressIndicator or Error Banner
- Scrollable: IndexedStack (Page Content)
- Fixed bottom: StitchBottomNav [Tab icons] [More]
- End Drawer: StitchCommandDrawer (dark chrome, #0B132B)

The bottom bar shows Dashboard, Dispatch, Fleet, Staff, Finance, and More. Reports, Audit, and Pricing remain destinations in the command drawer. The eight-item table below is the full destination set, not the number of bottom-bar items.

Navigation Tabs (8 items):

| Index | Tab Label | Screen |
|---|---|---|
| 0 | Dashboard | AdminDashboardScreen |
| 1 | Bookings | AdminBookingsScreen |
| 2 | Fleet | AdminFleetScreen |
| 3 | Staff | AdminStaffScreen |
| 4 | Finance | AdminQuotationsScreen |
| 5 | Reports | AdminReportsScreen |
| 6 | Audit | AdminAuditScreen |
| 7 | Pricing Settings | AdminPricingScreen |

Booking 360 Detail is a full-screen overlay pushed imperatively (replaces shell content without changing tab index).

### 3.3 Screen Inventory

#### Dashboard (AdminDashboardScreen)

A command-center overview screen with 7 functional sections stacked vertically:

| # | Section | Key Data |
|---|---|---|
| 1 | Live Triage Ticker | Active bookings cycling every 4s with pause/play control via AnimatedSwitcher |
| 2 | Executive KPI Grid (StitchMetricCard x2) | Total Bookings, Active Trips (sub-labels: Transit / Started / Picked Up) |
| 3 | Fleet Readiness Gauge (StitchFleetReadinessCard) | Available / Total ambulances count |
| 4 | Revenue & Quotations Matrix (_FinanceBox x4) | Quoted Pipeline, Accepted Orders, Paid/Recognized, Outstanding |
| 5 | Live Active Bookings Feed (_ActiveBookingItem list) | Patient, route, ETA, urgency pip, status badge |
| 6 | Medical Staff Readiness (_StaffRosterRow x3) | Doctors / EMTs / Drivers — available vs. total |
| 7 | Governance & Audit Feed | Recent 3 audit log entries — severity icon, entity ID, timestamp delta |

Triage Ticker:
- surfaceContainerHigh background, red dot indicator, "TRIAGE TICKER:" label in error color
- AnimatedSwitcher for smooth message transitions, pause/play toggle

Active Booking Item:
- Left urgency pip: error (CRITICAL) or warning (URGENT) — 5px wide vertical bar
- Booking ID in JetBrains Mono + relative timestamp + status badge pill
- Patient avatar (initials, primaryContainer bg) + name/age/gender + ETA in error color
- Route row: pickup -> destination + ambulance ID

#### Bookings (AdminBookingsScreen)

Full booking list with search, status filter tabs, and booking cards. Taps open AdminBookingDetailScreen for 360-degree view.

#### Fleet (AdminFleetScreen)

Fleet registry with ambulance cards: availability status, type, registration, assigned driver. Register new fleet via AdminFleetRegisterScreen.

#### Staff (AdminStaffScreen)

Staff roster with role tabs (Doctors / EMTs / Drivers). Availability status pills, contact info, assignment summary.

#### Finance (AdminQuotationsScreen)

Quotation pipeline list with financial breakdown: quoted -> accepted -> paid -> outstanding.

#### Reports (AdminReportsScreen)

Analytics report view with category filters for drill-down to the Bookings tab.

#### Audit (AdminAuditScreen)

Full audit log trail. Severity-coded entries: CRITICAL (error red), WARNING (secondary), INFO (tertiary/emerald).

#### Pricing (AdminPricingScreen)

Pricing configuration settings management screen.

### 3.4 Component Patterns

#### StitchMetricCard

Structure: Title + icon row | Value (Inter display style) | Trend/badge or subtitle row when provided
- Zero elevation card, surfaceContainerLowest bg, hairline border
- Tappable to navigate to relevant tab

#### StitchStatusBadge

Pill-shaped status label derived from BookingStatus enum:
- In Transit -> Amber (warning)
- Pickup Started -> Primary blue
- Patient Picked Up -> Emerald (tertiary)
- Completed -> Secondary green
- Cancelled -> Error red

#### Finance Box (_FinanceBox)

Label (labelSm, outline color) | Value (labelLg, semantic color) | Subtitle (bodySm, muted)
Background: surfaceContainerLow, radiusSm

#### Staff Roster Row (_StaffRosterRow)

Role icon + title + subtitle on left. Available/total count on right with emerald accent for available.

---

## 4. Customer Portal Design

### 4.1 Identity & Theme

| Property | Value |
|---|---|
| Shell | `CustomerShell` |
| Role theme | `AmbulanceFirstTheme.lightTheme()` is applied inside the shell |
| Brand | Clinical cobalt (#00507D) with emerald readiness accents |
| Surface | Role theme uses #F8F9FF; many shared widgets still use green `AppColors` (#F6F8F7 / #3FAF6A) |
| Type | Role theme uses Inter + JetBrains Mono; shared `AppTextStyles` uses Plus Jakarta Sans + Space Grotesk |
| Platform | Responsive mobile/tablet and desktop |

The active Customer experience is visually mixed: `CustomerShell` applies the cobalt `AmbulanceFirstTheme`, while multiple screens and AeroMed widgets read `AppColors`/`AppTextStyles`, whose current values are green and Plus Jakarta Sans/Space Grotesk. A future visual-system cleanup should choose one source and migrate consumers deliberately.

### 4.2 Navigation Shell

At widths below 1024px the shell uses a compact top app bar and a six-item bottom navigation bar. At 1024px and wider it uses a 240px persistent left rail with a primary booking action and profile/sign-out footer.

| Index | Destination | Screen |
|---|---|---|
| 0 | Dashboard | `CustomerDashboardScreen` |
| 1 | Bookings | `CustomerBookingsScreen` |
| 2 | Active Trips | `CustomerActiveTripScreen` |
| 3 | Quotations | `CustomerQuotationsScreen` |
| 4 | History | `CustomerHistoryScreen` |
| 5 | Home Services | `HomeServicesScreen` |

The booking wizard replaces the tab content and hides mobile navigation while open. Header actions provide Emergency SOS, notifications, and profile access. The rail also exposes Book Ambulance as its primary CTA.

### 4.3 Screen & Component Patterns

- **Dashboard:** Booking overview, active-trip status, quick booking entry, and route/location information. Uses shared booking/workflow state.
- **Bookings / History / Quotations:** Customer-owned booking list, active trip detail, historical trips, and quotation/invoice views.
- **Home Services:** Separate service request flow from transport booking.
- **Booking Wizard:** Multi-step patient, service, route, and schedule form; scrollable on narrow screens.
- **Active Trip:** Route/map, trip status, driver telemetry, hospital alert, and SOS actions.
- **Booking details and quotation sheets:** Modal/sheet surfaces with route, patient, fare, and lifecycle information.
- **Status and telemetry:** Green readiness, amber pending, and crimson emergency states; route and trip metrics use monospaced styles in AeroMed widgets.

The Customer family uses more tactile/rounded surfaces than Admin: `AppRadius` ranges from 8px controls to 32px sheets, cards commonly use 12–16px radii, and selected AeroMed cards use low-opacity layered shadows.

## 5. Driver Console Design

### 5.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | DriverTheme |
| Colors class | DriverColors |
| Text styles class | DriverTextStyles |
| Design system name | Emergency Response Console |
| Scaffold background | #F8F9FF |
| Card border radius | 16px |
| Button border radius | 14px |
| Input border radius | 12px |
| Font | Public Sans (UI) + JetBrains Mono (telemetry) |
| Primary color | #0369A1 (Clinical Cobalt) |
| Secondary | #006C4A (Operational Emerald) |
| Tertiary / Error | #DC2626 (Code Red) |
| Target platform | Mobile and tablet; adaptive web/desktop shell |

Authentication is handled by the shared application entry flow; the Driver role shell begins after authentication and does not define a separate Driver login screen.

### 5.2 Navigation Shell

Shell class: DriverShell (lib/features/driver/presentation/shell/driver_shell.dart)

Layout:
- Fixed top: `DriverTopBar` with active-trip/SOS and profile actions; a GPS state banner appears when needed.
- At widths below 768px: scrollable content and a five-destination Material `NavigationBar`.
- At 768px and wider: persistent `NavigationRail` and content workspace; bottom navigation is removed.

Navigation Tabs (4 items):

| Tab | Icon | Screen |
|---|---|---|
| Dashboard | home_rounded | DriverDashboardScreen |
| Assignments | assignment_rounded | DriverAssignmentsScreen |
| Active Trip | navigation_rounded | DriverActiveTripScreen |
| History | history_rounded | DriverTripHistoryScreen |
| Profile | person_rounded | DriverProfileScreen |

The shell retains all five pages in its page list. Active-trip state is surfaced in navigation with a badge; mission actions and GPS lifecycle state affect the dashboard and trip console.

### 5.3 Screen Inventory

#### Dashboard (DriverDashboardScreen)

Mobile-first scrollable screen with 4 sections:

**1. Pilot Identity Card**
- CircleAvatar (radius 26, primaryContainer bg, white initial letter)
- Name (headlineSmall) + PILOT ID & ambulance number (telemetryMicro, primaryContainer)
- License number + expiry (bodySmall)
- DriverDutySwitcher below divider

**2. Active Mission Card** (when active trip exists)
- primaryContainer border and header bar strip
- Header: "ACTIVE MISSION IN PROGRESS" + Booking ID (white, JetBrains Mono)
- Body: Patient name/age/gender, medical condition, route (pickup -> destination)
- Full-width CTA: "OPEN ACTIVE TRIP CONSOLE" (primaryContainer button, speed icon)

**2b. Standby Readiness Card** (no active trip)
- Emerald check icon + "Ready on Standby Depot" + unit number text

**3. Assigned Bookings Queue**
- Up to 2 previewed, View All link to AssignmentsScreen
- Each row: hospital icon box + booking ID + time chip + patient + route + START button

**4. Pilot Performance Stats**
- 3x _StatCard horizontal: Total Transports, Response Accuracy, Pilot Rating
- Each: icon (semantic color) + telemetryMedium value + telemetryMicro label

#### Active Trip (DriverActiveTripScreen)

Full-mission management screen:
- LiveMapViewport — GPS map with route overlay and recenter FAB
- TripStageStepper — stage progression with completed/active/upcoming node states
- HUDTelemetryBar — dark chrome bar with speed, GPS status, ETA, booking ID
- EmergencySOSModal — accessible at all times via persistent button

#### Assignments (DriverAssignmentsScreen)

Full list of assigned bookings. AssignmentCard widget per booking:
- Booking ID + time badges
- Patient details + pickup/drop route
- Status label + advance action button

#### Profile (DriverProfileScreen)

Driver profile: name, photo, license, ambulance assignment, rating. Links to trip history.

#### Trip History (DriverTripHistoryScreen)

Chronological list of past completed/cancelled trips with dates and patient summaries.

### 5.4 Component Patterns

#### DriverDutySwitcher

Segmented control: ON DUTY (emerald) | OFF DUTY (surface). Disabled when active trip exists.

#### AssignmentCard

[Hospital Icon Box] + BOOKING-ID (bookingId) + [TIME CHIP] (telemetryMicro) + Patient/route (bodySmall) + [ADVANCE] button (primary)

#### HUDTelemetryBar

Dark-chrome bar (inverseSurfaceDark #131D2A):
- Speed (telemetryLarge, white)
- GPS dot (live #10B981 / stale #F59E0B / unavailable #EF4444)
- ETA (telemetryMedium, inversePrimary)
- Booking ID (bookingId, muted)

#### LiveMapViewport

Full-width map with driver pin, destination marker, route polyline (primaryContainer), recenter FAB.

#### TripStageStepper

Vertical stepper: completed (emerald filled circle) / active (primary outlined, pulse) / upcoming (outline, muted).

#### EmergencySOSModal

Red-themed full-screen modal: large SOS button (#DC2626), contact dispatch/hospital quick-dial, incident report form.

#### QuickContactModal

Bottom sheet for quick-calling patient, caller, or hospital contacts during a trip.

---

## 6. Customer Care Portal Design

### 6.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | CustomerCareTheme |
| Colors class | CustomerCareColors |
| Text styles class | CustomerCareTextStyles |
| Design system name | Clinical High-Density Operations |
| Scaffold background | #F8F9FF |
| Card border radius | 12px (standard), 16px (panels) |
| Font | Inter (UI) + JetBrains Mono (telemetry) |
| Primary | #0369A1 (Clinical Cobalt) |
| Secondary | #006C4A (Operational Emerald) |
| Tertiary | #392CD1 (Specialist Lavender) — PICU/Pediatric |
| Tactical Nav bg | #0B132B, border #1E293B |
| Target platform | Web, tablet, and mobile |

Authentication is handled by the shared application entry flow; Customer Care does not provide a separate sign-in screen in this shell.

### 6.2 Navigation Shell

Shell class: CustomerCareShell (lib/features/customer_care/presentation/shell/customer_care_shell.dart)

Layout:
- Below 840px: Customer Care top bar, drawer, content, and five-item bottom bar.
- At 840px and wider: persistent left navigation rail and content; top bar and bottom bar are removed.
- A floating toast overlays the content for transient feedback.

Navigation Tabs (5 items):

| Tab | Icon | Screen |
|---|---|---|
| Dashboard | grid_view_rounded | `CustomerCareDashboardScreen` |
| New | move_to_inbox_rounded | `NewBookingsIntakeScreen` |
| Pending | phone_in_talk_rounded | `CallVerificationConsoleScreen` for the first pending case |
| Handoff | assignment_ind_rounded | `TeamLeadHandoverScreen` |
| Active | flight_takeoff_rounded | `ActiveTripsScreen` |

The desktop rail has six destinations: Dashboard, New Requests, Pending Calls, Handoff Monitor, Active Trips, and All Bookings Archive. Verified queue and archive are secondary states opened from dashboard/drawer actions; neither is a mobile bottom-bar destination. Booking details and call verification replace the shell content while active.

### 6.3 Screen Inventory

#### Dashboard (CustomerCareDashboardScreen)

High-density triage operations hub with 6 sections:

**1. Agent Shift Banner (AgentShiftBanner)**
- Left green accent border, surfaceContainerLow bg
- Agent name, CC ID, shift time, shift status label

**2. KPI Queue Cards Grid** — `LayoutBuilder` uses 2 columns at widths up to 580px and 4 columns above 580px.

| Card | Accent Color | Badge | Interaction |
|---|---|---|---|
| New Inbound | error (#DC2626) | "2 Code Red" | Pulse animation; tap to filter |
| Pending Calls | warning (#D97706) | "1 Follow-up" | Tap to filter to pending |
| Verified | secondary (#006C4A) | "Ready" | Tap to filter to verified |
| Sent to Lead | primaryContainer (#0369A1) | "In Dispatch" | Tap to filter to handed-over |

Selected state: primaryContainer bg fill, white text.

**3. Search & Filter Ribbon**
- Full-width search input (12px radius, surfaceContainerLowest, no border ring)
- Placeholder: "Search Booking ID, patient, caller phone..."
- Filter chips: All . Code Red (red dot) . High Urgency (amber dot) . Pediatric (child icon) . ICU Required

**4. Triage Incident Queue Header**
- Emergency icon + "Triage Incident Queue" (headlineSm, w700)
- "Real-time sync: Active" (labelSm, muted, right-aligned)

**5. Incident Cards (TriageIncidentCard)** — Scrollable list, separated by 10px gaps

**6. Telemetry Radar Card (TelemetryRadarCard)** — Air corridor airspace animated widget at bottom of scroll

#### New Intake (NewBookingsIntakeScreen)

Structured form for logging a new emergency booking: caller info, patient profile, medical condition, pickup/destination address, priority selection, pediatric/ICU flags, submit action.

#### Active Trips (ActiveTripsScreen)

Real-time list of in-transit bookings with: live GPS telemetry access (LiveGPSTelemetryDialog), driver/ambulance assignment status, ETAs, BookingLifecycleTimeline.

#### Verified Bookings (VerifiedBookingsScreen)

Queue of CC-verified cases: verified timestamp, verifying agent name, priority badge, case notes preview, Send to Team Lead button.

#### Archive (AllBookingsArchiveScreen)

Complete historical booking archive with date filtering and status search.

#### Booking 360 Degree Details (Booking360DetailsScreen)

AppBar: Back arrow + "Dossier 360°: #ID" title + status badge chip (surfaceContainerHigh bg)

| Section | Icon | Content |
|---|---|---|
| Patient & Clinical Profile | person_rounded | Name, age/gender, acuity, condition, MRN, pediatric flag |
| Caller & Contact | phone_rounded | Caller name, phone, relationship |
| Route & Logistics | navigation_rounded | Pickup address, destination, region |
| Booking Timeline | timeline_rounded | BookingLifecycleTimeline widget |
| Verification Notes | verified_rounded | Checklist items + agent notes |

#### Call Verification Console (CallVerificationConsoleScreen)

- Caller info header + call-back button
- VerificationChecklistView — protocol checklist (ICU bed confirmed, route clear, etc.)
- CallOutcomeSelector — radio: Verified / Unable to Contact / Requires Escalation
- Submit verification action

#### Team Lead Handover (TeamLeadHandoverScreen)

- Case summary review panel
- Priority confirmation
- Handover notes text field
- "SEND TO TEAM LEAD" CTA (full-width primaryContainer button)

### 6.4 Component Patterns

#### KpiQueueCard

[Icon] Count (JetBrains Mono telemetryDisplay) | [Badge pill] | Title (headlineSm) | Subtitle (bodySm, muted)
Selected: primaryContainer bg fill, white text. hasPulse=true adds pulse animation to New Inbound card.

#### TriageIncidentCard

Left urgency pip (error=Code Red, warning=High, secondary=Normal, 4px wide) + card body:
- Row 1: #ID (JetBrains Mono) + Priority Badge + Time ago
- Row 2: Patient Name (age/gender) + Caller phone
- Row 3: Pickup -> Destination route
- Tags row: Condition chip + ICU chip + Pediatric chip
- Action row: [CALL VERIFY] [VIEW DETAILS] [SEND TO TEAM LEAD]

#### AgentShiftBanner

Left emerald accent border, surfaceContainerLow bg, Inter bodyMd for agent name/ID, labelSm for shift time/status.

#### BookingLifecycleTimeline

Vertical timeline nodes:
- Completed: emerald filled circle + label
- Active: primary outlined circle + animated pulse ring
- Upcoming: outline circle, muted text

#### VerificationChecklistView

Protocol checkboxes with secondary check icons for verified items, outlineVariant ring for unchecked. Progress summary: X/Y complete, secondary progress bar.

#### CallOutcomeSelector

Full-width radio group:
- Verified (secondary/emerald accent)
- Unable to Contact (warning/amber accent)
- Requires Escalation (error/red accent)
Each option has a title + descriptive sub-label.

#### TelemetryRadarCard

Air corridor radar-style animated widget. Tappable to navigate to 360 degree case details.

#### LiveGPSTelemetryDialog

Modal: last known GPS coordinates (JetBrains Mono), last ping timestamp, telemetry freshness dot (live/stale/unavailable), ambulance unit + driver name.

---

## 7. Team Lead Portal Design

### 7.1 Identity & Theme

| Property | Value |
|---|---|
| Shell | `TeamLeadLayoutShell` |
| Token source | `TeamLeadTheme` plus screen-local colors/styles |
| Canvas | Theme #F8F9FF; command-center and queue screens also use #F6F8FB |
| Brand | Deep cobalt #00507D, vibrant cobalt #0369A1, pale blue primary container #CDE5FF |
| Status accents | Emerald #006C4A, crimson #DC2626, amber #D97706 |
| Typography | Inter UI and JetBrains Mono telemetry tokens; some screens use direct `TextStyle` values |

The shell and theme are more consistent than the individual screen layer. Command Center and Allocation Queue currently include literal color/style values, so visual parity with `TeamLeadTheme` is partial.

### 7.2 Adaptive Navigation Shell

`TeamLeadLayoutShell` uses three layouts: below 768px it shows an app bar, drawer, and five-item bottom bar; from 768px through 1023px it uses a `NavigationRail`; at 1024px and wider it uses a 250px sidebar and a top bar with shared search, operational status, and notifications.

| Index | Destination | Screen |
|---|---|---|
| 0 | Command Center | `TeamLeadCommandCenter` |
| 1 | Allocation Queue | `AllocationQueueScreen` |
| 2 | Budget & Quotations | `BudgetQuotationsScreen` |
| 3 | Active Trips | `ActiveTripsScreen` |
| 4 | Fleet | `FleetScreen` |
| 5 | Drivers | `DriverRosterScreen` |
| 6 | EMTs | `EmtRosterScreen` |
| 7 | Doctors | `DoctorRosterScreen` |
| 8 | Operations Reports | `ReportsScreen` |

The mobile bottom bar exposes Command Center, Allocation Queue, Budget & Quotations, Active Trips, and Fleet. The drawer exposes all nine modules.

### 7.3 Screen & Component Patterns

- **Command Center:** Refreshable live operations overview with allocation/quotation/trip metrics, fleet and staff availability, live data status, and links into operational queues.
- **Allocation Queue:** Search, status chips, critical-only filtering, booking cards, and allocation modal/actions.
- **Budget & Quotations:** Quote review and budget controls.
- **Active Trips:** Live mission roster and trip-state monitoring.
- **Fleet / Drivers / EMTs / Doctors:** Resource rosters for readiness and assignment decisions.
- **Operations Reports:** Team-level operational metrics.
- **Shell status:** Notifications show unread counts; desktop search state is shared with screens that accept the query.

## 8. Doctor Workspace Design

### 8.1 Identity & Theme

Doctor has no role-specific theme. `DoctorShell` composes `AeroMedRoleShell`, uses the shared Material theme, and consumes the shared `AppColors`/`AppTextStyles` green visual system. Typography is Plus Jakarta Sans for general UI and Space Grotesk for route/data labels where shared styles are used.

### 8.2 Navigation & Screens

`AeroMedRoleShell` switches at 760px: below that it uses a mobile role bar, drawer, and bottom navigation; at 760px and wider it uses a 248px sidebar and desktop app bar.

| Index | Destination | Screen |
|---|---|---|
| 0 | Overview | `DoctorDashboardScreen` |
| 1 | Patients | `DoctorBookingScreen` |

The Overview screen has loading, resource-link error, refresh, assigned/critical metrics, and an assigned-bookings list. Patients lists assigned bookings and opens a patient/booking dossier containing route and clinical summary, latest vitals, and assessment history. Empty states explain when a doctor resource, booking, vitals, or assessment is unavailable.

### 8.3 Clinical Read-Only Pattern

The current Doctor UI is review-only. A visible notice explains that assessment, medication, intervention, and vitals writes remain locked pending verification of the Doctor RLS/write contract. Do not describe write workflows as available until that contract is implemented.

## 9. Cross-Portal Design Patterns

These are consistency goals, not claims that every current screen already implements each pattern. Apply them with the role-specific token system and workflow in mind.

| Rule | Detail |
|---|---|
| Booking identifiers | Use the owning role's data/monospaced style when available; retain full IDs in details and avoid letting long IDs break compact layouts. |
| Urgency | Pair urgency color with explicit status text/icon; left-edge urgency markers appear on selected booking cards. |
| Status | Prefer concise semantic badges or labels rather than color-only state. Badge shape and palette are role-specific. |
| Empty and loading states | Explain whether data is empty, loading, or unavailable. Use a progress indicator for asynchronous work and a useful recovery action when one exists. |
| Errors | Keep errors close to the affected workflow; use a retry action only when the operation is safely retryable. |
| Patient identity | Initial avatars are used in several queue/card surfaces; do not expose unnecessary patient details in overview lists. |
| Timestamps | Relative time suits live queues; absolute date/time suits history and audit records. |
| High-risk actions | Use clear action labels and confirmation/feedback for dispatch, handoff, sign-off, and emergency actions. |
| Material | Use Material 3 controls and semantics consistently; role-specific surfaces may override default shape and color. |

---

## 10. Semantic Color Usage

| Situation | Color Token | Example |
|---|---|---|
| Available / verified | Role-specific emerald token | Admin #00573B; Driver/Customer Care/Team Lead #006C4A; Customer values vary between green and cobalt systems |
| Pending / attention | Role-specific amber token | Usually #D97706 in operations portals; shared Customer palette uses #D99A32 |
| Critical / emergency | Role-specific crimson token | Usually #DC2626; shared Customer palette uses #D95353 |
| Primary action | Owning role's primary token | Cobalt in Admin, Driver, Customer Care, and Team Lead; mixed green/cobalt in Customer/Doctor |
| Specialist / pediatric | Customer Care tertiary violet | #392CD1 / #534BE9; do not reuse the same tertiary token in other roles |
| Live / stale / unavailable GPS | Driver telemetry tokens | #10B981 / #F59E0B / #EF4444 |
| Muted metadata | Owning role's outline/text token | Timestamps, secondary descriptions, and capacity labels |

## 11. Accessibility, Responsiveness & Gaps

### Responsive Breakpoints (Observed)

| Role | Narrow layout | Intermediate layout | Wide layout |
|---|---|---|---|
| Admin | Scrollable content; fixed compact header and five destinations plus More in bottom bar | Same shell | Same shell; page contents adapt independently |
| Customer | App bar + six-item bottom navigation | Same until 1024px | At 1024px: app bar plus 240px persistent rail |
| Customer Care | At <840px: top bar, drawer, five-item bottom bar | Same until 840px | At >=840px: persistent rail |
| Driver | At <768px: top bar and five-item bottom navigation | Same below 768px | At >=768px: NavigationRail |
| Team Lead | At <768px: app bar, drawer, five-item bottom bar | 768–1023px: NavigationRail | At >=1024px: 250px sidebar and top bar |
| Doctor | At <760px: mobile role bar, drawer, bottom navigation | Same below 760px | At >=760px: shared 248px sidebar and desktop app bar |

### Cross-Role Interaction Patterns

- Use visible labels/tooltips for icon-only actions, and provide keyboard-accessible controls on web.
- Keep booking IDs and telemetry visually distinct from narrative text; use the role's data typeface where available.
- Pair semantic colors with text or icons; color alone must not carry operational meaning.
- Provide explicit loading, empty, and error states. Existing implementations vary by screen; do not assume every empty state currently has an icon or every error has a retry action.
- Preserve safe-area insets and allow long content to scroll. Use available constraints rather than device-wide width assumptions inside nested layouts.
- Keep high-risk actions explicit and separated from routine navigation; Driver SOS and Customer SOS use emergency styling.

### Validation Status and Known Gaps

- Color token contrast ratios have not been audited across all role/background combinations. Do not claim blanket WCAG AA compliance without measuring rendered foreground/background pairs.
- Minimum touch-target dimensions are not enforced uniformly in code; verify compact icon buttons, custom bottom bars, and dense data rows.
- Customer currently mixes its cobalt `AmbulanceFirstTheme` with green shared `AppColors`/`AppTextStyles` consumers.
- Team Lead screens partially bypass `TeamLeadTheme` with literal colors and text styles.
- Doctor intentionally exposes review/read-only UI; clinical write actions must remain described as locked until backend authorization and workflows are verified.
- Reduced-motion behavior and system text-scaling behavior have not been verified consistently across roles.

### Source of Truth

- Theme files and shell implementations are authoritative for current values; this document is a cross-role implementation map, not a guarantee that every screen follows every pattern.
- Shared foundation: `lib/shared/theme/` and `lib/shared/widgets/`.
- Role systems: `lib/roles/admin/theme/`, `lib/roles/customer/theme/`, `lib/features/driver/theme/`, `lib/features/customer_care/theme/`, `lib/roles/team_lead/theme/`, and shared theme usage in `lib/roles/doctor/`.

---

*This document reflects the design system as implemented in the codebase.*
*Key source files: `lib/roles/admin/theme/admin_theme.dart`, `lib/roles/customer/theme/ambulance_first_theme.dart`, `lib/features/driver/theme/`, `lib/features/customer_care/theme/`, `lib/roles/team_lead/theme/team_lead_theme.dart`, and `lib/shared/widgets/aeromed_role_shell.dart`.*
*Stitch MCP Project references: DriverColors (Project 15205856723727982878), CustomerCareColors (Project 1449624092268908152)*
