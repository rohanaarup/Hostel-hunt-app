import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:rohii_hostel_hunt/core/network/api_activity.dart';

/// How a request waits between two attempts. Tests replace it so no real time passes.
typedef Wait = Future<void> Function(Duration duration);

/// The one door every request leaves the app through.
///
///  * ONE shared [http.Client], so the TCP and TLS connection is reused between requests. Before,
///    every call built a new client and paid the full handshake again on mobile data.
///  * A timeout that really stops the request. `Future.timeout` only stops WAITING; the socket stayed
///    open. Each attempt here is an abortable request and the timer aborts it.
///  * Retry for idempotent reads only (`retry: true`, the caller decides). Writes are never retried:
///    the server may already have done the work. See [shouldRetryStatus] for what is retried.
///  * [ApiActivity] is told when a request starts and ends, so the UI can say "waking the server".
class HttpTransport {
  HttpTransport({
    http.Client Function()? clientFactory,
    Random? random,
    Wait? wait,
    DateTime Function()? now,
  })  : _clientFactory = clientFactory ?? _defaultClient,
        _random = random ?? Random(),
        _wait = wait ?? ((d) => Future<void>.delayed(d)),
        _now = now ?? DateTime.now;

  final http.Client Function() _clientFactory;
  final Random _random;
  final Wait _wait;
  final DateTime Function() _now;
  http.Client? _client;

  // ── Policy (numbers and reasons are in docs/NETWORK.md) ──────────────────────────────────────

  /// One attempt of a read. Render needs 30 to 60 s to wake, so the first attempt can answer or the
  /// retry can land on a server that is awake by then.
  static const Duration readTimeout = Duration(seconds: 30);

  /// One attempt of a write. The server caps its own outside calls at 13 s.
  static const Duration writeTimeout = Duration(seconds: 45);

  /// A photo upload over slow mobile data.
  static const Duration uploadTimeout = Duration(seconds: 90);

  /// A read, with its retries, is over after this long. No new attempt starts with less than
  /// [minimumAttempt] left.
  static const Duration budget = Duration(seconds: 75);
  static const Duration minimumAttempt = Duration(seconds: 10);

  /// Attempts for a read: the first plus two retries.
  static const int maxAttempts = 3;

  /// A server that asks us to wait longer than this on a 429 is not waited for.
  static const Duration maxRetryAfter = Duration(seconds: 10);

  /// 0.5 to 1.5 s before the first retry, 1 to 3 s before the second.
  static Duration backoff(int retryNumber, Random random) {
    final seconds = min(8, pow(2, retryNumber - 1).toInt());
    final factor = 0.5 + random.nextDouble();
    return Duration(milliseconds: (seconds * factor * 1000).round());
  }

  /// Statuses worth another try. 500 is not (it is a bug and trying again only repeats it); other
  /// 4xx never are.
  static bool shouldRetryStatus(int status) => const {408, 429, 502, 503, 504}.contains(status);

  // `http.Client()` picks the right client for the platform (and lets tests swap it with
  // `http.runWithClient`). Its idle connections are closed after 15 s, well before a server or proxy
  // would drop them, so a reused connection is almost never a dead one. A connection that hangs is
  // bounded by the attempt timeout, which aborts it.
  static http.Client _defaultClient() => http.Client();

  /// The shared client, created on first use.
  http.Client get client => _client ??= _clientFactory();

  /// Drop the shared client (and every pooled connection). Used by tests, and the way to recover
  /// should a network change ever leave dead connections behind.
  void reset() {
    _client?.close();
    _client = null;
  }

  Future<http.Response> send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
    bool retry = false,
    bool trackSlow = true,
  }) async {
    final attemptTimeout = timeout ?? (retry ? readTimeout : writeTimeout);
    final token = trackSlow ? ApiActivity.start() : null;
    final started = _now();
    try {
      for (var attempt = 1;; attempt++) {
        final remaining = budget - _now().difference(started);
        final limit = retry && remaining < attemptTimeout ? maxDuration(remaining, minimumAttempt) : attemptTimeout;
        final canRetry = retry && attempt < maxAttempts;
        http.Response response;
        try {
          response = await _once(method, url, headers, body, limit);
        } on TimeoutException {
          if (!canRetry || !_hasTimeFor(started)) rethrow;
          await _wait(backoff(attempt, _random));
          continue;
        } on http.RequestAbortedException {
          rethrow; // cancelled on purpose: never tried again
        } on http.ClientException {
          if (!canRetry || !_hasTimeFor(started)) rethrow;
          await _wait(backoff(attempt, _random));
          continue;
        } on SocketException {
          if (!canRetry || !_hasTimeFor(started)) rethrow;
          await _wait(backoff(attempt, _random));
          continue;
        }

        if (canRetry && shouldRetryStatus(response.statusCode) && _hasTimeFor(started)) {
          final delay = _delayFor(response, attempt);
          if (delay != null) {
            await _wait(delay);
            continue;
          }
        }
        return response;
      }
    } finally {
      if (token != null) ApiActivity.end(token);
    }
  }

  bool _hasTimeFor(DateTime started) => budget - _now().difference(started) >= minimumAttempt;

  /// How long to wait before retrying [response], or null when it must not be retried.
  Duration? _delayFor(http.Response response, int attempt) {
    if (response.statusCode != 429) return backoff(attempt, _random);
    final asked = int.tryParse(response.headers['retry-after'] ?? '');
    if (asked == null) return backoff(attempt, _random);
    final wait = Duration(seconds: asked);
    return wait <= maxRetryAfter ? wait : null;
  }

  Future<http.Response> _once(
    String method,
    Uri url,
    Map<String, String>? headers,
    String? body,
    Duration timeout,
  ) async {
    final abort = Completer<void>();
    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      if (!abort.isCompleted) abort.complete();
    });
    final request = http.AbortableRequest(method, url, abortTrigger: abort.future);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;
    try {
      // Raced against the abort as well: a client that ignores abortTrigger must not keep us waiting.
      final streamed = await Future.any<http.StreamedResponse>([
        client.send(request),
        abort.future.then<http.StreamedResponse>((_) => throw http.RequestAbortedException(url)),
      ]);
      return await Future.any<http.Response>([
        http.Response.fromStream(streamed),
        abort.future.then<http.Response>((_) => throw http.RequestAbortedException(url)),
      ]);
    } on http.RequestAbortedException {
      if (timedOut) throw TimeoutException('request timed out', timeout);
      rethrow;
    } finally {
      timer.cancel();
    }
  }
}

Duration maxDuration(Duration a, Duration b) => a > b ? a : b;
