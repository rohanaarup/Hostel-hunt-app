import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/booking/presentation/providers/my_bookings_provider.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';

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

  // Profile Stats (from GET /dashboard/student/stats/)
  final int profileCompletePercent;
  final int bookingsCount;
  final int savedHostelsCount;
  final int reviewsCount; // Placeholder, not supported by backend
  final List<dynamic> recentBookings;

  /// False when the counts could not be loaded: show "-", never a made-up 0.
  final bool statsAvailable;

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
    this.statsAvailable = false,
  });

  /// Reads the `data` object of GET /auth/me/ (and of the PATCH and photo replies).
  factory UserProfile.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // The server sends profile_photo_url: a Cloudinary https URL. An older record may still carry
    // a path on the server's own disk, which needs the server root in front of it.
    String? photoUrl;
    final rawPhoto = (json['profile_photo_url'] ?? json['profile_photo']) as String?;
    if (rawPhoto != null && rawPhoto.isNotEmpty) {
      if (rawPhoto.startsWith('http')) {
        photoUrl = rawPhoto;
      } else {
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
    final date = DateTime.tryParse(isoString ?? '');
    if (date == null) return 'Member';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  /// This profile with the counts from the student stats reply.
  UserProfile withStats(Map<String, dynamic> stats) {
    final bookingStats = stats['booking_stats'];
    final recent = stats['recent_activity'];
    return _copy(
      bookingsCount: bookingStats is Map ? (bookingStats['total'] as num?)?.toInt() ?? 0 : 0,
      savedHostelsCount: (stats['wishlist_count'] as num?)?.toInt() ?? 0,
      recentBookings: recent is List ? recent : const [],
      statsAvailable: true,
    );
  }

  /// A fresh profile from a server reply, keeping the counts already loaded.
  UserProfile withProfileJson(Map<String, dynamic> json) {
    return UserProfile.fromJson(json)._copy(
      bookingsCount: bookingsCount,
      savedHostelsCount: savedHostelsCount,
      recentBookings: recentBookings,
      statsAvailable: statsAvailable,
    );
  }

  UserProfile _copy({
    required int bookingsCount,
    required int savedHostelsCount,
    required List<dynamic> recentBookings,
    required bool statsAvailable,
  }) {
    return UserProfile(
      id: id,
      email: email,
      name: name,
      phone: phone,
      isVerified: isVerified,
      joinedAt: joinedAt,
      gender: gender,
      dateOfBirth: dateOfBirth,
      profilePhotoUrl: profilePhotoUrl,
      profileCompletePercent: profileCompletePercent,
      bookingsCount: bookingsCount,
      savedHostelsCount: savedHostelsCount,
      reviewsCount: reviewsCount,
      recentBookings: recentBookings,
      statsAvailable: statsAvailable,
    );
  }
}

/// The reason a failed [ApiResponse] gives, as an [ApiError] (always has words).
ApiError _errorOf(ApiResponse response) {
  return response.error ??
      ApiError(
        kind: ApiErrorKind.unexpected,
        statusCode: response.statusCode,
        message: response.message.isEmpty ? ApiError.unexpected.message : response.message,
      );
}

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  // Not stored in a field: build() runs again on every refresh, and a `late final` field would
  // throw when assigned a second time.
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<UserProfile?> build() => _fetchProfile();

  Future<UserProfile?> _fetchProfile() async {
    if (!await _api.isLoggedIn()) return null;

    final response = await _api.authGetRaw('/auth/me/');
    if (!response.success) {
      throw ApiException(response.error ?? ApiError.unexpected);
    }

    final body = response.body;
    final data = body is Map<String, dynamic> ? (body['data'] ?? body) : null;
    if (data is! Map<String, dynamic>) {
      throw ApiException(ApiError.unreadable(response.statusCode));
    }

    final profile = UserProfile.fromJson(data);

    // One cheap request for all the counts and the recent bookings. If it fails the profile still
    // opens and says the counts are unavailable (ApiService has already noted why).
    final stats = await _api.authGetRaw('/dashboard/student/stats/');
    final statsBody = stats.body;
    if (stats.success && statsBody is Map<String, dynamic>) {
      return profile.withStats(statsBody);
    }
    return profile;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfile);
  }

  /// Re-reads the profile without showing a spinner. If it fails, what is on screen stays.
  Future<void> reloadQuietly() async {
    final fresh = await AsyncValue.guard(_fetchProfile);
    if (fresh.hasValue && fresh.value != null) state = fresh;
  }

  /// PATCH /auth/me/ with text field updates.
  /// Returns null on success, or the reason it failed.
  Future<ApiError?> updateProfile(Map<String, dynamic> fields) async {
    final response = await _api.authPatch('/auth/me/', fields);
    if (!response.success) return _errorOf(response);

    final current = state.valueOrNull;
    final data = response.data;
    if (current != null && data != null) {
      state = AsyncData(current.withProfileJson(data));
    }
    return null;
  }

  /// POST /auth/me/photo/ (multipart). Returns null on success, or the reason it failed; a
  /// cancelled upload comes back as an error of kind [ApiErrorKind.cancelled].
  Future<ApiError?> uploadPhoto(
    List<int> bytes,
    String filename,
    String mimeType, {
    void Function(double progress)? onProgress,
    Future<void>? cancel,
  }) async {
    final response = await _api.authMultipartPost(
      '/auth/me/photo/',
      fieldName: 'profile_photo',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      onProgress: onProgress,
      cancel: cancel,
    );
    if (!response.success) return _errorOf(response);

    // Show the new photo straight away from the reply, then re-read the profile from the server.
    final current = state.valueOrNull;
    final data = response.data;
    if (current != null && data != null) {
      state = AsyncData(current.withProfileJson(data));
    }
    await reloadQuietly();
    return null;
  }

  /// Forgets the saved login and the cached profile.
  Future<void> signOut() async {
    await _api.clearTokens();
    state = const AsyncData(null);
    // The saved hostels and the bookings belong to the person who just left.
    ref.invalidate(savedIdsProvider);
    ref.invalidate(savedListProvider);
    ref.invalidate(myBookingsProvider);
  }
}

final userProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
