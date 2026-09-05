# Путь

Flutter + PocketBase MVP for passenger and driver trip flows. Product behavior,
data rules, acceptance criteria, and delivery requirements are defined in
[`docs/TZ_Put_Flutter_PocketBase.md`](docs/TZ_Put_Flutter_PocketBase.md).

## Requirements

- Flutter `3.47.2` / Dart `3.13.2` (also pinned in `.fvmrc`)
- Xcode/Android Studio for the target platform
- `curl`, `unzip`, and `shasum` for the local PocketBase bootstrap

Generated platform baselines are Android API 24+ and iOS 15.0+.

## First setup

```sh
flutter pub get
cp config/dev.example.json config/dev.json
./tool/bootstrap_pocketbase.sh
```

Change `PB_BASE_URL` in `config/dev.json` to the appropriate HTTPS backend.
For a local simulator you may deliberately use a simulator-reachable local URL;
never use it in a release configuration.

Run the backend and application in separate terminals:

```sh
./tool/run_pocketbase.sh
flutter run --dart-define-from-file=config/dev.json
```

Run quality checks:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Structure

```text
lib/app                  app, router, theme
lib/core                 config, API, auth, errors, utilities, shared widgets
lib/features             feature UI and controllers/providers
lib/data                 models, repositories, PocketBase adapters
backend/pb_migrations    reproducible PocketBase schema
backend/pb_hooks         server-only routes and business transitions
backend/seed             reproducible demo data
```

Implementation follows `UI -> Controller/Provider -> Repository -> PocketBase`.
Payment, publication, approval, cancellation, and other critical state changes
must go through server actions.

## Test behavior required by the TZ

```text
Тестовый SMS-код для любого номера: 111111
Оплата: mock, реальный платежный сервис не подключен
```

Do not commit auth tokens, PocketBase superuser credentials, `pb_data`, vehicle
registration documents, or real user data.
