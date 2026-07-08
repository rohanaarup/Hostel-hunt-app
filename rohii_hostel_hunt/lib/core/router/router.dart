import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/features/support/presentation/pages/about_stuff.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/bed_selection_screen.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/pages/profile.dart';
import 'package:rohii_hostel_hunt/features/home/presentation/pages/homepage.dart';
import 'package:rohii_hostel_hunt/shared/widgets/loading.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/pages/location.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/login_page.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/pages/search.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/signup_page.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/pages/saved_recent_pages.dart';
import 'package:rohii_hostel_hunt/features/booking/presentation/pages/booking_requests_page.dart';
import 'package:rohii_hostel_hunt/features/settings/presentation/pages/preferences_page.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payments_page.dart';
import 'package:rohii_hostel_hunt/features/support/presentation/pages/support_page.dart';
import 'package:rohii_hostel_hunt/features/settings/presentation/pages/settings_page.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — GoRouter Configuration
/// ─────────────────────────────────────────────────────────
///
/// 1:1 mapping of all 17 GetPage routes from the original main.dart.
/// Every route path is identical to the original GetX setup.

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const Homepage(),
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => const Loading(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutStuff(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const Profile(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/profile/saved',
      builder: (context, state) => const SavedHostelsPage(),
    ),
    GoRoute(
      path: '/profile/recent',
      builder: (context, state) => const RecentActivityPage(),
    ),
    GoRoute(
      path: '/profile/bookings',
      builder: (context, state) => const BookingRequestsPage(),
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => const PreferencesPage(),
    ),
    GoRoute(
      path: '/profile/payments',
      builder: (context, state) => const PaymentsPage(),
    ),
    GoRoute(
      path: '/profile/support',
      builder: (context, state) => const SupportPage(),
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) => const AppSettingsPage(),
    ),
    GoRoute(
      path: '/bed-selection',
      builder: (context, state) => const BedSelectionScreen(),
    ),
  ],
);
