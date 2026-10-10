import 'debug_log.dart';

/// Where unexpected errors and API breadcrumbs go.
///
/// The app talks to this interface only. Production uses the Sentry-backed
/// implementation (see sentry_setup.dart); tests use a fake; with no DSN the
/// no-op reporter is used.
abstract class ErrorReporter {
  /// Report an error that was caught or that escaped to a global handler.
  void report(Object error, StackTrace? stack, {String? hint});

  /// Record a breadcrumb that is attached to the next reported error.
  /// Callers must never put personal data in [message] or [data].
  void breadcrumb({
    required String category,
    required String message,
    Map<String, Object?>? data,
  });
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  void report(Object error, StackTrace? stack, {String? hint}) {
    debugLog('[error] ${hint ?? 'unhandled'}: ${error.runtimeType}');
  }

  @override
  void breadcrumb({
    required String category,
    required String message,
    Map<String, Object?>? data,
  }) {}
}

/// The reporter in use. Replaced at startup by [bootstrapObservability] and in tests.
ErrorReporter errorReporter = const NoopErrorReporter();
