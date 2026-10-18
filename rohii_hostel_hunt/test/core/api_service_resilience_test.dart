import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How ApiService behaves on top of the transport: shared connection, retry for reads only,
/// one token refresh at a time, and a best-effort server logout.
http.Response jsonReply(int status, Object body, {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...headers});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  late List<Duration> waits;
  late List<String> seen;

  void serve(Future<http.Response> Function(http.Request request) handler, {void Function()? onClient}) {
    waits = [];
    seen = [];
    ApiService.configureTransport(
      clientFactory: () {
        onClient?.call();
        return MockClient((request) {
          seen.add('${request.method} ${request.url.path}');
          return handler(request);
        });
      },
      wait: (d) async => waits.add(d),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({'jwt_access': 'old-access', 'jwt_refresh': 'refresh-1'});
    ApiService.setUnauthorizedHandler(() {});
  });
  tearDown(() {
    ApiService.setUnauthorizedHandler(null);
    ApiService.configureTransport();
  });

  test('three calls in a row use ONE client, so one connection', () async {
    var clients = 0;
    serve((request) async => jsonReply(200, {'results': []}), onClient: () => clients++);
    await api.getRaw('/hostels/');
    await api.getRaw('/hostels/');
    await api.getRaw('/cities/');
    expect(clients, 1);
  });

  group('reads are retried, writes are not', () {
    test('a public GET that gets a 503 once and then a 200 succeeds', () async {
      serve((request) async => seen.length == 1 ? jsonReply(503, {'detail': 'waking up'}) : jsonReply(200, {'results': []}));
      final result = await api.getRaw('/hostels/');
      expect(result.success, isTrue);
      expect(seen, hasLength(2));
      expect(waits, hasLength(1));
    });

    test('an authenticated GET is retried too', () async {
      serve((request) async => seen.length == 1 ? jsonReply(502, {'detail': 'bad gateway'}) : jsonReply(200, {'ok': true}));
      expect((await api.authGetRaw('/wishlist/ids/')).success, isTrue);
      expect(seen, hasLength(2));
    });

    test('a POST that gets a 503 is NOT retried (it may already have been done)', () async {
      serve((request) async => jsonReply(503, {'detail': 'waking up'}));
      final result = await api.post('/auth/send-otp/', {'identifier': 'a@example.test'});
      expect(result.success, isFalse);
      expect(seen, ['POST /api/v1/auth/send-otp/']);
    });

    test('creating a booking is never retried, even after a timeout-like failure', () async {
      serve((request) async => throw http.ClientException('Connection closed'));
      final result = await api.authPostRaw('/bookings/', {'hostel': 'h'});
      expect(result.success, isFalse);
      expect(seen, hasLength(1));
    });

    test('PATCH and DELETE are never retried', () async {
      serve((request) async => jsonReply(503, {'detail': 'x'}));
      await api.authPatch('/auth/me/', {'display_name': 'x'});
      await api.authDeleteRaw('/wishlist/hostel/h/');
      expect(seen, ['PATCH /api/v1/auth/me/', 'DELETE /api/v1/wishlist/hostel/h/']);
    });

    test('payment status polling is not retried by the client (the poller owns its schedule)', () async {
      serve((request) async => jsonReply(503, {'detail': 'x'}));
      await api.authGetRaw('/payments/status/p1/');
      expect(seen, hasLength(1));
    });

    test('a 500 is shown, not retried', () async {
      serve((request) async => jsonReply(500, {'detail': 'boom'}));
      final result = await api.getRaw('/hostels/');
      expect(result.success, isFalse);
      expect(seen, hasLength(1));
    });
  });

  group('one token refresh at a time', () {
    test('three requests that all get a 401 together cause ONE refresh and all succeed', () async {
      var refreshes = 0;
      serve((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return jsonReply(200, {'access': 'new-access'});
        }
        return request.headers['Authorization'] == 'Bearer new-access' ? jsonReply(200, {'ok': true}) : jsonReply(401, {'detail': 'expired'});
      });
      final results = await Future.wait([api.authGetRaw('/a/'), api.authGetRaw('/b/'), api.authGetRaw('/c/')]);
      expect(results.every((r) => r.success), isTrue);
      expect(refreshes, 1);
      expect((await SharedPreferences.getInstance()).getString('jwt_access'), 'new-access');
    });

    test('a request whose 401 arrives AFTER another request refreshed just retries with the new token', () async {
      var refreshes = 0;
      serve((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) {
          refreshes++;
          return jsonReply(200, {'access': 'new-access'});
        }
        if (request.url.path.endsWith('/slow/')) await Future<void>.delayed(const Duration(milliseconds: 80));
        return request.headers['Authorization'] == 'Bearer new-access' ? jsonReply(200, {'ok': true}) : jsonReply(401, {'detail': 'expired'});
      });
      final slow = api.authGetRaw('/slow/'); // sent with the old token, its 401 comes late
      final quick = await api.authGetRaw('/quick/'); // 401, refreshes
      expect(quick.success, isTrue);
      expect((await slow).success, isTrue);
      expect(refreshes, 1, reason: 'the late request must not start a second refresh');
    });

    test('a refresh that fails on the network keeps the session and every caller gets the error', () async {
      var unauthorized = 0;
      ApiService.setUnauthorizedHandler(() => unauthorized++);
      serve((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) throw http.ClientException('no network');
        return jsonReply(401, {'detail': 'expired'});
      });
      final results = await Future.wait([api.authGetRaw('/a/'), api.authGetRaw('/b/')]);
      expect(results.every((r) => !r.success), isTrue);
      expect(unauthorized, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_access'), 'old-access');
      expect(prefs.getString('jwt_refresh'), 'refresh-1');
    });

    test('a refresh the server rejects ends the session once, not once per caller', () async {
      var unauthorized = 0;
      ApiService.setUnauthorizedHandler(() => unauthorized++);
      serve((request) async {
        if (request.url.path.endsWith('/auth/token/refresh/')) return jsonReply(401, {'detail': 'invalid'});
        return jsonReply(401, {'detail': 'expired'});
      });
      await Future.wait([api.authGetRaw('/a/'), api.authGetRaw('/b/'), api.authGetRaw('/c/')]);
      expect(unauthorized, 1);
      expect((await SharedPreferences.getInstance()).getString('jwt_access'), isNull);
    });
  });

  group('Log Out tells the server', () {
    test('revokeSession sends the refresh token to /auth/logout/', () async {
      Map<String, dynamic>? sent;
      serve((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.headers['Authorization'], 'Bearer old-access');
        return jsonReply(200, {'success': true});
      });
      await api.revokeSession();
      expect(seen, ['POST /api/v1/auth/logout/']);
      expect(sent, {'refresh': 'refresh-1'});
    });

    test('it never throws and never retries, whatever the server does', () async {
      serve((request) async => throw http.ClientException('offline'));
      await api.revokeSession();
      expect(seen, hasLength(1));
      serve((request) async => jsonReply(503, {'detail': 'x'}));
      await api.revokeSession();
      expect(seen, hasLength(1));
    });

    test('with no login saved it sends nothing', () async {
      SharedPreferences.setMockInitialValues({});
      serve((request) async => jsonReply(200, {}));
      await api.revokeSession();
      expect(seen, isEmpty);
    });
  });
}
