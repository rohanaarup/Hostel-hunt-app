import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rohii_hostel_hunt/models/hostel.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Search Provider
/// ─────────────────────────────────────────────────────────
///
/// Manages all search state and business logic, fully separated
/// from the UI layer. Uses [ChangeNotifier] for consistency with
/// the existing [LocationProvider].
///
/// Features:
///  • Real-time debounced filtering (300 ms)
///  • Enum-driven search states for clean UI mapping
///  • Recent searches (in-memory, future: SharedPreferences)
///  • Popular suggestion terms
///  • Async-ready: swap [_performSearch] for an API call later

// ── Search state machine ──
enum SearchState {
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

class SearchProvider extends ChangeNotifier {
  // ── State ──
  SearchState _state = SearchState.idle;
  SearchState get state => _state;

  String _query = '';
  String get query => _query;

  List<Hostel> _results = [];
  List<Hostel> get results => List.unmodifiable(_results);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Recent searches (stored in memory for now) ──
  final List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  // ── Popular / suggested search terms ──
  static const List<String> popularSearches = [
    'AC Hostel',
    'Girls Hostel',
    'Boys Hostel',
    'Premium',
    'Kukatpally',
    'Gachibowli',
    'Madhapur',
    'Budget Friendly',
  ];

  // ── Data source (future: injected repository) ──
  List<Hostel> _allHostels = Hostel.sampleHostels;

  // ── Debounce timer ──
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 300);

  // ═══════════════════════ PUBLIC API ═══════════════════════

  /// Called on every keystroke from the search input.
  void onQueryChanged(String newQuery) {
    _query = newQuery.trim();

    // If cleared, revert to idle
    if (_query.isEmpty) {
      _debounce?.cancel();
      _state = SearchState.idle;
      _results = [];
      notifyListeners();
      return;
    }

    // Show searching state immediately for visual feedback
    _state = SearchState.searching;
    notifyListeners();

    // Debounce the actual filtering
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _performSearch(_query);
    });
  }

  /// Apply a popular / recent search term directly (no debounce).
  void searchForTerm(String term) {
    _query = term;
    _addToRecent(term);
    _performSearch(term);
  }

  /// Clear query and return to idle state.
  void clearSearch() {
    _query = '';
    _results = [];
    _state = SearchState.idle;
    _debounce?.cancel();
    notifyListeners();
  }

  /// Clear recent search history.
  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  /// Replace the hostel data source (e.g. after API fetch).
  void updateHostels(List<Hostel> hostels) {
    _allHostels = hostels;
    // Re-run current query if any
    if (_query.isNotEmpty) {
      _performSearch(_query);
    }
  }

  // ═══════════════════════ INTERNAL ═══════════════════════

  /// Core search logic — local filter for now.
  ///
  /// To integrate a remote API later, make this method `async`,
  /// call your API service, and assign the response to [_results].
  void _performSearch(String searchQuery) {
    try {
      final q = searchQuery.toLowerCase();

      _results = _allHostels.where((hostel) {
        final nameMatch = hostel.name.toLowerCase().contains(q);
        final locationMatch = hostel.location.toLowerCase().contains(q);
        final tagMatch = hostel.tags.any(
          (tag) => tag.toLowerCase().contains(q),
        );
        return nameMatch || locationMatch || tagMatch;
      }).toList();

      _state = _results.isEmpty ? SearchState.empty : SearchState.results;
      _addToRecent(searchQuery);
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[SearchProvider] Search error: $e');
    }

    notifyListeners();
  }

  /// Add a term to recent searches (max 8, no duplicates).
  void _addToRecent(String term) {
    if (term.length < 2) return; // skip very short queries
    _recentSearches.remove(term); // remove if already exists
    _recentSearches.insert(0, term); // add to front
    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
