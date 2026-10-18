import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tells the UI when the server is slow to answer.
///
/// A sleeping Render instance takes 30 to 60 seconds to wake up. Without a word from the app that
/// looks like a frozen screen. [slow] turns true once any tracked request has been waiting longer
/// than [threshold], and back to false when none is. The app shell shows a banner while it is true.
class ApiActivity {
  const ApiActivity._();

  /// How long a request may wait before the app says the server is slow. Tests shorten it.
  static Duration threshold = const Duration(seconds: 5);

  static final ValueNotifier<bool> slow = ValueNotifier<bool>(false);

  static final Map<Object, Timer> _waiting = {};
  static final Set<Object> _late = {};

  /// A request is starting. Pass the returned token to [end] when it finishes, whatever the outcome.
  static Object start() {
    final token = Object();
    _waiting[token] = Timer(threshold, () {
      _waiting.remove(token);
      _late.add(token);
      slow.value = true;
    });
    return token;
  }

  static void end(Object token) {
    _waiting.remove(token)?.cancel();
    _late.remove(token);
    slow.value = _late.isNotEmpty;
  }

  /// Forget everything (tests).
  @visibleForTesting
  static void reset() {
    for (final timer in _waiting.values) {
      timer.cancel();
    }
    _waiting.clear();
    _late.clear();
    slow.value = false;
    threshold = const Duration(seconds: 5);
  }
}
