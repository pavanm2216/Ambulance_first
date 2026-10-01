# MASTER COPILOT PROMPT — AMBULANCE FIRST FLUTTER PROJECT

## Full-project error recovery, architecture repair, website parity, Supabase integration, and workflow preservation

You are working on an existing Flutter/Dart application called:

**Ambulance First**

This Flutter project is being developed against an existing Ambulance First website and its existing Supabase backend.

The project is already partially implemented and currently reports approximately **7,000+ analyzer/compiler errors**.

Your job is NOT to make the error counter smaller at any cost.

Your job is to:

1. Understand the entire existing project before making large changes.
2. Identify root causes rather than fixing cascading errors individually.
3. Repair the existing Flutter implementation instead of rebuilding it.
4. Preserve existing UI, workflows, models, services, and business logic wherever they are valid.
5. Bring the Flutter implementation into functional parity with the existing website where applicable.
6. Integrate with the EXISTING Supabase schema instead of inventing a second backend architecture.
7. Handle empty Supabase tables correctly.
8. Respect the ACTUAL role values confirmed in Supabase.
9. Keep Admin OUT of the Flutter application UI.
10. Do not invent an EMT role or database table without evidence.
11. Verify every major repair with `flutter analyze`, tests, and runtime checks.
12. Clearly distinguish code problems, database/schema problems, missing operational data, and unsupported backend functionality.

---

# 1. NON-NEGOTIABLE RULES

## DO NOT

- Rewrite the entire application from scratch.
- Replace the existing application with a simplified demo.
- Delete screens just because they contain errors.
- Delete features merely to make compilation succeed.
- Remove model fields merely to silence errors.
- Replace business logic with dummy implementations.
- Invent database tables.
- Invent database columns.
- Invent foreign keys.
- Invent enum/check-constraint values.
- Invent Supabase roles.
- Invent operational database records.
- Automatically seed production data.
- Add an EMT role to `profiles.role` without evidence.
- Create an `emts` table automatically.
- Create an Admin Flutter portal.
- Hardcode Supabase service-role credentials.
- Disable RLS to make queries work.
- Hide errors with broad `dynamic`, `!`, `late`, `ignore`, or analyzer suppression.
- Silently fall back from Supabase to fake data.
- Claim a workflow works without actually verifying it.
- Change business logic simply because the current code is broken.
- Perform a mass rewrite before completing the repository audit.

## DO

- Inspect first.
- Establish the real architecture.
- Establish the real Supabase contract.
- Fix root causes.
- Propagate correct model changes through callers.
- Preserve valid existing behavior.
- Use strongly typed Dart.
- Handle loading, success, empty, and error states.
- Keep database access out of UI where practical.
- Verify changes incrementally.
- Report uncertainty instead of guessing.

---

# 2. IMPORTANT USER PREFERENCES

Follow these preferences throughout the repair:

- Be pragmatic and implementation-focused.
- Prefer repairing the existing code over replacing it.
- Do not make assumptions about the backend when the actual schema/code can be inspected.
- Do not create duplicate architecture simply because a feature is missing.
- Preserve the existing visual design unless a change is necessary for correctness.
- Keep the project clean and organized by role/domain.
- Do not introduce unnecessary abstractions.
- Do not hide errors merely to reduce analyzer output.
- Explain blockers honestly.
- When something cannot be implemented because the backend does not currently support it, identify the backend gap rather than inventing a solution.
- Treat the website as the functional reference, but do not blindly copy website bugs or local/mock implementation details.
- Keep Admin out of the Flutter application.
- Do not assume EMT is a Supabase profile role.

---

# 3. CURRENT BACKEND FACTS — THESE ARE CONFIRMED

The existing Supabase `public` schema currently contains these tables:

```text
ambulances
audit_logs
booking_doctor_assessments
booking_status_history
booking_vitals
bookings
customer_care
doctors
drivers
notifications
profiles
```

The current database state observed by the user is:

```text
profiles                    → contains data
ambulances                  → currently empty
drivers                     → currently empty
doctors                     → currently empty
customer_care               → currently empty
bookings                    → currently empty
booking_status_history     → currently empty
booking_vitals             → currently empty
booking_doctor_assessments → currently empty
notifications               → currently empty
audit_logs                  → currently empty
```

