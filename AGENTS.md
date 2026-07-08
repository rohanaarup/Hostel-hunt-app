# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**Hostel Hunt** — A Flutter mobile app for finding PG/hostel accommodations. The project has two distinct parts:

| Directory | Technology | Purpose |
|-----------|-----------|---------|
| `rohii_hostel_hunt/` | Flutter (Dart) | Mobile app frontend |
| `backend/` | Django (Python) | REST API backend |

## Commands

### Flutter App
```bash
cd rohii_hostel_hunt

# Run the app
flutter run

# Build debug APK
flutter build apk --debug

# Run on specific device
flutter run -d <device_id>
```

### Django Backend
```bash
cd backend

# Run migrations
python manage.py migrate

# Start development server (port 8000)
python manage.py runserver 0.0.0.0:8000

# Create superuser
python manage.py createsuperuser
```

## Architecture

### Frontend (Flutter)

**Entry point**: [main.dart](rohii_hostel_hunt/lib/main.dart)

**State Management**: Uses two approaches:
- **GetX** — Navigation and routing via `GetMaterialApp` and `GetPage` routes
- **Provider** — `ChangeNotifier` for app-wide state (`LocationProvider`, `SearchProvider`)
- **ValueNotifier** — Simple reactive state (theme toggle in `notifiers.dart`)

**Central API Client**: [api_service.dart](rohii_hostel_hunt/lib/services/api_service.dart)
- Singleton HTTP client using `package:http`
- Base URL: `http://10.0.2.2:8000/api` (Android emulator → host machine)
- Handles JWT token storage, injection, and automatic refresh on 401
- All API calls must go through this service

**Key Providers**:
- `LocationProvider` — GPS location detection, saved addresses
- `SearchProvider` — Real-time search with 300ms debounce

**Navigation**: GetX routes defined in `main.dart` `getPages` list. Routes: `/home`, `/login`, `/signup`, `/profile`, `/search`, `/location`, etc.

### Backend (Django)

**Settings**: [settings.py](backend/rohii_backend/settings.py)
- JWT auth via `rest_framework_simplejwt`
- Connected to **Railway Postgres** for production database (shared with Admin Panel).
- CORS enabled for all origins (`CORS_ALLOW_ALL_ORIGINS = True`)
- `AUTH_USER_MODEL = 'owners.Owner'` (Mapped to `owners` table using custom app label)

> [!CAUTION]
> ### CRITICAL DATABASE RULES FOR AI AGENTS
> The Flutter App backend is deeply synchronized with the Admin Panel's existing **Railway Postgres Database**. You must **NEVER** alter or blindly regenerate the following files, as doing so will break the database connection, crash migrations, or cause data loss:
> 
> 1. **`backend/accounts/apps.py`**: Contains `label = 'owners'`. This maps the `accounts` app to the `owners` database table. Removing this will break the entire backend.
> 2. **`backend/rohii_backend/settings.py`**: In `INSTALLED_APPS`, `accounts.apps.AccountsConfig` MUST appear *before* `rest_framework_simplejwt.token_blacklist` to prevent lazy reference resolution errors.
> 3. **`backend/accounts/models.py`**: The `Owner` model uses `owner_id` (UUID), `db_table = 'owners'`, and overrides M2M tables (`owners_groups`, `owners_user_permissions`). Do not change these column/table names or primary key types.
> 4. **All Migration Files (`backend/*/migrations/*.py`)**: The migration files (especially `owners/migrations/0001_initial.py` and `0002_otprecord_verification_token.py`) are carefully synced to match the `django_migrations` history in Railway. **DO NOT** delete them or run `makemigrations` to regenerate initial schemas, as running `migrate` will attempt to recreate tables that already exist in Railway and crash the system.

**Installed Apps**:
- `accounts` — User model, registration, login, logout
- `otp_auth` — OTP generation and email verification
- `hostels` — Hostel listings CRUD
- `bookings` — Booking management
- `reviews` — Hostel reviews and ratings

**API Authentication**: All protected endpoints require `Authorization: Bearer <access_token>` header. Access tokens expire in 1 day, refresh tokens in 30 days.

**Key Endpoints**:
```
POST /api/auth/register/    — Create account (requires OTP verified first)
POST /api/auth/login/       — Login, returns JWT tokens
POST /api/auth/logout/      — Blacklist refresh token
GET  /api/auth/me/          — Get authenticated user profile
POST /api/otp/send/         — Send OTP to email
POST /api/otp/verify/       — Verify OTP code
```

### Data Flow

```
Flutter App                          Django Backend
     │                                       │
     ├──► ApiService (HTTP client) ─────────►► Views (parse requests)
     │                                       │
     ├──► Provider/ChangeNotifier ◄───◄───► JSON Response
     │        (app state)                    
     │                                    
     └──► GetX Navigation ◄──────────► pages/
          (screen routing)                          
```

## Important Patterns

### Adding a New API Endpoint

1. Add URL to Django `urls.py` in the appropriate app
2. Add view function in `views.py`
3. In Flutter: add method to `ApiService` class (use `authGet` or `authPost`)
4. Call from UI via Provider or GetX controller

### Firebase Status

Firebase packages (`firebase_core`, `firebase_auth`, `cloud_firestore`) are declared in `pubspec.yaml` but **not actively used**. Firebase is initialized in `main.dart` but no Firebase Auth calls exist in the codebase. All auth flows currently use Django JWT.

### Hostel Data

The `Hostel` model in [hostel.dart](rohii_hostel_hunt/lib/models/hostel.dart) serves as the **single source of truth** for hostel data. It contains hardcoded `sampleHostels` list for development. Future integration will fetch from `/api/hostels/` endpoint.

## File Conventions

- Pages/screens go in `lib/pages/`
- Reusable widgets in `lib/widgets/`
- Business logic and state in `lib/services/`
- Data models in `lib/models/`
- Navigation utilities in `lib/utils/`
- Backend apps follow Django convention: `models.py`, `views.py`, `serializers.py`, `urls.py`, `services.py`
