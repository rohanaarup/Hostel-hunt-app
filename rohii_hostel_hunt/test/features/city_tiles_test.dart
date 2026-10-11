import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/pages/location.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/cities_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('city tiles draw Lucide icons: regular stroke when selected, light stroke otherwise', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_city': 'Hyderabad'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(FakeApiService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          citiesProvider.overrideWith(
            (ref) async => const [
              CityOption(id: '1', name: 'Hyderabad', slug: 'hyderabad'),
              CityOption(id: '2', name: 'Pune', slug: 'pune'),
              CityOption(id: '3', name: 'Somewhere New', slug: 'somewhere-new'),
            ],
          ),
        ],
        child: const MaterialApp(home: LocationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final tileIcons = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((i) => i.icon)
        .where((i) => i?.fontFamily == 'Lucide' || i?.fontFamily == 'Lucide200')
        .toList();

    expect(tileIcons, [
      LucideIcons.castle, // Hyderabad is the saved city: regular stroke
      LucideIcons.graduationCap200, // Pune: light stroke
      LucideIcons.mapPin200, // a city with no dedicated icon gets the map pin, not a crash
    ]);
  });
}
