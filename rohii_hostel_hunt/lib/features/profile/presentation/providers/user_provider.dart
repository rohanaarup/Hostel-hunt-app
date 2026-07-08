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

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.isVerified,
    required this.joinedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['owner_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['display_name'] as String? ?? 'User',
      phone: json['phone_number'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? true,
      joinedAt: _formatDate(json['created_at'] as String?),
    );
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
    if (!response.success) {
      throw Exception(response.message);
    }
    
    final body = response.body;
    if (body is Map<String, dynamic>) {
      // The API wraps responses in a { "success": true, "data": { ... } } envelope.
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }
    }
    
    return null;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfile);
  }
}

final userProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
