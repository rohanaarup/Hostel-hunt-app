# CLAUDE.md — Project Guide for AI Agents

> **Audience:** Claude Code, Codex, Cursor, and any other AI coding agent working on this repository.
> **Purpose:** Single-file onboarding — read this first before touching code, models, or migrations.

---

## 1. What is this project?

**ROHII Hostel Hunt** is a full-stack application for finding and booking PG/hostel accommodations. It targets students looking for housing and hostel owners listing their properties.

| Layer | Technology | Location |
|------|-----------|----------|
| Mobile app | Flutter (Dart, SDK ^3.10.4) | `rohii_hostel_hunt/` |
| Backend API | Django 5 + Django REST Framework | `backend/` |
| Database | PostgreSQL on **Railway** (shared with Admin Panel) | `backend/.env` |
| Auth | JWT (`rest_framework_simplejwt`) | `backend/accounts/` + `backend/otp_auth/` |
| State (app) | Riverpod 2 + GoRouter 14 | `lib/core/`, `lib/features/*/presentation/providers/` |
| Email | Gmail SMTP | `backend/.env` |

There is also a legacy `auth_learn/` sandbox folder (empty — ignore unless asked).

---

## 2. Repository layout

```
ROHIIs_hostel_hunt/
├── AGENTS.md                 # Legacy Codex-style guide (older version)
├── claude.md                 # ← YOU ARE HERE (canonical, use this one)
├── backend/                  # Django REST API
│   ├── rohii_backend/        # Project package (settings, urls, wsgi)
│   ├── accounts/             # User model, register/login/logout
│   ├── otp_auth/             # OTP generation, email verification
│   ├── hostels/              # Hostel listings
│   ├── rooms/                # Rooms within hostels
│   ├── bookings/             # Booking flow
│   ├── reviews/              # Reviews (model only — no live data yet)
│   ├── payments/             # Payments app (skeleton)
│   ├── media_uploads/        # Media uploads (skeleton)
│   ├── favorites/            # Favorites app (skeleton)
│   ├── .env                  # Local secrets (DO NOT COMMIT)
│   ├── .env.example          # Template
│   ├── db.sqlite3            # Local dev fallback (Railway is production)
│   ├── manage.py
│   └── requirements.txt
├── rohii_hostel_hunt/        # Flutter app
│   ├── lib/
│   │   ├── main.dart         # Entry point — ProviderScope + MaterialApp.router
│   │   ├── core/             # Cross-cutting: router, theme, network, utils
│   │   │   ├── router/router.dart
│   │   │   ├── network/api_service.dart
│   │   │   ├── network/api_provider.dart
│   │   │   ├── theme/{colors,notifiers,theme_provider}.dart
│   │   │   └── utils/{call,hostel_navigation}.dart
│   │   ├── features/         # Feature-first organization
│   │   │   ├── auth/         # login, signup
│   │   │   ├── home/         # homepage
│   │   │   ├── search/       # search + debounce
│   │   │   ├── hostel/       # hostel detail, bed selection
│   │   │   ├── booking/      # booking requests
│   │   │   ├── location/     # GPS, saved addresses
│   │   │   ├── profile/      # profile + edit + sub-pages
│   │   │   ├── payments/     # payments page
│   │   │   ├── wishlist/     # saved hostels + recent activity
│   │   │   ├── settings/     # preferences + app settings
│   │   │   └── support/      # support + about
│   │   └── shared/           # Truly shared widgets/helpers
│   │       ├── widgets/{loading,premium_bottom_nav,sub_header}.dart
│   │       └── dialogs/, extensions/, helpers/  (mostly empty placeholders)
│   ├── pubspec.yaml
│   ├── android/  ios/  web/  windows/  macos/  linux/
│   └── build/  .dart_tool/
├── .venv/                    # Python virtualenv (Django side)
└── .vscode/settings.json
```

---

## 3. Quick start

### Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # optional
pip install -r requirements.txt
cp .env.example .env                                # then edit secrets
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### Flutter app
```bash
cd rohii_hostel_hunt
flutter pub get
flutter run              # picks up device automatically
flutter run -d chrome    # web (uses 127.0.0.1:8000)
```

### Environment variables (`backend/.env`)
| Var | Purpose |
|---|---|
| `SECRET_KEY` | Django + JWT signing key |
| `DEBUG` | `True` for local, `False` for production |
| `ALLOWED_HOSTS` | Comma-separated host list |
| `DATABASE_URL` | Postgres connection string (Railway in prod, SQLite fallback in dev) |
| `EMAIL_BACKEND`, `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USE_TLS` | SMTP config |
| `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` | Gmail credentials |
| `DEFAULT_FROM_EMAIL` | Display sender |

