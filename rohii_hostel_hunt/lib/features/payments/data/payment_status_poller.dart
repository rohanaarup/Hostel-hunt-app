/// How a payment ended, as far as the server has said.
enum PaymentOutcome {
  /// The server confirmed the money.
  success,

  /// The server closed the payment without taking money (failed, lapsed or refunded).
  failed,

  /// The server has not decided, or could not be reached.
  undecided,
}

/// Asks the server for one payment's status. Returns the status word (CREATED, PENDING, SUCCESS,
/// FAILED, REFUNDED), or null when the server could not be asked or gave no usable answer.
typedef PaymentStatusCheck = Future<String?> Function(String paymentId);

/// Waits for the server to decide a payment, ONE question at a time.
///
/// The next question is only asked after the previous answer (or failure) has arrived, so two checks
/// are never in flight, however slow the network is. (A timer that fires every 2.5 seconds does not
/// give that: on a slow connection the checks pile up, each one holding a connection and waking the
/// radio.) The wait is a time budget, not a count of questions, so a slow answer uses it up too.
class PaymentStatusPoller {
  PaymentStatusPoller({
    required this.check,
    this.interval = const Duration(milliseconds: 2500),
    this.budget = const Duration(seconds: 75),
    Future<void> Function(Duration)? wait,
    DateTime Function()? now,
  })  : _wait = wait ?? Future<void>.delayed,
        _now = now ?? DateTime.now;

  final PaymentStatusCheck check;
  final Duration interval;
  final Duration budget;
  final Future<void> Function(Duration) _wait;
  final DateTime Function() _now;

  /// SUCCESS and FAILED are the only words that end the wait; a refund also ends it (not paid).
  static PaymentOutcome outcomeOf(String? status) {
    switch (status) {
      case 'SUCCESS':
        return PaymentOutcome.success;
      case 'FAILED':
      case 'REFUNDED':
        return PaymentOutcome.failed;
      default:
        return PaymentOutcome.undecided;
    }
  }

  /// One question, one answer. A check that throws counts as "could not ask".
  Future<PaymentOutcome> checkOnce(String paymentId) async {
    try {
      return outcomeOf(await check(paymentId));
    } on Exception {
      return PaymentOutcome.undecided;
    }
  }

  /// Keeps asking until the server decides, [budget] has passed, or [isCancelled] turns true.
  Future<PaymentOutcome> run(String paymentId, {bool Function()? isCancelled}) async {
    final started = _now();
    while (true) {
      final outcome = await checkOnce(paymentId);
      if (outcome != PaymentOutcome.undecided) return outcome;
      if (isCancelled?.call() ?? false) return PaymentOutcome.undecided;
      if (_now().difference(started) >= budget) return PaymentOutcome.undecided;
      await _wait(interval);
      if (isCancelled?.call() ?? false) return PaymentOutcome.undecided;
    }
  }
}
