import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_error_reporter.dart';

http.Response jsonReply(int status, Object body, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

Future<T> withClient<T>(MockClientHandler handler, Future<T> Function() body) {
  ApiService.resetConnections(); // the shared client is built inside this zone, so it is this test's mock
  return http.runWithClient(body, () => MockClient(handler));
}

const okProfile = {'success': true, 'message': 'Profile updated.', 'data': {'display_name': 'New'}};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeErrorReporter reporter;
  late int unauthorizedCalls;
  final api = ApiService();

  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_access': 'old-access', 'jwt_refresh': 'refresh-1'});
    reporter = FakeErrorReporter();
    errorReporter = reporter;
    unauthorizedCalls = 0;
    ApiService.setUnauthorizedHandler(() => unauthorizedCalls++);
  });

  tearDown(() {
    errorReporter = const NoopErrorReporter();
    ApiService.setUnauthorizedHandler(null);
  });

  Future<String?> storedAccess() async => (await SharedPreferences.getInstance()).getString('jwt_access');

  group('401 handling', () {
    test('a 401 refreshes the token and retries the request once with the new token', () async {
      final seen = <String>[];
      final result = await withClient((request) async {
        seen.add('${request.method} ${request.url.path} ${request.headers['Authorization']}');
        if (request.url.path.endsWith('/auth/token/refresh/')) return jsonReply(200, {'access': 'new-access'});
        return request.headers['Authorization'] == 'Bearer new-access'
            ? jsonReply(200, okProfile)
            : jsonReply(401, {'detail': 'token expired', 'code': 'token_not_valid'});
      }, () => api.authPatch('/auth/me/', {'display_name': 'New'}));

      expect(result.success, isTrue);
      expect(seen.where((s) => s.startsWith('PATCH')).length, 2);
      expect(seen.last, 'PATCH /api/v1/auth/me/ Bearer new-access');
      expect(await storedAccess(), 'new-access');
    });

    test('the photo upload is retried after a 401 refresh too (it used to fail outright)', () async {
      var uploads = 0;
      final result = await withClient((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) return jsonReply(200, {'access': 'new-access'});
        uploads++;
        if (request.headers['Authorization'] != 'Bearer new-access') return jsonReply(401, {'detail': 'expired'});
        expect(request.bodyBytes, isNotEmpty);
        return jsonReply(200, {'success': true, 'message': 'Profile photo updated.', 'data': {'profile_photo_url': 'https://x/a.jpg'}});
      }, () => api.authMultipartPost(
            '/auth/me/photo/',
            fieldName: 'profile_photo',
            bytes: List<int>.filled(100, 7),
            filename: 'a.jpg',
            mimeType: 'image/jpeg',
          ));

      expect(result.success, isTrue, reason: result.message);
      expect(uploads, 2);
      expect(result.data?['profile_photo_url'], 'https://x/a.jpg');
    });

    test('when the server REJECTS the refresh token the session ends: tokens cleared, handler called', () async {
      final result = await withClient((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) return jsonReply(401, {'detail': 'invalid', 'code': 'token_not_valid'});
        return jsonReply(401, {'detail': 'expired'});
      }, () => api.authPatch('/auth/me/', {'display_name': 'x'}));

      expect(result.error?.kind, ApiErrorKind.unauthorized);
      expect(result.message, 'Your session has expired. Please log in again.');
      expect(await storedAccess(), isNull);
      expect(unauthorizedCalls, 1);
    });

    test('a refresh that fails because the server is waking up does NOT log the user out', () async {
      final result = await withClient((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) {
          return http.Response('<html>Bad gateway</html>', 502, headers: {'content-type': 'text/html'});
        }
        return jsonReply(401, {'detail': 'expired'});
      }, () => api.authPatch('/auth/me/', {'display_name': 'x'}));

      expect(result.error?.kind, ApiErrorKind.unavailable);
      expect(await storedAccess(), 'old-access', reason: 'tokens must survive a bad moment on the network');
      expect(unauthorizedCalls, 0);
    });

    test('a refresh that fails because there is no connection does NOT log the user out', () async {
      final result = await withClient((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) throw http.ClientException('Failed host lookup');
        return jsonReply(401, {'detail': 'expired'});
      }, () => api.authGetRaw('/dashboard/student/stats/'));

      expect(result.error?.kind, ApiErrorKind.offline);
      expect(await storedAccess(), 'old-access');
      expect(unauthorizedCalls, 0);
    });
  });

  group('what the caller gets back', () {
    test('a failed upload carries the server\'s reason', () async {
      final result = await withClient(
        (request) async => jsonReply(400, {
          'success': false,
          'message': 'The file is not a valid image.',
          'errors': {'profile_photo': 'The file is not a valid image.'},
        }),
        () => api.authMultipartPost(
          '/auth/me/photo/',
          fieldName: 'profile_photo',
          bytes: const [1, 2, 3],
          filename: 'a.png',
          mimeType: 'image/png',
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, 'The file is not a valid image.');
      expect(result.error?.fieldErrors['profile_photo'], isNotNull);
      expect(reporter.reported, isEmpty, reason: 'a validation message is not a bug');
    });

    test('progress goes up to 1.0', () async {
      final progress = <double>[];
      await withClient(
        (request) async => jsonReply(200, {'success': true, 'message': 'ok', 'data': <String, dynamic>{}}),
        () => api.authMultipartPost(
          '/auth/me/photo/',
          fieldName: 'profile_photo',
          bytes: List<int>.filled(200000, 1),
          filename: 'a.jpg',
          mimeType: 'image/jpeg',
          onProgress: progress.add,
        ),
      );

      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
      expect(progress, orderedEquals([...progress]..sort()));
    });

    test('cancelling an upload returns "cancelled" quickly and reports nothing', () async {
      final cancel = Completer<void>();
      final watch = Stopwatch()..start();
      final future = withClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 3));
        return jsonReply(200, {'success': true, 'message': 'late', 'data': <String, dynamic>{}});
      }, () => api.authMultipartPost(
            '/auth/me/photo/',
            fieldName: 'profile_photo',
            bytes: const [1],
            filename: 'a.jpg',
            mimeType: 'image/jpeg',
            cancel: cancel.future,
          ));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cancel.complete();
      final result = await future;

      expect(result.error?.kind, ApiErrorKind.cancelled);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(reporter.reported, isEmpty);
    });

    test('a 405 is reported to Sentry with the route and status only, and the user still gets words', () async {
      final result = await withClient(
        (request) async => jsonReply(405, {'detail': 'Method "PATCH" not allowed.'}),
        () => api.authPatch('/auth/me/', {'display_name': 'x'}),
      );

      expect(result.message, isNotEmpty);
      expect(reporter.reported, hasLength(1));
      expect(reporter.hints.single, 'api: PATCH /auth/me/ -> 405');
    });

    test('no connection is not reported', () async {
      final result = await withClient(
        (request) async => throw http.ClientException('Failed host lookup'),
        () => api.getRaw('/cities/'),
      );

      expect(result.error?.kind, ApiErrorKind.offline);
      expect(reporter.reported, isEmpty);
    });

    test('a bug inside a call IS reported, and the user is not told it was the network', () async {
      final result = await withClient(
        (request) async => throw StateError('bug'),
        () => api.getRaw('/cities/'),
      );

      expect(result.error?.kind, ApiErrorKind.unexpected);
      expect(result.message, 'Something went wrong. Please try again.');
      expect(reporter.reported, hasLength(1));
    });
  });
}
