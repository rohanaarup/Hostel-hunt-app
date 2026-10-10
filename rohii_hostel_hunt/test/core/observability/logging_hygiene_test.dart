import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the privacy rules for the app source: no bare print/debugPrint
/// (use debugLog, which does nothing outside debug mode), no empty catch blocks,
/// and no logging of /auth/me responses or tokens.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/');

  test('no print or debugPrint outside the debugLog helper', () {
    final offenders = <String>[];
    for (final file in files) {
      if (rel(file).endsWith('core/observability/debug_log.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\b(print|debugPrint)\s*\(').hasMatch(lines[i])) {
          offenders.add('${rel(file)}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no empty catch blocks', () {
    final offenders = <String>[];
    final empty = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final m in empty.allMatches(text)) {
        final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
        offenders.add('${rel(file)}:$line');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('auth/me responses and tokens are never logged', () {
    for (final file in files) {
      final text = file.readAsStringSync();
      expect(text.contains('auth/me response'), isFalse, reason: rel(file));
      expect(text.contains('Tokens saved'), isFalse, reason: rel(file));
    }
  });
}
