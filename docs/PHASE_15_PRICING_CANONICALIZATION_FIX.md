# Phase 15 — Pricing Canonicalization Fix

## Problem

The Team Lead quotation builder previously used hard-coded values that did not match `public.pricing_settings` / `public.prepare_booking_quotation()`.

Examples of previous UI-only defaults included:

- Doctor: ₹2,500
- EMT: ₹800
- Oxygen: ₹600
- Logistics/tolls: ₹750
- Fake 20 km fallback when route distance was missing
- Equipment charge based on the number of equipment labels

The backend quotation RPC uses the configured pricing table instead.

## Fix

`lib/roles/team_lead/widgets/quotation_builder_dialog.dart` now:

1. Loads `pricing_settings` from Supabase.
2. Uses the same configured road base/per-km, doctor, EMT, oxygen, ICU, ventilator, pediatric and tax values as the backend.
3. Uses the actual booking route distance; it no longer invents a 20 km fallback.
4. Starts optional equipment/logistics charges at zero instead of silently adding fees.
5. Preserves manually edited quotation values for the Team Lead.
6. Leaves the protected backend RPC as the authoritative persisted quotation calculation.

## Current QA example

For a ROAD Advanced Life Support booking at 1.813 km with:

- Doctor required
- EMT required
- Oxygen required
- No ICU
- No ventilator
- No pediatric protocol

Using the current QA `pricing_settings` values:

```text
Base                         ₹2500.00
Distance 1.813 × ₹40        ₹72.52
Doctor                      ₹1000.00
EMT                         ₹500.00
Oxygen                      ₹300.00
-----------------------------------
Subtotal                    ₹4372.52
5% tax                      ₹218.63
-----------------------------------
Final                       ₹4591.15
```

This is a QA calculation, not a declaration of final company tariffs.

## Important

Customer Care should not treat a locally displayed estimate as an authoritative quotation. The authoritative amount is the persisted quotation (`q_*` / quotation record) after Team Lead quotation preparation.
