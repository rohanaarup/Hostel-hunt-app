import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/observability/debug_log.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last answer the server gave for a few public reads, kept so the app has something to show
/// when the network fails (offline, a timeout, a server that is still waking).
///
/// Deliberately small: JSON in SharedPreferences, at most [maxEntries] entries of at most
/// [maxEntryChars] characters, none older than [maxAge]. It is a fallback, not a database: it is
/// written after every good answer and read ONLY when a request fails for a connection reason.
/// Never used for anything personal (no profile, bookings or saved list) or for payments.
class LastGoodCache {
  LastGoodCache(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const int maxEntries = 12;
  static const int maxEntryChars = 60000;
  static const Duration maxAge = Duration(days: 7);

  static const String _indexKey = 'lg_index';
  static String _entryKey(String key) => 'lg:$key';

  /// Key -> when it was saved (milliseconds since the epoch).
  Map<String, int> _index() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.map((k, v) => MapEntry('$k', (v as num).toInt()));
    } on FormatException {
      debugLog('last-good cache: index unreadable, starting again');
    }
    return {};
  }

  Future<void> put(String key, Object data) async {
    final encoded = jsonEncode(data);
    if (encoded.length > maxEntryChars) return; // too big to be worth keeping
    final index = _index();
    index[key] = _now().millisecondsSinceEpoch;
    // Forget the oldest entries beyond the limit.
    final byAge = index.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    while (byAge.length > maxEntries) {
      final oldest = byAge.removeAt(0);
      index.remove(oldest.key);
      await _prefs.remove(_entryKey(oldest.key));
    }
    await _prefs.setString(_entryKey(key), encoded);
    await _prefs.setString(_indexKey, jsonEncode(index));
  }

  /// What was saved under [key], or null when there is nothing, it is too old, or it is unreadable.
  CachedEntry? get(String key) {
    final saved = _index()[key];
    final raw = _prefs.getString(_entryKey(key));
    if (saved == null || raw == null) return null;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(saved);
    if (_now().difference(savedAt) > maxAge) return null;
    try {
      return CachedEntry(savedAt, jsonDecode(raw) as Object);
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    for (final key in _index().keys) {
      await _prefs.remove(_entryKey(key));
    }
    await _prefs.remove(_indexKey);
  }
}

class CachedEntry {
  const CachedEntry(this.savedAt, this.data);
  final DateTime savedAt;
  final Object data;
}

/// Null in tests that do not provide SharedPreferences: then nothing is cached and nothing breaks.
final lastGoodCacheProvider = Provider<LastGoodCache?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs == null ? null : LastGoodCache(prefs);
});

/// "2 hours ago", "yesterday": for the line that says how old the saved list is.
String savedAgo(DateTime savedAt, DateTime now) {
  final age = now.difference(savedAt);
  if (age.inMinutes < 2) return 'a moment ago';
  if (age.inMinutes < 60) return '${age.inMinutes} minutes ago';
  if (age.inHours < 24) return age.inHours == 1 ? '1 hour ago' : '${age.inHours} hours ago';
  return age.inDays == 1 ? 'yesterday' : '${age.inDays} days ago';
}
