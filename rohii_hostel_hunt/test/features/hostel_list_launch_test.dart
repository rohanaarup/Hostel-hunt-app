import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';

/// Launch with a saved location (finding X06).
///
/// Before the fix the saved city loaded asynchronously after the first request, the hostel list
/// rebuilt, and build() assigned `late final _api` a second time (LateInitializationError).
/// Wanted: the saved location is known before the first request, so the list is fetched once with
/// that location, and a late-arriving location can never put the list into an error state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_city': 'Hyderabad',
      'selected_locality': 'Kondapur',
    });
  });

  test('a saved location is loaded before the first list request: one call, with that location', () async {
    final prefs = await SharedPreferences.getInstance();
    final api = FakeApiService();
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(hostelListProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(hostelListProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(hostelListProvider);
    expect(state.hasError, isFalse, reason: 'the list ended in an error: ${state.error}');
    final listCalls = api.calls.where((c) => c == 'GET /hostels/').length;
    expect(listCalls, 1, reason: 'expected one list request at launch, saw $listCalls: ${api.calls}');
    expect(api.queries.single?['city'], 'Hyderabad');
    expect(api.queries.single?['locality'], 'Kondapur');
  });

  test('even when the saved location arrives late, the list never ends in an error', () async {
    final api = FakeApiService();
    final container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(api)], // no preloaded preferences
    );
    addTearDown(container.dispose);

    final subscription = container.listen(hostelListProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final state = container.read(hostelListProvider);
    expect(state.hasError, isFalse, reason: 'the list ended in an error: ${state.error}');
    expect(api.queries.last?['city'], 'Hyderabad');
  });
}