IMPORTANT:

The tables already EXIST.

Do NOT interpret an empty table as a missing table.

Do NOT create duplicate tables because these tables currently contain zero rows.

---

# 4. EMPTY DATABASE DATA IS NOT AUTOMATICALLY A BUG

Treat these as separate situations:

### A. Code error

Example:

```text
Undefined getter
Undefined method
Type mismatch
Missing constructor
Invalid import
```

Fix the Dart code.

### B. Database/schema error

Example:

```text
relation does not exist
column does not exist
invalid enum value
foreign-key violation
RLS policy rejection
```

Inspect the real schema/policies and fix the integration.

### C. Empty data

Example:

```text
Supabase query succeeds
result = []
```

This is a legitimate application state.

Do NOT "fix" it by inventing records.

Example:

```text
ambulances = []
```

must produce an appropriate empty state such as:

> No compatible ambulances are currently available.

It must NOT:

- crash,
- access `[0]`,
- invent an ambulance,
- silently use fake ambulance data,
- display "Ambulance assigned" when none exists.

---

# 5. CONFIRMED SUPABASE PROFILE ROLES

The actual `profiles.role` values confirmed by the user are:

```text
CUSTOMER
ADMIN
DOCTOR
DRIVER
TEAM_LEAD
CUSTOMER_CARE
```

These are the currently confirmed profile roles.

## CRITICAL EMT RULE

`EMT` is NOT currently a confirmed `profiles.role`.

Therefore:

- Do NOT add `EMT` to the profile-role enum automatically.
- Do NOT assume `profiles.role = 'EMT'`.
- Do NOT create an EMT profile row.
- Do NOT create an `emts` table automatically.
- Do NOT build EMT authentication based on an invented role.

The existing website/project may still contain EMT functionality. Investigate how that functionality is represented.

Possible implementations include:

- EMT represented by another existing profile/resource structure.
- EMT represented by a separate existing backend resource.
- EMT represented only by local/mock data.
- EMT partially implemented but not backend-connected.
- EMT not yet supported by the current backend.

Determine the truth from the actual code and schema.

---

# 6. FLUTTER ROLE SCOPE

The Flutter application should support the currently relevant non-admin operational roles:

```text
CUSTOMER
CUSTOMER_CARE
TEAM_LEAD
DRIVER
DOCTOR
```

The backend also has:

```text
ADMIN
```

but Admin is explicitly OUT OF SCOPE for this Flutter application.

Do not build:

- Admin dashboard
- Admin management screens
- Admin CRUD
- Admin analytics
- Admin resource-management UI
- Admin navigation shell

However, authentication must handle an Admin profile safely.

If an Admin logs into the Flutter application, do NOT silently convert the account to CUSTOMER.

Handle it explicitly as an unsupported/out-of-scope role.

Unknown roles must also be handled explicitly.

---

# 7. EMT FUNCTIONALITY — INVESTIGATE, DO NOT INVENT

The website workflow may include EMT/medical-attendant functionality.

Before modifying EMT-related code:

1. Search the website implementation.
2. Search the Flutter implementation.
3. Inspect `profiles`.
4. Inspect all relevant Supabase tables.
5. Inspect booking fields.
6. Inspect allocation logic.
7. Inspect any existing EMT model/service/store.
8. Determine whether EMT is an operational resource, profile role, or another concept.

Preserve existing EMT functionality if it is valid.

But do not turn EMT into a Supabase profile role without evidence.

If the backend currently lacks a supported EMT representation, report:

```text
EMT backend representation is not currently confirmed/supported.
```

Do not fabricate schema to make the workflow appear complete.

---

# 8. WEBSITE WORKFLOW TO PRESERVE

The existing Ambulance First workflow is approximately:

```text
CUSTOMER
   ↓
Create booking
   ↓
CUSTOMER CARE
   ↓
Contact / verify / triage
   ↓
VERIFICATION
   ↓
TEAM LEAD
   ↓
Check resource compatibility
   ↓
Resource allocation
   ↓
Quotation
   ↓
CUSTOMER
   ↓
Accept / reject quotation
   ↓
DRIVER / OPERATIONS
   ↓
Pickup started
   ↓
Patient picked up
   ↓
In transit
   ↓
Arrived
   ↓
Service completed
```

