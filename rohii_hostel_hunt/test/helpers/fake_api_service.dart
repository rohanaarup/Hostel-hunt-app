import 'dart:convert';
import 'dart:io';

import 'package:rohii_hostel_hunt/core/network/api_service.dart';

/// An ApiService that never touches the network. Public list endpoints answer from the recorded
/// fixture; everything authenticated answers "not logged in".
class FakeApiService implements ApiService {
  final List<String> calls = [];

  /// The query parameters of every public GET, in order (null when none were sent).
  final List<Map<String, String>?> queries = [];

  /// Answer public GETs yourself. When null, /hostels/ answers from the fixture.
  RawApiResponse Function(String path, Map<String, String>? query)? onGetRaw;

  /// Whether the fake user is signed in. Authenticated GETs answer from [onAuthGetRaw] when set.
  bool loggedIn = false;
  bool tokensCleared = false;
  Future<RawApiResponse> Function(String path)? onAuthGetRaw;

  /// Like [onAuthGetRaw] but also sees the query parameters (paging).
  Future<RawApiResponse> Function(String path, Map<String, String>? query)? onAuthGetRawWithQuery;
  Future<RawApiResponse> Function(String path, Map<String, dynamic> body)? onAuthPostRaw;
  Future<RawApiResponse> Function(String path)? onAuthDeleteRaw;

  /// Answer PATCH and multipart calls yourself.
  Future<ApiResponse> Function(String path, Map<String, dynamic> body)? onAuthPatch;
  Future<ApiResponse> Function(String path, List<int> bytes)? onMultipart;

  static Map<String, dynamic> hostelsFixture() =>
      jsonDecode(File('test/fixtures/hostels_list.json').readAsStringSync())
          as Map<String, dynamic>;

  RawApiResponse _ok(dynamic body) =>
      RawApiResponse(success: true, message: '', body: body, statusCode: 200);

  @override
  Future<RawApiResponse> getRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path');
    queries.add(queryParams);
    final custom = onGetRaw;
    if (custom != null) return custom(path, queryParams);
    if (path == '/hostels/') return _ok(hostelsFixture());
    return _ok(<dynamic>[]);
  }

  @override
  Future<RawApiResponse> authGetRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path (auth)');
    queries.add(queryParams);
    final withQuery = onAuthGetRawWithQuery;
    if (withQuery != null) return withQuery(path, queryParams);
    final custom = onAuthGetRaw;
    if (custom != null) return custom(path);
    return const RawApiResponse(
      success: false,
      message: 'Session expired. Please login again.',
      statusCode: 401,
    );
  }

  @override
  Future<RawApiResponse> authDeleteRaw(String path) async {
    calls.add('DELETE $path (auth)');
    final custom = onAuthDeleteRaw;
    if (custom != null) return custom(path);
    return const RawApiResponse(
      success: false,
      message: 'Session expired. Please login again.',
      statusCode: 401,
    );
  }

  @override
  Future<RawApiResponse> authPostRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    calls.add('POST $path (auth)');
    final custom = onAuthPostRaw;
    if (custom != null) return custom(path, body);
    return const RawApiResponse(
      success: false,
      message: 'Session expired. Please login again.',
      statusCode: 401,
    );
  }

  @override
  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    calls.add('POST $path');
    return const ApiResponse(success: false, message: 'fake', statusCode: 400);
  }

  @override
  Future<ApiResponse> authPost(String path, Map<String, dynamic> body) async =>
      post(path, body);

  @override
  Future<ApiResponse> authGet(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path (auth)');
    return const ApiResponse(success: false, message: 'fake', statusCode: 401);
  }

  @override
  Future<ApiResponse> authPatch(String path, Map<String, dynamic> body) async {
    calls.add('PATCH $path (auth)');
    final custom = onAuthPatch;
    if (custom != null) return custom(path, body);
    return post(path, body);
  }

  @override
  Future<ApiResponse> authMultipartPost(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    void Function(double progress)? onProgress,
    Future<void>? cancel,
  }) async {
    calls.add('POST $path (multipart)');
    final custom = onMultipart;
    if (custom != null) return custom(path, bytes);
    return post(path, {});
  }

  /// Sessions the app asked the server to revoke at Log Out.
  final List<SessionTokens> revoked = [];

  @override
  Future<SessionTokens?> captureSession() async => loggedIn ? const SessionTokens('fake-access', 'fake-refresh') : null;

  @override
  Future<void> revoke(SessionTokens session) async => revoked.add(session);

  @override
  Future<void> revokeSession() async {
    final session = await captureSession();
    if (session != null) await revoke(session);
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {
    tokensCleared = true;
    loggedIn = false;
  }

  @override
  Future<bool> isLoggedIn() async => loggedIn;
}
