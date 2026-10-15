import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/features/search/domain/speech_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// The real [SpeechService]: the speech_to_text plugin for recognition and permission_handler for
/// the microphone permission and the phone's settings page.
class SpeechToTextService implements SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  void Function(SpeechIssue issue, String code)? _onIssue;
  void Function()? _onEnded;

  static MicPermission _map(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return MicPermission.granted;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return MicPermission.permanentlyDenied;
      case PermissionStatus.denied:
        return MicPermission.denied;
    }
  }

  // A browser asks for the microphone itself when listening starts.
  @override
  Future<MicPermission> micPermission() async =>
      kIsWeb ? MicPermission.granted : _map(await Permission.microphone.status);

  @override
  Future<MicPermission> requestMicPermission() async =>
      kIsWeb ? MicPermission.granted : _map(await Permission.microphone.request());

  @override
  Future<bool> openSettings() async => kIsWeb ? false : openAppSettings();

  @override
  Future<bool> initialize({
    required void Function(SpeechIssue issue, String code) onIssue,
    required void Function() onListeningEnded,
  }) async {
    _onIssue = onIssue;
    _onEnded = onListeningEnded;
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(onError: _handleError, onStatus: _handleStatus);
    } catch (e, st) {
      errorReporter.report(e, st, hint: 'voice search: initialize');
      return false;
    }
    return _initialized;
  }

  // What the engine reports, as one of our issues. The code is kept for logs only.
  void _handleError(SpeechRecognitionError error) {
    final code = error.errorMsg;
    final SpeechIssue issue;
    switch (code) {
      case 'error_no_match':
      case 'error_speech_timeout':
        issue = SpeechIssue.noMatch;
      case 'error_permission':
        issue = SpeechIssue.permissionDenied;
      case 'error_network':
      case 'error_network_timeout':
        issue = SpeechIssue.offline;
      case 'error_busy':
        issue = SpeechIssue.busy;
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        issue = SpeechIssue.languageUnavailable;
      default:
        issue = SpeechIssue.other;
    }
    _onIssue?.call(issue, code);
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') _onEnded?.call();
  }

  @override
  Future<Set<String>> installedLocales() async {
    try {
      final locales = await _speech.locales();
      return {for (final l in locales) l.localeId.replaceAll('-', '_')};
    } catch (e, st) {
      errorReporter.report(e, st, hint: 'voice search: list languages');
      return {};
    }
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  }) async {
    await _speech.listen(
      onResult: (result) => onWords(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.search,
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}
