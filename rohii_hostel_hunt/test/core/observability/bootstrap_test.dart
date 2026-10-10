import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/core/observability/sentry_setup.dart';

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
    errorReporter = const NoopErrorReporter();
  });

  test(
    'without a DSN the app still starts and installs the global handlers',
    () async {
      var started = false;
      await bootstrapObservability(() => started = true);

      expect(started, isTrue);
      expect(errorReporter, isA<NoopErrorReporter>());
      expect(FlutterError.onError, isNot(same(savedFlutterHandler)));
      expect(PlatformDispatcher.instance.onError, isNotNull);
    },
  );

  test(
    'the synthetic test error is a StateError with a recognisable message',
    () {
      expect(
        throwSyntheticTestError,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Sentry test error'),
          ),
        ),
      );
    },
  );
}
