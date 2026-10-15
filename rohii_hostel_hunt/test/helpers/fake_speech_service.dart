import 'package:rohii_hostel_hunt/features/search/domain/speech_service.dart';

/// A speech service with no microphone. Tests script what the phone "hears".
class FakeSpeechService implements SpeechService {
  FakeSpeechService({
    this.permission = MicPermission.granted,
    this.afterRequest = MicPermission.granted,
    this.recognizerInstalled = true,
    this.locales = const {'en_IN', 'hi_IN', 'te_IN'},
  });

  MicPermission permission;

  /// What the system prompt answers when asked.
  MicPermission afterRequest;
  bool recognizerInstalled;
  Set<String> locales;

  final List<String> calls = [];
  String? listeningLocale;
  bool listening = false;
  bool settingsOpened = false;

  void Function(SpeechIssue issue, String code)? _onIssue;
  void Function()? _onEnded;
  void Function(String words, bool isFinal)? _onWords;

  @override
  Future<MicPermission> micPermission() async => permission;

  @override
  Future<MicPermission> requestMicPermission() async {
    calls.add('requestMicPermission');
    permission = afterRequest;
    return permission;
  }

  @override
  Future<bool> openSettings() async {
    calls.add('openSettings');
    settingsOpened = true;
    return true;
  }

  @override
  Future<bool> initialize({
    required void Function(SpeechIssue issue, String code) onIssue,
    required void Function() onListeningEnded,
  }) async {
    calls.add('initialize');
    _onIssue = onIssue;
    _onEnded = onListeningEnded;
    return recognizerInstalled;
  }

  @override
  Future<Set<String>> installedLocales() async => locales;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  }) async {
    calls.add('listen $localeId');
    listeningLocale = localeId;
    listening = true;
    _onWords = onWords;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    // Like the real plugin: stopping delivers the last words as the final result, then ends.
    if (listening) {
      listening = false;
      _onEnded?.call();
    }
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
    listening = false;
  }

  // ── What the phone "hears" ──

  void hear(String words) => _onWords?.call(words, false);

  /// The recogniser's final result. The engine then reports that it stopped.
  void hearFinal(String words) {
    _onWords?.call(words, true);
    listening = false;
    _onEnded?.call();
  }

  /// The engine stopped without any words (silence).
  void hearNothing() {
    listening = false;
    _onEnded?.call();
  }

  void fail(SpeechIssue issue, {String code = 'error_test'}) {
    listening = false;
    _onIssue?.call(issue, code);
    _onEnded?.call();
  }
}
