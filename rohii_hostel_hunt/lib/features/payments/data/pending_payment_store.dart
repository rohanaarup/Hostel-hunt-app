import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/observability/debug_log.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A payment the student may have paid but the app has not yet seen confirmed.
class PendingPayment {
  const PendingPayment({required this.paymentId, required this.bookingId, required this.startedAt});

  final String paymentId;
  final String bookingId;
  final DateTime startedAt;
}

/// Remembers the ONE payment in flight, on the phone's storage.
///
/// A student pays inside a UPI app or the card sheet, which puts Hostel Hunt in the background; the
/// phone may kill it there. Without this note the app wakes up knowing nothing about the payment and
/// the student, who may already have been charged, is offered a fresh "Pay Now". With it the app can
/// ask the server what happened to that payment before it does anything else.
///
/// Holds an id and nothing else: no amount, no card or UPI detail. It is written the moment the
/// student leaves for the UPI app or opens the card sheet, and removed as soon as the server says the
/// payment is over (paid or failed).
class PendingPaymentStore {
  PendingPaymentStore(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const String _key = 'pending_payment';

  /// A note older than this is dropped unread: the server's bed hold lasts 15 minutes, so a day-old
  /// note is a leftover, not a payment in flight.
  static const Duration maxAge = Duration(hours: 24);

  Future<PendingPayment> save({required String paymentId, required String bookingId}) async {
    final pending = PendingPayment(paymentId: paymentId, bookingId: bookingId, startedAt: _now());
    await _prefs.setString(
      _key,
      jsonEncode({'p': paymentId, 'b': bookingId, 't': pending.startedAt.millisecondsSinceEpoch}),
    );
    return pending;
  }

  PendingPayment? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map && map['p'] is String && map['b'] is String && map['t'] is num) {
        final startedAt = DateTime.fromMillisecondsSinceEpoch((map['t'] as num).toInt());
        if (_now().difference(startedAt) <= maxAge) {
          return PendingPayment(paymentId: map['p'] as String, bookingId: map['b'] as String, startedAt: startedAt);
        }
      }
    } on FormatException {
      debugLog('pending payment: note unreadable, dropping it');
    }
    _prefs.remove(_key);
    return null;
  }

  Future<void> clear() => _prefs.remove(_key);
}

/// Null in tests that do not provide SharedPreferences.
final pendingPaymentStoreProvider = Provider<PendingPaymentStore?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs == null ? null : PendingPaymentStore(prefs);
});

/// The payment in flight, for the screens that must not start a second one and for the banner that
/// takes the student back to the first.
class PendingPaymentNotifier extends Notifier<PendingPayment?> {
  @override
  PendingPayment? build() => ref.watch(pendingPaymentStoreProvider)?.load();

  Future<void> mark({required String paymentId, required String bookingId}) async {
    final store = ref.read(pendingPaymentStoreProvider);
    state = await store?.save(paymentId: paymentId, bookingId: bookingId) ??
        PendingPayment(paymentId: paymentId, bookingId: bookingId, startedAt: DateTime.now());
  }

  Future<void> clear() async {
    state = null;
    await ref.read(pendingPaymentStoreProvider)?.clear();
  }
}

final pendingPaymentProvider = NotifierProvider<PendingPaymentNotifier, PendingPayment?>(
  PendingPaymentNotifier.new,
);
