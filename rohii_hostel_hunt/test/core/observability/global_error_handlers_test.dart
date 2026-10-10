import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/observability/global_error_handlers.dart';

import '../../helpers/fake_error_reporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? savedFlutterHandler;
  late ErrorCallback? savedPlatformHandler;

  setUp(() {
    savedFlutterHandler = FlutterError.onError;
    savedPlatformHandler = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = savedFlutterHandler;
    PlatformDispatcher.instance.onError = savedPlatformHandler;
  });

  test('a Flutter framework error is forwarded to the reporter', () {
    final reporter = FakeErrorReporter();
    installGlobalErrorHandlers(reporter);

    final error = StateError('boom from widget');
    FlutterError.onError!(
      FlutterErrorDetails(exception: error, stack: StackTrace.current),
    );

    expect(reporter.reported, [error]);
  });

  test('an uncaught async error is forwarded and marked handled', () {
    final reporter = FakeErrorReporter();
    installGlobalErrorHandlers(reporter);

    final error = Exception('async failure');
    final handled = PlatformDispatcher.instance.onError!(
      error,
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(reporter.reported, [error]);
  });

  test('a reporter that throws does not crash the handler', () {
    installGlobalErrorHandlers(_ThrowingReporter());

    expect(
      () => PlatformDispatcher.instance.onError!(
        Exception('x'),
        StackTrace.current,
      ),
      returnsNormally,
    );
  });
}

class _ThrowingReporter extends FakeErrorReporter {
  @override
  void report(Object error, StackTrace? stack, {String? hint}) {
    throw StateError('reporter is down');
  }
}
