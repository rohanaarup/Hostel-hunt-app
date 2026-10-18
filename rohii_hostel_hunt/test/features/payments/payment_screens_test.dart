import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/payments/data/payment_status_poller.dart';
import 'package:rohii_hostel_hunt/features/payments/data/pending_payment_store.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_confirming_screen.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_screen.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_service.dart';

RawApiResponse _status(String value) =>
    RawApiResponse(success: true, message: '', body: {'payment_id': 'pay-1', 'status': value}, statusCode: 200);

/// A poller whose clock moves only when it waits: the 75 s budget runs out instantly.
PaymentStatusPoller _fastPoller(FakeApiService api) {
  var time = DateTime(2026, 1, 1);
  return PaymentStatusPoller(
    check: (id) async {
      final res = await api.authGetRaw('/payments/status/$id/');
      return res.statusCode == 200 && res.body is Map ? (res.body as Map)['status'] as String? : null;
    },
    wait: (d) async => time = time.add(d),
    now: () => time,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeApiService api;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    api = FakeApiService()..loggedIn = true;
    container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });
  tearDown(() => container.dispose());

  Widget app(Widget home) => UncontrolledProviderScope(container: container, child: MaterialApp(home: home));

  /// Opens [screen] on top of a plain page and records what it pops with.
  Future<ValueNotifier<bool?>> open(WidgetTester tester, Widget screen) async {
    final popped = ValueNotifier<bool?>(null);
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => popped.value = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen)),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    return popped;
  }

  testWidgets('polling never has two requests in flight (slow network, 12 s)', (tester) async {
    var inFlight = 0, most = 0;
    api.onAuthGetRaw = (path) {
      inFlight++;
      if (inFlight > most) most = inFlight;
      return Completer<RawApiResponse>().future; // no answer ever comes
    };
    await tester.pumpWidget(app(const PaymentConfirmingScreen(paymentId: 'pay-1')));
    await tester.pump(const Duration(seconds: 12));
    expect(most, 1, reason: 'the next question waits for the previous answer');
    expect(find.text('Waiting for your payment to confirm...'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // leave: the poller sees it is cancelled
  });

  testWidgets('SUCCESS from the server shows the success screen and forgets the pending note', (tester) async {
    await tester.runAsync(() => container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'b1'));
    api.onAuthGetRaw = (path) async => _status('SUCCESS');
    await tester.pumpWidget(app(PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api))));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PaymentSuccessScreen), findsOneWidget);
    expect(container.read(pendingPaymentProvider), isNull);
  });

  testWidgets('FAILED shows Payment Failed; Try Again checks the status first, then offers a new order', (tester) async {
    await tester.runAsync(() => container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'b1'));
    api.onAuthGetRaw = (path) async => _status('FAILED');
    final popped = await open(tester, PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api)));
    expect(find.text('Payment Failed'), findsOneWidget);
    expect(container.read(pendingPaymentProvider), isNull);

    final before = api.calls.length;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(api.calls.length, greaterThan(before), reason: 'Try Again asked the server before closing');
    expect(popped.value, isTrue, reason: 'only a payment the server calls FAILED lets a new order start');
  });

  testWidgets('Try Again on a payment that turned out SUCCESS goes to success, not to a second order', (tester) async {
    var answers = ['PENDING'];
    api.onAuthGetRaw = (path) async => _status(answers.first);
    final popped = await open(tester, PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api)));
    expect(find.text('Still Waiting'), findsOneWidget);

    answers = ['SUCCESS'];
    await tester.tap(find.text('Check Again'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PaymentSuccessScreen), findsOneWidget);
    expect(popped.value, isNull);
  });

  testWidgets('Check Again while the payment is still open keeps the student here and says not to pay again', (tester) async {
    api.onAuthGetRaw = (path) async => _status('PENDING');
    final popped = await open(tester, PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api)));
    expect(find.text('Still Waiting'), findsOneWidget);

    await tester.tap(find.text('Check Again'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('do not pay again'), findsOneWidget);
    expect(find.byType(PaymentConfirmingScreen), findsOneWidget);
    expect(popped.value, isNull, reason: 'no new order may start while the first one is undecided');
  });

  testWidgets('"Check later" leaves without a new order and keeps the pending note', (tester) async {
    await tester.runAsync(() => container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'b1'));
    api.onAuthGetRaw = (path) async => _status('PENDING');
    final popped = await open(tester, PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api)));
    await tester.tap(find.text('Check later'));
    await tester.pumpAndSettle();
    expect(popped.value, isFalse);
    expect(container.read(pendingPaymentProvider)?.paymentId, 'pay-1');
  });

  testWidgets('a server that cannot be reached is "still waiting", never "failed"', (tester) async {
    api.onAuthGetRaw = (path) async => RawApiResponse.fromError(ApiError.offline);
    await open(tester, PaymentConfirmingScreen(paymentId: 'pay-1', poller: _fastPoller(api)));
    expect(find.text('Still Waiting'), findsOneWidget);
    expect(find.text('Payment Failed'), findsNothing);
  });

  group('opening the payment screen after the app was killed mid-payment', () {
    Future<void> remember() async {
      await container.read(pendingPaymentProvider.notifier).mark(paymentId: 'pay-1', bookingId: 'book-1');
    }

    void serveOrders() {
      api.onAuthPostRaw = (path, body) async => RawApiResponse(
            success: true,
            message: '',
            body: {'payment_id': 'pay-2', 'amount': '5000'},
            statusCode: 201,
          );
    }

    testWidgets('a payment the server says is SUCCESS: no new order, success screen', (tester) async {
      await tester.runAsync(remember);
      serveOrders();
      api.onAuthGetRaw = (path) async => _status('SUCCESS');
      await tester.pumpWidget(app(const PaymentScreen(bookingId: 'book-1')));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PaymentSuccessScreen), findsOneWidget);
      expect(api.calls.where((c) => c.contains('create-order')), isEmpty);
      expect(container.read(pendingPaymentProvider), isNull);
    });

    testWidgets('a payment still open: no new order, the status screen watches the first one', (tester) async {
      await tester.runAsync(remember);
      serveOrders();
      api.onAuthGetRaw = (path) async => _status('PENDING');
      await tester.pumpWidget(app(const PaymentScreen(bookingId: 'book-1')));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PaymentConfirmingScreen), findsOneWidget);
      expect(api.calls.where((c) => c.contains('create-order')), isEmpty,
          reason: 'a second order while the first may still complete could charge the student twice');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3)); // the poller's last pause ends; it sees the screen is gone
    });

    testWidgets('a payment the server says FAILED: the old note is dropped and a fresh order is created', (tester) async {
      await tester.runAsync(remember);
      serveOrders();
      api.onAuthGetRaw = (path) async => _status('FAILED');
      await tester.pumpWidget(app(const PaymentScreen(bookingId: 'book-1')));
      await tester.pump();
      await tester.pump();
      expect(api.calls.where((c) => c.contains('create-order')), hasLength(1));
      expect(container.read(pendingPaymentProvider), isNull);
    });

    testWidgets('a note for ANOTHER booking does not stop this booking from paying', (tester) async {
      await tester.runAsync(remember);
      serveOrders();
      await tester.pumpWidget(app(const PaymentScreen(bookingId: 'book-2')));
      await tester.pump();
      await tester.pump();
      expect(api.calls.where((c) => c.contains('create-order')), hasLength(1));
      expect(api.calls.where((c) => c.contains('/payments/status/')), isEmpty);
    });
  });
}
