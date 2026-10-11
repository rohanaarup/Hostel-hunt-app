import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_api_service.dart';

/// Starts the real app (router, theme, providers) inside a ProviderScope with a fake API client and
/// checks the home screen builds and asks the API for hostels, without any exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the app starts and loads hostels through the API client', (
    tester,
  ) async {
    final api = FakeApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: const MyApp(),
      ),
    );
    // The home screen has endless animations, so settle with fixed pumps instead.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(api.calls, contains('GET /hostels/'));
  });
}
