import 'package:rohii_hostel_hunt/core/cache/last_good_cache.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
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

/// When the hostels on screen are a SAVED copy (the network failed), the moment that copy was
/// saved. Null while the list is fresh from the server.
class HostelListFreshnessNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? savedAt) => state = savedAt;
}

final hostelListFreshnessProvider = NotifierProvider<HostelListFreshnessNotifier, DateTime?>(
  HostelListFreshnessNotifier.new,
);

/// One page as the server sent it.
class _Page {
  const _Page(this.rows, this.hasMore);
  final List<Map<String, dynamic>> rows;
  final bool hasMore;
}

class HostelListNotifier extends AsyncNotifier<List<Hostel>> {
  // Current active chip filters (gender/amenity) sent to the server
  Map<String, String> _chipFilters = {};

  // Chip filters the server cannot do ('Non-AC', 'Premium'); applied here, to every page
  String _clientFilter = 'All';

  // Every page loaded so far, exactly as the server answered (before the local chips).
  List<Hostel> _loaded = [];

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

  /// What the screen shows: the loaded pages with the local chip applied.
  List<Hostel> _view() {
    if (_clientFilter == 'Non-AC') {
      return _loaded.where((h) => !h.amenities.any((a) => a.toLowerCase() == 'ac')).toList();
    }
    if (_clientFilter == 'Premium') {
      return _loaded.where((h) => h.amenities.length >= 5).toList();
    }
    return _loaded;
  }

  Map<String, String> _params(int page) {
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
    return params;
  }

  Future<_Page> _fetchPage(int page) async {
    final response = await ref.read(apiServiceProvider).getRaw('/hostels/', queryParams: _params(page));

    if (!response.success) {
      throw response.toException();
    }

    final body = response.body;
    final List<dynamic> results;
    final bool hasMore;
    if (body is Map<String, dynamic> && body.containsKey('results')) {
      results = body['results'] as List<dynamic>;
      hasMore = body['next'] != null;
    } else if (body is List) {
      results = body;
      hasMore = false;
    } else {
      throw ApiException(ApiError.unreadable(response.statusCode));
    }
    return _Page(results.cast<Map<String, dynamic>>(), hasMore);
  }

  /// The saved copy is kept per place and per server-side chip.
  String _cacheKey() {
    final p = _params(1)..remove('page_size');
    final parts = (p.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}');
    return 'hostels:${parts.join('&')}';
  }

  List<Hostel> _parse(List<Map<String, dynamic>> rows) => rows.map(Hostel.fromJson).toList();

  /// Page one of the current location and filters. Resets paging. When the network fails and a saved
  /// copy exists, that copy is shown (and [hostelListFreshnessProvider] says so) instead of an error.
  Future<List<Hostel>> _fetchFirstPage() async {
    final generation = ++_generation;
    _hasMore = false;
    _nextPage = 2;
    _loadingMore = null;
    final cache = ref.read(lastGoodCacheProvider);
    final key = _cacheKey();
    try {
      final page = await _fetchPage(1);
      _hasMore = page.hasMore;
      _loaded = _parse(page.rows);
      if (generation == _generation) {
        _publishPaging();
        ref.read(hostelListFreshnessProvider.notifier).set(null);
        await cache?.put(key, {'results': page.rows});
      }
      return _view();
    } on ApiException catch (e) {
      final saved = e.error.isConnectionProblem ? cache?.get(key) : null;
      final data = saved?.data;
      if (saved != null && data is Map && data['results'] is List && generation == _generation) {
        _hasMore = false;
        _loaded = _parse((data['results'] as List).cast<Map<String, dynamic>>());
        _publishPaging();
        ref.read(hostelListFreshnessProvider.notifier).set(saved.savedAt);
        return _view();
      }
      rethrow;
    }
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
        final page = await _fetchPage(_nextPage);
        if (generation != _generation) return; // the list started again meanwhile
        _nextPage++;
        _hasMore = page.hasMore;
        final seen = _loaded.map((h) => h.id).toSet();
        _loaded = [..._loaded, ..._parse(page.rows).where((h) => seen.add(h.id))];
        state = AsyncData(_view());
        _publishPaging();
      } catch (e, st) {
        if (generation != _generation) return;
        if (e is! ApiException) errorReporter.report(e, st, hint: 'hostel list: load more');
        _publishPaging(error: userMessageOf(e));
      } finally {
        if (generation == _generation) _loadingMore = null;
      }
    }();
    _loadingMore = load;
    return load;
  }

  static Map<String, String> _serverFiltersFor(String filter) {
    switch (filter) {
      case 'Boys':
        return {'gender_type': 'boys'};
      case 'Girls':
        return {'gender_type': 'girls'};
      case 'AC':
        return {'amenity': 'ac'};
      default: // All, Non-AC and Premium: nothing the server can do
        return {};
    }
  }

  static bool _same(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// Apply a filter chip selection. A chip the server cannot filter (Non-AC, Premium) and the move
  /// back to All only change what is shown of the pages already loaded: no request, no blank list.
  /// A chip the server filters (Boys, Girls, AC) asks for a new first page.
  Future<void> applyFilter(String filter) async {
    const known = {'All', 'Boys', 'Girls', 'AC', 'Non-AC', 'Premium'};
    final chosen = known.contains(filter) ? filter : 'All';
    final before = _chipFilters;
    _clientFilter = chosen;
    _chipFilters = _serverFiltersFor(chosen);
    if (_same(before, _chipFilters) && state.hasValue) {
      state = AsyncData(_view());
      return;
    }
    await refresh();
  }

  /// Retry / refresh with current filters. Hostels already on screen stay visible while the new
  /// page loads; with nothing on screen (a first load or an error) the spinner shows.
  Future<void> refresh() async {
    state = state.hasValue ? const AsyncLoading<List<Hostel>>().copyWithPrevious(state) : const AsyncLoading();
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
    final cache = ref.read(lastGoodCacheProvider);
    final key = 'localities:$city';
    final response = await api.getRaw(
      '/hostels/localities/',
      queryParams: city.isNotEmpty ? {'city': city} : null,
    );

    List<LocalityCount> parse(Object? body) => body is List
        ? body.whereType<Map<String, dynamic>>().map(LocalityCount.fromJson).toList()
        : <LocalityCount>[];

    if (!response.success) {
      final saved = response.error?.isConnectionProblem == true ? cache?.get(key) : null;
      if (saved != null) return parse(saved.data);
      throw response.toException();
    }

    final body = response.body;
    if (body is List) await cache?.put(key, body);
    return parse(body);
  },
);

/// ─────────────────────────────────────────────────────────
/// Hostel Detail Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// GET /hostels/{id}/ - the full hostel, with its rooms already inside. One request, nothing else:
/// the screens take the rooms from here instead of asking for them again. Dropped when the
/// screen closes, so a failure is never remembered.

final hostelDetailProvider = FutureProvider.autoDispose.family<Hostel, String>((ref, hostelId) async {
  final response = await ref
      .read(apiServiceProvider)
      .getRaw('/hostels/$hostelId/')
      .timeout(const Duration(seconds: 25), onTimeout: () => throw const ApiException(ApiError.timeout));

  if (!response.success) throw response.toException();
  final body = response.body;
  if (body is! Map<String, dynamic>) throw ApiException(ApiError.unreadable(response.statusCode));
  return Hostel.fromJson(body);
});