Where supported by the existing implementation:

- Driver provides trip/location information.
- Clinical personnel record vitals.
- Doctor records assessment.
- Customer tracks active trip.
- Notifications are generated by meaningful events.
- Audit records are generated by auditable events.

Do not collapse this workflow merely to eliminate errors.

---

# 9. BOOKING STATUS

The intended website lifecycle includes concepts such as:

```text
NEW
CUSTOMER_CARE_CONTACTED
VERIFICATION_PENDING
VERIFIED
SENT_TO_TEAM_LEAD
ALLOCATION_PENDING
BUDGET_PENDING
QUOTATION_SENT
CUSTOMER_ACCEPTED
CUSTOMER_REJECTED
ASSIGNED
PICKUP_STARTED
PATIENT_PICKED_UP
IN_TRANSIT
ARRIVED
SERVICE_COMPLETED
CANCELLED
```

IMPORTANT:

These are workflow concepts, not proof that every exact string exists in the Supabase schema.

Before persisting statuses:

1. Inspect the actual database representation.
2. Inspect existing website code.
3. Inspect existing Flutter enums/models.
4. Establish one canonical Flutter representation.
5. Map it correctly to the backend.

Do not invent database enum values.

Do not allow arbitrary invalid transitions.

---

# 10. SERVICE CATEGORIES

The website supports these service categories:

```text
ROAD
RAILWAY
AIR
DEAD_BODY
```

Subtypes include:

```text
ROAD:
  BASIC_OXYGEN
  ADVANCED_ICU
  PEDIATRIC_ICU

RAILWAY:
  TRAIN_ICU_COACH

AIR:
  AIR_DOMESTIC_JET
  AIR_INTERNATIONAL_HELI_OR_JET

DEAD_BODY:
  DEAD_BODY_FREEZER
```

Preserve this functional parity.

Before mapping these to database enums/columns, verify the actual backend representation.

---

# 11. BOOKING DATA PARITY

The website workflow supports concepts including:

### Customer

```text
full name
mobile
email
```

### Patient

```text
full name
age
gender
```

### Route

```text
pickup
destination
current hospital
destination hospital
preferred date/time
```

### Patient condition

```text
Stable
Needs Medical Assistance
Serious
Emergency
Not Sure
```

### Medical requirements

```text
oxygen
oxygen flow
wheelchair
stretcher
doctor
ICU
ventilator
ventilator mode
cardiac monitor
pediatric
doctor specialization
EMT/medical attendant
additional equipment
special instructions
```

### Transport-specific requirements

Railway:

```text
train number
train name
coach number
pickup station
destination station
```

Air:

```text
flight type
pickup airport
destination airport
air permit number
```

Dead body:

```text
death certificate number
freezer required
hospital/morgue release
family NOC
```

Do not force irrelevant fields onto every booking.

Do not remove valid fields merely because a screen currently does not use them.

---

# 12. MODEL REPAIR STRATEGY

Identify one canonical model for each domain concept.

At minimum investigate:

```text
Booking
Ambulance
DriverProfile
Doctor
Quotation
VitalSign
CustomerCareCase
AuthUser
```

Also inspect any existing EMT/medical-attendant model.

Do not create multiple competing versions such as:

```text
Booking
BookingModel
BookingData
BookingEntity
BookingDTO
```

unless the architecture intentionally requires those layers.

If multiple layers already exist, define explicit conversions rather than mixing them.

---

# 13. MODEL FIRST, CALLERS SECOND

If a model is incorrect:

1. Fix the canonical model.
2. Fix constructors.
3. Fix `fromMap`.
4. Fix `toMap` where applicable.
5. Find every caller.
6. Update callers.
7. Run `flutter analyze`.
8. Continue only after the error cascade has reduced.

Do not fix 100 individual caller errors with unrelated hacks.

---

# 14. SUPABASE SCHEMA IS AUTHORITATIVE

Before changing any repository/query, inspect the actual database schema.

Verify:

- actual table names
- actual column names
- data types
- nullable/non-nullable fields
- primary keys
- foreign keys
- constraints
- enum/check values
- RLS policies
- relationships

