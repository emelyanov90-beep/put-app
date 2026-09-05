# Product rules supplied during implementation

These explicit product rules supplement the main TZ and must be considered in
screen flows, transitions, states, and Flutter/PocketBase behavior.

## Onboarding, authorization, and registration

1. Onboarding explains step by step who the application is for and how to use
   it. After onboarding, the user proceeds to the application flow.
2. Before starting work, the user selects a city or locality from the available
   list.
3. Authorization and registration use a phone number and confirmation code.
4. After phone confirmation, a new user supplies a required name and an
   optional avatar.
5. The user chooses the action/role that leads to the passenger or driver
   section: finding a trip or creating a trip.

For the test implementation no real SMS provider is connected. The confirmation
code for every valid phone number is always `111111`.

## Platform priority and delivery

- The current delivery target is Android. The required distributable at the end
  of the test task is an APK.
- Development, visual QA, and release checks should therefore be Android-first.
- Shared Flutter/Dart code must remain cross-platform and avoid unnecessary
  Android-only assumptions.
- A complete iOS version, iOS-specific polish, and iOS release delivery are not
  part of the current scope unless explicitly requested later.
