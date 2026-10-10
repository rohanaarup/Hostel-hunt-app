import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_error_reporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeErrorReporter reporter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reporter = FakeErrorReporter();
    errorReporter = reporter;
  });

  tearDown(() => errorReporter = const NoopErrorReporter());

  Future<T> withClient<T>(
    Future<T> Function() body,
    Future<http.Response> Function(http.Request) handler,
  ) {
    return http.runWithClient(body, () => MockClient(handler));
  }

  test(
    'a failed call leaves one breadcrumb with method, route and status',
    () async {
      await withClient(
        () =>
            ApiService().post('/hostels/42/', {'email': 'person@example.com'}),
        (_) async => http.Response('{"success":false,"message":"boom"}', 500),
      );

      expect(reporter.breadcrumbs, hasLength(1));
      final crumb = reporter.breadcrumbs.single;
      expect(crumb.category, 'api');
      expect(crumb.message, 'POST /hostels/:id/ -> 500');
      expect(crumb.data, {
        'method': 'POST',
        'route': '/hostels/:id/',
        'status': 500,
      });
    },
  );

  test('a successful call leaves no breadcrumb', () async {
    await withClient(
      () => ApiService().getRaw('/hostels/'),
      (_) async => http.Response('[]', 200),
    );
    expect(reporter.breadcrumbs, isEmpty);
  });

  test('query strings and bodies never reach the breadcrumb', () async {
    await withClient(
      () => ApiService().getRaw(
        '/search/',
        queryParams: {'q': 'person@example.com'},
      ),
      (_) async => http.Response('{"detail":"nope person@example.com"}', 400),
    );

    final crumb = reporter.breadcrumbs.single;
    expect('${crumb.message} ${crumb.data}', isNot(contains('person')));
    expect(crumb.data!['route'], '/search/');
    expect(crumb.data!['status'], 400);
  });

  test('a timeout is recorded with status 0', () async {
    await withClient(
      () => ApiService().post('/auth/send-otp/', {'identifier': 'x'}),
      (_) async => throw TimeoutException('slow'),
    );
    expect(reporter.breadcrumbs.single.data, {
      'method': 'POST',
      'route': '/auth/send-otp/',
      'status': 0,
    });
  });

  test(
    'a network failure on an authenticated call is recorded with status 0',
    () async {
      await withClient(
        () => ApiService().authGet('/bookings/my-bookings/'),
        (_) async => throw http.ClientException('no route to host'),
      );
      expect(reporter.breadcrumbs.single.data, {
        'method': 'GET',
        'route': '/bookings/my-bookings/',
        'status': 0,
      });
    },
  );
}