Do not infer the database schema from:

- Flutter model names,
- website TypeScript interfaces,
- filenames,
- old documentation,
- assumptions.

If the website has localStorage/mock data for something, do not assume it is a Supabase table.

---

# 15. EXISTING SUPABASE RESOURCES

The existing website has used Supabase resources such as:

```text
profiles
drivers
doctors
customer_care
ambulances
```

and the database currently contains:

```text
bookings
booking_status_history
booking_vitals
booking_doctor_assessments
notifications
audit_logs
```

Use the existing resources.

Do NOT create duplicates such as:

```text
staff
new_drivers
new_doctors
new_ambulances
employee_profiles
emts
```

unless actual inspection proves they are necessary.

---

# 16. IMPORTANT: RESOURCE DATA VS AUTHENTICATION DATA

Do not assume that:

```text
profiles.role = DRIVER
```

automatically means:

```text
drivers table contains a valid operational driver
```

These are separate concepts.

Likewise:

```text
profiles.role = DOCTOR
```

does not automatically mean:

```text
doctors table contains an available doctor
```

The application must use the actual resource tables and relationships for operational allocation.

If there are zero resource rows, handle the empty state.

---

# 17. REPOSITORY ARCHITECTURE

Keep UI, business logic, and persistence reasonably separated.

Preferred direction:

```text
Screen / Widget
      ↓
State / Controller
      ↓
Service
      ↓
Repository
      ↓
Supabase
```

Do not scatter raw queries throughout widgets.

However, do not blindly add a huge new architecture if the existing project already has a valid repository/service structure.

Reuse existing classes when they already perform the required responsibility.

---

# 18. EXISTING LOCAL SERVICES/STORES

The project contains or may contain concepts such as:

```text
SharedBookingStore
CustomerBookingWorkflowService
TeamLeadOperationsService
DriverLocationStore
DriverLocationService
```

Do NOT delete them automatically.

First determine:

- what business rules they contain,
- whether they are mock persistence,
- whether they are state-management stores,
- whether they are intended adapters,
- whether they are production-ready.

Separate business rules from persistence where necessary.

For example:

```text
TeamLeadOperationsService
        ↓
compatibility/business rules
        ↓
AmbulanceRepository
DriverRepository
DoctorRepository
```

Do not duplicate compatibility logic across multiple services.

---

# 19. SUPABASE INITIALIZATION

Initialize Supabase once in the application startup path.

Preferred structure:

```text
main.dart
   ↓
Supabase.initialize(...)
   ↓
runApp(...)
```

Use:

```dart
Supabase.instance.client
```

through controlled data-access layers.

Do not initialize Supabase independently in each screen.

---

# 20. SUPABASE SECURITY

Never put a service-role key in Flutter.

Never bypass RLS just to make the app work.

Never trust a client-provided role for authorization.

Never expose private backend credentials.

Use the existing safe client configuration.

If the project uses environment configuration or `--dart-define`, preserve that mechanism.

---

# 21. AUTHENTICATION FLOW

The intended production flow should be based on the actual backend:

```text
Supabase Auth
    ↓
authenticated user
    ↓
profiles lookup
    ↓
role
    ↓
role validation
    ↓
correct Flutter experience
```

Handle:

- authenticated user with missing profile,
- unsupported ADMIN role,
- unknown role,
- expired session,
- signed-out state,
- RLS failures.

Do not silently fall back to CUSTOMER.

Do not use fake production authentication such as:

```dart
_signedIn = true;
_role = 'CUSTOMER';
```

unless it is explicitly isolated as development/demo code.

---

# 22. CUSTOMER WORKFLOW

Preserve the existing Customer workflow.

Customer should be able to use the supported application flow for:

```text
authentication
↓
booking creation
↓
service selection
↓
patient information
↓
route/location
↓
medical requirements
↓
transport-specific requirements
↓
booking submission
↓
booking status
↓
quotation
↓
accept/reject
↓
active trip tracking
↓
booking history
```

Only mark a feature complete when the relevant backend/state transition actually works.

---

# 23. CUSTOMER CARE WORKFLOW

Preserve:

