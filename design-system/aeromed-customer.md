# AeroMed Customer Design System

## Direction
Premium healthcare mobile UX inspired by the supplied appointment UI: layered white surfaces, soft lavender ambient background, cobalt interaction cards, compact category chips, circular icon actions, and a floating dark navigation bar. Ambulance-specific meaning remains visible through medical-green success states and emergency red.

## Core tokens
- Primary cobalt: `#315BEF`
- Primary dark: `#2446C7`
- Deep navy: `#1B2B55`
- Ambient background: `#E7ECFF`
- Lavender: `#DDE5FF`
- White surface: `#FFFFFF`
- Text: `#172033`
- Secondary text: `#6B7488`
- Border: `#E1E6F0`
- Medical green: `#58B947`
- Emergency red: `#D92D20`

## Shape language
- Hero: 26px
- Cards: 20px
- Buttons: 14px
- Inputs: 14px
- Bottom navigation: 26px
- Bottom sheets/dialogs: 28px/22px

## UX rules
- Mobile-first; minimum 44x44 touch targets.
- Bottom navigation stays at five destinations or fewer.
- Use one dominant action per surface.
- Use semantic colors and labels; never rely on color alone for status.
- Keep body text readable and avoid tiny metadata.
- Motion should explain a state change, not decorate every element.
- Preserve safe areas and avoid horizontal overflow.

## Customer information hierarchy
1. Book an ambulance
2. Emergency request
3. Active trip / ETA
4. Upcoming bookings
5. Services
6. Quotes/invoices/history

## Implementation note
The two Claude skill files are included under `.claude/skills/` as project-local design guidance. The UI/UX Pro Max markdown references its optional local search database/scripts; those additional package files were not supplied with the uploaded skill document.


## Glassmorphism + Neumorphism layer

The Customer UI keeps the teal palette while using a hybrid surface language: translucent blurred glass panels for cards/navigation and paired light/dark soft shadows for tactile controls and inputs. Glass is used for containers that benefit from depth and hierarchy; neumorphism is reserved for interactive controls so the UI remains readable and doesn't become visually muddy.
