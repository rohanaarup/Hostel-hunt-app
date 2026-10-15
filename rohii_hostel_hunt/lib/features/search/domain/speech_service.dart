// What voice search needs from the phone, behind an interface so tests can use a fake and never
// need a microphone. The real one is SpeechToTextService (the speech_to_text plugin).

enum MicPermission { granted, denied, permanentlyDenied }

/// Why voice search could not (or did not) give a result.
enum SpeechIssue {
  /// Listened, but heard nothing usable.
  noMatch,

  /// The person said no to the microphone prompt; asking again is allowed.
  permissionDenied,

  /// "Don't ask again" (or turned off in settings): only the phone's settings can fix it.
  permissionPermanentlyDenied,

  /// The phone has no speech recognition service installed or enabled.
  noRecognizer,

  /// Recognition needs the internet on this phone and there is none.
  offline,

  /// The recogniser is in use by something else.
  busy,

  /// The chosen language is not installed for speech recognition.
  languageUnavailable,

  /// Anything else; reported to Sentry with its error code only.
  other,
}

/// The words shown to the person for each issue.
String speechIssueMessage(SpeechIssue issue) {
  switch (issue) {
    case SpeechIssue.noMatch:
      return "Didn't catch that. Tap the mic and try again.";
    case SpeechIssue.permissionDenied:
      return 'Microphone access is needed for voice search.';
    case SpeechIssue.permissionPermanentlyDenied:
      return 'Microphone access is turned off for Hostel Hunt.';
    case SpeechIssue.noRecognizer:
      return "Voice search isn't available on this phone (no speech recognition service found). "
          'Install or enable Google speech services, or type your search.';
    case SpeechIssue.offline:
      return 'Voice search needs an internet connection. Check your connection and try again.';
    case SpeechIssue.busy:
      return 'Voice search is busy. Try again in a moment.';
    case SpeechIssue.languageUnavailable:
      return "That language isn't installed for voice search on this phone. Pick another, or add it in your phone's language settings.";
    case SpeechIssue.other:
      return 'Voice search stopped unexpectedly. Please try again.';
  }
}

/// A language the person can speak. [id] is the Android locale id.
class VoiceLocale {
  const VoiceLocale(this.id, this.name, this.badge);
  final String id;
  final String name;

  /// Two or three characters for the small button next to the mic.
  final String badge;
}

const List<VoiceLocale> kVoiceLocales = [
  VoiceLocale('en_IN', 'English (India)', 'EN'),
  VoiceLocale('hi_IN', 'हिन्दी (Hindi)', 'हि'),
  VoiceLocale('te_IN', 'తెలుగు (Telugu)', 'తె'),
];

const String kDefaultVoiceLocale = 'en_IN';

abstract class SpeechService {
  Future<MicPermission> micPermission();

  /// Shows the system prompt (only possible while not permanently denied).
  Future<MicPermission> requestMicPermission();

  /// Opens this app's page in the phone's settings.
  Future<bool> openSettings();

  /// Starts the recogniser. False means this phone has no speech recognition service.
  /// [onIssue] gets errors that happen while listening, with the engine's error code (for logs).
  /// [onListeningEnded] is called when listening stops, whether by silence, a final result or an error.
  Future<bool> initialize({
    required void Function(SpeechIssue issue, String code) onIssue,
    required void Function() onListeningEnded,
  });

  /// Locale ids installed for recognition, in the form `en_IN`. Empty when the phone does not say.
  Future<Set<String>> installedLocales();

  /// Listens. [onWords] gets partial text as it comes, then the final text with `isFinal` true.
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  });

  /// Stops listening and delivers what was heard so far as the final result.
  Future<void> stop();

  /// Stops listening and throws the result away.
  Future<void> cancel();
}
