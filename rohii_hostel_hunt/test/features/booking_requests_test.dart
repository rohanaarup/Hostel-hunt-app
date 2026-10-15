import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/booking/domain/booking_request.dart';
import 'package:rohii_hostel_hunt/features/booking/presentation/pages/booking_requests_page.dart';
import 'package:rohii_hostel_hunt/features/booking/presentation/providers/my_bookings_provider.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body) => RawApiResponse(success: true, message: '', statusCode: 200, body: body);

Map<String, dynamic> booking(String id, String hostel, {String status = 'pending'}) => {
      'id': id,
      'hostel_name': hostel,
      'room_display': 'Room 1',
      'status': status,
      'amount': '6500.00',
      'payment_mode': 'offline',
      'created_at': '2026-10-01T10:00:00Z',
    };

Map<String, dynamic> page(List<Map<String, dynamic>> rows, {String? next, int? count}) =>
    {'count': count ?? rows.length, 'next': next, 'previous': null, 'results': rows};

FakeApiService backend(Future<RawApiResponse> Function(Map<String, String>? query) answer, {bool loggedIn = true}) {
  final api = FakeApiService()..loggedIn = loggedIn;
  api.onAuthGetRawWithQuery = (path, query) async {
    switch (path) {
      case '/bookings/my/':
        return answer(query);
      case '/auth/me/':
        return ok(recorded('auth_me.json'));
      case '/dashboard/student/stats/':
        return ok(recorded('student_stats.json'));
    }
    return const RawApiResponse(success: false, message: 'Not found.', statusCode: 404);
  };
  return api;
}

ProviderContainer containerFor(FakeApiService api) {
  final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  container.listen(myBookingsProvider, (_, _) {});
  return container;
}

void main() {
  group('the booking model', () {
    test('parses the response recorded from the real backend', () async {
      final api = backend((_) async => ok(recorded('bookings_my.json')));
      final bookings = await containerFor(api).read(myBookingsProvider.future);

      expect(bookings.map((b) => b.hostelName).toSet(), {'Sunrise PG', 'Lakeview Hostel'});
      final sunrise = bookings.firstWhere((b) => b.hostelName == 'Sunrise PG');
      expect(sunrise.status, BookingRequestStatus.pending);
      expect(sunrise.statusLabel, 'Pending');
      expect(sunrise.amountLabel, '₹6,500');
      expect(sunrise.roomLabel, 'Room 101');
      expect(sunrise.paymentMode, 'offline');
      expect(sunrise.submittedOn, matches(RegExp(r'^\d{1,2} [A-Z][a-z]{2} \d{4}$')));
      final lakeview = bookings.firstWhere((b) => b.hostelName == 'Lakeview Hostel');
      expect((lakeview.status, lakeview.statusLabel), (BookingRequestStatus.confirmed, 'Confirmed'));
    });

    test('every status the backend has gets a label; a new one does not crash', () {
      expect(
        ['pending', 'confirmed', 'paid', 'cancelled', 'rejected']
            .map((s) => BookingRequest.fromJson(booking('x', 'H', status: s)).statusLabel),
        ['Pending', 'Confirmed', 'Paid', 'Cancelled', 'Rejected'],
      );
      final odd = BookingRequest.fromJson(booking('x', 'H', status: 'on_hold'));
      expect((odd.status, odd.statusLabel), (BookingRequestStatus.unknown, 'On hold'));
    });

    test('amounts use Indian grouping and a missing amount says nothing', () {
      String label(Object? amount) => BookingRequest.fromJson({...booking('x', 'H'), 'amount': amount}).amountLabel;
      expect(label('150000.00'), '₹1,50,000');
      expect(label('900.00'), '₹900');
      expect(label(null), '');
    });

    test('a row with missing fields still parses', () {
      final b = BookingRequest.fromJson(const {'id': 'x'});
      expect((b.hostelName, b.roomLabel, b.submittedOn), ('Hostel', '', ''));
    });
  });

  group('the list', () {
    test('signed out: empty, and nothing is requested', () async {
      final api = backend((_) async => ok(page([])), loggedIn: false);

      expect(await containerFor(api).read(myBookingsProvider.future), isEmpty);
      expect(api.calls, isEmpty);
    });

    test('pages append without duplicates, once, and stop after the last page', () async {
      final seenPages = <String?>[];
      final api = backend((query) async {
        seenPages.add(query?['page']);
        return query?['page'] == '2'
            ? ok(page([booking('b2', 'Two'), booking('b3', 'Three')], count: 3))
            : ok(page([booking('b1', 'One'), booking('b2', 'Two')], next: 'https://x/api/v1/bookings/my/?page=2', count: 3));
      });
      final container = containerFor(api);
      await container.read(myBookingsProvider.future);

      await container.read(myBookingsProvider.notifier).loadMore();
      await container.read(myBookingsProvider.notifier).loadMore();

      expect(container.read(myBookingsProvider).value!.map((b) => b.hostelName), ['One', 'Two', 'Three']);
      expect(seenPages.where((p) => p == '2'), hasLength(1));
      expect(container.read(myBookingsPagingProvider).hasMore, isFalse);
    });

    test('an error carries its reason, and a retry works', () async {
      var attempts = 0;
      final api = backend((query) async => ++attempts == 1
          ? RawApiResponse.fromError(ApiError.offline)
          : ok(page([booking('b1', 'One')])));
      final container = containerFor(api);

      await expectLater(container.read(myBookingsProvider.future), throwsA(isA<ApiException>()));
      expect(userMessageOf(container.read(myBookingsProvider).error!),
          'No internet connection. Check your network and try again.');

      await container.read(myBookingsProvider.notifier).refresh();
      expect(container.read(myBookingsProvider).value!.single.hostelName, 'One');
    });
  });

  group('the page', () {
    Future<void> pump(WidgetTester tester, FakeApiService api) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: const MaterialApp(home: BookingRequestsPage()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('shows the real bookings with their status, and no buttons that do nothing', (tester) async {
      await pump(tester, backend((_) async => ok(recorded('bookings_my.json'))));

      expect(find.text('Sunrise PG'), findsOneWidget);
      expect(find.text('Lakeview Hostel'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('₹6,500'), findsOneWidget);
      expect(find.text('2 booking requests'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing, reason: 'there is no cancel route for students');
      expect(find.text('View Details'), findsNothing);
      expect(find.text('Sri Lakshmi Hostels'), findsNothing, reason: 'the made-up hostels are gone');
    });

    testWidgets('empty', (tester) async {
      await pump(tester, backend((_) async => ok(page([]))));

      expect(find.text('No booking requests yet'), findsOneWidget);
    });

    testWidgets('error: the reason and a Retry that works', (tester) async {
      var attempts = 0;
      final api = backend((query) async => ++attempts == 1
          ? RawApiResponse.fromError(const ApiError(
              kind: ApiErrorKind.unavailable,
              statusCode: 503,
              message: 'The server is starting up. Please try again in a few seconds.'))
          : ok(page([booking('b1', 'One')])));
      await pump(tester, api);
      expect(find.text('The server is starting up. Please try again in a few seconds.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('signed out: asks to log in and requests nothing', (tester) async {
      final api = backend((_) async => ok(page([])), loggedIn: false);
      await pump(tester, api);

      expect(find.text('Log in to see your booking requests'), findsOneWidget);
      expect(api.calls.where((c) => c.contains('/bookings/')), isEmpty);
    });
  });
}
