# Project instructions

`docs/TZ_Put_Flutter_PocketBase.md` is the main source of truth for this project.
Explicit additions supplied during implementation are recorded in
`docs/PRODUCT_RULES.md`. Before changing a feature, read its relevant sections,
data model, access rules, acceptance criteria, smoke-test steps, and Definition
of Done.

Requirement priority is exactly section 3 of the specification: the TZ, the
explicit test-task conditions, Figma flows, then technical decisions in the TZ.
Do not invent product behavior where the TZ or Figma already defines it.

Architecture and invariant rules:

- Keep the flow `UI -> Controller/Provider -> Repository -> PocketBase SDK or
  custom route`.
- Server-controlled transitions (publish, approve/reject, pay, cancel, vehicle
  verification) must not be arbitrary client-side collection updates.
- Test OTP is always `111111`; never add a real SMS provider unless the TZ is
  explicitly changed.
- Payments and refunds are mock server actions. Never add a payment SDK without
  an explicit requirement change.
- With zero published reviews, UI text must express `5 звезд, нет
  отзывов`; do not store a fake 5.0 rating.
- Trips, bookings, payments, and parcels are separate entities.
- Never expose another user's phone, vehicle registration document, auth token,
  or PocketBase superuser credentials.
- Backend URLs come from build/deploy configuration and production traffic is
  HTTPS. Never make localhost the mobile app default.
- UI must ultimately follow the supplied Figma. Foundation placeholders must be
  clearly marked and must not be treated as final design tokens.

Before handing off a change, format touched Dart files and run the relevant
tests plus `flutter analyze`. Keep PocketBase migrations, hooks, and seed data
reproducible; never commit `pb_data`, backend binaries, secrets, or local config.
