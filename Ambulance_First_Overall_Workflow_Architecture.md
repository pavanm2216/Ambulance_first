# Ambulance First / AeroMed --- Overall Workflow & Architecture

> **Purpose:** This document describes the app's role-based
> responsibilities, end-to-end ambulance booking workflow, and intended
> application/database architecture. It is a working architecture guide;
> exact database columns, RPC signatures, and authorization rules must
> be verified against the current Supabase project before
> implementation.

------------------------------------------------------------------------

## 1. Application Overview

Ambulance First / AeroMed is a role-based ambulance booking and
operations platform. A customer requests an ambulance, Customer Care
verifies the request, Team Lead prepares a quotation and---only after
customer acceptance---allocates operational resources. The assigned
Driver manages the trip, while the Doctor records authorized clinical
information when required. Admin manages staff, fleet, and operational
configuration.

### Core design principle

**One booking, one canonical record:** every role works on the same
`public.bookings` record and its related records. Role-specific screens
must not create parallel or duplicate bookings.

------------------------------------------------------------------------

## 2. Roles and Responsibilities

### 2.1 Customer

**Purpose:** Request ambulance service and make booking/quotation
decisions.

Responsibilities: - Register/sign in and access their own profile. -
Enter patient, pickup, destination, date/time, and service/medical
requirements. - Submit a booking and receive its booking reference. -
View their own booking status, booking history, quotations,
notifications, and trip information permitted to the customer. - Accept
or reject a quotation; provide a rejection reason when required. - View
assigned ambulance/driver and trip progress when those details are
available. - Receive updates as the booking moves through the workflow.

**Data boundary:** A customer may access only their own profile,
bookings, quotations, notifications, and customer-visible trip details.

### 2.2 Customer Care

**Purpose:** Contact the customer, verify the booking details, and hand
verified requests to Team Lead.

Responsibilities: - View the incoming booking queue and booking
details. - Contact the customer and record call outcomes/logs. - Confirm
patient condition, medical requirements, pickup/destination location,
and preferred date/time. - Complete the applicable verification
checklist. - Mark the booking verified only through the authorized
workflow. - Hand off verified bookings to Team Lead. - Review booking
history and relevant notifications.

**Workflow boundary:** Customer Care verifies and hands off the request;
it does not prepare the quotation or allocate fleet resources unless a
separately authorized feature explicitly permits it.

### 2.3 Team Lead

**Purpose:** Manage operational planning, quotations, and resource
allocation.

Responsibilities: - View bookings handed off by Customer Care. - Review
verified booking details and service requirements. - Prepare and send a
quotation with charges, terms, and validity. - Review the customer's
quotation response. - If rejected, prepare and send a revised quotation
according to the supported workflow. - **Allocate an ambulance, driver,
and required medical resources only after the customer accepts the
quotation.** - Ensure selected resources meet the booking's requirements
and are eligible/available. - Monitor assignment and operational status;
use authorized database actions for updates.

**Workflow boundary:** Allocation must be enforced in both the UI and
backend. A disabled UI control alone is not sufficient authorization.

### 2.4 Driver

**Purpose:** Accept and execute an assigned ambulance trip.

Responsibilities: - Sign in and view assignments associated with the
authenticated driver. - Review assignment and trip details. - Accept or
decline an assignment through the supported workflow. - Update trip
milestones, such as reaching pickup, patient onboard, in transit,
arrival, and completion, where supported by the current status model. -
Share location updates during the permitted active-trip stages. - Update
duty/availability status through authorized actions. - View relevant
trip history.

**Data boundary:** A driver can access only assignments and operational
data authorized for that driver. Location sharing should be limited to
the applicable trip/duty policy.

### 2.5 Doctor

**Purpose:** Provide clinical assessment and patient-care information
associated with a booking when required and authorized.

Responsibilities: - View authorized assigned bookings and relevant
patient/transport information. - Record clinical assessment and vitals
only through approved, role-authorized operations. - View permitted
clinical history and trip context. - Avoid editing booking, quotation,
or fleet-allocation data unless explicitly authorized.

**Important:** Doctor write operations must remain disabled or read-only
until the actual Doctor authorization rules, database functions, and RLS
policies are verified. Do not simulate successful clinical writes
locally.

### 2.6 Admin

**Purpose:** Administer staff accounts, fleet, and platform operations.

