import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rohii_hostel_hunt/core/network/api_activity.dart';
import 'package:rohii_hostel_hunt/core/network/http_transport.dart';

/// The rules every request lives by: one shared connection, real timeouts, retry for reads only.
void main() {
  final url = Uri.parse('https://example.test/api/v1/hostels/');

  late List<Duration> waits;
  late int calls;

  /// A transport over a scripted server. [script] gets the attempt number (1, 2, 3...).
  HttpTransport transport(Future<http.Response> Function(int attempt, http.Request request) script,
      {DateTime Function()? now, Random? random}) {
    waits = [];
    calls = 0;
    return HttpTransport(
      clientFactory: () => MockClient((request) {
        calls++;
        return script(calls, request);
      }),
      random: random ?? Random(1),
      wait: (d) async => waits.add(d),
      now: now,
    );
  }

  http.Response status(int code, {Map<String, String> headers = const {}}) => http.Response('{}', code, headers: headers);

  group('retry (reads only)', () {
    for (final code in [408, 502, 503, 504]) {
      test('a GET answered $code once is tried again and succeeds', () async {
        final t = transport((attempt, _) async => attempt == 1 ? status(code) : status(200));
        final response = await t.send('GET', url, retry: true);
        expect(response.statusCode, 200);
        expect(calls, 2);
        expect(waits, hasLength(1));
      });
    }

    for (final code in [400, 401, 403, 404, 405, 422, 500]) {
      test('a GET answered $code is NOT tried again (a retry cannot change it)', () async {
        final t = transport((_, _) async => status(code));
        final response = await t.send('GET', url, retry: true);
        expect(response.statusCode, code);
        expect(calls, 1);
        expect(waits, isEmpty);
      });
    }

    test('a read has three attempts at most, then the last answer is returned', () async {
      final t = transport((_, _) async => status(503));
      final response = await t.send('GET', url, retry: true);
      expect(response.statusCode, 503);
      expect(calls, 3);
      expect(waits, hasLength(2));
    });

    test('a 429 that asks for a short wait is waited for exactly, then retried', () async {
      final t = transport((attempt, _) async => attempt == 1 ? status(429, headers: {'retry-after': '3'}) : status(200));
      expect((await t.send('GET', url, retry: true)).statusCode, 200);
      expect(waits, [const Duration(seconds: 3)]);
    });

    test('a 429 that asks for a long wait is not waited for', () async {
      final t = transport((_, _) async => status(429, headers: {'retry-after': '60'}));
      expect((await t.send('GET', url, retry: true)).statusCode, 429);
      expect(calls, 1);
    });

    test('a dropped connection is retried', () async {
      final t = transport((attempt, _) async => attempt == 1 ? throw http.ClientException('Connection closed') : status(200));
      expect((await t.send('GET', url, retry: true)).statusCode, 200);
      expect(calls, 2);
    });

    test('a timeout is retried and the retry can succeed', () async {
      final t = transport((attempt, _) => attempt == 1 ? Completer<http.Response>().future : Future.value(status(200)));
      final response = await t.send('GET', url, retry: true, timeout: const Duration(milliseconds: 40));
      expect(response.statusCode, 200);
      expect(calls, 2);
    });

    test('three timeouts end in a TimeoutException', () async {
      final t = transport((_, _) => Completer<http.Response>().future);
      await expectLater(
        t.send('GET', url, retry: true, timeout: const Duration(milliseconds: 20)),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, 3);
    });

    test('no new attempt starts when less than 10 seconds of the 75 are left', () async {
      var clock = DateTime(2026);
      final t = transport((_, _) async {
        clock = clock.add(const Duration(seconds: 70)); // the first attempt used up 70 s
        return status(503);
      }, now: () => clock);
      expect((await t.send('GET', url, retry: true)).statusCode, 503);
      expect(calls, 1);
    });
  });

  group('writes are never retried', () {
    for (final method in ['POST', 'PATCH', 'PUT', 'DELETE']) {
      test('$method after a 503: one attempt', () async {
        final t = transport((_, _) async => status(503));
        expect((await t.send(method, url, body: '{}')).statusCode, 503);
        expect(calls, 1);
      });

      test('$method after a timeout: one attempt', () async {
        final t = transport((_, _) => Completer<http.Response>().future);
        await expectLater(
          t.send(method, url, body: '{}', timeout: const Duration(milliseconds: 20)),
          throwsA(isA<TimeoutException>()),
        );
        expect(calls, 1);
      });

      test('$method after a dropped connection: one attempt', () async {
        final t = transport((_, _) async => throw http.ClientException('Connection closed'));
        await expectLater(t.send(method, url, body: '{}'), throwsA(isA<http.ClientException>()));
        expect(calls, 1);
      });
    }
  });

  group('backoff', () {
    test('the waits stay inside their bounds for any random draw', () {
      for (var seed = 0; seed < 300; seed++) {
        final random = Random(seed);
        final first = HttpTransport.backoff(1, random);
        final second = HttpTransport.backoff(2, random);
        final tenth = HttpTransport.backoff(10, random);
        expect(first.inMilliseconds, inInclusiveRange(500, 1500));
        expect(second.inMilliseconds, inInclusiveRange(1000, 3000));
        expect(tenth, lessThanOrEqualTo(const Duration(seconds: 12)));
      }
    });

    test('the waits are not all the same (jitter)', () {
      final random = Random(7);
      final draws = {for (var i = 0; i < 20; i++) HttpTransport.backoff(1, random).inMilliseconds};
      expect(draws.length, greaterThan(10));
    });
  });

  group('timeouts really stop the request', () {
    test('the request is told to abort when its time is up', () async {
      Future<void>? abortTrigger;
      final t = HttpTransport(
        clientFactory: () => _ObservingClient((request) {
          abortTrigger = (request as http.Abortable).abortTrigger;
          return Completer<http.StreamedResponse>().future;
        }),
        wait: (_) async {},
      );
      await expectLater(
        t.send('GET', url, timeout: const Duration(milliseconds: 30)),
        throwsA(isA<TimeoutException>()),
      );
      var aborted = false;
      await abortTrigger!.then((_) => aborted = true);
      expect(aborted, isTrue, reason: 'Future.timeout would only have stopped waiting; the socket stayed open');
    });
  });

  group('one shared client', () {
    test('many requests are sent through the same client', () async {
      var made = 0;
      final t = HttpTransport(clientFactory: () {
        made++;
        return MockClient((request) async => status(200));
      });
      for (var i = 0; i < 5; i++) {
        await t.send('GET', url);
      }
      expect(made, 1);
    });

    test('after reset a new client is built', () async {
      var made = 0;
      final t = HttpTransport(clientFactory: () {
        made++;
        return MockClient((request) async => status(200));
      });
      await t.send('GET', url);
      t.reset();
      await t.send('GET', url);
      expect(made, 2);
    });
  });

  group('the slow-server signal', () {
    setUp(() {
      ApiActivity.reset();
      ApiActivity.threshold = const Duration(milliseconds: 40);
    });
    tearDown(ApiActivity.reset);

    test('a request that waits longer than the threshold turns the signal on, and off when it ends', () async {
      final gate = Completer<http.Response>();
      final t = transport((_, _) => gate.future);
      final pending = t.send('GET', url);
      expect(ApiActivity.slow.value, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(ApiActivity.slow.value, isTrue);
      gate.complete(status(200));
      await pending;
      expect(ApiActivity.slow.value, isFalse);
    });

    test('a quick request never turns it on', () async {
      final t = transport((_, _) async => status(200));
      await t.send('GET', url);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(ApiActivity.slow.value, isFalse);
    });

    test('a failed request still turns it off', () async {
      final t = transport((_, _) async => throw http.ClientException('x'));
      await expectLater(t.send('GET', url), throwsA(isA<http.ClientException>()));
      expect(ApiActivity.slow.value, isFalse);
    });

    test('a request that opts out (a photo upload) is not tracked', () async {
      final gate = Completer<http.Response>();
      final t = transport((_, _) => gate.future);
      final pending = t.send('POST', url, body: '{}', trackSlow: false);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(ApiActivity.slow.value, isFalse);
      gate.complete(status(200));
      await pending;
    });
  });
}

/// A client whose `send` is scripted, so a test can look at the request it was given.
class _ObservingClient extends http.BaseClient {
  _ObservingClient(this._script);
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _script;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _script(request);
}
