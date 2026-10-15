import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/search/data/speech_to_text_service.dart';
import 'package:rohii_hostel_hunt/features/search/domain/speech_service.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/search_riverpod_provider.dart';

/// The speech engine. Tests override this with a fake that needs no microphone.
final speechServiceProvider = Provider<SpeechService>((ref) => SpeechToTextService());

enum VoicePhase {
  /// Nothing happening: the mic button is idle.
  idle,

  /// The microphone is open and words are being recognised.
  listening,

  /// Something stopped it; [VoiceState.issue] says what.
  issue,
}

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.transcript = '',
    this.issue,
    this.localeId = kDefaultVoiceLocale,
    this.installed = const {},
  });

  final VoicePhase phase;

  /// The words heard so far (kept after listening ends, so the search box can show them).
  final String transcript;
  final SpeechIssue? issue;
  final String localeId;

  /// Languages the phone has for recognition; empty when it did not say.
  final Set<String> installed;

  /// The languages worth offering: the ones installed, or all three while that is unknown.
  List<VoiceLocale> get availableLocales =>
      installed.isEmpty ? kVoiceLocales : kVoiceLocales.where((l) => installed.contains(l.id)).toList();

  VoiceState copyWith({
    VoicePhase? phase,
    String? transcript,
    SpeechIssue? issue,
    bool clearIssue = false,
    String? localeId,
    Set<String>? installed,
  }) {
    return VoiceState(
      phase: phase ?? this.phase,
      transcript: transcript ?? this.transcript,
      issue: clearIssue ? null : (issue ?? this.issue),
      localeId: localeId ?? this.localeId,
      installed: installed ?? this.installed,
    );
  }
}

/// An error code from the speech engine, for Sentry. Carries the code only, never what was said.
class VoiceEngineException implements Exception {
  const VoiceEngineException(this.code);
  final String code;

  @override
  String toString() => 'Voice engine error: $code';
}

/// Voice search: listens, shows what it hears in the search box, and runs the search.
///
/// Partial words go through the search's own debounce; the final words search at once.
class VoiceSearchNotifier extends Notifier<VoiceState> {
  static const _localeKey = 'voice_locale';

  bool _initialised = false;
  bool _userStopped = false;
  bool _heardFinal = false;
  bool _listening = false;

  SpeechService get _speech => ref.read(speechServiceProvider);

  @override
  VoiceState build() {
    final saved = ref.read(sharedPreferencesProvider)?.getString(_localeKey);
    // Captured now: the container may already be gone when this runs.
    final speech = ref.read(speechServiceProvider);
    ref.onDispose(() {
      if (_listening) speech.cancel();
    });
    return VoiceState(
      localeId: kVoiceLocales.any((l) => l.id == saved) ? saved! : kDefaultVoiceLocale,
    );
  }

  /// The mic button: start listening, or stop if already listening.
  Future<void> toggle() async {
    if (state.phase == VoicePhase.listening) {
      _userStopped = true;
      await _speech.stop();
      _listening = false;
      if (state.phase == VoicePhase.listening) state = state.copyWith(phase: VoicePhase.idle);
      return;
    }
    await _start();
  }

  /// The "Allow" button after the microphone was refused: asks again, and listens if allowed.
  Future<void> allowMicrophone() => _start();

  Future<void> openSettings() async {
    await _speech.openSettings();
  }

  void dismiss() => state = state.copyWith(phase: VoicePhase.idle, clearIssue: true);

  Future<void> chooseLanguage(String id) async {
    if (!kVoiceLocales.any((l) => l.id == id)) return;
    if (state.phase == VoicePhase.listening) await _speech.cancel();
    _listening = false;
    state = state.copyWith(phase: VoicePhase.idle, localeId: id, clearIssue: true);
    await ref.read(sharedPreferencesProvider)?.setString(_localeKey, id);
  }

  Future<void> _start() async {
    state = state.copyWith(phase: VoicePhase.idle, clearIssue: true);

    var permission = await _speech.micPermission();
    if (permission == MicPermission.denied) permission = await _speech.requestMicPermission();
    if (permission == MicPermission.permanentlyDenied) return _fail(SpeechIssue.permissionPermanentlyDenied);
    if (permission == MicPermission.denied) return _fail(SpeechIssue.permissionDenied);

    if (!_initialised) {
      _initialised = await _speech.initialize(onIssue: _onIssue, onListeningEnded: _onEnded);
      if (!_initialised) return _fail(SpeechIssue.noRecognizer);
    }

    final installed = await _speech.installedLocales();
    state = state.copyWith(installed: installed);
    if (installed.isNotEmpty && !installed.contains(state.localeId)) return _fail(SpeechIssue.languageUnavailable);

    _userStopped = false;
    _heardFinal = false;
    state = state.copyWith(phase: VoicePhase.listening, transcript: '', clearIssue: true);
    _listening = true;
    await _speech.listen(localeId: state.localeId, onWords: _onWords);
  }

  void _fail(SpeechIssue issue) {
    _listening = false;
    state = state.copyWith(phase: VoicePhase.issue, issue: issue);
  }

  void _onWords(String words, bool isFinal) {
    final text = words.trim();
    if (text.isEmpty || state.phase != VoicePhase.listening) return;
    state = state.copyWith(transcript: text);
    final search = ref.read(searchProvider.notifier);
    if (isFinal) {
      _heardFinal = true;
      search.searchForTerm(text);
    } else {
      search.onQueryChanged(text);
    }
  }

  void _onIssue(SpeechIssue issue, String code) {
    if (state.phase != VoicePhase.listening) return;
    if (issue == SpeechIssue.other) errorReporter.report(VoiceEngineException(code), null, hint: 'voice search');
    _fail(issue);
  }

  void _onEnded() {
    if (state.phase != VoicePhase.listening) return;
    _listening = false;
    if (_userStopped || _heardFinal) {
      state = state.copyWith(phase: VoicePhase.idle);
    } else if (state.transcript.isNotEmpty) {
      // Listening ended without a final result: search for what was heard.
      ref.read(searchProvider.notifier).searchForTerm(state.transcript);
      state = state.copyWith(phase: VoicePhase.idle);
    } else {
      _fail(SpeechIssue.noMatch);
    }
  }
}

final voiceSearchProvider = NotifierProvider<VoiceSearchNotifier, VoiceState>(VoiceSearchNotifier.new);
