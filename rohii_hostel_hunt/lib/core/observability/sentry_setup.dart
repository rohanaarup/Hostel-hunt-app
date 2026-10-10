import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'error_reporter.dart';
import 'global_error_handlers.dart';
import 'privacy.dart';

// Supplied at build/run time, never committed:
//   --dart-define=SENTRY_DSN=...          (empty = Sentry is off)
//   --dart-define=SENTRY_ENVIRONMENT=...  (default: production for release builds)
//   --dart-define=SENTRY_RELEASE=...      (e.g. the git short hash)
//   --dart-define=SENTRY_TEST_ERROR=true  (throws one synthetic error 2 s after start)
const String _dsn = String.fromEnvironment('SENTRY_DSN');
const String _environment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: kReleaseMode ? 'production' : 'development',
);
const String _release = String.fromEnvironment('SENTRY_RELEASE');
const bool _testError = bool.fromEnvironment('SENTRY_TEST_ERROR');

/// Starts error reporting, installs the global handlers, then runs the app.
Future<void> bootstrapObservability(FutureOr<void> Function() runApp) async {
  ErrorReporter reporter = const NoopErrorReporter();
  if (_dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) => configureSentryOptions(
        options,
        dsn: _dsn,
        environment: _environment,
        release: _release,
      ),
    );
    reporter = SentryErrorReporter();
  }
  errorReporter = reporter;
  // After Sentry's own integrations, so ours are the only handlers (no duplicates).
  installGlobalErrorHandlers(reporter);

  await runApp();

  if (_testError) {
    if (_dsn.isNotEmpty) {
      Sentry.configureScope((scope) => scope.setTag('synthetic', 'true'));
    }
    Timer(const Duration(seconds: 2), throwSyntheticTestError);
  }
}

/// Throws the error used to prove the reporting pipeline end to end. Reached
/// only with --dart-define=SENTRY_TEST_ERROR=true; the uncaught error lands in
/// the global handler like any real async failure.
Never throwSyntheticTestError() {
  throw StateError('Sentry test error (synthetic, safe to ignore)');
}

/// Privacy-first Sentry options: no PII, no screenshots, no automatic
/// breadcrumbs (route names and taps can carry ids), no tracing.
void configureSentryOptions(
  SentryFlutterOptions options, {
  required String dsn,
  required String environment,
  String release = '',
}) {
  options.dsn = dsn;
  options.environment = environment;
  if (release.isNotEmpty) options.release = release;

  options.sendDefaultPii = false;
  options.attachScreenshot = false;
  options.tracesSampleRate = 0;

  options.enableAutoNativeBreadcrumbs = false;
  options.enableUserInteractionBreadcrumbs = false;
  options.enableUserInteractionTracing = false;
  options.enableAppLifecycleBreadcrumbs = false;
  options.enableWindowMetricBreadcrumbs = false;
  options.enableBrightnessChangeBreadcrumbs = false;
  options.enableTextScaleChangeBreadcrumbs = false;
  options.maxBreadcrumbs = 50;

  options.beforeSend = scrubEvent;
  options.beforeBreadcrumb = scrubBreadcrumb;
}

SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
  final message = event.message;
  final template = message?.template;
  return event.copyWith(
    message: message?.copyWith(
      formatted: scrubText(message.formatted),
      template: template == null ? null : scrubText(template),
      params: message.params
          ?.map((p) => p is String ? scrubText(p) : p)
          .toList(),
    ),
    exceptions: event.exceptions
        ?.map(
          (e) => e.value == null ? e : e.copyWith(value: scrubText(e.value!)),
        )
        .toList(),
    breadcrumbs: event.breadcrumbs
        ?.map((b) => scrubBreadcrumb(b, Hint()) ?? b)
        .toList(),
  );
}

Breadcrumb? scrubBreadcrumb(Breadcrumb? crumb, Hint hint) {
  if (crumb == null) return null;
  final data = crumb.data;
  return crumb.copyWith(
    message: crumb.message == null ? null : scrubText(crumb.message!),
    data: data == null
        ? null
        : {
            for (final entry in data.entries)
              entry.key: isSensitiveKey(entry.key)
                  ? '[Filtered]'
                  : (entry.value is String
                        ? scrubText(entry.value as String)
                        : entry.value),
          },
  );
}

class SentryErrorReporter implements ErrorReporter {
  @override
  void report(Object error, StackTrace? stack, {String? hint}) {
    unawaited(
      Sentry.captureException(
        error,
        stackTrace: stack,
        hint: hint == null ? null : Hint.withMap({'source': hint}),
      ),
    );
  }

  @override
  void breadcrumb({
    required String category,
    required String message,
    Map<String, Object?>? data,
  }) {
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: category,
          message: message,
          data: data == null ? null : Map<String, dynamic>.of(data),
          level: SentryLevel.warning,
        ),
      ),
    );
  }
}