```text
view booking
contact customer
record call information
record notes
confirm patient condition
confirm medical requirements
confirm location
confirm date/time
set priority
complete verification
```

Do not automatically mark verification complete just because the screen opened.

---

# 24. TEAM LEAD WORKFLOW

Preserve:

```text
view verified bookings
inspect patient/medical requirements
find compatible resources
allocate resources
prepare quotation
send quotation
```

Compatibility must consider actual requirements and available resources.

Examples:

```text
pediatric → pediatric-capable resource
ICU → ICU-capable ambulance
ventilator → ventilator-capable ambulance
dead body → freezer-capable ambulance
```

Also check actual availability of required operational personnel.

Do not claim assignment succeeded if the backend update failed.

---

# 25. DRIVER WORKFLOW

Preserve:

```text
view assigned booking
view pickup
start pickup
patient picked up
in transit
arrived
service completed
```

If location is simulated, keep it clearly separate from production GPS.

Do not claim simulated coordinates are live GPS.

---

# 26. DOCTOR WORKFLOW

Preserve doctor functionality for:

```text
assigned booking
patient information
assessment
diagnosis
medications/interventions
clinical notes
submission
```

Use the actual `doctors` resource where applicable.

---

# 27. CLINICAL / EMT FUNCTIONALITY

The existing project may support:

```text
vitals
medical assessment
medical attendant/EMT
```

Preserve these capabilities where supported.

But do not invent backend role/schema support.

For vitals, support the existing concepts where applicable:

```text
heart rate
blood pressure
SpO2
respiratory rate
temperature
glucose
oxygen flow
ventilator pressure
clinical notes
```

Do not turn missing clinical values into fake zeros unless the domain explicitly requires that.

---

# 28. QUOTATION

Preserve the website's quotation concepts, including where supported:

```text
base ambulance
distance
doctor
EMT/medical attendant
oxygen
ICU
ventilator
pediatric ICU
equipment
attendant
railway
air ambulance
airport
additional charges
discount
tax
payment terms
validity
status
rejection reason
notes
```

The website has used a 5% tax default in its quotation logic.

Before hardcoding this into backend persistence, verify the actual current business rule.

Do not silently alter quotation calculations to make tests pass.

---

# 29. EMPTY RESOURCE HANDLING

The current database has empty operational tables.

Therefore these states MUST be supported:

```text
No ambulances available
No drivers available
No doctors available
No customer-care records available
No bookings available
No notifications available
No audit records available
```

Example:

```dart
if (items.isEmpty) {
  return const EmptyState(
    message: 'No compatible ambulances are currently available.',
  );
}
```

Do not treat zero rows as an exception.

Do not fabricate data.

---

# 30. TRANSACTIONAL TABLES

These tables are currently empty:

```text
bookings
booking_status_history
booking_vitals
booking_doctor_assessments
notifications
audit_logs
```

Treat them as transactional data.

Normally they should become populated through actual application actions.

Do not seed fake transactional history simply to make dashboards look populated.

If development seed data is genuinely required for integration testing, use an explicit development-only seed mechanism and the actual schema.

---

# 31. MASTER/RESOURCE DATA

These are operational/master resources:

```text
ambulances
drivers
doctors
customer_care
```

They may require legitimate development records before the complete dispatch workflow can be integration-tested.

If they are empty, report:

```text
Required operational master data is absent.
```

Do not claim that resource allocation is fully integration-tested.

---

# 32. MOCK DATA

If the project has mock/demo data:

- identify it,
- isolate it,
- do not silently use it in production,
- do not silently replace Supabase data with it.

Bad:

```text
Supabase query fails
    ↓
show fake successful booking
```

Do not do this unless explicitly intended as a development mode.

---

# 33. ASYNC / NULL SAFETY

Repair async code correctly.

Use:

```dart
await
Future<T>
Future<List<T>>
Stream<T>
StreamSubscription<T>
```

correctly.

Do not remove `async` merely to silence a type error.

Do not use:

```dart
items[0]
```

without checking.

Do not use:

```dart
value!
```

unless nullability is logically guaranteed.

Do not use `late` to hide lifecycle problems.

---

# 34. WIDGET LIFECYCLE

Audit:

```text
TextEditingController
AnimationController
StreamSubscription
Timer
FocusNode
ScrollController
Realtime subscriptions
Location subscriptions
```

Every disposable resource must be cleaned up.

Prevent:

```text
setState() after dispose
duplicate subscriptions
memory leaks
duplicate listeners
```

Use lifecycle-aware patterns.

---

# 35. REALTIME

Only use realtime where the workflow actually needs live updates.

Potential live areas include:

```text
booking status
notifications
trip/location information
clinical updates where applicable
```

Do not create subscriptions inside `build()`.

Subscribe/unsubscribe deliberately.

---

# 36. DRIVER LOCATION

Inspect the existing:

```text
DriverLocationService
DriverLocationStore
```

before replacing them.

If the existing project supports simulation:

- preserve it for development,
- clearly label it as simulation,
- do not claim it is production GPS.

For real GPS, use the existing architecture and platform capabilities rather than inventing a second location system.

---

# 37. NAVIGATION

Audit:

- routes,
- GoRouter/Navigator if used,
- role-based redirects,
- auth guards,
- dashboards,
- back-stack behavior.

The intended direction is:

```text
Authentication
    ↓
Profile
    ↓
Role
    ↓
Supported role shell
    ↓
Role-specific screens
```

Admin should not receive an Admin portal.

Unknown/unsupported roles must not silently enter Customer.

---

# 38. UI PRESERVATION

Preserve the existing UI unless fixing a functional/rendering problem requires change.

Do not replace substantial screens with:

```dart
Text('Coming soon')
```

to remove errors.

Preserve:

- branding,
- colors,
- typography,
- spacing,
- existing components,
- navigation,
- role-specific design,
- responsive behavior.

Fix actual rendering problems rather than redesigning the project.

---

# 39. JSON / MAP CONVERSION

Backend models should have predictable conversion where appropriate:

```dart
factory Model.fromMap(Map<String, dynamic> map)
```

and:

```dart
Map<String, dynamic> toMap()
```

Handle actual Supabase values safely.

Be careful with:

```text
null
int
double
String
bool
List
Map
DateTime
```

Do not assume PostgreSQL numeric values always arrive in one exact Dart type.

Use explicit parsing helpers where repeated.

---

# 40. DATE/TIME

Use `DateTime` internally.

Only convert to strings at:

- UI formatting,
- serialization,
- API/database boundaries.

Do not compare formatted date strings for business logic.

Handle timezone assumptions deliberately.

---

# 41. ERROR HANDLING

Do not use:

```dart
catch (_) {}
```

as a general strategy.

Handle:

- network errors,
- authentication errors,
- RLS errors,
- missing records,
- invalid input,
- duplicate records,
- timeouts,
- empty results,
- unexpected backend responses.

User-facing messages should be understandable.

Developer logs should retain enough detail to diagnose the actual failure.

---

# 42. DO NOT HIDE ANALYZER ERRORS

Do not use these as mass fixes:

```dart
dynamic
!
late
as dynamic
ignore:
```

Do not add:

```dart
// ignore_for_file:
```

just to make analyzer output smaller.

Do not disable lint/analyzer rules to hide unresolved problems.

The goal is real correctness.

---

# 43. ERROR-REPAIR ORDER

Fix in this order:

## Level 1 — Project foundation

```text
pubspec.yaml
dependencies
imports
syntax
missing files
duplicate declarations
```

## Level 2 — Core types

```text
enums
models
constructors
type definitions
JSON/map conversions
```

## Level 3 — Authentication and roles

```text
AuthUser
profile lookup
role mapping
auth guards
navigation
```

## Level 4 — Data layer

```text
repositories
Supabase queries
mappers
error handling
empty states
```

## Level 5 — Business logic

```text
booking
customer care
allocation
quotation
driver
doctor
clinical
location
```

## Level 6 — UI

```text
screens
widgets
forms
loading
empty
error
navigation
```

## Level 7 — Realtime/lifecycle

```text
subscriptions
GPS/location
notifications
dispose
```

## Level 8 — Warnings/cosmetic cleanup

```text
unused imports
lint warnings
style issues
```

Do not spend time cleaning cosmetic warnings while foundational models are still broken.

---