---

## 4. Architecture at a glance

### Flutter app
- **Entry:** `lib/main.dart` wraps the entire tree in a `ProviderScope` (Riverpod) and uses `MaterialApp.router` with `appRouter` from `lib/core/router/router.dart`.
- **Routing:** `GoRouter` with 17 named routes (see `lib/core/router/router.dart`). Initial location is `/home`.
- **HTTP:** All requests go through `ApiService` (singleton) at `lib/core/network/api_service.dart`. It owns:
  - Token storage via `SharedPreferences` (`jwt_access`, `jwt_refresh`).
  - Platform-aware base URL (Android emulator → `10.0.2.2:8000`, Web → `127.0.0.1:8000`, iOS sim → `localhost:8000`).
  - Automatic refresh on 401 by calling `/api/auth/token/refresh/`.
  - Two response wrappers:
    - `ApiResponse` — for the `{success, message, data}` envelope used by accounts/otp_auth.
    - `RawApiResponse` — for DRF endpoints that return paginated lists (hostels, bookings, rooms).
- **State:** Riverpod 2 throughout. Old GetX/Provider code was removed (see pubspec comments). Each feature has its own provider in `features/<feature>/presentation/providers/`.
- **Theme:** `AppColors.lightTheme()` / `AppColors.darkTheme()` in `lib/core/theme/colors.dart`, toggled via `themeProvider` in `lib/core/theme/theme_provider.dart`.
- **Location:** `geolocator` + `geocoding` packages, abstracted by `LocationProvider` (`features/location/presentation/providers/location_provider.dart`) and `location_riverpod_provider.dart`.
- **Navigation helpers:** `core/utils/hostel_navigation.dart` and `core/utils/call.dart` (launches phone dialer).

### Django backend
- **Project package:** `rohii_backend/` (settings, urls, exceptions, wsgi, asgi).
- **Apps:**
  - `accounts` — Custom `Owner` user model (UUID PK, `owner_id`). Has `AppUser` and `HostelOwner` proxy models for Django admin filtering.
  - `otp_auth` — `OTPRecord` model + `OTPService` for generation/rate-limiting/emailing.
  - `hostels` — `Hostel` model with `city`, `gender_type`, `amenities` (JSON), `occupancy_types` (JSON), geo fields.
  - `rooms` — Per-hostel room types and pricing.
  - `bookings` — Booking with denormalized user fields (Railway schema). Statuses: `pending`, `confirmed`, `cancelled`, `completed`.
  - `reviews` — Skeleton, not wired to a real Railway table.
  - `payments`, `media_uploads`, `favorites` — Skeletons.
- **DRF config:** JWT auth, `IsAuthenticated` by default, throttling (60/min anon, 300/min user), `PageNumberPagination` (page size 20), `DjangoFilterBackend` + `SearchFilter` + `OrderingFilter`.
- **Custom exception handler:** `rohii_backend.exceptions.custom_exception_handler` normalizes error envelopes to `{success, message, ...}`.
- **CORS:** Open by default (`CORS_ALLOW_ALL_ORIGINS = True`). CSRF trusted for localhost.

---

## 5. Database schema (logical)

| Table | Key columns | Notes |
|---|---|---|
| `owners` | `owner_id` (UUID PK), `email`, `phone_number`, `display_name`, `role` (`student`/`owner`), `signup_source` (`admin_panel`/`app`), `is_verified`, `is_active`, `is_staff`, `profile_photo`, timestamps | App label is `'owners'` even though the package is `accounts` (see §7). |
| `owners_groups` / `owners_user_permissions` | M2M tables | Custom table names to match Railway. |
| `otp_records` | `identifier`, `otp_code` (SHA-256 hash), `purpose`, `is_used`, `created_at`, `expires_at`, `verification_token` (UUID) | App label is also `'owners'` so content type is `owners.otprecord`. |
| `hostels` | `hostel_id` (UUID PK), `name`, `owner_id` (FK→owners), `city`, `state`, `pincode`, `latitude`, `longitude`, `google_maps_url`, `gender_type`, `total_floors`, `total_rooms`, `total_beds`, `occupancy_types` (JSON), `amenities` (JSON), `is_active`, `is_verified`, timestamps | Has `media_items` reverse relation (from `media_uploads`). |
| `rooms` | Per-hostel rooms, pricing, capacity | |
| `bookings` | `booking_id` (UUID PK), denormalized `user_*` fields, FKs to `hostels` and `rooms`, `status`, `check_in_date`, `check_out_date`, `requested_at` | Bookings do **not** use a FK to `owners` — they store user fields as text. |
| `django_migrations`, `django_content_type`, etc. | Standard Django | Critical: must match Railway's history (see §7). |

