import 'package:flutter/foundation.dart';

import 'debug_log.dart';
import 'error_reporter.dart';

/// Sends every error that escapes the app to [reporter]: Flutter framework
/// errors (build, layout, gestures) and uncaught async errors.
///
/// Call this last during startup. It replaces any handlers installed earlier
/// (including Sentry's own), so each error is reported exactly once.
void installGlobalErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (FlutterErrorDetails details) {
    _safeReport(reporter, details.exception, details.stack, 'FlutterError');
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _safeReport(reporter, error, stack, 'PlatformDispatcher');
    return true; // handled: do not crash the app
  };
}

void _safeReport(
  ErrorReporter reporter,
  Object error,
  StackTrace? stack,
  String hint,
) {
  try {
    reporter.report(error, stack, hint: hint);
  } catch (e) {
    debugLog('error reporter failed: ${e.runtimeType}');
  }
}
