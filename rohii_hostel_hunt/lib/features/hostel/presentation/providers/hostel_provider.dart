import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Hostel List Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Automatically watches [locationProvider] and re-fetches
/// when city or locality changes.
///
/// Supports filter query params:
///   • gender_type: 'boys' | 'girls' | 'mixed'
///   • amenity:     'ac'
///   • city:        case-insensitive city filter
///   • locality:    case-insensitive partial locality filter

class HostelListNotifier extends AsyncNotifier<List<Hostel>> {
  late final ApiService _api;

  // Current active chip filters (gender/amenity)
  Map<String, String> _chipFilters = {};

  @override
  Future<List<Hostel>> build() {
    _api = ref.read(apiServiceProvider);

    // Watch location — auto re-fetch when city/locality changes
    ref.watch(locationProvider.select((s) => '${s.selectedCity}|${s.selectedLocality}'));

    return _fetchHostels();
  }

  /// Core fetch logic — merges chip filters with location filters
  Future<List<Hostel>> _fetchHostels() async {
    final locState = ref.read(locationProvider);
    final params = <String, String>{..._chipFilters};

    if (locState.selectedCity.isNotEmpty) {
      params['city'] = locState.selectedCity;
    }
    if (locState.selectedLocality != null && locState.selectedLocality!.isNotEmpty) {
      params['locality'] = locState.selectedLocality!;
    }

    final response = await _api.getRaw(
      '/hostels/',
      queryParams: params.isEmpty ? null : params,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;

    List<dynamic> results;
    if (body is Map<String, dynamic> && body.containsKey('results')) {
      results = body['results'] as List<dynamic>;
    } else if (body is List) {
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
        _chipFilters = {};
      case 'Boys':
        _chipFilters = {'gender_type': 'boys'};
      case 'Girls':
        _chipFilters = {'gender_type': 'girls'};
      case 'AC':
        _chipFilters = {'amenity': 'ac'};
      case 'Non-AC':
        _chipFilters = {};
      case 'Premium':
        _chipFilters = {};
      default:
        _chipFilters = {};
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var hostels = await _fetchHostels();
      if (filter == 'Non-AC') {
        hostels = hostels
            .where((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac'))
            .toList();
      }
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
/// LocalityCount — returned by the /localities/ endpoint
/// ─────────────────────────────────────────────────────────

class LocalityCount {
  final String locality;
  final int count;

  const LocalityCount({required this.locality, required this.count});

  factory LocalityCount.fromJson(Map<String, dynamic> json) {
    return LocalityCount(
      locality: json['locality'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Localities Provider — family keyed by city name
/// ─────────────────────────────────────────────────────────
///
/// Usage: ref.watch(localitiesProvider('Hyderabad'))

final localitiesProvider = FutureProvider.family<List<LocalityCount>, String>(
  (ref, city) async {
    final api = ref.read(apiServiceProvider);
    final response = await api.getRaw(
      '/hostels/localities/',
      queryParams: city.isNotEmpty ? {'city': city} : null,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;
    if (body is List) {
      return body
          .map((e) => LocalityCount.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  },
);

/// ─────────────────────────────────────────────────────────
/// Hostel Detail Provider (Riverpod)
/// ─────────────────────────────────────────────────────────

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