---

## 6. API surface (current)

All routes are prefixed with `/api/`.

### Auth (`accounts/urls.py`)
- `POST /api/auth/register/` — `{display_name, email, role, password, password_confirm}` → `{user, tokens}`. **Requires OTP already verified** (see `RegisterSerializer.validate`).
- `POST /api/auth/login/` — `{email, password}` → `{user, tokens}`. Refuses if `is_verified` is `False`.
- `POST /api/auth/logout/` — `{refresh}` → blacklists refresh token.
- `POST /api/auth/token/refresh/` — SimpleJWT built-in.
- `GET  /api/auth/me/` — Current user profile.

### OTP (`otp_auth/urls.py`)
- `POST /api/otp/send/` — `{email}` → emails a 6-digit code, valid 5 min, cooldown 60 s, max 5 sends/hour.
- `POST /api/otp/verify/` — `{email, otp}` → marks record used.
- `POST /api/otp/dev-verify/` — **Dev-only** (gated by `DEBUG=True`); marks email verified without email roundtrip.

### Hostels (`hostels/urls.py`)
- `GET    /api/hostels/` — List (filterable by `city`, `gender_type`, `is_active`; searchable on `name/city/description/address/landmark`; ordered by `created_at`). Public.
- `POST   /api/hostels/create/` — Owner-only. Sets `owner=request.user`.
- `GET    /api/hostels/my-hostels/` — Owner-only list of own hostels.
- `GET    /api/hostels/<uuid:pk>/` — Public detail with `media_items` prefetched.
- `PATCH  /api/hostels/<uuid:pk>/update/` — Owner-only (own hostels).
- `DELETE /api/hostels/<uuid:pk>/delete/` — Owner-only (own hostels).

### Rooms (`rooms/urls.py` — mounted in root)
- `GET/POST /api/rooms/...` — Manage rooms under a hostel.

### Bookings (`bookings/urls.py`)
- `GET  /api/bookings/my-bookings/` — Student's own bookings (filter by `status`).
- `POST /api/bookings/create/` — Create booking.
- `GET  /api/bookings/hostel-bookings/` — Owner's incoming bookings.
- `PATCH /api/bookings/<uuid:pk>/update-status/` — Owner-only status transitions.
- `GET  /api/bookings/<uuid:pk>/` — Detail (student sees own, owner sees for own hostels).

> **Heads-up:** `payments`, `favorites`, `media_uploads` apps exist but are not mounted in `rohii_backend/urls.py` yet.

---

## 7. ⚠️ CRITICAL Database rules — DO NOT BREAK

> The Flutter app talks to a **Railway Postgres instance that is shared with a separate Admin Panel project**. Schema drift = production outage. Follow these rules religiously.

1. **Never** change `backend/accounts/apps.py`. The line `label = 'owners'` maps the `accounts` package to the `owners` database label. Removing it breaks the entire user/auth system and the `django_content_type` table.

2. **Never** change `AUTH_USER_MODEL = 'owners.Owner'` or the model class name `Owner`. Migrations and `django_content_type` rows reference both.

3. **Never** change the `Owner` model's primary key type or name. `owner_id` (UUID) and the M2M table overrides (`owners_groups`, `owners_user_permissions`) must stay.

4. **Never** delete, rename, or rewrite the initial migration files. They are synced to Railway's `django_migrations` history:
   - `backend/accounts/migrations/0001_initial.py`
   - `backend/accounts/migrations/0002_otprecord_verification_token.py` (or equivalent for OTP)
   - All other `migrations/*.py` files across apps.
   Running `makemigrations` on a clean clone is OK if Railway is also empty; otherwise it's dangerous.

5. **App loading order in `settings.py` matters.** `accounts.apps.AccountsConfig` must appear **before** `rest_framework_simplejwt.token_blacklist` because the blacklist app needs the custom user model already registered. Do not reorder `INSTALLED_APPS`.

