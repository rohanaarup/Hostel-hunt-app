import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central HTTP client for all Django API calls.
///
/// Handles:
/// - Base URL configuration (change [baseUrl] for production)
/// - JWT Bearer token injection for authenticated requests
/// - Automatic token refresh on 401 responses
/// - Consistent request/response envelope
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static void Function()? _onUnauthorized;

  static void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────────────────

  // Toggle this to true if you want to test against your local Django server
  static const bool useLocalBackend = true;

  /// Platform-aware base URL:
  ///   Flutter Web  → http://127.0.0.1:8001  (localhost, same machine)
  ///   Android emu  → http://10.0.2.2:8001   (emulator alias for host)
  ///   iOS sim/dev  → http://localhost:8001
  ///   Production   → https://rohii-backend.onrender.com/api
  static String get baseUrl {
    if (!useLocalBackend) {
      // TODO: Replace with your ACTUAL Render backend URL!
      return 'https://hostel-hunt-backend.onrender.com/api/v1';
    }

    if (kIsWeb) {
      // Flutter Web runs in Chrome — can reach the host directly
      return 'http://127.0.0.1:8000/api/v1';
    }
    if (Platform.isAndroid) {
      // For physical Android devices on the same Wi-Fi to reach your PC
      return 'http://192.168.1.43:8000/api/v1';
    }
    // iOS simulator and macOS can reach localhost directly
    return 'http://localhost:8000/api/v1';
  }

  static const Duration _timeout = Duration(seconds: 60);

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

  /// Public POST — no auth header (login, register, OTP)
  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return ApiResponse.fromResponse(response);
    } on TimeoutException {
      return ApiResponse.timeoutError();
    } catch (e) {
      debugPrint('API Error (post): $e');
      return ApiResponse.networkError();
    }
  }

  /// Authenticated POST — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authPost(String path, Map<String, dynamic> body) async {
    return _authenticatedRequest(() async {
      final token = await getAccessToken();
      debugPrint('[API] authPost $path | Token: ${token != null ? "present" : "MISSING"}');
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(accessToken: token),
        body: jsonEncode(body),
      );
    });
  }

  /// Authenticated GET — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authGet(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _authenticatedRequest(() async {
      final token = await getAccessToken();
      debugPrint('[API] authGet $path | Token: ${token != null ? "present" : "MISSING"}');
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParams);
      return http.get(uri, headers: _headers(accessToken: token));
    });
  }

  /// Authenticated PATCH — sends JSON body, retries once on 401
  Future<ApiResponse> authPatch(String path, Map<String, dynamic> body) async {
    return _authenticatedRequest(() async {
      final token = await getAccessToken();
      return http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers(accessToken: token),
        body: jsonEncode(body),
      );
    });
  }

  /// Authenticated multipart POST — for file uploads (e.g. profile photo)
  Future<ApiResponse> authMultipartPost(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final token = await getAccessToken();
      final uri = Uri.parse('$baseUrl$path');
      final parts = mimeType.split('/');
      final contentType = parts.length == 2
          ? MediaType(parts[0], parts[1])
          : MediaType('image', 'jpeg');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: contentType,
        ));
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return ApiResponse.fromResponse(response);
    } on TimeoutException {
      return ApiResponse.timeoutError();
    } catch (e) {
      debugPrint('Multipart upload error: $e');
      return ApiResponse.networkError();
    }
  }

  /// Public GET — no auth header. Returns raw decoded JSON body.
  /// Use for public endpoints that don't follow the {success, message, data} envelope
  /// (e.g. DRF paginated list views, detail views).
  Future<RawApiResponse> getRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers())
          .timeout(_timeout);
      return RawApiResponse.fromResponse(response);
    } on TimeoutException {
      return RawApiResponse.timeoutError();
    } catch (e) {
      debugPrint('API Error (getRaw): $e');
      return RawApiResponse.networkError();
    }
  }

  /// Authenticated GET — returns raw decoded JSON body.
  /// Use for DRF endpoints that return paginated or non-envelope responses.
  Future<RawApiResponse> authGetRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _authenticatedRawRequest(() async {
      final token = await getAccessToken();
      debugPrint('[API] authGetRaw $path | Token: ${token != null ? "present" : "MISSING"}');
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParams);
      return http.get(uri, headers: _headers(accessToken: token));
    });
  }

  /// Authenticated POST — returns raw decoded JSON body.
  /// Use for DRF endpoints that return raw response without envelope (e.g. ModelViewSet POST).
  Future<RawApiResponse> authPostRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _authenticatedRawRequest(() async {
      final token = await getAccessToken();
      debugPrint('[API] authPostRaw $path | Token: ${token != null ? "present" : "MISSING"}');
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(accessToken: token),
        body: jsonEncode(body),
      );
    });
  }

  /// Wraps an authenticated request with automatic token refresh on 401
  Future<ApiResponse> _authenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request().timeout(_timeout);

      if (response.statusCode == 401) {
        // Try to refresh the access token
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await request().timeout(_timeout);
        } else {
          await _handleUnauthorized();
          return ApiResponse(
            success: false,
            message: 'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return ApiResponse.fromResponse(response);
    } on TimeoutException {
      return ApiResponse.timeoutError();
    } catch (_) {
      return ApiResponse.networkError();
    }
  }

  /// Wraps an authenticated request with automatic token refresh on 401.
  /// Returns raw decoded JSON instead of ApiResponse envelope.
  Future<RawApiResponse> _authenticatedRawRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request().timeout(_timeout);

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await request().timeout(_timeout);
        } else {
          await _handleUnauthorized();
          return const RawApiResponse(
            success: false,
            message: 'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return RawApiResponse.fromResponse(response);
    } on TimeoutException {
      return RawApiResponse.timeoutError();
    } catch (_) {
      return RawApiResponse.networkError();
    }
  }

  /// Calls /auth/token/refresh/ to get a new access token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/token/refresh/'),
            headers: _headers(),
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;
        if (newAccess != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_access', newAccess);
          if (newRefresh != null) {
            await prefs.setString('jwt_refresh', newRefresh);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('API Error (_refreshToken): $e');
      return false;
    }
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

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ApiResponse.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? (response.statusCode < 400),
        message: body['message'] as String? ?? '',
        data: body['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('API Error (ApiResponse.fromResponse): $e');
      return ApiResponse(
        success: false,
        message: 'Unexpected server response.',
        statusCode: response.statusCode,
      );
    }
  }

  factory ApiResponse.networkError() => const ApiResponse(
    success: false,
    message: 'No internet connection. Please check your network.',
    statusCode: 0,
  );

  factory ApiResponse.timeoutError() => const ApiResponse(
    success: false,
    message: 'Request timed out. Please try again.',
    statusCode: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Raw Response Model (for DRF endpoints without {success, message, data} envelope)
// ─────────────────────────────────────────────────────────────────────────────

class RawApiResponse {
  final bool success;
  final String message;
  final dynamic body; // raw decoded JSON (Map or List)
  final int statusCode;

  const RawApiResponse({
    required this.success,
    required this.message,
    this.body,
    required this.statusCode,
  });

  factory RawApiResponse.fromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return RawApiResponse(
        success: response.statusCode < 400,
        message: response.statusCode < 400
            ? ''
            : (decoded is Map
                  ? decoded['detail'] as String? ?? 'Request failed.'
                  : 'Request failed.'),
        body: decoded,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('API Error (RawApiResponse.fromResponse): $e');
      debugPrint('URL: ${response.request?.url}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      return RawApiResponse(
        success: false,
        message: 'Unexpected server response.',
        statusCode: response.statusCode,
      );
    }
  }

  factory RawApiResponse.networkError() => const RawApiResponse(
    success: false,
    message: 'No internet connection. Please check your network.',
    statusCode: 0,
  );

  factory RawApiResponse.timeoutError() => const RawApiResponse(
    success: false,
    message: 'Request timed out. Please try again.',
    statusCode: 0,
  );
}
