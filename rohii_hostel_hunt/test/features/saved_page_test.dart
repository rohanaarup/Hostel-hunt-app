import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/pages/saved_recent_pages.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/save_heart_actions.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body) => RawApiResponse(success: true, message: '', statusCode: 200, body: body);

/// Answers like the real backend, from the recorded responses, unless a test changes an answer.
FakeApiService backend({
  bool loggedIn = true,
  Future<RawApiResponse> Function(Map<String, String>? query)? wishlist,
}) {
  final api = FakeApiService()..loggedIn = loggedIn;
  api.onAuthGetRawWithQuery = (path, query) async {
    switch (path) {
      case '/auth/me/':
        return ok(recorded('auth_me.json'));
      case '/dashboard/student/stats/':
        return ok(recorded('student_stats.json'));
      case '/wishlist/ids/':
        return ok(recorded('wishlist_ids.json'));
      case '/wishlist/':
        return wishlist != null ? wishlist(query) : ok(recorded('wishlist_page.json'));
    }
    return const RawApiResponse(success: false, message: 'Not found.', statusCode: 404);
  };
  return api;
}

Future<void> pumpPage(WidgetTester tester, FakeApiService api, Widget page) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [apiServiceProvider.overrideWithValue(api)],
    child: MaterialApp(home: page),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('the Saved page', () {
    testWidgets('shows the hostels recorded from the real backend, and how many are saved', (tester) async {
      await pumpPage(tester, backend(), const SavedHostelsPage());

      expect(find.text('Lakeview Hostel'), findsOneWidget);
      expect(find.text('Sunrise PG'), findsOneWidget);
      expect(find.text('2 hostels saved'), findsOneWidget);
      expect(find.byKey(const Key('saved-remove')), findsNWidgets(2));
    });

    testWidgets('empty: says how to save one', (tester) async {
      final api = backend(wishlist: (_) async => ok({'count': 0, 'next': null, 'previous': null, 'wishlist': []}));
      await pumpPage(tester, api, const SavedHostelsPage());

      expect(find.text('No Saved Hostels'), findsOneWidget);
      expect(find.textContaining('Tap the heart icon'), findsOneWidget);
    });

    testWidgets('error: shows the reason and a Retry that works', (tester) async {
      var attempts = 0;
      final api = backend(wishlist: (_) async {
        attempts++;
        if (attempts == 1) {
          return RawApiResponse.fromError(const ApiError(
            kind: ApiErrorKind.unavailable,
            statusCode: 503,
            message: 'The server is starting up. Please try again in a few seconds.',
          ));
        }
        return ok(recorded('wishlist_page.json'));
      });
      await pumpPage(tester, api, const SavedHostelsPage());

      expect(find.text('The server is starting up. Please try again in a few seconds.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lakeview Hostel'), findsOneWidget);
    });

    testWidgets('not signed in: asks to log in, makes no list request', (tester) async {
      final api = backend(loggedIn: false);
      await pumpPage(tester, api, const SavedHostelsPage());

      expect(find.text('Log in to see your saved hostels'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(api.calls.where((c) => c.contains('/wishlist/')), isEmpty);
    });

    testWidgets('removing takes the card away at once and says so', (tester) async {
      final api = backend()..onAuthDeleteRaw = (path) async => ok({'deleted': true});
      await pumpPage(tester, api, const SavedHostelsPage());

      await tester.tap(find.byKey(const Key('saved-remove')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lakeview Hostel'), findsNothing);
      expect(find.text('Lakeview Hostel removed from saved'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a failed removal puts the card back and shows why', (tester) async {
      final api = backend()
        ..onAuthDeleteRaw = (path) async => RawApiResponse.fromError(ApiError.offline);
      await pumpPage(tester, api, const SavedHostelsPage());

      await tester.tap(find.byKey(const Key('saved-remove')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lakeview Hostel'), findsOneWidget);
      expect(find.text('No internet connection. Check your network and try again.'), findsOneWidget);
    });
  });

  group('a heart', () {
    Hostel hostel() => Hostel.fromJson({'hostel_id': 'h-new', 'name': 'New Hostel', 'city': 'Hyderabad'});

    // A one-heart host built the way the cards and the detail page build theirs.
    Widget host() => Consumer(builder: (context, ref, _) {
          final saved = ref.watch(isSavedProvider('h-new'));
          return Scaffold(
            body: Center(
              child: IconButton(
                key: const Key('heart'),
                icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                onPressed: () => onHeartTapped(context, ref, hostel()),
              ),
            ),
          );
        });

    testWidgets('fills at once when tapped and stays filled when the server agrees', (tester) async {
      final api = backend()
        ..onAuthPostRaw = (path, body) async => const RawApiResponse(
              success: true, message: '', statusCode: 201,
              body: {'id': 'r', 'hostel_id': 'h-new', 'created': true, 'saved': true});
      await pumpPage(tester, api, host());
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('heart')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('New Hostel saved'), findsOneWidget);
    });

    testWidgets('goes back to empty and shows the reason when the server refuses (the rollback)', (tester) async {
      final api = backend()
        ..onAuthPostRaw = (path, body) async => RawApiResponse.fromError(const ApiError(
              kind: ApiErrorKind.server,
              statusCode: 500,
              message: 'The server had a problem. Please try again in a moment.',
            ));
      await pumpPage(tester, api, host());

      await tester.tap(find.byKey(const Key('heart')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget, reason: 'the heart must not stay filled');
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.text('The server had a problem. Please try again in a moment.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('signed out: asks to log in instead of pretending to save', (tester) async {
      final api = backend(loggedIn: false);
      await pumpPage(tester, api, host());

      await tester.tap(find.byKey(const Key('heart')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in to save hostels'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('Log in to save hostels'), findsNothing);
    });
  });

  testWidgets('Recently Viewed no longer shows made-up hostels', (tester) async {
    await pumpPage(tester, backend(), const RecentActivityPage());

    expect(find.text('Coming soon'), findsWidgets);
    expect(find.textContaining('Today,'), findsNothing);
  });
}
