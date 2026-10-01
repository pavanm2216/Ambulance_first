# AeroMed quotation template

Every role renders the same persisted quotation. Flutter does not calculate or
invent operational fares; the Team Lead quotation RPC is the authoritative
generator.

```
OFFICIAL MEDICAL TRANSPORT QUOTATION
Quotation ID / Booking ID / Status / Valid until

Patient and route
  Patient name, requested service, pickup -> destination, distance

Cost breakdown
  Base ambulance charge
  Distance charge
  Doctor, medical crew, ICU, ventilator, oxygen and other required equipment
  Additional operational charges
  Discount
  Subtotal
  GST / tax
  TOTAL PAYABLE

Payment terms and customer acceptance/rejection controls
```

The UI maps the backend quotation fields `base_ambulance_charge`,
`distance_charge`, optional clinical charges, `subtotal`, `tax_amount`, and
`final_amount` (or `total_amount`) into this template. A quotation must never
be replaced with a locally calculated fallback when those backend values are
missing.
