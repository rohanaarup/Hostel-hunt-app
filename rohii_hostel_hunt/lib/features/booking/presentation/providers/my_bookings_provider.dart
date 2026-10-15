import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/list_body.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/features/booking/domain/booking_request.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';

/// The signed-in student's bookings, newest first as the server sends them, one page at a time
/// (GET /bookings/my/). Signed out: empty, and nothing is requested.
class MyBookingsNotifier extends AsyncNotifier<List<BookingRequest>> {
  static const pageSize = 20;

  int _nextPage = 2;
  bool _hasMore = false;
  Future<void>? _loadingMore;
  int _generation = 0;

  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<List<BookingRequest>> build() => _fetchFirstPage();

  void _publishPaging({bool loadingMore = false, String? error}) {
    ref
        .read(myBookingsPagingProvider.notifier)
        .set(HostelPaging(hasMore: _hasMore, loadingMore: loadingMore, loadMoreError: error));
  }

  Future<List<BookingRequest>> _fetchPage(int page) async {
    if (!await _api.isLoggedIn()) {
      _hasMore = false;
      return [];
    }
    final response = await _api.authGetRaw('/bookings/my/', queryParams: {
      'page_size': '$pageSize',
      if (page > 1) 'page': '$page',
    });
    if (!response.success) throw response.toException();

    final body = response.body;
    if (body is! Map && body is! List) throw ApiException(ApiError.unreadable(response.statusCode));
    _hasMore = body is Map && body['next'] != null;
    return itemsFromBody(body).whereType<Map<String, dynamic>>().map(BookingRequest.fromJson).toList();
  }

  Future<List<BookingRequest>> _fetchFirstPage() async {
    final generation = ++_generation;
    _hasMore = false;
    _nextPage = 2;
    _loadingMore = null;
    final bookings = await _fetchPage(1);
    if (generation == _generation) _publishPaging();
    return bookings;
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
        final seen = current.map((b) => b.id).toSet();
        state = AsyncData([...current, ...more.where((b) => seen.add(b.id))]);
        _publishPaging();
      } catch (e, st) {
        if (generation != _generation) return;
        if (e is! ApiException) errorReporter.report(e, st, hint: 'my bookings: load more');
        _publishPaging(error: userMessageOf(e));
      } finally {
        if (generation == _generation) _loadingMore = null;
      }
    }();
    _loadingMore = load;
    return load;
  }
}

final myBookingsProvider = AsyncNotifierProvider<MyBookingsNotifier, List<BookingRequest>>(MyBookingsNotifier.new);

final myBookingsPagingProvider = NotifierProvider<HostelPagingNotifier, HostelPaging>(HostelPagingNotifier.new);
