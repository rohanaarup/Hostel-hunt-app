import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/http_transport.dart';
import 'package:rohii_hostel_hunt/core/observability/debug_log.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/core/observability/privacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central HTTP client for all Django API calls.
///
/// Handles:
/// - Base URL configuration (change [baseUrl] for production)
/// - JWT Bearer token injection for authenticated requests
/// - Automatic token refresh on 401 responses (one refresh at a time, shared by every waiting request)
/// - Consistent request/response envelope
///
/// Every request leaves through [HttpTransport] (one shared connection, real timeouts, retry for reads
/// only, a signal for the "waking the server" banner).
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static HttpTransport _transport = HttpTransport();

  /// Swap the transport (tests: no real waiting between retries, a fixed random source).
  @visibleForTesting
  static void configureTransport({
    http.Client Function()? clientFactory,
    Wait? wait,
    Random? random,
    DateTime Function()? now,
  }) {
    _transport.reset();
    _transport = HttpTransport(clientFactory: clientFactory, wait: wait, random: random, now: now);
  }

  /// Forget the shared connection so the next request builds a new client (tests that switch the
  /// client with `http.runWithClient`).
  @visibleForTesting
  static void resetConnections() => _transport.reset();

  static void Function()? _onUnauthorized;

  static void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────────────────

  // Defaults to the deployed Render backend so every normal run/build
  // resolves to a reachable server. Razorpay's webhook is registered against
  // the Render URL and cannot reach a local LAN IP, so payment testing on a
  // real device or emulator specifically requires this to stay false.
  // Override for local Django dev server testing with:
  //   flutter run --dart-define=USE_LOCAL_BACKEND=true
  static const bool useLocalBackend = bool.fromEnvironment(
    'USE_LOCAL_BACKEND',
    defaultValue: false,
  );
  static const String localApiHost = String.fromEnvironment(
    'LOCAL_API_HOST',
    defaultValue: '192.168.1.51',
  );

  /// Point the app at any server, for example staging:
  ///   flutter run --dart-define=API_BASE_URL=https://hostel-hunt-admin-pannel.onrender.com/api/v1
  /// Wins over everything else when set.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Platform-aware base URL:
  ///   API_BASE_URL set → that
  ///   Flutter Web      → http://127.0.0.1:8000  (localhost, same machine)
  ///   Android          → http://LOCAL_API_HOST:8000
  ///   iOS sim/dev      → http://localhost:8000
  ///   Production       → https://hostel-hunt-backend.onrender.com/api/v1
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (!useLocalBackend) {
      return 'https://hostel-hunt-backend.onrender.com/api/v1';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://$localApiHost:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Token Storage
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_access', accessToken);
    await prefs.setString('jwt_refresh', refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_access');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_refresh');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_access');
    await prefs.remove('jwt_refresh');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
  }

  /// The saved login, read BEFORE it is cleared, so [revoke] can still use it afterwards. Null when
  /// nobody is logged in.
  Future<SessionTokens?> captureSession() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) return null;
    return SessionTokens(access, refresh);
  }

  /// Asks the server to forget this device's refresh token, so a copied token stops working after
  /// Log Out. Best effort: it never throws, never retries and never blocks the screen for long. The
  /// login is cleared on the phone whether or not this reaches the server.
  Future<void> revoke(SessionTokens session) async {
    try {
      await _transport.send(
        'POST',
        Uri.parse('$baseUrl/auth/logout/'),
        headers: _headers(accessToken: session.access),
        body: jsonEncode({'refresh': session.refresh}),
        timeout: const Duration(seconds: 8),
        trackSlow: false,
      );
    } catch (e) {
      debugLog('revoke session: ${e.runtimeType}');
    }
  }

  /// [captureSession] then [revoke], for callers that do not clear the login in between.
  Future<void> revokeSession() async {
    final session = await captureSession();
    if (session != null) await revoke(session);
  }

  Future<void> _handleUnauthorized() async {
    await clearTokens();
    _onUnauthorized?.call();
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Leaves a breadcrumb for a failed call: method, route template and status
  /// only (status 0 = no response: timeout or network failure). Never the
  /// query string, headers or any body.
  static void _crumb(String method, String path, int status) {
    if (status != 0 && status < 400) return;
    final route = routeTemplate(path);
    errorReporter.breadcrumb(
      category: 'api',
      message: '$method $route -> $status',
      data: {'method': method, 'route': route, 'status': status},
    );
  }

  /// Records a failed call: a breadcrumb (method, route template, status only), and a Sentry report
  /// when the failure is one a developer should hear about (a 5xx, an unreadable reply, a 405, a bug).
  static void _noteFailure(String method, String path, ApiError error, {Object? original, StackTrace? stack}) {
    _crumb(method, path, error.statusCode);
    if (error.worthReporting) {
      errorReporter.report(
        original ?? ApiException(error),
        stack,
        hint: 'api: $method ${routeTemplate(path)} -> ${error.statusCode}',
      );
    }
  }

  /// An exception from a call that produced no response, as an [ApiError].
  static ApiError _errorFromException(String method, String path, Object e, StackTrace st) {
    final error = ApiErrorReader.fromException(e);
    debugLog('API Error ($method): ${e.runtimeType}');
    _noteFailure(method, path, error, original: e, stack: st);
    return error;
  }

  Map<String, String> _headers({String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// A read goes through the retrying path, except payment status polling, which keeps its own
  /// schedule (the poller must never have two requests in flight).
  static bool _retriesReads(String path) => !path.startsWith('/payments/');

  Future<http.Response> _get(String path, Map<String, String>? queryParams, String? token) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return _transport.send(
      'GET',
      uri,
      headers: _headers(accessToken: token),
      retry: _retriesReads(path),
    );
  }

  Future<http.Response> _write(String method, String path, Map<String, dynamic> body, String? token) {
    return _transport.send(
      method,
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken: token),
      body: jsonEncode(body),
    );
  }

  /// Public POST — no auth header (login, register, OTP)
  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _write('POST', path, body, null);
      final result = ApiResponse.fromResponse(response);
      _noteResult('POST', path, result.statusCode, result.error);
      return result;
    } catch (e, st) {
      return ApiResponse.fromError(_errorFromException('POST', path, e, st));
    }
  }

  static void _noteResult(String method, String path, int status, ApiError? error) {
    if (error == null) {
      _crumb(method, path, status);
    } else {
      _noteFailure(method, path, error);
    }
  }

  /// Authenticated POST — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authPost(String path, Map<String, dynamic> body) async {
    return _authenticatedRequest('POST', path, (token) => _write('POST', path, body, token));
  }

  /// Authenticated GET — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authGet(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _authenticatedRequest('GET', path, (token) => _get(path, queryParams, token));
  }

  /// Authenticated PATCH — sends JSON body, retries once on 401
  Future<ApiResponse> authPatch(String path, Map<String, dynamic> body) async {
    return _authenticatedRequest('PATCH', path, (token) => _write('PATCH', path, body, token));
  }

  /// Authenticated multipart POST — for file uploads (e.g. profile photo).
  ///
  /// [onProgress] gets 0.0 to 1.0 as the bytes are handed to the network (approximate: the OS
  /// buffers a little). Completing [cancel] aborts the upload; the result then has
  /// `error.kind == ApiErrorKind.cancelled`. Like every authenticated call it refreshes the token
  /// and retries once after a 401. An upload is never retried after a timeout or a network error.
  Future<ApiResponse> authMultipartPost(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    void Function(double progress)? onProgress,
    Future<void>? cancel,
  }) async {
    final parts = mimeType.split('/');
    final contentType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('image', 'jpeg');

    return _authenticatedRequest('POST', path, (token) async {
      // A multipart request can only be sent once, so each attempt builds its own.
      final abort = Completer<void>();
      var timedOut = false;
      unawaited(cancel?.then((_) {
        if (!abort.isCompleted) abort.complete();
      }));
      final timer = Timer(HttpTransport.uploadTimeout, () {
        timedOut = true;
        if (!abort.isCompleted) abort.complete();
      });
      final url = Uri.parse('$baseUrl$path');
      final request = _UploadRequest('POST', url, onProgress: onProgress, abortTrigger: abort.future);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename, contentType: contentType),
      );
      try {
        final streamed = await Future.any<http.StreamedResponse>([
          _transport.client.send(request),
          abort.future.then<http.StreamedResponse>((_) => throw http.RequestAbortedException(url)),
        ]);
        return await Future.any<http.Response>([
          http.Response.fromStream(streamed),
          abort.future.then<http.Response>((_) => throw http.RequestAbortedException(url)),
        ]);
      } on http.RequestAbortedException {
        if (timedOut) throw TimeoutException('upload timed out', HttpTransport.uploadTimeout);
        rethrow;
      } finally {
        timer.cancel();
      }
    });
  }

  /// Public GET — no auth header. Returns raw decoded JSON body.
  /// Use for public endpoints that don't follow the {success, message, data} envelope
  /// (e.g. DRF paginated list views, detail views).
  Future<RawApiResponse> getRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await _get(path, queryParams, null);
      final result = RawApiResponse.fromResponse(response);
      _noteResult('GET', path, result.statusCode, result.error);
      return result;
    } catch (e, st) {
      return RawApiResponse.fromError(_errorFromException('GET', path, e, st));
    }
  }

  /// Authenticated GET — returns raw decoded JSON body.
  /// Use for DRF endpoints that return paginated or non-envelope responses.
  Future<RawApiResponse> authGetRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _authenticatedRawRequest('GET', path, (token) => _get(path, queryParams, token));
  }

  /// Authenticated POST — returns raw decoded JSON body.
  /// Use for DRF endpoints that return raw response without envelope (e.g. ModelViewSet POST).
  Future<RawApiResponse> authPostRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _authenticatedRawRequest('POST', path, (token) => _write('POST', path, body, token));
  }

  /// Authenticated DELETE - returns the raw decoded JSON body.
  Future<RawApiResponse> authDeleteRaw(String path) async {
    return _authenticatedRawRequest('DELETE', path, (token) {
      return _transport.send(
        'DELETE',
        Uri.parse('$baseUrl$path'),
        headers: _headers(accessToken: token),
      );
    });
  }

  /// Sends an authenticated request. A 401 triggers one token refresh and one retry.
  ///
  /// Only a refresh the server REJECTS ends the session. If the refresh could not be attempted
  /// (timeout, no connection, a 5xx while the server wakes up) the tokens are kept and the caller
  /// gets that error instead, so a bad moment on the network never logs anyone out.
  ///
  /// Several requests can get a 401 together: the refresh runs once for all of them, and one that
  /// finds the token already replaced by somebody else's refresh just retries with the new one.
  Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(String? token) request,
  ) async {
    final used = await getAccessToken();
    final response = await request(used);
    if (response.statusCode != 401) return response;

    final current = await getAccessToken();
    if (current != null && current.isNotEmpty && current != used) return request(current);

    final refresh = await _refreshToken();
    if (refresh.ok) return request(await getAccessToken());
    if (refresh.rejected) {
      // Every request that was waiting on this refresh sees the same answer; the session ends once.
      if (!refresh.sessionEnded) {
        refresh.sessionEnded = true;
        await _handleUnauthorized();
      }
      throw const ApiException(ApiError.sessionExpired);
    }
    throw ApiException(refresh.error!);
  }

  /// Wraps an authenticated request with automatic token refresh on 401
  Future<ApiResponse> _authenticatedRequest(
    String method,
    String path,
    Future<http.Response> Function(String? token) request,
  ) async {
    try {
      final response = await _sendAuthenticated(request);
      final result = ApiResponse.fromResponse(response);
      _noteResult(method, path, result.statusCode, result.error);
      return result;
    } on ApiException catch (e) {
      _noteFailure(method, path, e.error);
      return ApiResponse.fromError(e.error);
    } catch (e, st) {
      return ApiResponse.fromError(_errorFromException(method, path, e, st));
    }
  }

  /// Wraps an authenticated request with automatic token refresh on 401.
  /// Returns raw decoded JSON instead of ApiResponse envelope.
  Future<RawApiResponse> _authenticatedRawRequest(
    String method,
    String path,
    Future<http.Response> Function(String? token) request,
  ) async {
    try {
      final response = await _sendAuthenticated(request);
      final result = RawApiResponse.fromResponse(response);
      _noteResult(method, path, result.statusCode, result.error);
      return result;
    } on ApiException catch (e) {
      _noteFailure(method, path, e.error);
      return RawApiResponse.fromError(e.error);
    } catch (e, st) {
      return RawApiResponse.fromError(_errorFromException(method, path, e, st));
    }
  }

  Future<_Refresh>? _refreshing;

  /// Gets a new access token from /auth/token/refresh/. Only one refresh runs at a time: a caller
  /// that arrives while one is under way waits for its result instead of starting another.
  Future<_Refresh> _refreshToken() {
    final running = _refreshing;
    if (running != null) return running;
    final started = _refreshOnce();
    _refreshing = started;
    started.whenComplete(() {
      if (identical(_refreshing, started)) _refreshing = null;
    });
    return started;
  }

  Future<_Refresh> _refreshOnce() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return _Refresh.rejected();

      final response = await _transport.send(
        'POST',
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: _headers(),
        body: jsonEncode({'refresh': refreshToken}),
        timeout: const Duration(seconds: 20),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data is Map ? data['access'] as String? : null;
        final newRefresh = data is Map ? data['refresh'] as String? : null;
        if (newAccess != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_access', newAccess);
          if (newRefresh != null) {
            await prefs.setString('jwt_refresh', newRefresh);
          }
          return _Refresh.ok();
        }
        return _Refresh.rejected();
      }
      _crumb('POST', '/auth/token/refresh/', response.statusCode);
      // 400, 401 and 403: the server looked at the refresh token and refused it.
      if (const {400, 401, 403}.contains(response.statusCode)) return _Refresh.rejected();
      // Anything else (5xx, 429...) says nothing about the token: keep it.
      return _Refresh.unreachable(ApiErrorReader.fromResponse(response));
    } catch (e) {
      debugLog('API Error (_refreshToken): ${e.runtimeType}');
      _crumb('POST', '/auth/token/refresh/', 0);
      return _Refresh.unreachable(ApiErrorReader.fromException(e));
    }
  }
}