# 44. ITERATIVE ANALYZER PROCESS

Before changing the project:

```bash
flutter clean
flutter pub get
flutter analyze
```

Record the initial error count.

Then repair ONE logical group at a time.

After each major group:

```bash
flutter analyze
```

Record:

```text
previous count
current count
root cause fixed
files changed
```

The purpose is to identify high-impact root causes.

---

# 45. PRIORITIZE CASCADING ERRORS

For example:

```text
Wrong Booking model
      ↓
Wrong constructors
      ↓
Wrong service signatures
      ↓
Wrong repositories
      ↓
Wrong screens
      ↓
Hundreds/thousands of errors
```

Fix the Booking model first.

Do NOT individually patch every screen around the wrong model.

Likewise:

```text
Wrong UserRole
      ↓
Wrong auth state
      ↓
Wrong navigation
      ↓
Wrong dashboard types
      ↓
Many downstream errors
```

Fix the role system first.

---

# 46. TESTING

After meaningful repairs run:

```bash
flutter test
```

if tests exist.

Then run:

```bash
flutter run -d chrome
```

or the project's configured target.

Test at least:

### Scenario 1 — Customer booking

```text
Customer authentication
↓
Create ROAD booking
↓
Booking is created
↓
Status is correct
```

### Scenario 2 — Empty operational resources

```text
Team Lead
↓
Allocation
↓
ambulances = []
↓
Meaningful empty state
↓
No crash
```

### Scenario 3 — Resource allocation

Only when legitimate development resources exist:

```text
compatible ambulance
+
available driver
+
required doctor
↓
allocation
```

### Scenario 4 — Quotation

```text
quotation
↓
customer receives it
↓
accept/reject
↓
status updates
```

### Scenario 5 — Trip lifecycle

```text
ASSIGNED
↓
PICKUP_STARTED
↓
PATIENT_PICKED_UP
↓
IN_TRANSIT
↓
ARRIVED
↓
SERVICE_COMPLETED
```

Do NOT claim Scenario 3–5 are fully integration-tested if the required backend data does not exist.

---

# 47. DEVELOPMENT SEED DATA

Do not automatically populate production tables.

If development testing requires operational records, create a clearly separated development seed mechanism.

Potential development resources:

```text
one compatible ambulance
one available driver
one available doctor
one customer-care resource
```

But before generating seed data:

1. Inspect actual columns.
2. Inspect constraints.
3. Inspect foreign keys.
4. Inspect enum values.
5. Inspect RLS.
6. Use legitimate development/test identities.

Never guess the schema.

---

# 48. DATABASE SEEDING VS NORMAL APP BEHAVIOR

Never insert fake records automatically from:

```text
main.dart
app startup
screen initialization
repository constructor
```

A normal application startup must NOT create fake ambulances, drivers, doctors, bookings, or notifications.

---

# 49. SECURITY

Never:

- put service-role keys in Flutter,
- disable RLS,
- trust client role values for privileged actions,
- trust client prices,
- trust client resource assignments,
- expose private credentials.

The backend must remain authoritative.

---

# 50. PROJECT ORGANIZATION

Keep the repository clean.

Do not create:

```text
booking_fixed.dart
booking_new.dart
booking_final.dart
booking2.dart
```

to work around existing errors.

If duplicate implementations exist:

1. identify which one is canonical,
2. migrate callers,
3. remove obsolete duplicates only after confirming they are unused.

Organize code logically by responsibility/role without creating unnecessary folders or abstractions.

---

# 51. WEBSITE PARITY RULE

Use the existing website as the functional reference for:

- booking fields,
- service types,
- workflow,
- resource allocation,
- quotation,
- status progression,
- notifications,
- audit concepts,
- clinical concepts.

But distinguish:

```text
website backend functionality
```

from:

```text
website localStorage/mock functionality
```

If a website feature is only local/mock, do not assume a matching Supabase table exists.

If Flutter needs a backend-backed version of such a feature, inspect the actual database first.

---

# 52. IMPORTANT CURRENT DATABASE LIMITATION

Because the current database has operational tables with zero rows:

The following may be impossible to fully integration-test right now:

```text
ambulance allocation
driver assignment
doctor assignment
customer-care operational workflow
complete trip dispatch
```

