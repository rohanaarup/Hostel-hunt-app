import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the error handling rules (X11): a catch-all must tell Sentry, and screens must not show
/// an exception's own text. Reads the sources, so a new violation fails the build.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // These two are the reporter itself and the HTTP layer, which reports through its own helpers.
  bool exempt(File f) =>
      f.path.replaceAll('\\', '/').endsWith('core/observability/global_error_handlers.dart') ||
      f.path.replaceAll('\\', '/').endsWith('core/network/api_service.dart');

  test('every catch-all reports to Sentry', () {
    final offenders = <String>[];
    final catchAll = RegExp(r'(?<!on \w+ )catch\s*\(\s*\w+\s*(,\s*\w+\s*)?\)\s*\{');
    for (final file in files.where((f) => !exempt(f))) {
      final text = file.readAsStringSync();
      for (final match in catchAll.allMatches(text)) {
        final body = text.substring(match.end, (match.end + 500).clamp(0, text.length));
        if (!body.contains('errorReporter.report')) {
          final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'catch blocks that do not call errorReporter.report: $offenders');
  });

  test('no catch block is empty', () {
    final offenders = <String>[];
    final empty = RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}');
    for (final file in files) {
      if (empty.hasMatch(file.readAsStringSync())) offenders.add(file.path);
    }
    expect(offenders, isEmpty);
  });

  test('screens and providers never show an error\'s own text', () {
    final offenders = <String>[];
    final shown = RegExp(r'\b(e|err|error|ex)\.toString\(\)|\$\{?(e|err|error|ex)\}?[\x27"]');
    for (final file in files) {
      final text = file.readAsStringSync();
      final lines = text.split('\n');
      for (final match in shown.allMatches(text)) {
        final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
        // `list.map((e) => e.toString())` is a list item, not an error.
        if (lines[line - 1].contains('=> e.toString()')) continue;
        offenders.add('${file.path}:$line');
      }
    }
    expect(offenders, isEmpty, reason: 'use userMessageOf(error) instead: $offenders');
  });
}
