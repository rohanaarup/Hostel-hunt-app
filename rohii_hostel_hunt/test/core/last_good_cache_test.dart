import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/cache/last_good_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late DateTime now;
  late LastGoodCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 1, 10, 12);
    cache = LastGoodCache(prefs, now: () => now);
  });

  test('what was saved is read back with the moment it was saved', () async {
    await cache.put('cities', [
      {'name': 'Hyderabad'}
    ]);
    final entry = cache.get('cities');
    expect(entry, isNotNull);
    expect(entry!.savedAt, now);
    expect(entry.data, [
      {'name': 'Hyderabad'}
    ]);
  });

  test('nothing saved means null, not an error', () {
    expect(cache.get('cities'), isNull);
  });

  test('an entry older than a week is not offered', () async {
    await cache.put('cities', ['a']);
    now = now.add(const Duration(days: 6));
    expect(cache.get('cities'), isNotNull);
    now = now.add(const Duration(days: 2));
    expect(cache.get('cities'), isNull);
  });

  test('an answer too big to be worth keeping is not stored', () async {
    await cache.put('big', ['x' * (LastGoodCache.maxEntryChars + 1)]);
    expect(cache.get('big'), isNull);
  });

  test('only the newest entries are kept; the oldest are forgotten and their storage freed', () async {
    for (var i = 0; i < LastGoodCache.maxEntries + 3; i++) {
      now = now.add(const Duration(minutes: 1));
      await cache.put('k$i', [i]);
    }
    expect(cache.get('k0'), isNull);
    expect(cache.get('k2'), isNull);
    expect(cache.get('k3'), isNotNull);
    expect(cache.get('k${LastGoodCache.maxEntries + 2}'), isNotNull);
    expect(prefs.containsKey('lg:k0'), isFalse, reason: 'a forgotten entry must not keep its bytes');
  });

  test('saving the same key again replaces it and refreshes the time', () async {
    await cache.put('cities', ['old']);
    now = now.add(const Duration(hours: 1));
    await cache.put('cities', ['new']);
    expect(cache.get('cities')!.data, ['new']);
    expect(cache.get('cities')!.savedAt, now);
  });

  test('a damaged entry or index reads as nothing and does not throw', () async {
    await cache.put('cities', ['a']);
    await prefs.setString('lg:cities', '{broken');
    expect(cache.get('cities'), isNull);
    await prefs.setString('lg_index', 'not json');
    expect(cache.get('cities'), isNull);
    await cache.put('cities', ['b']); // and it recovers
    expect(cache.get('cities')!.data, ['b']);
  });

  test('clear removes every entry and the index', () async {
    await cache.put('a', [1]);
    await cache.put('b', [2]);
    await cache.clear();
    expect(cache.get('a'), isNull);
    expect(cache.get('b'), isNull);
    expect(prefs.getKeys().where((k) => k.startsWith('lg')), isEmpty);
  });

  test('savedAgo speaks in plain words', () {
    final base = DateTime(2026, 1, 10, 12);
    expect(savedAgo(base, base.add(const Duration(seconds: 30))), 'a moment ago');
    expect(savedAgo(base, base.add(const Duration(minutes: 20))), '20 minutes ago');
    expect(savedAgo(base, base.add(const Duration(hours: 1, minutes: 10))), '1 hour ago');
    expect(savedAgo(base, base.add(const Duration(hours: 5))), '5 hours ago');
    expect(savedAgo(base, base.add(const Duration(days: 1, hours: 2))), 'yesterday');
    expect(savedAgo(base, base.add(const Duration(days: 4))), '4 days ago');
  });
}
