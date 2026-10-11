import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Hostel List Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Watches [locationProvider] and starts again from page one when the
/// city or locality changes. The list is paged: [HostelListNotifier.loadMore]
/// appends the next page (the server's `next` link says whether there is one).
///
/// Query params sent to GET /hostels/:
///   • city / locality : the selected location (server resolves names, aliases)
///   • gender_type:      'boys' | 'girls' | 'mixed'
///   • amenity:          'ac'
///   • page, page_size:  paging

/// How many hostels one request asks for. The server allows up to 50.
const int kHostelPageSize = 20;

/// What the screen needs to know about paging, besides the hostels themselves.
class HostelPaging {
  final bool hasMore;
  final bool loadingMore;
  final String? loadMoreError;

  const HostelPaging({this.hasMore = false, this.loadingMore = false, this.loadMoreError});
}

class HostelPagingNotifier extends Notifier<HostelPaging> {
  @override
  HostelPaging build() => const HostelPaging();

  void set(HostelPaging value) => state = value;
}

final hostelPagingProvider = NotifierProvider<HostelPagingNotifier, HostelPaging>(
  HostelPagingNotifier.new,
);

class HostelListNotifier extends AsyncNotifier<List<Hostel>> {
  // Current active chip filters (gender/amenity) sent to the server
  Map<String, String> _chipFilters = {};

  // Chip filters the server cannot do ('Non-AC', 'Premium'); applied to every page here
  String _clientFilter = 'All';

  int _nextPage = 2;
  bool _hasMore = false;
  Future<void>? _loadingMore;

  // Bumped whenever the list starts again, so a slow reply for the old list is dropped
  int _generation = 0;

  @override
  Future<List<Hostel>> build() {
    // Watch location — start again from page one when city/locality changes
    ref.watch(locationProvider.select((s) => '${s.selectedCity}|${s.selectedLocality}'));

    return _fetchFirstPage();
  }

  void _publishPaging({bool loadingMore = false, String? error}) {
    ref
        .read(hostelPagingProvider.notifier)
        .set(HostelPaging(hasMore: _hasMore, loadingMore: loadingMore, loadMoreError: error));
  }

  Future<List<Hostel>> _fetchPage(int page) async {
    final locState = ref.read(locationProvider);
    final params = <String, String>{..._chipFilters, 'page_size': '$kHostelPageSize'};

    if (locState.selectedCity.isNotEmpty) {
      params['city'] = locState.selectedCity;
    }
    if (locState.selectedLocality != null && locState.selectedLocality!.isNotEmpty) {
      params['locality'] = locState.selectedLocality!;
    }
    if (page > 1) {
      params['page'] = '$page';
    }

    final response = await ref.read(apiServiceProvider).getRaw('/hostels/', queryParams: params);

    if (!response.success) {
      throw Exception(response.message);
    }

    final body = response.body;

    List<dynamic> results;
    if (body is Map<String, dynamic> && body.containsKey('results')) {
      results = body['results'] as List<dynamic>;
      _hasMore = body['next'] != null;
    } else if (body is List) {
      results = body;
      _hasMore = false;
    } else {
      throw Exception('Unexpected response format.');
    }

    var hostels = results.map((json) => Hostel.fromJson(json as Map<String, dynamic>)).toList();
    if (_clientFilter == 'Non-AC') {
      hostels = hostels.where((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac')).toList();
    }
    if (_clientFilter == 'Premium') {
      hostels = hostels.where((h) => h.amenities.length >= 5).toList();
    }
    return hostels;
  }

  /// Page one of the current location and filters. Resets paging.
  Future<List<Hostel>> _fetchFirstPage() async {
    final generation = ++_generation;
    _hasMore = false;
    _nextPage = 2;
    _loadingMore = null;
    final hostels = await _fetchPage(1);
    if (generation == _generation) _publishPaging();
    return hostels;
  }

  /// Append the next page. Does nothing when there is no next page or one is already loading.
  Future<void> loadMore() {
    final running = _loadingMore;
    if (running != null) return running;
    final current = state.value;
    if (!_hasMore || current == null) return Future.value();

    final generation = _generation;
    final load = () async {
      _publishPaging(loadingMore: true);
      try {
        final more = await _fetchPage(_nextPage);
        if (generation != _generation) return; // the list started again meanwhile
        _nextPage++;
        final seen = current.map((h) => h.id).toSet();
        state = AsyncData([...current, ...more.where((h) => seen.add(h.id))]);
        _publishPaging();
      } catch (e) {
        if (generation != _generation) return;
        _publishPaging(error: e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (generation == _generation) _loadingMore = null;
      }
    }();
    _loadingMore = load;
    return load;
  }

  /// Apply a filter chip selection and re-fetch
  Future<void> applyFilter(String filter) async {
    _clientFilter = filter;
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
        _clientFilter = 'All';
    }
    await refresh();
  }

  /// Retry / refresh with current filters
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
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
  @override
  Future<Hostel> build(int hostelId) {
    return _fetchDetail(hostelId);
  }

  Future<Hostel> _fetchDetail(int hostelId) async {
    final response = await ref.read(apiServiceProvider).getRaw('/hostels/$hostelId/');

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
