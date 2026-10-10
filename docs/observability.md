# App observability

Crash and error reporting for the Flutter app uses Sentry (free tier) through a small `ErrorReporter` interface in `rohii_hostel_hunt/lib/core/observability/`. The server side (request log, `/healthz`, `/readyz`, database queries) is documented in the backend repo's `backend/docs/observability.md`.

## What is reported
- Every error that escapes the app: Flutter framework errors and uncaught async errors, through one pair of global handlers (`global_error_handlers.dart`).
- Errors the app used to swallow silently: profile stats loading, saved city load/save and GPS detection now report a non-fatal error.
- Breadcrumbs for failed API calls: `method`, the route template (`/hostels/:id/`, never the real id or the query string) and the status. Status `0` means no response (timeout or no network). Successful calls leave no breadcrumb.

## What is never sent
Emails, phone numbers, tokens, OTPs, request or response bodies, query strings, screenshots, view hierarchies, user details, location. Sentry options: `sendDefaultPii` off, screenshots off, tracing off, automatic navigation/tap/lifecycle breadcrumbs off. Before anything is sent, `scrubEvent` and `scrubBreadcrumb` mask email-like and phone-like text, strip URL query strings and replace fields named like `otp`, `token`, `password` with `[Filtered]`.

Debug logging goes through `debugLog()`, which prints only in debug builds. A test (`logging_hygiene_test.dart`) fails the build if someone adds a bare `print`/`debugPrint`, an empty `catch` block, or logging of `/auth/me` responses or tokens.

## Turn it on
Sentry stays off unless a DSN is passed at build time. Never commit the DSN.

```
flutter run --dart-define=SENTRY_DSN=<Flutter project DSN> --dart-define=SENTRY_ENVIRONMENT=test
flutter build appbundle --dart-define=SENTRY_DSN=<Flutter project DSN> --dart-define=SENTRY_ENVIRONMENT=production --dart-define=SENTRY_RELEASE=<git short hash>
```

| Name | Meaning |
|---|---|
| `SENTRY_DSN` | Sentry project DSN. Empty means off. |
| `SENTRY_ENVIRONMENT` | Default `production` for release builds, `development` otherwise. |
| `SENTRY_RELEASE` | Version tag, for example `git rev-parse --short HEAD`. If empty, Sentry uses the app name and version. |
| `SENTRY_TEST_ERROR` | `true` throws one synthetic error two seconds after startup, tagged `synthetic=true`. |

Do not build the Play Store bundle with `--obfuscate`; stack traces stay readable that way. If you obfuscate later, symbol upload must be added first.

## Safe test error
Prove the pipeline end to end from a device or emulator (this sends one event to the DSN's project):

```
flutter run --dart-define=SENTRY_DSN=<Flutter project DSN> --dart-define=SENTRY_ENVIRONMENT=test --dart-define=SENTRY_TEST_ERROR=true
```

Within about a minute an issue titled "Sentry test error (synthetic, safe to ignore)" appears in the Sentry project, in environment `test`. It is safe to resolve and ignore.

## Package
`sentry_flutter 8.14.2` (pinned exactly), which brings `sentry`, `package_info_plus` and `package_info_plus_platform_interface`. Version 10.0.0 also resolves but was not chosen: it needs Android `minSdk` 26 (dropping older phones) and forwards Sentry logs by default.
