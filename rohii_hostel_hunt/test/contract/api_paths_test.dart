import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every API path the Dart code calls must be listed in test/contract/app_endpoints.txt (a copy of
/// the backend's contract list), and every listed path must still be called. This makes a new or
/// removed API call show up in review; the backend's contract test then checks the route exists.
void main() {
  const methodFor = {
    'post': 'POST',
    'authPost': 'POST',
    'authPostRaw': 'POST',
    'authMultipartPost': 'POST',
    'getRaw': 'GET',
    'authGet': 'GET',
    'authGetRaw': 'GET',
    'authPatch': 'PATCH',
  };

  Set<String> scanSources() {
    final found = <String>{};
    final call = RegExp(
      r'''\.(post|authPost|authPostRaw|authMultipartPost|getRaw|authGet|authGetRaw|authPatch)\(\s*['"](/[^'"]*)['"]''',
    );
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final m in call.allMatches(text)) {
        found.add('${methodFor[m[1]]} ${_normalise(m[2]!)}');
      }
      // The token refresh call builds its URL from baseUrl.
      if (RegExp(r"Uri\.parse\('\$baseUrl(/auth/token/refresh/)'\)").hasMatch(text)) {
        found.add('POST /auth/token/refresh/');
      }
    }
    return found;
  }

  Set<String> listed() {
    final entries = <String>{};
    for (final raw in File('test/contract/app_endpoints.txt').readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('|').first.trim().split(RegExp(r'\s+'));
      expect(parts, hasLength(3), reason: 'bad line: $raw');
      if (parts[2].contains('?')) continue; // query-parameter lines are backend-checked
      entries.add('${parts[1]} ${parts[2].replaceAll('{id}', '{id}')}');
    }
    return entries;
  }

  test('every API call in the Dart code is listed', () {
    final missing = scanSources().difference(listed());
    expect(
      missing,
      isEmpty,
      reason:
          'Add these to test/contract/app_endpoints.txt AND the backend contract/endpoints.txt:\n${missing.join('\n')}',
    );
  });

  test('every listed call still exists in the Dart code', () {
    final stale = listed().difference(scanSources());
    expect(stale, isEmpty, reason: 'No longer called, remove from the list:\n${stale.join('\n')}');
  });
}

/// `/hostels/$hostelId/` and `/payments/status/${widget.paymentId}/` become `/hostels/{id}/`.
String _normalise(String path) => path.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '{id}');
