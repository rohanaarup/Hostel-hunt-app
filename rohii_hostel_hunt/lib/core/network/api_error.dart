import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The one place that turns "something went wrong talking to the server" into text a person can
/// act on. ApiResponse and RawApiResponse both build their failures here, providers throw
/// [ApiException], and screens show [userMessageOf]. Nothing else formats a network error.
///
/// Shapes of failure it understands (all produced by our Django backend or the host in front of it):
///   * the envelope        {success:false, message, errors: {field: "text" | ["text"]}}
///   * plain DRF           {detail: "..."}  (401, 403, 404, 405, 429 and 5xx) and {code, messages}
///   * DRF field errors    {field: ["text"]}, {non_field_errors: [...]} or a bare ["text"]
///   * a proxy / HTML page (Render while it wakes up: 502, 503, 504; a wrong route: 404)
///   * transport failures  timeout, no connection, a cancelled request, an unreadable reply
enum ApiErrorKind {
  offline,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  methodNotAllowed,
  throttled,
  validation,
  server,
  unavailable,
  unreadable,
  cancelled,
  unexpected,
}

class ApiError {
  const ApiError({
    required this.kind,
    required this.message,
    this.statusCode = 0,
    this.fieldErrors = const {},
    this.retryAfter,
    this.serverDetail,
  });

  final ApiErrorKind kind;

  /// Text for the user. Never HTML, JSON, a stack trace or an exception name.
  final String message;

  /// HTTP status, or 0 when there was no response (timeout, offline, cancelled).
  final int statusCode;

  /// Per-field messages from the server, for forms that want to mark the field.
  final Map<String, String> fieldErrors;

  final Duration? retryAfter;

  /// What the server said, for logs and Sentry only. Never shown.
  final String? serverDetail;

  /// Whether a developer should hear about it. Offline, timeouts, an expired session, throttling,
  /// validation and a server that is still waking up are normal life, not bugs.
  bool get worthReporting =>
      kind == ApiErrorKind.server ||
      kind == ApiErrorKind.unreadable ||
      kind == ApiErrorKind.methodNotAllowed ||
      kind == ApiErrorKind.unexpected;

  static const sessionExpired = ApiError(
    kind: ApiErrorKind.unauthorized,
    statusCode: 401,
    message: 'Your session has expired. Please log in again.',
  );

  static const offline = ApiError(
    kind: ApiErrorKind.offline,
    message: 'No internet connection. Check your network and try again.',
  );

  static const timeout = ApiError(
    kind: ApiErrorKind.timeout,
    message: 'The server took too long to answer. Check your connection and try again.',
  );

  static const cancelled = ApiError(kind: ApiErrorKind.cancelled, message: 'Cancelled.');

  static const unexpected = ApiError(
    kind: ApiErrorKind.unexpected,
    message: 'Something went wrong. Please try again.',
  );

  static ApiError unreadable(int statusCode) => ApiError(
        kind: ApiErrorKind.unreadable,
        statusCode: statusCode,
        message: "The server sent a reply the app couldn't read. Please try again.",
      );
}

/// Thrown by providers when a request failed; carries the already-worded [error].
class ApiException implements Exception {
  const ApiException(this.error);

  final ApiError error;

  String get message => error.message;

  @override
  String toString() => error.message;
}

/// The text to show for any error caught in a screen or provider. An [ApiException] shows its
/// own worded message; anything else is a bug, so the user gets a plain sentence and the caller
/// is expected to report the real error.
String userMessageOf(Object error) {
  if (error is ApiException) return error.message;
  return ApiError.unexpected.message;
}

class ApiErrorReader {
  const ApiErrorReader._();

  /// A failed HTTP response (any status of 400 or more).
  static ApiError fromResponse(http.Response response) {
    final status = response.statusCode;
    final body = _decode(response);
    final parsed = _Parsed.from(body);
    final retryAfter = status == 429 ? _retryAfter(response.headers, parsed.detail) : null;

    // Text the server wrote on purpose for people (our envelope) wins over the generic wording.
    final custom = parsed.envelope ? parsed.message : null;

    ApiError make(ApiErrorKind kind, String standard) => ApiError(
          kind: kind,
          statusCode: status,
          message: custom ?? standard,
          fieldErrors: parsed.fields,
          retryAfter: retryAfter,
          serverDetail: parsed.detail ?? parsed.message,
        );

    switch (status) {
      case 401:
        return make(ApiErrorKind.unauthorized, ApiError.sessionExpired.message);
      case 403:
        return make(ApiErrorKind.forbidden, "You don't have permission to do that.");
      case 404:
        return make(ApiErrorKind.notFound, "We couldn't find that.");
      case 405:
        return make(
          ApiErrorKind.methodNotAllowed,
          "This isn't supported by the server yet. Please update the app.",
        );
      case 408:
        return make(ApiErrorKind.timeout, ApiError.timeout.message);
      case 413:
        return make(ApiErrorKind.validation, 'That file is too large to upload.');
      case 429:
        return make(ApiErrorKind.throttled, _throttledMessage(retryAfter));
      case 502:
      case 503:
      case 504:
        return make(
          ApiErrorKind.unavailable,
          'The server is starting up. Please try again in a few seconds.',
        );
    }
    if (status >= 500) {
      return make(ApiErrorKind.server, 'The server had a problem. Please try again in a moment.');
    }
    // 400 and the other 4xx: the field message the server gave, else a plain sentence.
    return make(
      ApiErrorKind.validation,
      parsed.message ?? 'The request was not accepted. Please check your details and try again.',
    );
  }