That is not necessarily a Flutter bug.

Report it as:

```text
Required operational master data is currently absent.
```

Do not fake success.

---

# 53. FINAL QUALITY REQUIREMENTS

The project is considered technically repaired only when:

```text
☐ flutter pub get succeeds
☐ flutter analyze has no compilation errors
☐ no missing imports
☐ no undefined core classes
☐ no constructor mismatch errors
☐ no invalid Future/async usage
☐ no critical null-safety violations
☐ authentication compiles
☐ role mapping is correct
☐ Customer workflow compiles
☐ Customer Care workflow compiles
☐ Team Lead workflow compiles
☐ Driver workflow compiles
☐ Doctor workflow compiles
☐ EMT-related functionality is correctly handled according to actual backend support
☐ navigation compiles
☐ Supabase layer compiles
☐ empty database states do not crash the application
☐ existing UI is preserved
☐ Admin UI is not introduced
```

Runtime verification must still be reported separately from compilation.

---

# 54. FINAL REPORT FORMAT

At the end, provide:

## Analyzer statistics

```text
Initial errors:
After foundation repair:
After model repair:
After service/repository repair:
After UI repair:
Final errors:
Final warnings:
```

## Root causes

List the major root causes discovered.

## Files changed

List the important files.

## Models changed

List model changes.

## Services changed

List service changes.

## Repositories changed

List repository changes.

## Authentication/roles

Explain:

```text
Supabase Auth
+
profiles
+
actual role mapping
```

## Supabase

Explain:

- existing tables reused,
- queries added/fixed,
- mappings added,
- RLS issues,
- empty-state handling.

## EMT

Explicitly state:

- how EMT is currently represented, OR
- why backend EMT support is not confirmed.

Do not claim an EMT profile role unless verified.

## Admin

State:

```text
ADMIN exists in the backend.
Admin Flutter UI remains intentionally out of scope.
```

## Testing

Report exactly which tests were executed and their results.

## Remaining issues

Separate:

```text
Code issues
Backend/schema issues
Missing operational data
Unsupported features
Warnings
```

Do not hide unresolved problems.

---

# 55. MOST IMPORTANT PRINCIPLE

Your objective is NOT:

> "Make the error counter become zero at any cost."

Your objective is:

> "Restore the existing Ambulance First Flutter project into a clean, strongly typed, maintainable application that preserves its intended UI and workflows, matches the existing website where applicable, and integrates correctly with the EXISTING Supabase backend."

Use this strategy:

```text
AUDIT
  ↓
IDENTIFY ROOT CAUSE
  ↓
FIX FOUNDATION
  ↓
FIX CANONICAL MODELS
  ↓
FIX AUTH / ROLES
  ↓
FIX REPOSITORIES
  ↓
FIX SERVICES
  ↓
FIX NAVIGATION
  ↓
FIX SCREENS / WIDGETS
  ↓
FIX REALTIME / LIFECYCLE
  ↓
VERIFY
  ↓
REPEAT
```

Do not randomly edit thousands of errors.

---

# 56. FIRST ACTION — DO NOT START MASS EDITING

Before modifying large numbers of files, perform a complete audit.

Report:

1. Actual project structure.
2. `pubspec.yaml` dependencies.
3. Main entry point.
4. Authentication implementation.
5. Actual role model.
6. Actual profile-role handling.
7. Booking model.
8. Booking status model.
9. Service category/subtype model.
10. Main repositories.
11. Main services.
12. Supabase initialization.
13. Supabase-related files.
14. Current local/mock data architecture.
15. Navigation architecture.
16. Top analyzer error categories.
17. Top 20 likely root causes.
18. Duplicate/conflicting models.
19. Missing imports/files.
20. EMT implementation status.
21. Backend assumptions made by the Flutter project.
22. Which assumptions are confirmed vs unverified.
23. Which database tables are empty and how the code currently handles them.
24. Recommended repair order.

DO NOT perform a huge rewrite before producing this audit.

After the audit, begin with the highest-impact root cause.

Then run:

```bash
flutter analyze
```

and continue iteratively.

Every modification must preserve valid existing functionality.

END OF MASTER PROMPT.
