import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rohii_hostel_hunt/pages/about_stuff.dart';
import 'package:rohii_hostel_hunt/pages/contents_home_page/profile.dart';
import 'package:rohii_hostel_hunt/pages/loading.dart';
import 'package:rohii_hostel_hunt/pages/location.dart';
import 'package:rohii_hostel_hunt/pages/login_page.dart';
import 'package:rohii_hostel_hunt/pages/homepage.dart';
import 'package:rohii_hostel_hunt/pages/search.dart';
import 'package:rohii_hostel_hunt/pages/signup_page.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/services/location_provider.dart';
import 'package:rohii_hostel_hunt/services/notifiers.dart';
import 'package:rohii_hostel_hunt/services/search_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    /// ── Global providers ──
    /// Use MultiProvider so future providers (auth, cart, etc.) can be
    /// added here without restructuring.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        // Future providers go here:
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Hostel Hunt',
          debugShowCheckedModeBanner: false,
          theme: AppColors.lightTheme(),
          darkTheme: AppColors.darkTheme(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const Homepage(),
          routes: {
            '/loading': (context) => const Loading(),
            '/login': (context) => const LoginPage(),
            '/about': (context) => const AboutStuff(),
            '/home': (context) => const Homepage(),
            '/signup': (context) => const SignupPage(),
            '/profile': (context) => const Profile(),
            '/location': (context) => const LocationScreen(),
            '/search': (context) => const SearchPage(),
          },
        );
      },
    );
  }
}
