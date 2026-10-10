import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/observability/privacy.dart';
import 'package:rohii_hostel_hunt/core/observability/sentry_setup.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('maskText', () {
    test('masks emails and long digit runs, keeps small numbers and dates', () {
      final out = maskText(
        'a.b+c@Mail.example.co.in called 9876543210 and +919876543210, '
        'order 42 on 2026-10-10',
      );
      expect(out, isNot(contains('@')));
      expect(out, isNot(contains('9876543210')));
      expect(out, contains('order 42'));
      expect(out, contains('2026-10-10'));
    });

    test('scrubText also strips URL query strings', () {
      final out = scrubText(
        'GET https://api.example.com/api/v1/search/?q=person@example.com failed',
      );
      expect(out, contains('https://api.example.com/api/v1/search/'));
      expect(out, isNot(contains('person')));
      expect(out, isNot(contains('?q=')));
    });
  });

  group('routeTemplate', () {
    test('replaces ids and drops the query string', () {
      expect(routeTemplate('/hostels/42/'), '/hostels/:id/');
      expect(
        routeTemplate('/payments/status/123/?x=person@example.com'),
        '/payments/status/:id/',
      );
      expect(
        routeTemplate('/bookings/0c9c4728-51db-4cc3-8abc-94aa0315dcc7/cancel/'),
        '/bookings/:id/cancel/',
      );
      expect(routeTemplate('/auth/me/'), '/auth/me/');
    });
  });

  group('scrubEvent', () {
    test(
      'masks personal data in message, exceptions and breadcrumbs',
      () async {
        final event = SentryEvent(
          message: SentryMessage('Failed for person@example.com'),
          exceptions: [
            SentryException(
              type: 'Exception',
              value: 'refused person@example.com +919876543210',
            ),
          ],
          breadcrumbs: [
            Breadcrumb(
              message: 'sent to person@example.com',
              data: {'token': 'abc', 'route': '/a/'},
            ),
          ],
        );

        final out = scrubEvent(event, Hint())!;
        final text = out.toJson().toString();

        expect(text, isNot(contains('person@example.com')));
        expect(text, isNot(contains('9876543210')));
        final data = out.breadcrumbs!.single.data!;
        expect(data['token'], '[Filtered]');
        expect(data['route'], '/a/');
      },
    );

    test('scrubBreadcrumb tolerates null', () {
      expect(scrubBreadcrumb(null, Hint()), isNull);
    });
  });

  test('Sentry options are privacy-safe', () {
    final options = SentryFlutterOptions();
    configureSentryOptions(
      options,
      dsn: 'https://key@o0.ingest.sentry.io/1',
      environment: 'production',
      release: 'abc1234',
    );

    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    // ignore: experimental_member_use
    expect(options.attachViewHierarchy, isFalse);
    expect(options.tracesSampleRate, 0);
    expect(options.enableUserInteractionBreadcrumbs, isFalse);
    expect(options.enableAutoNativeBreadcrumbs, isFalse);
    expect(options.release, 'abc1234');
    expect(options.environment, 'production');
    expect(options.beforeSend, isNotNull);
    expect(options.beforeBreadcrumb, isNotNull);
  });
}
