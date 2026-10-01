# Final Release Checklist

## Backend
- [ ] Pricing migration applied and verified.
- [ ] Phase 6 controlled workflow migration applied.
- [ ] Phase 7–10 controlled operations migration applied.
- [ ] Customer booking RPC tested.
- [ ] Customer quotation response tested.
- [ ] Customer Care transitions tested.
- [ ] Team Lead quotation tested against persisted pricing.
- [ ] Team Lead/Admin allocation tested with real resources.
- [ ] Driver transitions tested with assigned driver account.
- [ ] Doctor assessment tested with assigned doctor account.
- [ ] Doctor vitals tested with assigned doctor account.
- [ ] Completion tested.
- [ ] Audit rows verified.
- [ ] Notifications/status-history persistence contract verified before enabling related policies.
- [ ] Secure staff-provisioning Edge Function deployed.
- [ ] Reviewed RLS replacement applied only after RPC smoke tests pass.

## Flutter
- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Web release build
- [ ] Android release build if required
- [ ] Login tested for each active role.
- [ ] Empty/loading/error states tested.
- [ ] Admin navigation tested on narrow and desktop widths.
- [ ] Doctor navigation tested on narrow and desktop widths.
- [ ] Customer booking and quotation workflow tested end-to-end.
- [ ] Driver assigned workflow tested.

## Security
- [ ] No service-role key in source, assets, `.env`, or build arguments.
- [ ] No unrestricted `*_open` policies remain after cutover.
- [ ] Historical delete operations are not exposed.
- [ ] Customer cannot read another customer's booking.
- [ ] Driver cannot modify another driver's booking.
- [ ] Doctor cannot write to an unassigned booking.
- [ ] Customer cannot modify quotation amounts/status directly.
- [ ] Audit records cannot be edited by ordinary clients.
