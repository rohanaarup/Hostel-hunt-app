import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/payments/data/pending_payment_store.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/widgets/pending_payment_banner.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> freshPrefs([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    SharedPreferences.resetStatic();
    return SharedPreferences.getInstance();
  }

  group('PendingPaymentStore', () {
    test('a saved payment is found again after a simulated restart of the app', () async {
      var prefs = await freshPrefs();
      await PendingPaymentStore(prefs).save(paymentId: 'pay-1', bookingId: 'book-1');
      final onDisk = prefs.getString('pending_payment')!;

      // The process dies; the next start only has what is on disk.
      prefs = await freshPrefs({'pending_payment': onDisk});
      final found = PendingPaymentStore(prefs).load();
      expect(found, isNotNull);
      expect(found!.paymentId, 'pay-1');
      expect(found.bookingId, 'book-1');
    });

    test('it holds ids only: no amount, card or UPI detail', () async {
      final prefs = await freshPrefs();
      await PendingPaymentStore(prefs).save(paymentId: 'pay-1', bookingId: 'book-1');
      final map = jsonDecode(prefs.getString('pending_payment')!) as Map;
      expect(map.keys.toSet(), {'p', 'b', 't'});
    });

    test('clear forgets it', () async {
      final prefs = await freshPrefs();
      final store = PendingPaymentStore(prefs);
      await store.save(paymentId: 'pay-1', bookingId: 'book-1');
      await store.clear();
      expect(store.load(), isNull);
    });

    test('a note older than a day is dropped, an unreadable one too', () async {
      final prefs = await freshPrefs();
      var now = DateTime(2026, 1, 1, 12);
      final store = PendingPaymentStore(prefs, now: () => now);
      await store.save(paymentId: 'pay-1', bookingId: 'book-1');
      now = now.add(const Duration(hours: 23));
      expect(store.load(), isNotNull);
      now = now.add(const Duration(hours: 2));
      expect(store.load(), isNull);
      expect(prefs.containsKey('pending_payment'), isFalse);

      await prefs.setString('pending_payment', '{not json');
      expect(store.load(), isNull);
      expect(prefs.containsKey('pending_payment'), isFalse);
    });
  });

  group('pendingPaymentProvider', () {
    test('a new container (the app restarted) starts with the payment still in flight', () async {
      final prefs = await freshPrefs();
      final first = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      await first.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'book-1');
      expect(first.read(pendingPaymentProvider)?.paymentId, 'pay-1');
      first.dispose();

      final second = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(second.dispose);
      expect(second.read(pendingPaymentProvider)?.paymentId, 'pay-1');
      await second.read(pendingPaymentProvider.notifier).clear();
      expect(second.read(pendingPaymentProvider), isNull);
      expect(prefs.containsKey('pending_payment'), isFalse);
    });

    test('Log Out forgets the payment note along with the login', () async {
      final prefs = await freshPrefs();
      final api = FakeApiService()..loggedIn = true;
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      await container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'book-1');

      await container.read(userProvider.notifier).signOut();

      expect(api.tokensCleared, isTrue);
      expect(container.read(pendingPaymentProvider), isNull);
      expect(prefs.containsKey('pending_payment'), isFalse);
    });
  });

  group('PendingPaymentBanner', () {
    testWidgets('shows only while a payment is waiting to be confirmed', (tester) async {
      final prefs = await freshPrefs();
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(FakeApiService()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: PendingPaymentBanner())),
      ));
      expect(find.text('A payment is waiting to be confirmed.'), findsNothing);

      await tester.runAsync(() => container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'book-1'));
      await tester.pump();
      expect(find.text('A payment is waiting to be confirmed.'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);

      await tester.runAsync(() => container.read(pendingPaymentProvider.notifier).clear());
      await tester.pump();
      expect(find.text('A payment is waiting to be confirmed.'), findsNothing);
    });
  });
}
