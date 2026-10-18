import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/features/payments/data/payment_status_poller.dart';

/// A clock that only moves when the poller waits or a (slow) check takes time.
class _Clock {
  DateTime time = DateTime(2026, 1, 1);
  final List<Duration> waits = [];
  DateTime now() => time;
  Future<void> wait(Duration d) async {
    waits.add(d);
    time = time.add(d);
  }
}

void main() {
  late _Clock clock;
  setUp(() => clock = _Clock());

  PaymentStatusPoller poller(PaymentStatusCheck check, {Duration budget = const Duration(seconds: 75)}) =>
      PaymentStatusPoller(check: check, budget: budget, wait: clock.wait, now: clock.now);

  test('only SUCCESS, FAILED and REFUNDED end the wait', () {
    expect(PaymentStatusPoller.outcomeOf('SUCCESS'), PaymentOutcome.success);
    expect(PaymentStatusPoller.outcomeOf('FAILED'), PaymentOutcome.failed);
    expect(PaymentStatusPoller.outcomeOf('REFUNDED'), PaymentOutcome.failed);
    for (final open in ['CREATED', 'PENDING', 'SOMETHING_NEW', null]) {
      expect(PaymentStatusPoller.outcomeOf(open), PaymentOutcome.undecided, reason: '$open');
    }
  });

  test('it stops as soon as the server says SUCCESS', () async {
    final answers = ['PENDING', 'PENDING', 'SUCCESS'];
    var asked = 0;
    final outcome = await poller((_) async => answers[asked++]).run('p1');
    expect(outcome, PaymentOutcome.success);
    expect(asked, 3);
  });

  test('it stops as soon as the server says FAILED', () async {
    final outcome = await poller((_) async => 'FAILED').run('p1');
    expect(outcome, PaymentOutcome.failed);
  });

  test('it never has two questions in flight, even when the network is slow', () async {
    var inFlight = 0, most = 0, asked = 0;
    final slow = poller((_) async {
      inFlight++;
      asked++;
      if (inFlight > most) most = inFlight;
      await Future<void>.delayed(Duration.zero);
      clock.time = clock.time.add(const Duration(seconds: 20)); // each answer takes 20 s
      inFlight--;
      return null; // never decided
    });
    await slow.run('p1');
    expect(most, 1);
    expect(asked, greaterThan(1));
  });

  test('the wait is bounded by time, so slow answers use the budget up too', () async {
    var asked = 0;
    final outcome = await poller((_) async {
      asked++;
      clock.time = clock.time.add(const Duration(seconds: 30));
      return 'PENDING';
    }).run('p1');
    expect(outcome, PaymentOutcome.undecided);
    // 30 s per answer plus 2.5 s pauses: about 3 questions fit in 75 s, never an endless loop.
    expect(asked, inInclusiveRange(2, 4));
  });

  test('with instant answers the budget allows about 30 questions 2.5 s apart', () async {
    var asked = 0;
    final outcome = await poller((_) async {
      asked++;
      return 'PENDING';
    }).run('p1');
    expect(outcome, PaymentOutcome.undecided);
    expect(asked, inInclusiveRange(29, 32));
    expect(clock.waits.every((w) => w == const Duration(milliseconds: 2500)), isTrue);
  });

  test('a check that throws counts as "could not ask" and the wait goes on', () async {
    var asked = 0;
    final outcome = await poller((_) async {
      asked++;
      if (asked < 3) throw Exception('connection reset');
      return 'SUCCESS';
    }).run('p1');
    expect(outcome, PaymentOutcome.success);
  });

  test('cancelling stops the questions', () async {
    var asked = 0;
    var cancelled = false;
    final outcome = await poller((_) async {
      asked++;
      if (asked == 2) cancelled = true;
      return 'PENDING';
    }).run('p1', isCancelled: () => cancelled);
    expect(outcome, PaymentOutcome.undecided);
    expect(asked, 2);
  });

  test('checkOnce asks exactly once and never waits', () async {
    var asked = 0;
    final outcome = await poller((_) async {
      asked++;
      return 'PENDING';
    }).checkOnce('p1');
    expect(outcome, PaymentOutcome.undecided);
    expect(asked, 1);
    expect(clock.waits, isEmpty);
  });
}
