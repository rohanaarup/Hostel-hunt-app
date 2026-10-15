import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/search_riverpod_provider.dart';

import '../helpers/fake_api_service.dart';

RawApiResponse _page(String name) => RawApiResponse(
      success: true,
      message: '',
      statusCode: 200,
      body: {
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {'hostel_id': name, 'name': name, 'city': 'Hyderabad', 'state': 'Telangana', 'gender_type': 'boys'},
        ],
      },
    );

/// Answers the first search slowly and the second one fast, as a bad connection can.
class _SlowFirstApi extends FakeApiService {
  final first = Completer<RawApiResponse>();
  int searches = 0;

  @override
  Future<RawApiResponse> getRaw(String path, {Map<String, String>? queryParams}) async {
    searches++;
    if (searches == 1) return first.future;
    return _page('Newer Result');
  }
}

void main() {
  test('a slow reply for an older search never overwrites the newer results', () async {
    final api = _SlowFirstApi();
    final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    container.listen(searchProvider, (_, _) {});
    final search = container.read(searchProvider.notifier);

    search.searchForTerm('kond'); // slow
    search.searchForTerm('kondapur'); // fast, and newer
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(searchProvider).results.map((h) => h.name), ['Newer Result']);

    api.first.complete(_page('Older Result'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(container.read(searchProvider).results.map((h) => h.name), ['Newer Result']);
    expect(container.read(searchProvider).query, 'kondapur');
  });
}
