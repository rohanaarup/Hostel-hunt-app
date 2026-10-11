import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> hostelJson(String id, String name) => {
      'hostel_id': id,
      'name': name,
      'city': 'Hyderabad',
      'state': 'Telangana',
      'locality': 'Kondapur',
      'gender_type': 'boys',
      'price_from': 6000.0,
      'cover_image': 'https://example.test/$id.jpg',
      'amenities': ['wifi'],
    };

RawApiResponse page(List<Map<String, dynamic>> items, {String? next}) => RawApiResponse(
      success: true,
      message: '',
      statusCode: 200,
      body: {'count': 4, 'next': next, 'previous': null, 'results': items},
    );

/// Two pages that overlap on h3 (as happens when a hostel is added between requests).
FakeApiService twoPageApi() {
  final api = FakeApiService();
  api.onGetRaw = (path, query) {
    if (path != '/hostels/') return page([]);
    return query?['page'] == '2'
        ? page([hostelJson('h3', 'Three'), hostelJson('h4', 'Four')])
        : page(
            [hostelJson('h1', 'One'), hostelJson('h2', 'Two'), hostelJson('h3', 'Three')],
            next: 'https://api.example.test/api/v1/hostels/?page=2&page_size=20',
          );
  };
  return api;
}

Future<ProviderContainer> launch(FakeApiService api) async {
  SharedPreferences.setMockInitialValues({'selected_city': 'Hyderabad'});
  final prefs = await SharedPreferences.getInstance();
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
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first page loads and says there is more', () async {
    final container = await launch(twoPageApi());

    expect(container.read(hostelListProvider).value!.map((h) => h.name), ['One', 'Two', 'Three']);
    expect(container.read(hostelPagingProvider).hasMore, isTrue);
  });

  test('loading more appends the next page without duplicates', () async {
    final api = twoPageApi();
    final container = await launch(api);

    await container.read(hostelListProvider.notifier).loadMore();

    final names = container.read(hostelListProvider).value!.map((h) => h.name).toList();
    expect(names, ['One', 'Two', 'Three', 'Four']);
    expect(container.read(hostelPagingProvider).hasMore, isFalse);
    expect(api.queries.last?['page'], '2');
    expect(api.queries.last?['city'], 'Hyderabad');
  });

  test('once the last page is loaded, loadMore does nothing', () async {
    final api = twoPageApi();
    final container = await launch(api);
    final notifier = container.read(hostelListProvider.notifier);

    await notifier.loadMore();
    final callsAfterLastPage = api.calls.length;
    await notifier.loadMore();
    await notifier.loadMore();

    expect(api.calls.length, callsAfterLastPage);
  });

  test('two loadMore calls at once fetch the page only once', () async {
    final api = twoPageApi();
    final container = await launch(api);
    final notifier = container.read(hostelListProvider.notifier);

    await Future.wait([notifier.loadMore(), notifier.loadMore()]);

    expect(api.queries.where((q) => q?['page'] == '2').length, 1);
  });

  test('changing the location starts again from page one', () async {
    final api = twoPageApi();
    final container = await launch(api);
    await container.read(hostelListProvider.notifier).loadMore();

    // pick a locality: the list reloads from the first page
    container.read(locationProvider.notifier).setCityAndLocality('Hyderabad', 'Kondapur');
    await container.read(hostelListProvider.future);

    final names = container.read(hostelListProvider).value!.map((h) => h.name).toList();
    expect(names, ['One', 'Two', 'Three']);
    expect(api.queries.last?['locality'], 'Kondapur');
    expect(api.queries.last?['page'], isNot('2'));
  });
}
