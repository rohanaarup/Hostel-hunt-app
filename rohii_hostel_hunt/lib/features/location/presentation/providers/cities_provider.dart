import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// A city from the server's list (GET /cities/): active cities that have at least one active hostel.
class CityOption {
  final String id;
  final String name;
  final String slug;
  final String state;
  final int hostelCount;

  const CityOption({
    required this.id,
    required this.name,
    required this.slug,
    this.state = '',
    this.hostelCount = 0,
  });

  factory CityOption.fromJson(Map<String, dynamic> json) => CityOption(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        state: json['state'] as String? ?? '',
        hostelCount: (json['hostel_count'] as num?)?.toInt() ?? 0,
      );
}

/// The cities a student can choose from. A failed request is an error (the screen shows the reason
/// and a retry), never a silently empty list.
final citiesProvider = FutureProvider<List<CityOption>>((ref) async {
  final response = await ref.read(apiServiceProvider).getRaw('/cities/');
  if (!response.success) {
    throw response.toException();
  }
  final body = response.body;
  if (body is! List) throw ApiException(ApiError.unreadable(response.statusCode));
  return body
      .whereType<Map<String, dynamic>>()
      .map(CityOption.fromJson)
      .where((c) => c.name.isNotEmpty)
      .toList();
});
