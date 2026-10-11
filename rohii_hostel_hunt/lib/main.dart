import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/observability/sentry_setup.dart';
import 'package:rohii_hostel_hunt/core/router/router.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Using Django JWT auth - no Firebase needed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setUnauthorizedHandler(() {
    appRouter.go('/login');
  });
  // Saved settings (selected city and locality) are loaded before the first screen builds, so the
  // hostel list is requested once, with the right location.
  final prefs = await SharedPreferences.getInstance();
  // Starts error reporting (if SENTRY_DSN is set), installs the global error
  // handlers, then runs the app.
  await bootstrapObservability(
    () => runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Hostel Hunt',
      debugShowCheckedModeBanner: false,
      theme: AppColors.lightTheme(),
      darkTheme: AppColors.darkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
