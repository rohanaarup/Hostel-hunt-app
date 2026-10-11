import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/config/feature_flags.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/cities_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/search_riverpod_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';

Future<ProviderContainer> containerWith(FakeApiService api, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(
    overrides: [
      apiServiceProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('search stays inside the selected location', () {
    test('it sends the city and locality with the search text', () async {
      final api = FakeApiService();
      final container = await containerWith(
        api,
        prefs: {'selected_city': 'Hyderabad', 'selected_locality': 'Kondapur'},
      );

      container.read(searchProvider.notifier).searchForTerm('boys');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(api.queries.last?['search'], 'boys');
      expect(api.queries.last?['city'], 'Hyderabad');
      expect(api.queries.last?['locality'], 'Kondapur');
      expect(container.read(searchProvider).results, isNotEmpty);
    });

    test('with only a city selected it sends the city and no locality', () async {
      final api = FakeApiService();
      final container = await containerWith(api, prefs: {'selected_city': 'Hyderabad'});

      container.read(searchProvider.notifier).searchForTerm('boys');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(api.queries.last?['city'], 'Hyderabad');
      expect(api.queries.last?.containsKey('locality'), isFalse);
    });
  });

  group('cities come from the server', () {
    test('the list is read from /cities/', () async {
      final api = FakeApiService();
      api.onGetRaw = (path, query) => RawApiResponse(
            success: true,
            message: '',
            statusCode: 200,
            body: path == '/cities/'
                ? [
                    {'id': 'c1', 'name': 'Hyderabad', 'slug': 'hyderabad', 'state': 'Telangana', 'hostel_count': 5},
                    {'id': 'c2', 'name': 'Pune', 'slug': 'pune', 'state': 'Maharashtra', 'hostel_count': 1},
                  ]
                : [],
          );
      final container = await containerWith(api);

      final cities = await container.read(citiesProvider.future);

      expect(cities.map((c) => c.name), ['Hyderabad', 'Pune']);
      expect(cities.first.hostelCount, 5);
      expect(api.calls, contains('GET /cities/'));
    });

    test('a failed request is an error the screen can show, not an empty list', () async {
      final api = FakeApiService();
      api.onGetRaw = (path, query) =>
          const RawApiResponse(success: false, message: 'Server error.', statusCode: 500);
      final container = await containerWith(api);

      await expectLater(container.read(citiesProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('Auto Detect is behind a flag', () {
    test('it is off by default', () {
      expect(kEnableAutoDetect, isFalse);
    });

    test('the location screen only shows the row when the flag is on', () {
      final source = File('lib/features/location/presentation/pages/location.dart').readAsStringSync();
      expect(RegExp(r'if \(kEnableAutoDetect\)[\s\S]{0,200}_AutoDetectRow\(').hasMatch(source), isTrue);
    });

    test('the city grid is no longer a hard-coded list', () {
      final source = File('lib/features/location/presentation/pages/location.dart').readAsStringSync();
      expect(source.contains("_CityMeta('Mumbai'"), isFalse);
      expect(source.contains('citiesProvider'), isTrue);
    });
  });
}
