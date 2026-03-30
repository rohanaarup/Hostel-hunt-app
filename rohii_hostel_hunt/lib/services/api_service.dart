import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────────────────

  /// Android emulator → host machine: use 10.0.2.2
  /// Physical device → dev machine IP: e.g. 192.168.1.5:8000
  /// Production: https://api.yourdomain.com
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const Duration _timeout = Duration(seconds: 30);

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
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeoutError();
    }
  }

  /// Authenticated POST — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authPost(String path, Map<String, dynamic> body) async {
    return _authenticatedRequest(() async {
      final token = await getAccessToken();
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(accessToken: token),
        body: jsonEncode(body),
      );
    });
  }

  /// Authenticated GET — injects JWT Bearer token, retries once on 401
  Future<ApiResponse> authGet(String path,
      {Map<String, String>? queryParams}) async {
    return _authenticatedRequest(() async {
      final token = await getAccessToken();
      final uri = Uri.parse('$baseUrl$path')
          .replace(queryParameters: queryParams);
      return http.get(uri, headers: _headers(accessToken: token));
    });
  }

  /// Wraps an authenticated request with automatic token refresh on 401
  Future<ApiResponse> _authenticatedRequest(
      Future<http.Response> Function() request) async {
    try {
      var response = await request().timeout(_timeout);

      if (response.statusCode == 401) {
        // Try to refresh the access token
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await request().timeout(_timeout);
        } else {
          await clearTokens();
          return ApiResponse(
            success: false,
            message: 'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return ApiResponse.fromResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeoutError();
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
    } catch (_) {
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
    } catch (_) {
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
