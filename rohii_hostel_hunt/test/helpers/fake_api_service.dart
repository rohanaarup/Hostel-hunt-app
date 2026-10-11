import 'dart:convert';
import 'dart:io';

import 'package:rohii_hostel_hunt/core/network/api_service.dart';

/// An ApiService that never touches the network. Public list endpoints answer from the recorded
/// fixture; everything authenticated answers "not logged in".
class FakeApiService implements ApiService {
  final List<String> calls = [];

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
    if (path == '/hostels/') return _ok(hostelsFixture());
    return _ok(<dynamic>[]);
  }

  @override
  Future<RawApiResponse> authGetRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path (auth)');
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
  Future<ApiResponse> authPatch(String path, Map<String, dynamic> body) async =>
      post(path, body);

  @override
  Future<ApiResponse> authMultipartPost(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async => post(path, {});

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {}

  @override
  Future<bool> isLoggedIn() async => false;
}
