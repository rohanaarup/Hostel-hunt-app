import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String phone;
  final bool isVerified;
  final String joinedAt;
  final String? gender;
  final String? dateOfBirth;    // ISO date string e.g. "1999-05-21"
  final String? profilePhotoUrl;

  // Profile Stats
  final int profileCompletePercent;
  final int bookingsCount;
  final int savedHostelsCount;
  final int reviewsCount; // Placeholder, not supported by backend
  final List<dynamic> recentBookings;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.isVerified,
    required this.joinedAt,
    this.gender,
    this.dateOfBirth,
    this.profilePhotoUrl,
    this.profileCompletePercent = 0,
    this.bookingsCount = 0,
    this.savedHostelsCount = 0,
    this.reviewsCount = 0,
    this.recentBookings = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // Build absolute URL for profile_photo if it's a relative path
    String? photoUrl;
    final rawPhoto = json['profile_photo'] as String?;
    if (rawPhoto != null && rawPhoto.isNotEmpty) {
      if (rawPhoto.startsWith('http')) {
        photoUrl = rawPhoto;
      } else {
        // Relative path from Django — prepend server root
        final root = baseUrl ?? ApiService.baseUrl.replaceAll(RegExp(r'/api(?:/v1)?'), '');
        photoUrl = '$root$rawPhoto';
      }
    }

    return UserProfile(
      id: json['owner_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['display_name'] as String? ?? 'User',
      phone: json['phone_number'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? true,
      joinedAt: _formatDate(json['created_at'] as String?),
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      profilePhotoUrl: photoUrl,
      profileCompletePercent: _calculateProfileCompletion(json),
      bookingsCount: json['bookings_count'] as int? ?? 0,
      savedHostelsCount: json['saved_hostels_count'] as int? ?? 0,
      reviewsCount: 0, // Placeholder
      recentBookings: json['recent_bookings'] as List<dynamic>? ?? [],
    );
  }

  static int _calculateProfileCompletion(Map<String, dynamic> json) {
    int score = 0;
    const int total = 6;

    if ((json['email'] as String? ?? '').isNotEmpty) score++;
    if ((json['display_name'] as String? ?? '').isNotEmpty) score++;
    if ((json['phone_number'] as String? ?? '').isNotEmpty) score++;
    if (json['is_verified'] == true) score++;
    if ((json['gender'] as String? ?? '').isNotEmpty) score++;
    if ((json['date_of_birth'] as String? ?? '').isNotEmpty) score++;

    return ((score / total) * 100).round();
  }

  static String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Member';
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Joined ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Member';
    }
  }

  /// Returns a copy with updated fields — used by provider after patch/upload
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profilePhotoUrl,
    int? profileCompletePercent,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isVerified: isVerified,
      joinedAt: joinedAt,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profileCompletePercent: profileCompletePercent ?? this.profileCompletePercent,
      bookingsCount: bookingsCount,
      savedHostelsCount: savedHostelsCount,
      reviewsCount: reviewsCount,
      recentBookings: recentBookings,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final ApiService _api;

  @override
  Future<UserProfile?> build() async {
    _api = ref.read(apiServiceProvider);
    return _fetchProfile();
  }

  Future<UserProfile?> _fetchProfile() async {
    final isLoggedIn = await _api.isLoggedIn();
    if (!isLoggedIn) return null;

    final response = await _api.authGetRaw('/auth/me/');
    print('[USER_PROVIDER] auth/me response: ${response.statusCode} ${response.success} ${response.message} ${response.body}');
    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {

        // Fetch extra stats since they aren't in /auth/me/
        int bookingsCount = 0;
        int savedCount = 0;
        List<dynamic> recentBookings = [];

        try {
          final bookingsRes = await _api.authGetRaw('/bookings/my-bookings/');
          if (bookingsRes.success && bookingsRes.body is List) {
            final list = bookingsRes.body as List;
            bookingsCount = list.length;
            recentBookings = list.take(5).toList();
          }
        } catch (_) {}

        try {
          final savedRes = await _api.authGetRaw('/favorites/hostels/');
          if (savedRes.success && savedRes.body is List) {
            savedCount = (savedRes.body as List).length;
          }
        } catch (_) {}

        final enrichedData = Map<String, dynamic>.from(data)
          ..['bookings_count'] = bookingsCount
          ..['saved_hostels_count'] = savedCount
          ..['recent_bookings'] = recentBookings;

        return UserProfile.fromJson(enrichedData);
      }
    }

    return null;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfile);
  }

  /// PATCH /auth/me/ with text field updates.
  /// Returns an error message string on failure, null on success.
  Future<String?> updateProfile(Map<String, dynamic> fields) async {
    final response = await _api.authPatch('/auth/me/', fields);
    if (!response.success) return response.message;

    // Merge updated fields into local state immediately (optimistic)
    final current = state.valueOrNull;
    if (current != null && response.data != null) {
      final d = response.data!;
      state = AsyncData(current.copyWith(
        name: d['display_name'] as String?,
        email: d['email'] as String?,
        phone: d['phone_number'] as String?,
        gender: d['gender'] as String?,
        dateOfBirth: d['date_of_birth'] as String?,
      ));
    }
    return null;
  }

  /// POST /auth/me/photo/ — multipart file upload.
  /// Returns an error message string on failure, null on success.
  Future<String?> uploadPhoto(List<int> bytes, String filename, String mimeType) async {
    final response = await _api.authMultipartPost(
      '/auth/me/photo/',
      fieldName: 'profile_photo',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
    if (!response.success) return response.message;

    // Refresh full profile to get the updated photo URL from server
    await refresh();
    return null;
  }
}

final userProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
