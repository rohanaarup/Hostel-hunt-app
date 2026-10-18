import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/cache/last_good_cache.dart';
import 'package:rohii_hostel_hunt/core/network/api_activity.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/core/widgets/connection_banners.dart';
import 'package:rohii_hostel_hunt/core/widgets/decode_size.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/widgets/hostel_cover_image.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/cities_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';

/// F6: a phone on a bad network. What the app shows when the network fails, how much memory a
/// picture takes, and the filter chips that must not blank the list.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeApiService api;
  late ProviderContainer container;

  Future<void> start([Map<String, Object> values = const {'selected_city': 'Hyderabad'}]) async {
    SharedPreferences.setMockInitialValues(values);
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    api = FakeApiService();
    container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    final subscription = container.listen(hostelListProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);
  }

  RawApiResponse offline() => RawApiResponse.fromError(ApiError.offline);

  group('chips', () {
    test('Non-AC and Premium filter the pages already loaded: no request, no blank list', () async {
      await start();
      final all = await container.read(hostelListProvider.future);
      expect(all, isNotEmpty);

      await container.read(hostelListProvider.notifier).applyFilter('Non-AC');
      await container.read(hostelListProvider.notifier).applyFilter('Premium');
      await container.read(hostelListProvider.notifier).applyFilter('All');

      expect(api.calls.where((c) => c == 'GET /hostels/'), hasLength(1));
      expect(container.read(hostelListProvider).value, hasLength(all.length));
    });

    test('Non-AC shows only hostels without AC', () async {
      await start();
      final all = await container.read(hostelListProvider.future);
      await container.read(hostelListProvider.notifier).applyFilter('Non-AC');
      final shown = container.read(hostelListProvider).value!;
      expect(shown.every((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac')), isTrue);
      expect(shown.length, all.where((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac')).length);
    });

    test('Boys is a server filter: it asks again, and the old list stays on screen meanwhile', () async {
      await start();
      await container.read(hostelListProvider.future);
      final pending = container.read(hostelListProvider.notifier).applyFilter('Boys');
      expect(container.read(hostelListProvider).isLoading, isTrue);
      expect(container.read(hostelListProvider).hasValue, isTrue, reason: 'the previous list is kept, not blanked');
      await pending;
      expect(api.calls.where((c) => c == 'GET /hostels/'), hasLength(2));
      expect(api.queries.last?['gender_type'], 'boys');
    });
  });

  group('last good copy', () {
    test('a good answer is saved; when the network then fails the saved list is shown, marked as saved', () async {
      await start();
      final fresh = await container.read(hostelListProvider.future);
      expect(container.read(hostelListFreshnessProvider), isNull);

      api.onGetRaw = (path, query) => offline();
      await container.read(hostelListProvider.notifier).refresh();

      final state = container.read(hostelListProvider);
      expect(state.hasError, isFalse);
      expect(state.value, hasLength(fresh.length));
      expect(container.read(hostelListFreshnessProvider), isNotNull, reason: 'the screen must say this is a saved copy');
    });

    test('a later good answer clears the saved-copy mark', () async {
      await start();
      await container.read(hostelListProvider.future);
      api.onGetRaw = (path, query) => offline();
      await container.read(hostelListProvider.notifier).refresh();
      expect(container.read(hostelListFreshnessProvider), isNotNull);

      api.onGetRaw = null;
      await container.read(hostelListProvider.notifier).refresh();
      expect(container.read(hostelListFreshnessProvider), isNull);
    });

    test('offline with nothing saved is an error with a message, not an empty list', () async {
      await start();
      await container.read(hostelListProvider.future);
      await container.read(lastGoodCacheProvider)!.clear(); // a phone that never had a good answer
      api.onGetRaw = (path, query) => offline();
      await container.read(hostelListProvider.notifier).refresh();
      final state = container.read(hostelListProvider);
      expect(state.hasError, isTrue);
      expect(userMessageOf(state.error!), isNotEmpty);
      expect(container.read(hostelListFreshnessProvider), isNull);
    });

    test('a server ERROR is never hidden behind the saved copy (only connection problems are)', () async {
      await start();
      await container.read(hostelListProvider.future);
      api.onGetRaw = (path, query) =>
          RawApiResponse.fromError(const ApiError(kind: ApiErrorKind.server, message: 'Something went wrong.', statusCode: 500));
      await container.read(hostelListProvider.notifier).refresh();
      expect(container.read(hostelListProvider).hasError, isTrue);
      expect(container.read(hostelListFreshnessProvider), isNull);
    });

    test('a saved copy is kept per city: another city never shows this one', () async {
      await start();
      await container.read(hostelListProvider.future);
      final cache = container.read(lastGoodCacheProvider)!;
      expect(cache.get('hostels:city=Hyderabad'), isNotNull);
      expect(cache.get('hostels:city=Pune'), isNull);
    });

    test('the cities list falls back to the saved one when the network fails', () async {
      await start();
      api.onGetRaw = (path, query) => path == '/cities/'
          ? RawApiResponse(success: true, message: '', statusCode: 200, body: [
              {'id': '1', 'name': 'Hyderabad', 'slug': 'hyderabad', 'hostel_count': 4}
            ])
          : offline();
      expect((await container.read(citiesProvider.future)).single.name, 'Hyderabad');

      container.invalidate(citiesProvider);
      api.onGetRaw = (path, query) => offline();
      expect((await container.read(citiesProvider.future)).single.name, 'Hyderabad');
    });
  });

  group('banners', () {
    tearDown(ApiActivity.reset);

    testWidgets('the waking banner appears while a request is slow and goes when it finishes', (tester) async {
      ApiActivity.threshold = const Duration(milliseconds: 50);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ServerWakingBanner())));
      expect(find.text(ServerWakingBanner.message), findsNothing);

      final token = ApiActivity.start();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text(ServerWakingBanner.message), findsOneWidget);

      ApiActivity.end(token);
      await tester.pump();
      expect(find.text(ServerWakingBanner.message), findsNothing);
    });

    testWidgets('a fast request never shows the banner', (tester) async {
      ApiActivity.threshold = const Duration(milliseconds: 200);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ServerWakingBanner())));
      final token = ApiActivity.start();
      await tester.pump(const Duration(milliseconds: 50));
      ApiActivity.end(token);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(ServerWakingBanner.message), findsNothing);
    });

    testWidgets('the saved-copy banner says how old the list is and offers Retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SavedCopyBanner(savedAt: DateTime.now().subtract(const Duration(hours: 3)), onRetry: () => retried++),
        ),
      ));
      expect(find.textContaining('saved 3 hours ago'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('pictures', () {
    testWidgets('a hostel cover is decoded at the size it is drawn, not at full size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: HostelCoverImage(source: 'https://res.cloudinary.com/x/image/upload/v1/a.jpg', width: 120, height: 90),
      ));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
    });

    testWidgets('decodeWidth follows the screen density and never goes past the cap', (tester) async {
      late int small, full, capped;
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1200, 2400); // 400 x 800 points
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          small = decodeWidth(context, 100);
          full = decodeWidth(context, double.infinity);
          capped = decodeWidth(context, double.infinity, max: 720);
          return const SizedBox();
        }),
      ));
      expect(small, 300);
      expect(full, 1080);
      expect(capped, 720);
    });

    test('every bundled picture is used, and no two are identical', () {
      final files = Directory('images').listSync(recursive: true).whereType<File>().toList();
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join('\n');
      final unused = [for (final f in files) if (!sources.contains(f.uri.pathSegments.last)) f.path];
      final identical = <String>[];
      for (var i = 0; i < files.length; i++) {
        for (var j = i + 1; j < files.length; j++) {
          if (files[i].lengthSync() == files[j].lengthSync() && _same(files[i], files[j])) {
            identical.add('${files[i].path} = ${files[j].path}');
          }
        }
      }
      expect(unused, isEmpty, reason: 'not referenced by any Dart file');
      expect(identical, isEmpty);
    });
  });
}

bool _same(File a, File b) {
  final x = a.readAsBytesSync(), y = b.readAsBytesSync();
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}