Responsibilities: - Provision and manage authorized staff roles, such as
Driver, Doctor, Customer Care, and Team Lead. - Register and maintain
ambulance/fleet records. - Associate a driver with an ambulance using
the canonical relationship. - Manage resource status through authorized
operations. - Review administrative operational information and audit
records where those records are actually persisted. - Maintain role
access and operational configuration through secure backend workflows.

**Security boundary:** Privileged provisioning and administrative
operations must run through authorized backend functions. Never embed a
Supabase service-role key in the Flutter client.

------------------------------------------------------------------------

## 3. End-to-End Business Workflow

``` mermaid
flowchart TD
    A[Customer submits booking] --> B[Booking stored in public.bookings]
    B --> C[Customer Care reviews incoming request]
    C --> D[Customer Care contacts customer and verifies details]
    D --> E{Verification complete?}
    E -- No --> F[Follow-up / record call outcome]
    F --> D
    E -- Yes --> G[Hand off to Team Lead]
    G --> H[Team Lead prepares and sends quotation]
    H --> I[Customer reviews quotation]
    I --> J{Customer response}
    J -- Reject --> K[Record rejection and reason]
    K --> L[Team Lead prepares revised quotation]
    L --> I
    J -- Accept --> M[Team Lead allocates eligible resources]
    M --> N[Driver receives assignment]
    N --> O{Driver response}
    O -- Decline --> P[Handle reassignment through authorized workflow]
    P --> M
    O -- Accept --> Q[Trip begins and status/location updates]
    Q --> R[Pickup / patient onboard / transit]
    R --> S[Arrival and trip completion]
    S --> T[Customer sees permitted final status/history]
    Q -. If required and authorized .-> U[Doctor assessment / vitals]
    U -. Persist clinical records .-> V[Authorized clinical tables]
```

### Main booking lifecycle (conceptual)

`NEW` → Customer Care verification → handoff to Team Lead → quotation
sent → customer response → `CUSTOMER_ACCEPTED` → resource
allocation/assignment → driver acceptance → trip progression →
completion.

The exact status strings and transitions must match the live database
functions and constraints. Rejected quotations may lead to a revised
quotation; they should not create a second booking.

------------------------------------------------------------------------

## 4. System Architecture

``` mermaid
flowchart TB
    subgraph Clients[Flutter application]
      C[Customer portal]
      CC[Customer Care portal]
      TL[Team Lead portal]
      D[Driver portal]
      DR[Doctor portal]
      A[Admin portal]
    end

    subgraph AppLayer[Application layer]
      AUTH[Supabase Auth session and role resolution]
      UI[Role screens and shared UI]
      REPO[Role-aware repositories / services]
      MAP[DTO and model mapping / validation]
    end

    subgraph Backend[Supabase backend]
      RLS[Row Level Security and grants]
      RPC[Authorized Postgres RPC functions]
      EF[Edge Functions for privileged/server workflows]
      DB[(Postgres database)]
      RT[Realtime / subscriptions where configured]
      STORAGE[Storage, if configured]
    end

    C --> AUTH
    CC --> AUTH
    TL --> AUTH
    D --> AUTH
    DR --> AUTH
    A --> AUTH
    AUTH --> UI
    UI --> REPO
    REPO --> MAP
    MAP --> RLS
    MAP --> RPC
    MAP --> EF
    RLS --> DB
    RPC --> DB
    EF --> DB
    DB --> RT
    RT --> REPO
    DB --- STORAGE
```

### Request and data flow

1.  User signs in through Supabase Auth.
2.  The app resolves the authenticated user's role from the trusted
    profile/authorization source.
3.  The role's screen calls a repository/service method.
4.  The repository invokes the verified RPC, Edge Function, or permitted
    table query.
5.  Backend authorization and RLS validate the user and operation.
6.  The database commits the canonical change and related history
    records as required.
7.  The repository maps the returned data into UI models.
8.  The UI displays persisted state; refresh/re-entry should show the
    same result.

**Do not treat local UI state, in-memory stores, demo fixtures, or
optimistic-only updates as persisted database truth.**

------------------------------------------------------------------------

## 5. Core Data Model and Relationships

The database is the source of truth. The following is a conceptual
relationship map; verify exact live columns and foreign keys before
writing queries or migrations.

