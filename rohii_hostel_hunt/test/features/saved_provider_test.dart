import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body, {int status = 200}) =>
    RawApiResponse(success: true, message: '', statusCode: status, body: body);

RawApiResponse failure(String message, {int status = 500}) =>
    RawApiResponse.fromError(ApiError(kind: ApiErrorKind.server, statusCode: status, message: message));

final ids = (recorded('wishlist_ids.json')['ids'] as List).cast<String>();

class Rig {
  Rig(this.container, this.api);
  final ProviderContainer container;
  final FakeApiService api;
  SavedIdsNotifier get saved => container.read(savedIdsProvider.notifier);
  Set<String> get current => container.read(savedIdsProvider).value ?? {};
}

Future<Rig> rig({bool loggedIn = true, FakeApiService? api}) async {
  final fake = api ?? FakeApiService();
  fake.loggedIn = loggedIn;
  fake.onAuthGetRaw ??= (path) async => switch (path) {
        '/wishlist/ids/' => ok(recorded('wishlist_ids.json')),
        _ => failure('not found', status: 404),
      };
  final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(fake)]);
  addTearDown(container.dispose);
  container.listen(savedIdsProvider, (_, _) {});
  return Rig(container, fake);
}

void main() {
  const fresh = '11111111-1111-1111-1111-111111111111';

  group('loading the saved ids', () {
    test('once: many readers, one request', () async {
      final r = await rig();

      await r.container.read(savedIdsProvider.future);
      await r.container.read(savedIdsProvider.future);
      r.container.read(isSavedProvider(ids.first));

      expect(r.api.calls.where((c) => c == 'GET /wishlist/ids/ (auth)'), hasLength(1));
      expect(r.current, ids.toSet());
      expect(r.container.read(isSavedProvider(ids.first)), isTrue);
      expect(r.container.read(isSavedProvider(fresh)), isFalse);
    });

    test('someone who is not signed in has no saved hostels and no request is made', () async {
      final r = await rig(loggedIn: false);

      expect(await r.container.read(savedIdsProvider.future), isEmpty);
      expect(r.api.calls, isEmpty);
    });

    test('signing out forgets them', () async {
      final r = await rig();
      r.api.onAuthGetRaw = (path) async => switch (path) {
            '/wishlist/ids/' => ok(recorded('wishlist_ids.json')),
            '/auth/me/' => ok(recorded('auth_me.json')),
            '/dashboard/student/stats/' => ok(recorded('student_stats.json')),
            _ => failure('not found', status: 404),
          };
      await r.container.read(userProvider.future);
      await r.container.read(savedIdsProvider.future);
      expect(r.current, isNotEmpty);

      await r.container.read(userProvider.notifier).signOut();

      expect(await r.container.read(savedIdsProvider.future), isEmpty);
    });
  });

  group('tapping the heart', () {
    test('saving shows at once, before the server has answered, and keeps it on success', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      final answer = Completer<RawApiResponse>();
      r.api.onAuthPostRaw = (path, body) {
        expect(path, '/wishlist/');
        expect(body, {'hostel_id': fresh});
        return answer.future;
      };

      final outcome = r.saved.toggle(fresh);
      await Future<void>.delayed(Duration.zero);
      expect(r.current, contains(fresh), reason: 'the heart must fill without waiting for the network');

      answer.complete(ok({'id': 'row1', 'hostel_id': fresh, 'created': true, 'saved': true}, status: 201));
      final result = await outcome;

      expect(result.result, SaveResult.saved);
      expect(r.current, contains(fresh));
    });

    test('a failed save rolls back and carries the reason', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      r.api.onAuthPostRaw = (path, body) async => failure('The server had a problem. Please try again in a moment.');

      final outcome = await r.saved.toggle(fresh);

      expect(outcome.result, SaveResult.failed);
      expect(outcome.error?.message, 'The server had a problem. Please try again in a moment.');
      expect(r.current, isNot(contains(fresh)));
    });

    test('removing uses the by-hostel route, shows at once, and a failure puts it back', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      final saved = ids.first;
      final answer = Completer<RawApiResponse>();
      r.api.onAuthDeleteRaw = (path) {
        expect(path, '/wishlist/hostel/$saved/');
        return answer.future;
      };

      final outcome = r.saved.toggle(saved);
      await Future<void>.delayed(Duration.zero);
      expect(r.current, isNot(contains(saved)));

      answer.complete(failure('No internet connection. Check your network and try again.', status: 0));
      final result = await outcome;

      expect(result.result, SaveResult.failed);
      expect(r.current, contains(saved), reason: 'a failed removal must put the heart back');
    });

    test('a removal that works stays removed', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      r.api.onAuthDeleteRaw = (path) async => ok({'deleted': true});

      final outcome = await r.saved.toggle(ids.first);

      expect(outcome.result, SaveResult.removed);
      expect(r.current, isNot(contains(ids.first)));
    });

    test('a second tap while the first is still running is ignored (one request)', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      final answer = Completer<RawApiResponse>();
      r.api.onAuthPostRaw = (path, body) => answer.future;

      final first = r.saved.toggle(fresh);
      await Future<void>.delayed(Duration.zero);
      final second = await r.saved.toggle(fresh);
      answer.complete(ok({'id': 'row1', 'hostel_id': fresh, 'created': true, 'saved': true}, status: 201));
      await first;

      expect(second.result, SaveResult.ignored);
      expect(r.api.calls.where((c) => c == 'POST /wishlist/ (auth)'), hasLength(1));
    });

    test('when signed out it asks for a login and sends nothing', () async {
      final r = await rig(loggedIn: false);

      final outcome = await r.saved.toggle(fresh);

      expect(outcome.result, SaveResult.needsLogin);
      expect(r.api.calls, isEmpty);
    });

    test('one failure does not undo a different heart that worked', () async {
      final r = await rig();
      await r.container.read(savedIdsProvider.future);
      const other = '22222222-2222-2222-2222-222222222222';
      final bad = Completer<RawApiResponse>();
      r.api.onAuthPostRaw = (path, body) async {
        if (body['hostel_id'] == fresh) return bad.future;
        return ok({'id': 'row2', 'hostel_id': other, 'created': true, 'saved': true}, status: 201);
      };

      final a = r.saved.toggle(fresh);
      await Future<void>.delayed(Duration.zero);
      final b = await r.saved.toggle(other);
      bad.complete(failure('The server had a problem. Please try again in a moment.'));
      await a;

      expect(b.result, SaveResult.saved);
      expect(r.current, contains(other));
      expect(r.current, isNot(contains(fresh)));
    });

    test('if the saved ids never loaded, it tries again first and reports why it could not', () async {
      final api = FakeApiService()..loggedIn = true;
      api.onAuthGetRaw = (path) async => failure('The server is starting up. Please try again in a few seconds.', status: 503);
      final r = await rig(api: api);
      await expectLater(r.container.read(savedIdsProvider.future), throwsA(isA<ApiException>()));

      final outcome = await r.saved.toggle(fresh);

      expect(outcome.result, SaveResult.failed);
      expect(outcome.error?.message, 'The server is starting up. Please try again in a few seconds.');
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty, reason: 'never save blind');
    });
  });
}
