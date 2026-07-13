import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Hostel List Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Supports filter query params:
///   • gender_type: 'boys' | 'girls' | 'mixed'
///   • amenity:     'ac'
///   • no params:   All hostels (no filter)

class HostelListNotifier extends AsyncNotifier<List<Hostel>> {
  late final ApiService _api;

  // Current active filters
  Map<String, String> _activeFilters = {};

  @override
  Future<List<Hostel>> build() {
    _api = ref.read(apiServiceProvider);
    return _fetchHostels();
  }

  /// Core fetch logic with optional filter params
  Future<List<Hostel>> _fetchHostels() async {
    final response = await _api.getRaw(
      '/hostels/',
      queryParams: _activeFilters.isEmpty ? null : _activeFilters,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;

    // DRF PageNumberPagination returns: {count, next, previous, results}
    List<dynamic> results;
    if (body is Map<String, dynamic> && body.containsKey('results')) {
      results = body['results'] as List<dynamic>;
    } else if (body is List) {
      // In case pagination is disabled, body is a plain list
      results = body;
    } else {
      throw Exception('Unexpected response format.');
    }

    return results
        .map((json) => Hostel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Apply a filter chip selection and re-fetch
  Future<void> applyFilter(String filter) async {
    switch (filter) {
      case 'All':
        _activeFilters = {};
      case 'Boys':
        _activeFilters = {'gender_type': 'boys'};
      case 'Girls':
        _activeFilters = {'gender_type': 'girls'};
      case 'AC':
        _activeFilters = {'amenity': 'ac'};
      case 'Non-AC':
        // Non-AC: fetch all and client-side exclude those with AC amenity
        // (backend doesn't support negation on JSON arrays easily)
        _activeFilters = {};
      case 'Premium':
        _activeFilters = {};
      default:
        _activeFilters = {};
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var hostels = await _fetchHostels();
      // Client-side post-filter for Non-AC (exclude hostels with 'ac' amenity)
      if (filter == 'Non-AC') {
        hostels = hostels
            .where((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac'))
            .toList();
      }
      // Premium: show only hostels that have ≥5 amenities (simple heuristic)
      if (filter == 'Premium') {
        hostels = hostels.where((h) => h.amenities.length >= 5).toList();
      }
      return hostels;
    });
  }

  /// Retry / refresh with current filters
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchHostels);
  }
}

final hostelListProvider =
    AsyncNotifierProvider<HostelListNotifier, List<Hostel>>(
  HostelListNotifier.new,
);

/// ─────────────────────────────────────────────────────────
/// Hostel Detail Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Translation of HostelController.fetchHostelDetail() into a
/// family AsyncNotifier keyed by hostel ID.
///
/// Usage: ref.watch(hostelDetailProvider(hostelId))

class HostelDetailNotifier extends FamilyAsyncNotifier<Hostel, int> {
  late final ApiService _api;

  @override
  Future<Hostel> build(int hostelId) {
    _api = ref.read(apiServiceProvider);
    return _fetchDetail(hostelId);
  }

  Future<Hostel> _fetchDetail(int hostelId) async {
    final response = await _api.getRaw('/hostels/$hostelId/');

    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;
    if (body is Map<String, dynamic>) {
      return Hostel.fromJson(body);
    } else {
      throw Exception('Unexpected response format.');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDetail(arg));
  }
}

final hostelDetailProvider =
    AsyncNotifierProvider.family<HostelDetailNotifier, Hostel, int>(
  HostelDetailNotifier.new,
);