/// The two tokens of a login, kept for a moment after Log Out so the server can be told.
class SessionTokens {
  const SessionTokens(this.access, this.refresh);
  final String access;
  final String refresh;
}

/// How a token refresh ended.
class _Refresh {
  _Refresh.ok() : ok = true, rejected = false, error = null;
  _Refresh.rejected() : ok = false, rejected = true, error = null;
  _Refresh.unreachable(ApiError this.error) : ok = false, rejected = false;

  final bool ok;
  final bool rejected;
  final ApiError? error;

  /// Set by the first request that ended the session after a rejection, so the others do not repeat it.
  bool sessionEnded = false;
}

/// A multipart request that can report progress and be aborted. (http's own
/// AbortableMultipartRequest is final, so it cannot be extended to count bytes.)
class _UploadRequest extends http.MultipartRequest with http.Abortable {
  _UploadRequest(super.method, super.url, {this.onProgress, this.abortTrigger});

  final void Function(double progress)? onProgress;

  @override
  final Future<void>? abortTrigger;

  @override
  http.ByteStream finalize() {
    final stream = super.finalize();
    final report = onProgress;
    if (report == null) return stream;
    final total = contentLength;
    var sent = 0;
    return http.ByteStream(
      stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            if (total > 0) report((sent / total).clamp(0.0, 1.0));
            sink.add(chunk);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Response Model
// ─────────────────────────────────────────────────────────────────────────────

class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final int statusCode;

  /// Set when the call failed: what kind of failure, in words for the user.
  final ApiError? error;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.error,
  });