  /// A failure that never produced a response.
  static ApiError fromException(Object error) {
    if (error is ApiException) return error.error;
    if (error is TimeoutException) return ApiError.timeout;
    if (error is http.RequestAbortedException) return ApiError.cancelled;
    if (error is http.ClientException) return ApiError.offline;
    if (error is FormatException) return ApiError.unreadable(0);
    // dart:io types are matched by name so this file also compiles for the web build.
    const offlineTypes = {'SocketException', 'HandshakeException', 'TlsException', 'OSError', 'WebSocketException'};
    if (offlineTypes.contains(error.runtimeType.toString())) return ApiError.offline;
    return ApiError.unexpected;
  }

  /// The decoded JSON body, or null when it is empty or not JSON (an HTML page).
  static dynamic _decode(http.Response response) {
    try {
      final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
      if (text.isEmpty) return null;
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static Duration? _retryAfter(Map<String, String> headers, String? detail) {
    final fromHeader = int.tryParse(headers['retry-after']?.trim() ?? '');
    if (fromHeader != null && fromHeader > 0) return Duration(seconds: fromHeader);
    final match = RegExp(r'(\d+)\s*second').firstMatch(detail ?? '');
    final seconds = int.tryParse(match?.group(1) ?? '');
    if (seconds != null && seconds > 0) return Duration(seconds: seconds);
    return null;
  }

  static String _throttledMessage(Duration? wait) {
    if (wait == null) return 'Too many attempts. Please wait a moment and try again.';
    final seconds = wait.inSeconds;
    if (seconds < 60) return 'Too many attempts. Try again in $seconds ${seconds == 1 ? 'second' : 'seconds'}.';
    final minutes = (seconds / 60).ceil();
    return 'Too many attempts. Try again in $minutes ${minutes == 1 ? 'minute' : 'minutes'}.';
  }
}

/// What could be read out of a failure body.
class _Parsed {
  _Parsed({required this.envelope, this.message, this.detail, this.fields = const {}});

  /// True when the body is our `{success:false, message, errors}` envelope.
  final bool envelope;

  /// The best human text in the body: the first field message, else the envelope's message.
  final String? message;

  /// DRF's `detail` text (for logs only).
  final String? detail;

  final Map<String, String> fields;

  static const _notFields = {'detail', 'code', 'messages', 'success', 'message', 'errors'};

  factory _Parsed.from(dynamic body) {
    if (body is List) {
      return _Parsed(envelope: false, message: _first(body));
    }
    if (body is! Map) return _Parsed(envelope: false);

    final detail = body['detail'] is String ? body['detail'] as String : null;

    if (body['success'] == false) {
      final fields = _fieldMap(body['errors']);
      final envelopeMessage = body['message'] is String ? (body['message'] as String).trim() : '';
      final text = fields.values.isNotEmpty
          ? fields.values.first
          : (envelopeMessage.isNotEmpty ? envelopeMessage : null);
      return _Parsed(envelope: text != null, message: text, detail: detail, fields: fields);
    }

    // Plain DRF field errors: {field: ["text"]}
    final fields = _fieldMap({
      for (final entry in body.entries)
        if (!_notFields.contains(entry.key)) entry.key.toString(): entry.value,
    });
    final nonField = _first(body['non_field_errors']);
    return _Parsed(
      envelope: false,
      message: nonField ?? (fields.values.isNotEmpty ? fields.values.first : null),
      detail: detail,
      fields: fields,
    );
  }

  static Map<String, String> _fieldMap(dynamic errors) {
    if (errors is! Map) return const {};
    final out = <String, String>{};
    for (final entry in errors.entries) {
      final text = _first(entry.value);
      if (text != null) out[entry.key.toString()] = text;
    }
    return out;
  }

  /// The first non-empty string inside a string, list or map.
  static String? _first(dynamic value) {
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is List) {
      for (final item in value) {
        final text = _first(item);
        if (text != null) return text;
      }
    }
    if (value is Map) {
      for (final item in value.values) {
        final text = _first(item);
        if (text != null) return text;
      }
    }
    return null;
  }
}
