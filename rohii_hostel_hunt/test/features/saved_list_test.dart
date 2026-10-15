import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body) => RawApiResponse(success: true, message: '', statusCode: 200, body: body);

Map<String, dynamic> row(String id, String name) => {
      'id': 'row-$id',
      'hostel_id': id,
      'name': name,
      'city': 'Hyderabad',
      'state': 'Telangana',
      'locality': 'Kondapur',
      'gender_type': 'boys',
      'price_from': 6500.0,
      'cover_image': 'https://example.test/$id.jpg',
      'amenities': ['wifi'],
    };

Map<String, dynamic> page(List<Map<String, dynamic>> rows, {String? next, int? count}) =>
    {'count': count ?? rows.length, 'next': next, 'previous': null, 'wishlist': rows};

({ProviderContainer container, FakeApiService api}) make(
  Future<RawApiResponse> Function(String path, Map<String, String>? query) listAnswer, {
  bool loggedIn = true,
}) {
  final api = FakeApiService()..loggedIn = loggedIn;
  api.onAuthGetRaw = (path) async => switch (path) {
        '/wishlist/ids/' => ok(recorded('wishlist_ids.json')),
        _ => const RawApiResponse(success: false, message: 'Not found.', statusCode: 404),
      };
  final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  container.listen(savedListProvider, (_, _) {});
  return (container: container, api: api);
}

void main() {
  group('the Saved page list', () {
    test('parses the response recorded from the real backend', () async {
      final api = FakeApiService()..loggedIn = true;
      api.onAuthGetRaw = (path) async => switch (path) {
            '/wishlist/' => ok(recorded('wishlist_page.json')),
            _ => const RawApiResponse(success: false, message: 'Not found.', statusCode: 404),
          };
      final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      container.listen(savedListProvider, (_, _) {});

      final hostels = await container.read(savedListProvider.future);

      expect(hostels.map((h) => h.name), ['Lakeview Hostel', 'Sunrise PG']);
      expect(hostels.first.pricePerMonth, 8000.0);
      expect(hostels.first.city, 'Hyderabad');
      expect(hostels.first.locality, 'Madhapur');
      expect(hostels.first.amenities, ['wifi', 'ac']);
      expect(hostels.every((h) => h.id.isNotEmpty), isTrue);
      expect(container.read(savedPagingProvider).hasMore, isFalse);
    });

    test('someone who is not signed in has an empty list and no request is made', () async {
      final r = make((_, _) async => ok(page([])), loggedIn: false);

      expect(await r.container.read(savedListProvider.future), isEmpty);
      expect(r.api.calls, isEmpty);
    });

    test('pages append without duplicates, asking for the next page by number', () async {
      final api = FakeApiService()..loggedIn = true;
      final queries = <Map<String, String>?>[];
      api.onAuthGetRawWithQuery = (path, query) async {
        queries.add(query);
        return query?['page'] == '2'
            ? ok(page([row('h2', 'Two'), row('h3', 'Three')], count: 3))
            : ok(page([row('h1', 'One'), row('h2', 'Two')], next: 'https://x/api/v1/wishlist/?page=2', count: 3));
      };
      final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      container.listen(savedListProvider, (_, _) {});
      await container.read(savedListProvider.future);
      expect(container.read(savedPagingProvider).hasMore, isTrue);

      await container.read(savedListProvider.notifier).loadMore();
      await container.read(savedListProvider.notifier).loadMore();

      expect(container.read(savedListProvider).value!.map((h) => h.name), ['One', 'Two', 'Three']);
      expect(container.read(savedPagingProvider).hasMore, isFalse);
      expect(queries.where((q) => q?['page'] == '2'), hasLength(1), reason: 'no request after the last page');
    });

    test('an error then a retry that works', () async {
      final api = FakeApiService()..loggedIn = true;
      var attempts = 0;
      api.onAuthGetRawWithQuery = (path, query) async {
        attempts++;
        if (attempts == 1) {
          return RawApiResponse.fromError(const ApiError(
            kind: ApiErrorKind.unavailable,
            statusCode: 503,
            message: 'The server is starting up. Please try again in a few seconds.',
          ));
        }
        return ok(page([row('h1', 'One')]));
      };
      final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      container.listen(savedListProvider, (_, _) {});

      await expectLater(container.read(savedListProvider.future), throwsA(isA<ApiException>()));
      expect(userMessageOf(container.read(savedListProvider).error!),
          'The server is starting up. Please try again in a few seconds.');

      await container.read(savedListProvider.notifier).refresh();

      expect(container.read(savedListProvider).value!.map((h) => h.name), ['One']);
    });

    test('removing takes the hostel off the list at once, and a failure puts it back in place', () async {
      final api = FakeApiService()..loggedIn = true;
      api.onAuthGetRawWithQuery = (path, query) async => path == '/wishlist/ids/'
          ? ok({'ids': ['h1', 'h2', 'h3'], 'count': 3})
          : ok(page([row('h1', 'One'), row('h2', 'Two'), row('h3', 'Three')]));
      final answer = Completer<RawApiResponse>();
      api.onAuthDeleteRaw = (path) => answer.future;
      final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      container.listen(savedListProvider, (_, _) {});
      container.listen(savedIdsProvider, (_, _) {});
      final hostels = await container.read(savedListProvider.future);
      await container.read(savedIdsProvider.future);

      final outcome = container.read(savedListProvider.notifier).remove(hostels[1]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(savedListProvider).value!.map((h) => h.name), ['One', 'Three']);

      answer.complete(RawApiResponse.fromError(ApiError.offline));
      final result = await outcome;

      expect(result.result, SaveResult.failed);
      expect(container.read(savedListProvider).value!.map((h) => h.name), ['One', 'Two', 'Three'],
          reason: 'back where it was');
      expect(container.read(savedIdsProvider).value, contains('h2'));
    });

    test('a removal that works leaves the list without it, and the heart elsewhere empty', () async {
      final api = FakeApiService()..loggedIn = true;
      api.onAuthGetRawWithQuery = (path, query) async => path == '/wishlist/ids/'
          ? ok({'ids': ['h1', 'h2'], 'count': 2})
          : ok(page([row('h1', 'One'), row('h2', 'Two')]));
      api.onAuthDeleteRaw = (path) async => ok({'deleted': true});
      final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      container.listen(savedListProvider, (_, _) {});
      container.listen(savedIdsProvider, (_, _) {});
      final hostels = await container.read(savedListProvider.future);
      await container.read(savedIdsProvider.future);

      final outcome = await container.read(savedListProvider.notifier).remove(hostels.first);

      expect(outcome.result, SaveResult.removed);
      expect(container.read(savedListProvider).value!.map((h) => h.name), ['Two']);
      expect(container.read(isSavedProvider('h1')), isFalse);
      expect(api.calls.where((c) => c == 'GET /wishlist/ (auth)'), hasLength(1), reason: 'the list is not reloaded');
    });
  });
}
