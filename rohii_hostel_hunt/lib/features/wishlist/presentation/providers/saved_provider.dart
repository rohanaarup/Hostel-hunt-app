import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/list_body.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';

/// What happened when the heart was tapped.
enum SaveResult {
  saved,
  removed,

  /// Nobody is signed in: ask them to log in first. Nothing was sent.
  needsLogin,

  /// The server said no (or could not be reached). The heart was put back; see [SaveOutcome.error].
  failed,

  /// The same hostel's heart is already being sent: this tap does nothing.
  ignored,
}

class SaveOutcome {
  const SaveOutcome(this.result, [this.error]);
  final SaveResult result;
  final ApiError? error;
}

/// The ids of the hostels this person has saved, loaded once after login and kept. Every heart in
/// the app (list cards, the detail page, the Saved page) reads this one set, so they always agree.
///
/// Signed out, it is empty and sends nothing. [UserProfileNotifier.signOut] and the login page
/// invalidate it so it follows the signed-in person.
class SavedIdsNotifier extends AsyncNotifier<Set<String>> {
  final Set<String> _busy = {};

  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<Set<String>> build() async {
    if (!await _api.isLoggedIn()) return {};
    final response = await _api.authGetRaw('/wishlist/ids/');
    if (!response.success) throw response.toException();
    final body = response.body;
    final ids = body is Map ? body['ids'] : null;
    if (ids is! List) throw ApiException(ApiError.unreadable(response.statusCode));
    return ids.whereType<String>().toSet();
  }

  void _put(String hostelId, {required bool saved}) {
    final next = {...(state.valueOrNull ?? <String>{})};
    saved ? next.add(hostelId) : next.remove(hostelId);
    state = AsyncData(next);
  }

  /// Saves the hostel, or removes it if it is saved (or exactly as [wantSaved] says). The heart
  /// changes at once; if the server refuses, it goes back and the outcome carries the reason.
  /// [refreshList] reloads the Saved page's list afterwards (the Saved page itself passes false).
  Future<SaveOutcome> toggle(String hostelId, {bool? wantSaved, bool refreshList = true}) async {
    if (!await _api.isLoggedIn()) return const SaveOutcome(SaveResult.needsLogin);
    if (_busy.contains(hostelId)) return const SaveOutcome(SaveResult.ignored);
    _busy.add(hostelId);
    try {
      // Never save blind: if the saved ids did not load, load them first and say why if that fails.
      if (state.valueOrNull == null) {
        if (state.hasError) ref.invalidateSelf();
        try {
          await future;
        } on ApiException catch (e) {
          return SaveOutcome(SaveResult.failed, e.error);
        } catch (e, st) {
          errorReporter.report(e, st, hint: 'saved: load ids');
          return const SaveOutcome(SaveResult.failed, ApiError.unexpected);
        }
      }

      final shouldSave = wantSaved ?? !(state.valueOrNull?.contains(hostelId) ?? false);
      _put(hostelId, saved: shouldSave); // the heart changes before the network answers

      final response = shouldSave
          ? await _api.authPostRaw('/wishlist/', {'hostel_id': hostelId})
          : await _api.authDeleteRaw('/wishlist/hostel/$hostelId/');

      if (!response.success) {
        _put(hostelId, saved: !shouldSave); // put the heart back
        return SaveOutcome(SaveResult.failed, response.toException().error);
      }
      if (refreshList) ref.invalidate(savedListProvider);
      return SaveOutcome(shouldSave ? SaveResult.saved : SaveResult.removed);
    } finally {
      _busy.remove(hostelId);
    }
  }
}

final savedIdsProvider = AsyncNotifierProvider<SavedIdsNotifier, Set<String>>(SavedIdsNotifier.new);

/// Whether one hostel is saved. A heart watches this, so it rebuilds only when its own answer changes.
final isSavedProvider = Provider.family<bool, String>(
  (ref, hostelId) => ref.watch(savedIdsProvider).valueOrNull?.contains(hostelId) ?? false,
);

/// The Saved page: the person's saved hostels, newest saved first, one page at a time.
class SavedListNotifier extends AsyncNotifier<List<Hostel>> {
  static const pageSize = 20;

  int _nextPage = 2;
  bool _hasMore = false;
  Future<void>? _loadingMore;
  int _generation = 0;

  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<List<Hostel>> build() => _fetchFirstPage();

  void _publishPaging({bool loadingMore = false, String? error}) {
    ref
        .read(savedPagingProvider.notifier)
        .set(HostelPaging(hasMore: _hasMore, loadingMore: loadingMore, loadMoreError: error));
  }

  Future<List<Hostel>> _fetchPage(int page) async {
    if (!await _api.isLoggedIn()) {
      _hasMore = false;
      return [];
    }
    final response = await _api.authGetRaw('/wishlist/', queryParams: {
      'page_size': '$pageSize',
      if (page > 1) 'page': '$page',
    });
    if (!response.success) throw response.toException();

    final body = response.body;
    if (body is! Map && body is! List) throw ApiException(ApiError.unreadable(response.statusCode));
    _hasMore = body is Map && body['next'] != null;
    return itemsFromBody(body, keys: const ['wishlist', 'results'])
        .whereType<Map<String, dynamic>>()
        .map(Hostel.fromJson)
        .toList();
  }

  Future<List<Hostel>> _fetchFirstPage() async {
    final generation = ++_generation;
    _hasMore = false;
    _nextPage = 2;
    _loadingMore = null;
    final hostels = await _fetchPage(1);
    if (generation == _generation) _publishPaging();
    return hostels;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  /// Appends the next page. Does nothing when there is none or one is already loading.
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
        if (generation != _generation) return;
        _nextPage++;
        final seen = current.map((h) => h.id).toSet();
        state = AsyncData([...current, ...more.where((h) => seen.add(h.id))]);
        _publishPaging();
      } catch (e, st) {
        if (generation != _generation) return;
        if (e is! ApiException) errorReporter.report(e, st, hint: 'saved list: load more');
        _publishPaging(error: userMessageOf(e));
      } finally {
        if (generation == _generation) _loadingMore = null;
      }
    }();
    _loadingMore = load;
    return load;
  }

  /// Takes the hostel off the list at once and un-saves it; if that fails it goes back where it was.
  Future<SaveOutcome> remove(Hostel hostel) async {
    final before = state.valueOrNull ?? const <Hostel>[];
    final index = before.indexWhere((h) => h.id == hostel.id);
    if (index < 0) return const SaveOutcome(SaveResult.ignored);
    state = AsyncData([...before]..removeAt(index));

    final outcome = await ref
        .read(savedIdsProvider.notifier)
        .toggle(hostel.id, wantSaved: false, refreshList: false);

    if (outcome.result == SaveResult.failed || outcome.result == SaveResult.needsLogin) {
      final now = [...(state.valueOrNull ?? const <Hostel>[])];
      now.insert(index.clamp(0, now.length), hostel);
      state = AsyncData(now);
    }
    return outcome;
  }
}

final savedListProvider = AsyncNotifierProvider<SavedListNotifier, List<Hostel>>(SavedListNotifier.new);

final savedPagingProvider = NotifierProvider<HostelPagingNotifier, HostelPaging>(HostelPagingNotifier.new);
