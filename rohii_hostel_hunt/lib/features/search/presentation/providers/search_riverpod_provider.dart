import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Search Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// 1:1 translation of SearchProvider (ChangeNotifier) into
/// a Riverpod Notifier with an immutable state class.
///
/// The SearchState enum is preserved exactly as-is.
/// All existing methods are preserved:
///   • onQueryChanged (debounced)
///   • searchForTerm (immediate)
///   • clearSearch / clearRecentSearches

// ── Search state machine — kept exactly as original ──
enum SearchStatus {
  /// No query entered — show suggestions / recent
  idle,

  /// Debounce timer running, query being collected
  searching,

  /// Results available
  results,

  /// Query submitted but no matches
  empty,

  /// Something went wrong (future: network errors)
  error,
}

// ── Immutable state class ──
class SearchStateData {
  final SearchStatus status;
  final String query;
  final List<Hostel> results;
  final String? errorMessage;
  final List<String> recentSearches;

  const SearchStateData({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.errorMessage,
    this.recentSearches = const [],
  });

  SearchStateData copyWith({
    SearchStatus? status,
    String? query,
    List<Hostel>? results,
    String? errorMessage,
    bool clearError = false,
    List<String>? recentSearches,
  }) {
    return SearchStateData(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// ── Popular / suggested search terms ──
const List<String> popularSearches = [
  'AC Hostel',
  'Girls Hostel',
  'Boys Hostel',
  'Premium',
  'Kukatpally',
  'Gachibowli',
  'Madhapur',
  'Budget Friendly',
];

class SearchNotifier extends Notifier<SearchStateData> {
  late final ApiService _api;
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  SearchStateData build() {
    _api = ref.read(apiServiceProvider);

    // Cancel debounce timer when provider is disposed
    ref.onDispose(() {
      _debounce?.cancel();
    });

    return const SearchStateData();
  }

  // ═══════════════════════ PUBLIC API ═══════════════════════

  /// Called on every keystroke from the search input.
  void onQueryChanged(String newQuery) {
    final query = newQuery.trim();

    // If cleared, revert to idle
    if (query.isEmpty) {
      _debounce?.cancel();
      state = state.copyWith(
        status: SearchStatus.idle,
        query: '',
        results: [],
      );
      return;
    }

    // Show searching state immediately for visual feedback
    state = state.copyWith(
      status: SearchStatus.searching,
      query: query,
    );

    // Debounce the actual search
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  /// Apply a popular / recent search term directly (no debounce).
  void searchForTerm(String term) {
    state = state.copyWith(
      query: term,
      status: SearchStatus.searching,
      recentSearches: _addToRecentList(term),
    );
    _performSearch(term);
  }

  /// Clear query and return to idle state.
  void clearSearch() {
    _debounce?.cancel();
    state = state.copyWith(
      query: '',
      results: [],
      status: SearchStatus.idle,
    );
  }

  /// Clear recent search history.
  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  // ═══════════════════════ INTERNAL ═══════════════════════

  /// Core search logic — 1:1 translation of SearchProvider._performSearch()
  Future<void> _performSearch(String searchQuery) async {
    try {
      final response = await _api.getRaw(
        '/hostels/',
        queryParams: {'search': searchQuery},
      );

      if (!response.success) {
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: response.message,
          recentSearches: _addToRecentList(searchQuery),
        );
        return;
      }

      final body = response.body;

      // DRF PageNumberPagination returns: {count, next, previous, results}
      List<dynamic> resultsList;
      if (body is Map<String, dynamic> && body.containsKey('results')) {
        resultsList = body['results'] as List<dynamic>;
      } else if (body is List) {
        resultsList = body;
      } else {
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: 'Unexpected response format.',
        );
        return;
      }

      final hostels = resultsList
          .map((json) => Hostel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        results: hostels,
        status: hostels.isEmpty ? SearchStatus.empty : SearchStatus.results,
        recentSearches: _addToRecentList(searchQuery),
      );
    } catch (e) {
      debugPrint('[SearchNotifier] Search error: $e');
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Add a term to recent searches (max 8, no duplicates).
  /// Returns a new list (immutable pattern).
  List<String> _addToRecentList(String term) {
    if (term.length < 2) return state.recentSearches;
    final updated = [...state.recentSearches];
    updated.remove(term);
    updated.insert(0, term);
    if (updated.length > 8) {
      updated.removeLast();
    }
    return updated;
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchStateData>(
  SearchNotifier.new,
);
