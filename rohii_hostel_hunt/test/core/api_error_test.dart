import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

http.Response json(int status, Object body, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

http.Response html(int status, [String body = '<html><body>Error</body></html>']) =>
    http.Response(body, status, headers: {'content-type': 'text/html'});

ApiError read(http.Response r) => ApiErrorReader.fromResponse(r);

void main() {
  group('response bodies the backend really sends', () {
    test('envelope with a field map: the specific field message wins and the field is kept', () {
      final e = read(json(400, {
        'success': false,
        'message': 'Some fields cannot be changed.',
        'errors': {'role': 'This field cannot be changed.'},
      }));
      expect(e.kind, ApiErrorKind.validation);
      expect(e.message, 'This field cannot be changed.');
      expect(e.fieldErrors['role'], 'This field cannot be changed.');
    });

    test('envelope with a list under a field', () {
      final e = read(json(400, {
        'success': false,
        'message': 'Error',
        'errors': {'display_name': ['Enter a name.']},
      }));
      expect(e.message, 'Enter a name.');
    });

    test('envelope with only a message (photo upload: file too large)', () {
      final e = read(json(413, {
        'success': false,
        'message': 'The image is too large (5 MB maximum).',
        'errors': <String, dynamic>{},
      }));
      expect(e.message, 'The image is too large (5 MB maximum).');
    });

    test('plain DRF field errors, non_field_errors and a bare list', () {
      expect(read(json(400, {'gender': ['"robot" is not a valid choice.']})).message, '"robot" is not a valid choice.');
      expect(read(json(400, {'non_field_errors': ['Passwords do not match.']})).message, 'Passwords do not match.');
      expect(read(json(400, ['Something is wrong.'])).message, 'Something is wrong.');
    });

    test('401 with a token detail says the session expired', () {
      final e = read(json(401, {'detail': 'Given token not valid for any token type', 'code': 'token_not_valid'}));
      expect(e.kind, ApiErrorKind.unauthorized);
      expect(e.message, 'Your session has expired. Please log in again.');
    });

    test('401 from the login envelope keeps the server wording', () {
      final e = read(json(401, {'success': false, 'message': 'Invalid credentials.', 'errors': <String, dynamic>{}}));
      expect(e.kind, ApiErrorKind.unauthorized);
      expect(e.message, 'Invalid credentials.');
    });

    test('403, 404 and 405 use our wording and keep the server detail for Sentry only', () {
      final forbidden = read(json(403, {'detail': 'You do not have permission to perform this action.'}));
      expect(forbidden.kind, ApiErrorKind.forbidden);
      expect(forbidden.message, "You don't have permission to do that.");
      expect(forbidden.serverDetail, contains('permission'));

      expect(read(html(404)).kind, ApiErrorKind.notFound);
      expect(read(html(404)).message, "We couldn't find that.");

      final notAllowed = read(json(405, {'detail': 'Method "PATCH" not allowed.'}));
      expect(notAllowed.kind, ApiErrorKind.methodNotAllowed);
      expect(notAllowed.message, contains('update the app'));
      expect(notAllowed.message, isNot(contains('PATCH')));
    });

    test('429 reads Retry-After', () {
      final e = read(json(429, {'detail': 'Request was throttled. Expected available in 37 seconds.'},
          headers: {'retry-after': '37'}));
      expect(e.kind, ApiErrorKind.throttled);
      expect(e.retryAfter, const Duration(seconds: 37));
      expect(e.message, 'Too many attempts. Try again in 37 seconds.');
    });

    test('429 without the header falls back to the number in the detail, in minutes when long', () {
      final e = read(json(429, {'detail': 'Request was throttled. Expected available in 120 seconds.'}));
      expect(e.retryAfter, const Duration(seconds: 120));
      expect(e.message, 'Too many attempts. Try again in 2 minutes.');
    });

    test('429 with nothing to read still says to wait', () {
      final e = read(json(429, {'detail': 'Slow down.'}));
      expect(e.message, 'Too many attempts. Please wait a moment and try again.');
    });

    test('a proxy page while the server wakes up is "starting up", not "unexpected"', () {
      for (final status in [502, 503, 504]) {
        final e = read(html(status));
        expect(e.kind, ApiErrorKind.unavailable, reason: '$status');
        expect(e.message, 'The server is starting up. Please try again in a few seconds.');
      }
    });

    test('other 5xx', () {
      final e = read(json(500, {'detail': 'oops'}));
      expect(e.kind, ApiErrorKind.server);
      expect(e.message, 'The server had a problem. Please try again in a moment.');
    });

    test('413 from a proxy', () {
      expect(read(html(413)).message, 'That file is too large to upload.');
    });

    test('the message never contains a stack trace, HTML or raw JSON', () {
      for (final r in [html(500, '<html>Traceback (most recent call last)'), json(500, {'detail': 'x'}), html(400)]) {
        final m = read(r).message;
        expect(m, isNot(contains('<')));
        expect(m, isNot(contains('Traceback')));
        expect(m, isNot(contains('{')));
      }
    });
  });

  group('exceptions', () {
    test('timeout', () {
      final e = ApiErrorReader.fromException(TimeoutException('slow'));
      expect(e.kind, ApiErrorKind.timeout);
      expect(e.message, 'The server took too long to answer. Check your connection and try again.');
    });

    test('no connection', () {
      final e = ApiErrorReader.fromException(http.ClientException('Failed host lookup'));
      expect(e.kind, ApiErrorKind.offline);
      expect(e.message, 'No internet connection. Check your network and try again.');
    });

    test('an unreadable reply', () {
      expect(ApiErrorReader.fromException(const FormatException('bad json')).kind, ApiErrorKind.unreadable);
    });

    test('a cancelled request', () {
      expect(ApiErrorReader.fromException(http.RequestAbortedException()).kind, ApiErrorKind.cancelled);
    });

    test('a programming error is "unexpected" and says so plainly', () {
      final e = ApiErrorReader.fromException(StateError('boom'));
      expect(e.kind, ApiErrorKind.unexpected);
      expect(e.message, 'Something went wrong. Please try again.');
      expect(e.message, isNot(contains('boom')));
    });

    test('userMessageOf shows an ApiException message and hides anything else', () {
      final api = ApiException(read(html(503)));
      expect(userMessageOf(api), 'The server is starting up. Please try again in a few seconds.');
      expect(userMessageOf(StateError('LateInitializationError: _api')), 'Something went wrong. Please try again.');
    });
  });

  group('both response parsers use the reader (X09)', () {
    test('ApiResponse keeps the message of a JSON 405 (it used to be empty)', () {
      final r = ApiResponse.fromResponse(json(405, {'detail': 'Method "PATCH" not allowed.'}));
      expect(r.success, isFalse);
      expect(r.statusCode, 405);
      expect(r.message, isNotEmpty);
      expect(r.error?.kind, ApiErrorKind.methodNotAllowed);
    });

    test('ApiResponse turns an HTML 502 into the starting-up message, not "Unexpected server response"', () {
      final r = ApiResponse.fromResponse(html(502));
      expect(r.message, 'The server is starting up. Please try again in a few seconds.');
    });

    test('ApiResponse keeps a success envelope', () {
      final r = ApiResponse.fromResponse(json(200, {'success': true, 'message': 'ok', 'data': {'a': 1}}));
      expect(r.success, isTrue);
      expect(r.data, {'a': 1});
    });

    test('ApiResponse survives a success reply whose data is a list', () {
      final r = ApiResponse.fromResponse(json(200, {'success': true, 'message': 'ok', 'data': [1, 2]}));
      expect(r.success, isTrue);
      expect(r.data, isNull);
    });

    test('a 2xx reply that is not JSON is reported as unreadable', () {
      final r = ApiResponse.fromResponse(html(200, 'maintenance'));
      expect(r.success, isFalse);
      expect(r.error?.kind, ApiErrorKind.unreadable);
    });

    test('RawApiResponse reads field errors and non-string detail', () {
      expect(RawApiResponse.fromResponse(json(400, {'city': ['Unknown city.']})).message, 'Unknown city.');
      expect(RawApiResponse.fromResponse(json(429, {'detail': 'x'}, headers: {'retry-after': '5'})).message,
          'Too many attempts. Try again in 5 seconds.');
      expect(RawApiResponse.fromResponse(html(503)).error?.kind, ApiErrorKind.unavailable);
    });

    test('RawApiResponse accepts an empty 204', () {
      final r = RawApiResponse.fromResponse(http.Response('', 204));
      expect(r.success, isTrue);
    });
  });
}