  factory ApiResponse.fromResponse(http.Response response) {
    final decoded = _tryDecode(response);
    final body = decoded is Map<String, dynamic> ? decoded : null;
    final dataField = body?['data'];
    final data = dataField is Map<String, dynamic> ? dataField : null;

    final isFailure = response.statusCode >= 400 || (body != null && body['success'] == false);
    if (isFailure) {
      return ApiResponse.fromError(ApiErrorReader.fromResponse(response), data: data);
    }
    if (body == null) {
      // A 2xx that is not an object: not something the app can use.
      return ApiResponse.fromError(ApiError.unreadable(response.statusCode));
    }
    return ApiResponse(
      success: true,
      message: body['message'] as String? ?? '',
      data: data,
      statusCode: response.statusCode,
    );
  }

  factory ApiResponse.fromError(ApiError error, {Map<String, dynamic>? data}) => ApiResponse(
        success: false,
        message: error.message,
        data: data,
        statusCode: error.statusCode,
        error: error,
      );

  static dynamic _tryDecode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
    } on FormatException {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Raw Response Model (for DRF endpoints without {success, message, data} envelope)
// ─────────────────────────────────────────────────────────────────────────────

class RawApiResponse {
  final bool success;
  final String message;
  final dynamic body; // raw decoded JSON (Map or List)
  final int statusCode;

  /// Set when the call failed: what kind of failure, in words for the user.
  final ApiError? error;

  const RawApiResponse({
    required this.success,
    required this.message,
    this.body,
    required this.statusCode,
    this.error,
  });

  factory RawApiResponse.fromResponse(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    dynamic decoded;
    var readable = true;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        readable = false;
      }
    }

    if (response.statusCode >= 400) {
      return RawApiResponse.fromError(ApiErrorReader.fromResponse(response), body: decoded);
    }
    if (!readable) {
      // Status only: the URL carries query strings and the body can hold personal data.
      debugLog('API Error (RawApiResponse.fromResponse): not JSON, status ${response.statusCode}');
      return RawApiResponse.fromError(ApiError.unreadable(response.statusCode));
    }
    return RawApiResponse(success: true, message: '', body: decoded, statusCode: response.statusCode);
  }

  /// The failure as an exception to throw from a provider (its message is already in words).
  ApiException toException() => ApiException(
        error ??
            ApiError(
              kind: ApiErrorKind.unexpected,
              statusCode: statusCode,
              message: message.isEmpty ? ApiError.unexpected.message : message,
            ),
      );

  factory RawApiResponse.fromError(ApiError error, {dynamic body}) => RawApiResponse(
        success: false,
        message: error.message,
        body: body,
        statusCode: error.statusCode,
        error: error,
      );
}
