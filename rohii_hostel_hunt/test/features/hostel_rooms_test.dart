import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/bed_selection_screen.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/room_provider.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body) => RawApiResponse(success: true, message: '', statusCode: 200, body: body);

RawApiResponse unavailable() => RawApiResponse.fromError(const ApiError(
      kind: ApiErrorKind.unavailable,
      statusCode: 503,
      message: 'The server is starting up. Please try again in a few seconds.',
    ));

Map<String, dynamic> room(int floor, String number, {String? id}) => {
      'room_id': id ?? 'r-$floor-$number',
      'hostel_id': 'h1',
      'room_name': 'Room $number',
      'floor_number': floor,
      'room_number': number,
      'sharing_type': 'double',
      'capacity': 2,
      'bed_count': 2,
      'available_beds': 2,
      'price_per_month': '6500.00',
      'is_ac': false,
      'has_attached_bathroom': false,
      'is_active': true,
    };

final detail = recorded('hostel_detail.json');
final hostelId = detail['hostel_id'] as String;

FakeApiService apiFor(Future<RawApiResponse> Function(String path, Map<String, String>? query) answer) =>
    _AsyncApi(answer);

/// A fake whose public GETs are answered by an async function (so a test can hold a reply back).
class _AsyncApi extends FakeApiService {
  _AsyncApi(this.answer);
  final Future<RawApiResponse> Function(String path, Map<String, String>? query) answer;

  @override
  Future<RawApiResponse> getRaw(String path, {Map<String, String>? queryParams}) {
    calls.add('GET $path');
    queries.add(queryParams);
    return answer(path, queryParams);
  }
}