``` mermaid
erDiagram
    PROFILES ||--o{ BOOKINGS : "customer"
    BOOKINGS ||--o{ QUOTATIONS : "has versions"
    BOOKINGS ||--o{ BOOKING_ASSIGNMENTS : "has assignments"
    BOOKINGS ||--o{ BOOKING_STATUS_HISTORY : "status history"
    BOOKINGS ||--o{ BOOKING_VITALS : "clinical vitals"
    BOOKINGS ||--o{ DRIVER_LOCATION_PINGS : "trip locations"
    PROFILES ||--o| DRIVERS : "driver profile"
    PROFILES ||--o| DOCTORS : "doctor profile"
    AMBULANCES ||--o| DRIVERS : "current_driver_id references driver"
    BOOKINGS }o--o| AMBULANCES : "assigned resource (verify FK)"
    BOOKINGS }o--o| DRIVERS : "assigned driver (verify FK)"
```

### Key entities

-   **`profiles`** --- authenticated user's profile and role
    information.
-   **`bookings`** --- canonical customer request and operational
    booking state.
-   **`quotations`** --- quotation versions, pricing, validity, and
    customer response.
-   **`booking_assignments`** --- assignment records linking a booking
    to operational resources, subject to the live schema.
-   **`ambulances`** --- fleet identity, category/capabilities, status,
    and current driver association.
-   **`drivers`** --- driver profile and duty/status information.
-   **`doctors` / `medical_crew`** --- clinical and medical resource
    records; crew types include EMT and PARAMEDIC in the known schema.
-   **`booking_status_history`** --- persisted status transition
    history.
-   **`booking_vitals`** --- clinical vitals when authorized and
    configured.
-   **`driver_location_pings`** --- driver location records, subject to
    retention/access policy.
-   **`notifications`**, call logs, and other supporting tables --- use
    only after confirming actual schema and access rules.

### Confirmed relationship note

The known canonical vehicle-driver association is
`ambulances.current_driver_id = drivers.id`. Do not rely on a
nonexistent `drivers.assigned_ambulance_number` field. Verify all other
relationships against the current live schema.

------------------------------------------------------------------------

## 6. Role-to-Data Responsibility Matrix

  -----------------------------------------------------------------------
  Role                    Main data read          Main data writes /
                                                  actions
  ----------------------- ----------------------- -----------------------
  Customer                Own profile, bookings,  Create booking, respond
                          quotations,             to quotation, mark own
                          notifications,          notifications read
                          customer-visible trip   
                          data                    

  Customer Care           Incoming bookings,      Save call logs, verify
                          booking                 booking, hand off to
                          details/history, call   Team Lead, mark
                          logs, notifications     notifications read

  Team Lead               Handed-off bookings,    Prepare/send
                          quotations, fleet,      quotations, allocate
                          drivers, doctors/crew   resources after
                          availability            acceptance, authorized
                                                  resource status updates

  Driver                  Own assignments, trip   Respond to assignment,
                          details, permitted      advance trip status,
                          patient/pickup details  publish location,
                                                  update duty status

  Doctor                  Authorized assigned     Clinical assessment and
                          bookings and clinical   vitals only through
                          context                 verified authorization

  Admin                   Staff and fleet         Provision staff,
                          records, authorized     register/manage fleet
                          operational views       and resources,
                                                  authorized
                                                  status/configuration
                                                  actions
  -----------------------------------------------------------------------

This is a responsibility overview, not a substitute for database grants
or RLS policies.

------------------------------------------------------------------------

## 7. Critical Business Rules and Safety Invariants

1.  **Single source of truth:** all portals operate on the same
    canonical booking.
2.  **Quotation gate:** resource allocation is allowed only after
    customer acceptance of the applicable quotation.
3.  **Backend enforcement:** role and status checks must be enforced by
    database functions/RLS or trusted backend---not only by Flutter UI.
4.  **Ownership:** customers see only their own data; staff access is
    limited to role- and assignment-authorized records.
5.  **Resource eligibility:** allocate only available resources that
    satisfy required ambulance capabilities and staffing requirements.
6.  **Assignment integrity:** use stable IDs and foreign keys, not
    display names or vehicle labels, to associate resources.
7.  **Persisted auditability:** show audit/history/notification data as
    persisted only when the backend actually stores it.
8.  **No fake success:** after a write, show success only after the
    backend confirms it; surface errors clearly.
9.  **No client secrets:** never put Supabase service-role credentials
    in Flutter or public client configuration.
