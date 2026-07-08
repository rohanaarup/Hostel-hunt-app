import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/router/router.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
// Using Django JWT auth - no Firebase needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setUnauthorizedHandler(() {
    appRouter.go('/login');
  });
  runApp(const ProviderScope(child: MyApp()));
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