ProviderContainer containerFor(FakeApiService api, {Duration? timeout}) {
  final container = ProviderContainer(overrides: [
    apiServiceProvider.overrideWithValue(api),
    if (timeout != null) roomsRequestTimeoutProvider.overrideWithValue(timeout),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the hostel model keeps what the detail reply carries', () {
    test('rooms come with the detail reply, and a list reply says it has none', () {
      final detailed = Hostel.fromJson(detail);
      final listed = Hostel.fromJson(const {'hostel_id': 'h1', 'name': 'From the list'});

      expect(detailed.roomsLoaded, isTrue);
      expect(detailed.rooms, hasLength(4));
      expect(detailed.rooms.first.roomId, isNotEmpty);
      expect(listed.roomsLoaded, isFalse);
    });

    test('merging a detail into a list hostel keeps its rooms and the fields that used to be dropped', () {
      final listed = Hostel.fromJson(const {'hostel_id': 'h1', 'name': 'From the list', 'city': 'Hyderabad'});
      final full = Hostel.fromJson({
        ...detail,
        'landmark': 'Near the lake',
        'rules': 'No smoking',
        'check_in_policy': 'After 10 am',
        'google_maps_url': 'https://maps.example.test/x',
      });

      final merged = listed.mergeWithDetail(full);

      expect(merged.rooms, hasLength(4));
      expect(merged.roomsLoaded, isTrue);
      expect((merged.landmark, merged.rules, merged.checkInPolicy), ('Near the lake', 'No smoking', 'After 10 am'));
      expect(merged.googleMapsUrl, 'https://maps.example.test/x');
    });
  });

  group('opening the detail', () {
    test('one request for the hostel and none for its rooms', () async {
      final api = apiFor((path, query) async => ok(detail));
      final container = containerFor(api);
      container.listen(hostelDetailProvider(hostelId), (_, _) {});

      final loaded = await container.read(hostelDetailProvider(hostelId).future);

      expect(api.calls, ['GET /hostels/$hostelId/']);
      expect(loaded.rooms, hasLength(4));
      expect(api.calls.where((c) => c.contains('/rooms/')), isEmpty);
    });

    test('an error says why, and leaving and coming back asks again (nothing stays cached)', () async {
      var attempts = 0;
      final api = apiFor((path, query) async => ++attempts == 1 ? unavailable() : ok(detail));
      final container = containerFor(api);

      final first = container.listen(hostelDetailProvider(hostelId), (_, _) {});
      await expectLater(container.read(hostelDetailProvider(hostelId).future), throwsA(isA<ApiException>()));
      expect(userMessageOf(container.read(hostelDetailProvider(hostelId)).error!),
          'The server is starting up. Please try again in a few seconds.');
      first.close();
      await Future<void>.delayed(Duration.zero);

      final again = await container.read(hostelDetailProvider(hostelId).future);

      expect(again.name, detail['name']);
      expect(attempts, 2);
    });

    test('a retry while the screen stays open works too', () async {
      var attempts = 0;
      final api = apiFor((path, query) async => ++attempts == 1 ? unavailable() : ok(detail));
      final container = containerFor(api);
      container.listen(hostelDetailProvider(hostelId), (_, _) {});
      await expectLater(container.read(hostelDetailProvider(hostelId).future), throwsA(isA<ApiException>()));

      container.invalidate(hostelDetailProvider(hostelId));

      expect((await container.read(hostelDetailProvider(hostelId).future)).rooms, hasLength(4));
    });
  });

  group('the rooms, when they have to be fetched', () {
    test('groups by floor, floors and rooms in order', () {
      final grouped = groupRoomsByFloor(
        [room(2, '201'), room(0, '002'), room(0, '001'), room(1, '101')].map(Room.fromJson).toList(),
      );

      expect(grouped.keys, [0, 1, 2]);
      expect(grouped[0]!.map((r) => r.roomNumber), ['001', '002']);
    });

    test('an error is not cached forever: closing the screen and opening it again asks again', () async {
      var attempts = 0;
      final api = apiFor((path, query) async => ++attempts == 1
          ? unavailable()
          : ok({'count': 1, 'next': null, 'previous': null, 'results': [room(0, '001')]}));
      final container = containerFor(api);

      final screen = container.listen(roomsProvider('h1'), (_, _) {});
      await expectLater(container.read(roomsProvider('h1').future), throwsA(isA<ApiException>()));
      screen.close(); // the person leaves the screen
      await Future<void>.delayed(Duration.zero);

      final rooms = await container.read(roomsProvider('h1').future);

      expect(rooms[0], hasLength(1));
      expect(attempts, 2);
    });

    test('the remaining pages are requested together, not one after another', () async {
      final gates = <String, Completer<RawApiResponse>>{};
      final requested = <String>[];
      final api = apiFor((path, query) {
        final page = query?['page'] ?? '1';
        requested.add(page);
        if (page == '1') {
          return Future.value(ok({'count': 25, 'next': 'x?page=2', 'previous': null, 'results': [for (var i = 0; i < 10; i++) room(0, 'A$i')]}));
        }
        return (gates[page] = Completer<RawApiResponse>()).future;
      });
      final container = containerFor(api);
      container.listen(roomsProvider('h1'), (_, _) {});
      final done = container.read(roomsProvider('h1').future);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(requested, containsAll(['1', '2', '3']), reason: 'page 3 must not wait for page 2');

      gates['2']!.complete(ok({'count': 25, 'next': 'x?page=3', 'previous': null, 'results': [for (var i = 0; i < 10; i++) room(1, 'B$i')]}));
      gates['3']!.complete(ok({'count': 25, 'next': null, 'previous': null, 'results': [for (var i = 0; i < 5; i++) room(2, 'C$i')]}));
      final rooms = await done;

      expect(rooms.keys, [0, 1, 2]);
      expect(rooms.values.expand((r) => r), hasLength(25));
    });

    test('a request that never answers ends in a timeout error instead of spinning forever', () async {
      final api = apiFor((path, query) => Completer<RawApiResponse>().future);
      final container = containerFor(api, timeout: const Duration(milliseconds: 40));
      container.listen(roomsProvider('h1'), (_, _) {});

      await expectLater(
        container.read(roomsProvider('h1').future),
        throwsA(isA<ApiException>().having((e) => e.error.kind, 'kind', ApiErrorKind.timeout)),
      );
    });
  });

  group('choosing a bed', () {
    Future<void> pumpBeds(WidgetTester tester, FakeApiService api, Hostel hostel) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: MaterialApp(home: BedSelectionScreen(hostel: hostel)),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('with the rooms already in the detail there is no second request', (tester) async {
      final api = apiFor((path, query) async => ok({'count': 0, 'next': null, 'previous': null, 'results': []}));

      await pumpBeds(tester, api, Hostel.fromJson(detail));

      expect(api.calls.where((c) => c.contains('/rooms/')), isEmpty);
      expect(find.text('Select Your Bed'), findsOneWidget);
      expect(find.textContaining('No rooms available'), findsNothing);
    });

    testWidgets('without them it fetches, shows the reason when that fails, and Retry works', (tester) async {
      var attempts = 0;
      final api = apiFor((path, query) async => ++attempts == 1
          ? unavailable()
          : ok({'count': 1, 'next': null, 'previous': null, 'results': [room(0, '001')]}));

      await pumpBeds(tester, api, Hostel.fromJson(const {'hostel_id': 'h1', 'name': 'From the list'}));
      expect(find.text('The server is starting up. Please try again in a few seconds.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('The server is starting up. Please try again in a few seconds.'), findsNothing);
      expect(attempts, 2);
    });
  });
}
