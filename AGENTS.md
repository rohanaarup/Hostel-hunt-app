# Hostel Hunt app

Flutter mobile app for finding PG and hostel accommodation in Hyderabad. It talks to the Django API in the separate backend repo (`hostel-hunt-admin-pannel`, see its `AGENTS.md`).
Everything below was checked against the code or run on 2026-10-10; things not run are listed under "Not verified".

## Layout
- `rohii_hostel_hunt/` – the Flutter project (package `rohii_hostel_hunt`, Dart SDK `^3.10.4`). Run all Flutter commands from this folder.
- Repo root also holds this file, `claude.md`, and a few loose files (`Rohii Neon DB.session.sql`, an image) that are not part of the app.

## Architecture
- State: Riverpod 2.x (`flutter_riverpod`). Routing: `go_router` (`lib/core/router/router.dart`). HTTP: the `http` package. Tokens: `shared_preferences`.
- `lib/features/<name>/` holds `auth, booking, dashboard, home, hostel, location, payments, profile, search, settings, support, wishlist`. `lib/core/` has `network`, `router`, `theme`, `services`, `constants`, `utils`; `lib/shared/` has common widgets and helpers.
- `lib/core/network/api_service.dart` is the only HTTP client. It stores the access and refresh tokens, and on a 401 refreshes the access token and retries the request once.
- Base URL: by default the deployed backend, `https://hostel-hunt-backend.onrender.com/api/v1`. Build or run with `--dart-define=USE_LOCAL_BACKEND=true` to use the local host and port constants in `api_service.dart` (keep them equal to the port Django runs on).
- Observability: `lib/core/observability/` (`ErrorReporter`, global error handlers, Sentry setup and scrubbing, `debugLog`). Sentry is on only when `--dart-define=SENTRY_DSN=...` is passed; see `docs/observability.md`. Use `debugLog()` instead of `print`/`debugPrint`; never log personal data.
- Payments: `razorpay_flutter`; the backend creates and verifies the Razorpay order. Do not change this flow without a task that says so.

## Commands (run from `rohii_hostel_hunt/`)
```
flutter pub get
flutter analyze      # 0 errors, 11 warnings, 53 infos at this commit
flutter test         # 19 tests, all pass (observability, privacy, logging hygiene)
```
Run on a device or emulator: `flutter run` (add `--dart-define=USE_LOCAL_BACKEND=true` for a local backend).

## Rules for changes
- Measure first. Keep changes small and in the existing style.
- The backend deploys before the app. The app must tolerate missing or extra fields in API responses.
- Errors must be visible: no empty `catch` blocks, and screens show the HTTP status and the server's reason.
- Never print, log or commit secrets. No keys belong in this repo.

## Known gaps
- Test coverage is limited to the observability layer (`test/core/observability/`). There are no screen or API-contract tests yet; the old default counter test was removed because it could never pass.
- Android `applicationId` is `com.example.rohii_hostel_hunt` (`android/app/build.gradle*`). Play Console is expected to reject `com.example.*` IDs, so choose a real ID before the first Play Store upload (an ID cannot be changed after publishing).
- `flutter analyze` reports 11 warnings (unused fields, variables and one import) and many deprecation infos such as `withOpacity`.

## Not verified
- `flutter run`, release builds and signing, and behaviour on a physical device.
- Sentry delivery to a real project (needs a DSN): use the safe test error in `docs/observability.md`.
