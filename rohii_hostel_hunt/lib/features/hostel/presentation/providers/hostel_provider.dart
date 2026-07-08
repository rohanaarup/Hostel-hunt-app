import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Hostel List Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Direct translation of HostelController (GetxController) into
/// a Riverpod AsyncNotifier. All business logic is preserved 1:1.
///
/// The 7 Rx variables in HostelController are collapsed into
/// Riverpod's AsyncValue<List<Hostel>> which natively provides:
///   • isLoading
///   • hasError / error
///   • data (the hostel list)

class HostelListNotifier extends AsyncNotifier<List<Hostel>> {
  late final ApiService _api;

  @override
  Future<List<Hostel>> build() {
    _api = ref.read(apiServiceProvider);
    return _fetchHostels();
  }

  /// Core fetch logic — 1:1 translation of HostelController.fetchHostels()
  Future<List<Hostel>> _fetchHostels() async {
    final response = await _api.getRaw('/hostels/');

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

  /// Retry / refresh — equivalent to HostelController.fetchHostels()
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