10. **No silent demo fallback:** production login must not silently
    substitute demo users, fixtures, or in-memory state.
11. **Clinical privacy:** restrict Doctor and patient clinical data to
    authorized users and verified policies.
12. **Location privacy:** share and expose driver location only for
    authorized, relevant trip states.

------------------------------------------------------------------------

## 8. Implementation Boundaries and Known Cautions

-   `SharedBookingStore` may support shared UI state, but it must
    hydrate from the database and must not replace backend persistence.
-   Team Lead local-only mutations (such as local quotation/resource
    updates or locally generated audit/notification entries) must be
    traced to active callers and migrated to verified backend operations
    before being treated as production functionality.
-   Doctor clinical write flows must remain read-only until the current
    database authorization contract is verified.
-   Remove or gate demo credential/fallback paths for production.
-   Avoid matching drivers, ambulances, doctors, or crew by names when
    stable resource IDs are available.
-   Do not assume old documentation matches the current live schema or
    RPC signatures.
-   Exact RPC names/signatures, table columns, RLS policies, and Edge
    Function contracts must be inspected before integration.

------------------------------------------------------------------------

## 9. Recommended Validation and Release Checklist

### Database and security

-   [ ] Verify live tables, columns, constraints, foreign keys, indexes,
    and status values.
-   [ ] Verify every RPC/function signature and its role/status checks.
-   [ ] Verify RLS policies and grants using real accounts for each
    role.
-   [ ] Confirm privileged operations use secure backend functions.
-   [ ] Confirm migrations are ordered, repeatable where intended, and
    documented.

### Role-based functional tests

-   [ ] Customer creates a booking; it appears in the database and
    Customer Care queue.
-   [ ] Customer Care records a call, verifies the booking, and hands it
    off.
-   [ ] Team Lead prepares and sends a quotation.
-   [ ] Customer accepts/rejects the correct quotation; rejection
    supports the approved revision flow.
-   [ ] Allocation is blocked before acceptance and succeeds only for
    eligible resources after acceptance.
-   [ ] Driver receives and responds to the assignment; trip milestones
    persist.
-   [ ] Location updates persist and are visible only to authorized
    viewers.
-   [ ] Doctor clinical writes succeed only with verified authorization;
    otherwise remain unavailable.
-   [ ] Admin staff provisioning and fleet registration persist with
    correct relationships.
-   [ ] Every role sees persisted data after refresh/re-login; no
    local-only state is mistaken for database data.

### Quality gates

-   [ ] Run `flutter analyze`.
-   [ ] Run project tests.
-   [ ] Build the intended deployment target.
-   [ ] Run a full multi-role end-to-end scenario with real test
    accounts.
-   [ ] Document any feature blocked by missing schema, policy, or
    backend support.

------------------------------------------------------------------------

## 10. End-to-End Scenario for QA

1.  Customer signs in and submits a booking.
2.  Confirm exactly one new row exists in `public.bookings`.
3.  Customer Care opens that booking, records contact details/outcome,
    verifies the request, and hands it to Team Lead.
4.  Team Lead opens the same booking and sends quotation version 1.
5.  Customer views and rejects quotation version 1 with a reason.
6.  Team Lead sends a revised quotation version 2.
7.  Customer accepts version 2.
8.  Team Lead allocates an eligible ambulance, driver, and required
    medical resources.
9.  Driver accepts the assignment and updates the trip through supported
    milestones.
10. Confirm status history, assignment, and location records persist
    where configured.
11. Doctor records assessment/vitals only if authorized and required.
12. Customer sees permitted progress and final status.
13. Admin can verify fleet/staff associations through authorized views.
14. Sign out and back in as each role; verify persisted data and access
    boundaries.

------------------------------------------------------------------------

## 11. Architecture Summary

``` text
Flutter role portals
    ↓
Authentication + role resolution
    ↓
Role-specific repositories/services
    ↓
Verified Supabase RPCs / Edge Functions / permitted queries
    ↓
RLS + backend authorization
    ↓
Canonical PostgreSQL records
    ↓
Persisted state, history, assignments, and permitted live updates
    ↓
Role-specific UI refreshes from the same source of truth
```

**Success criterion:** A booking can move from customer request to
verified handoff, quotation, customer acceptance, resource assignment,
and trip completion while every role sees only the data and actions
authorized for them---and every operational change is persisted in the
canonical backend.