6. **The `OTPRecord` model uses `app_label = 'owners'`** to match Railway's content type (`owners.otprecord`). Do not change this without coordinating a content-type migration.

7. **Adding a new column to an existing table?** Prefer a follow-up migration (`makemigrations <app>`) over editing `models.py` and re-running — Railway will reject schema that already exists.

8. **For local dev, `db.sqlite3` is fine**, but the **shape of every model must remain Postgres-compatible** (avoid SQLite-only types, JSON quirks, etc.). `latitude`/`longitude` use `DecimalField` deliberately.

9. **Do not commit `backend/.env`** — it contains SMTP credentials and the Railway DB URL. Use `backend/.env.example` for the template.

10. **All responses are wrapped** as `{success, message, data}` for the auth/OTP endpoints. The Flutter `ApiService` reads this envelope. When adding a new endpoint that should follow this convention, wrap it; otherwise return DRF defaults and read with `RawApiResponse` on the client.

---

## 8. Frontend conventions

### Adding a new screen
1. Create the page under `lib/features/<feature>/presentation/pages/<name>.dart` (use `ConsumerWidget` for Riverpod, `StatelessWidget` otherwise).
2. Register the route in `lib/core/router/router.dart` (`GoRoute(path: '/your-path', builder: ...)`).
3. If the screen needs data, add a provider in `lib/features/<feature>/presentation/providers/`.
4. Navigate with `context.go('/path')` or `context.push('/path')`.

### Adding a new API endpoint
1. Backend: add a `path()` in the appropriate app's `urls.py`, a view in `views.py`, a serializer in `serializers.py`.
2. Frontend: add a method to `ApiService` (or extend it in a new `*_provider.dart`).
3. Wrap the response with `ApiResponse` (envelope) or use `RawApiResponse` for paginated lists.
4. Consume it from a Riverpod provider — never call `ApiService` directly inside a widget `build()`.

### State management
- Use **Riverpod 2** (`ConsumerWidget`, `Provider`, `FutureProvider`, `AsyncNotifier`).
- One provider per concern. Do not put business logic inside widgets.
- `LocationProvider` and `SearchProvider` are the reference implementations (search uses a 300 ms debounce).

### Styling
- Colors live in `lib/core/theme/colors.dart` — extend `AppColors` rather than hard-coding hex.
- Reusable widgets in `lib/shared/widgets/`. The currently shipped ones: `Loading`, `PremiumBottomNav`, `SubHeader`.

### API client cheat sheet
```dart
// Public POST (envelope response)
final r = await ApiService().post('/auth/login/', {'email': e, 'password': p});
if (r.success) {
  final access = r.data!['tokens']['access'];
  final refresh = r.data!['tokens']['refresh'];
  await ApiService().saveTokens(access, refresh);
}

// Authenticated GET (envelope)
final r = await ApiService().authGet('/auth/me/');

// Authenticated GET (raw / paginated)
final r = await ApiService().authGetRaw('/hostels/');
final List items = r.body['results'];

// Authenticated POST
final r = await ApiService().authPost('/hostels/create/', {...});
```

---

## 9. Auth flow (end-to-end)

1. **App opens** → `main.dart` → `ProviderScope` → `MaterialApp.router` → `appRouter` initial location `/home`.
2. **User taps "Sign up"** → `/signup` (`SignupPage`) → calls `POST /api/otp/send/`.
3. **User enters OTP** → `POST /api/otp/verify/` → backend marks `OTPRecord.is_used = True`.
4. **User submits registration form** → `POST /api/auth/register/`:
   - `RegisterSerializer.validate` confirms an `is_used=True` OTP record exists for that email.
   - Creates an `Owner` with `is_verified=True`, returns `{user, tokens}`.
5. **Tokens saved** to `SharedPreferences` via `ApiService.saveTokens`.
6. **Subsequent calls** use `authGet` / `authPost` / `authGetRaw` with `Authorization: Bearer <access>`.
7. **On 401**, `ApiService` automatically calls `/api/auth/token/refresh/`. If that also fails, tokens are cleared and the user is sent back to login.

> Login is rejected (HTTP 403) if `is_verified` is `False` — so the OTP step is mandatory.

---

## 10. Common operations

### Create a superuser
```bash
cd backend
python manage.py createsuperuser
```

### Reset / re-sync local DB
```bash
cd backend
python manage.py migrate
python manage.py loaddata fixtures/*.json   # if any
```

