# Ambulance First — Project Structure

This project intentionally has one folder per portal and one shared core. Do not create a second `lib/screens` folder.

```text
lib/
├── main.dart                         # App entry + unified role routing
├── auth/                              # Unified login / registration
│   └── welcome_screen.dart
├── roles/
│   ├── customer/screens/              # CUSTOMER PORTAL ONLY
│   ├── customer_care/screens/         # CUSTOMER CARE PORTAL ONLY
│   ├── driver/screens/                # DRIVER PORTAL ONLY
│   └── team_lead/screens/             # TEAM LEAD PORTAL ONLY
├── core/
│   ├── models/                        # Shared domain models
│   └── services/                      # Shared workflow/state/services
└── shared/
    ├── theme/                         # App-wide visual system
    └── widgets/                       # Reusable UI components
```

## Portal ownership
- `roles/customer/`: Customer booking, trips, history, quotations/invoices, services, customer shell.
- `roles/customer_care/`: verification and customer-care operations.
- `roles/driver/`: driver login shell, assignments, active trip, location/profile interactions.
- `roles/team_lead/`: allocation, quotations, fleet/crew, trips, reports and audit.
- `auth/`: only the unified authentication entry point.
- `core/`: must remain role-neutral because all portals use the same booking/workflow objects.
- `shared/`: common theme/components; not a portal.

## Important
There is no duplicate legacy `lib/screens/`, `lib/models/`, `lib/services/`, `lib/theme/`, or `lib/widgets/` directory in this release.
