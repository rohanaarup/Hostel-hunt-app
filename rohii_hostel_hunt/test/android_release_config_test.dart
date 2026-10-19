import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F7: what the Android build files must say. These are text checks on the files in git; they cannot prove
/// the build works (the bundle build does), but they stop the launch blockers from creeping back.
void main() {
  String read(String path) => File(path).readAsStringSync();
  final main = read('android/app/src/main/AndroidManifest.xml');
  final gradle = read('android/app/build.gradle.kts');

  group('release manifest', () {
    test('does not allow plain HTTP', () {
      expect(main, isNot(contains('usesCleartextTraffic')));
    });

    test('plain HTTP is allowed in debug and profile builds only (the local development server)', () {
      expect(read('android/app/src/debug/AndroidManifest.xml'), contains('android:usesCleartextTraffic="true"'));
      expect(read('android/app/src/profile/AndroidManifest.xml'), contains('android:usesCleartextTraffic="true"'));
    });

    test('declares the UPI and https links the app checks with canLaunchUrl (package visibility)', () {
      expect(main, contains('android:scheme="upi"'));
      expect(main, contains('android:scheme="https"'));
    });

    test('has the app name people see, and does not let Android back up saved logins', () {
      expect(main, contains('android:label="Hostel Hunt"'));
      expect(main, contains('android:allowBackup="false"'));
    });

    test('asks only for the permissions the app uses', () {
      final asked = RegExp(r'<uses-permission android:name="android\.permission\.(\w+)"').allMatches(main).map((m) => m.group(1)).toSet();
      expect(asked, {'INTERNET', 'RECORD_AUDIO', 'BLUETOOTH', 'BLUETOOTH_ADMIN', 'BLUETOOTH_CONNECT'});
    });
  });

  group('build.gradle.kts', () {
    test('release signing and the application id come from the environment, not from files', () {
      for (final name in ['HH_APPLICATION_ID', 'HH_KEYSTORE_PATH', 'HH_KEYSTORE_PASSWORD', 'HH_KEY_ALIAS', 'HH_KEY_PASSWORD']) {
        expect(gradle, contains('System.getenv("$name")'), reason: name);
      }
      expect(RegExp(r'storePassword\s*=\s*"[^"]').hasMatch(gradle), isFalse, reason: 'no password written in the file');
    });

    test('a Play bundle cannot be built with the debug key or the placeholder id', () {
      expect(gradle, contains('Cannot build a Play bundle'));
      expect(gradle, contains('startsWith("com.example")'));
    });

    test('release builds are shrunk', () {
      expect(gradle, contains('isMinifyEnabled = true'));
      expect(gradle, contains('isShrinkResources = true'));
      expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);
    });
  });

  test('no keystore or key file is tracked in the project folder', () {
    final stray = Directory('android')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => RegExp(r'\.(jks|keystore|p12)$|key\.properties$').hasMatch(f.path))
        .map((f) => f.path)
        .toList();
    expect(stray, isEmpty);
  });
}