### Inspect Railway
Use the helper scripts in `backend/`:
- `python inspect_railway.py` — read-only DB inspection
- `python inspect_railway_full.py` — full schema dump
- `python audit_db.py` — table/column audit
- `python verify_signups.py` — list users and verification state

### Run lint
```bash
cd rohii_hostel_hunt
flutter analyze
```

### Format
```bash
cd rohii_hostel_hunt
dart format lib/
```

---

## 11. Things to avoid

- **Don't** introduce new packages without checking the existing `pubspec.yaml` — Riverpod + GoRouter + http + geolocator + share_plus + url_launcher is the intended stack. Firebase is **explicitly out** (see `pubspec.yaml` comment).
- **Don't** mix in GetX or Provider — they were intentionally removed in favor of Riverpod.
- **Don't** edit `Owner`/`OTPRecord`/initial migrations lightly.
- **Don't** add `print` debugging for long-term code; use `debugPrint` or the Flutter DevTools console.
- **Don't** commit secrets. `backend/.env` and any file containing SMTP/Gmail app passwords must stay local.
- **Don't** use the old `AGENTS.md` as the source of truth — `claude.md` is the canonical guide. (`AGENTS.md` describes an older GetX/Provider era; some references like `GetMaterialApp`, `GetX routes`, `SearchProvider` debounce, Firebase status are now stale.)
- **Don't** write to `lib/services/` (legacy folder) — use `lib/core/` and `lib/features/<x>/presentation/providers/`.

---

## 12. Quick file reference

| What | Where |
|---|---|
| App entry | `rohii_hostel_hunt/lib/main.dart` |
| Router | `rohii_hostel_hunt/lib/core/router/router.dart` |
| Theme | `rohii_hostel_hunt/lib/core/theme/{colors,notifiers,theme_provider}.dart` |
| HTTP client | `rohii_hostel_hunt/lib/core/network/api_service.dart` |
| Riverpod API providers | `rohii_hostel_hunt/lib/core/network/api_provider.dart` |
| Django settings | `backend/rohii_backend/settings.py` |
| Root URLs | `backend/rohii_backend/urls.py` |
| Custom user model | `backend/accounts/models.py` (`Owner`) |
| OTP model | `backend/otp_auth/models.py` (`OTPRecord`) |
| OTP service | `backend/otp_auth/services.py` (`OTPService`) |
| Hostel model | `backend/hostels/models.py` |
| Hostel filter | `backend/hostels/filters.py` (`HostelFilter`) |
| Booking model | `backend/bookings/models.py` |
| Auth serializers | `backend/accounts/serializers.py` |
| Auth views | `backend/accounts/views.py` |
| Auth URLs | `backend/accounts/urls.py` |
| OTP views | `backend/otp_auth/views.py` |

---

## 13. If something looks wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| `relation "owners" does not exist` | `label = 'owners'` removed from `accounts/apps.py` | Restore it (see §7 rule 1). |
| `AUTH_USER_MODEL refers to model 'owners.Owner' that has not been installed` | App order or label broken | Reorder `INSTALLED_APPS` so `accounts.apps.AccountsConfig` is first. |
| `migrate` crashes with "table already exists" | Tried to regenerate initial migrations | Restore the original `0001_initial.py` files. |
| Flutter app says "Session expired" on every call | Refresh token missing/expired | Re-login. Check that `LOGIN` returned both `access` and `refresh`. |
| OTP email never arrives | `EMAIL_HOST_PASSWORD` is wrong (must be a Gmail **App Password**, not the account password) | Regenerate at https://myaccount.google.com/apppasswords and update `.env`. |
| `Cannot connect to backend` from emulator | Wrong base URL | Android emulator must use `10.0.2.2:8000` (handled by `ApiService.baseUrl`). |
| 403 on login with "Email not verified" | OTP step was skipped | Hit `POST /api/otp/send/` then `POST /api/otp/verify/`, then re-register. |

---

## 14. tl;dr for new agents

1. Read this file. Then read `AGENTS.md` only to see the older GetX era — don't follow it blindly.
2. Frontend is Flutter + Riverpod + GoRouter; backend is Django REST + JWT + Railway Postgres.
3. All API calls go through `ApiService`. All routing goes through `appRouter`.
4. The `owners` app label and the `OTPRecord` `app_label = 'owners'` are sacred. Don't touch them.
5. New tables: model + serializer + view + URL + (if needed) Riverpod provider + GoRoute.
6. When in doubt about database changes: ask before acting — Railway is shared.

Happy hacking. 🏠
