import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/search/domain/speech_service.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/search_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/voice_search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';
import '../helpers/fake_error_reporter.dart';
import '../helpers/fake_speech_service.dart';

class Rig {
  Rig(this.container, this.speech, this.api, this.prefs);
  final ProviderContainer container;
  final FakeSpeechService speech;
  final FakeApiService api;
  final SharedPreferences prefs;

  VoiceSearchNotifier get voice => container.read(voiceSearchProvider.notifier);
  VoiceState get state => container.read(voiceSearchProvider);
  List<Map<String, String>?> get searches =>
      api.queries.where((q) => q != null && q.containsKey('search')).toList();
}

Future<Rig> rig({FakeSpeechService? speech, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({'selected_city': 'Hyderabad', ...prefs});
  final sharedPrefs = await SharedPreferences.getInstance();
  final fakeSpeech = speech ?? FakeSpeechService();
  final api = FakeApiService();
  final container = ProviderContainer(overrides: [
    apiServiceProvider.overrideWithValue(api),
    sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    speechServiceProvider.overrideWithValue(fakeSpeech),
  ]);
  addTearDown(container.dispose);
  container.listen(voiceSearchProvider, (_, _) {});
  container.listen(searchProvider, (_, _) {});
  return Rig(container, fakeSpeech, api, sharedPrefs);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 450));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeErrorReporter reporter;
  setUp(() {
    reporter = FakeErrorReporter();
    errorReporter = reporter;
  });
  tearDown(() => errorReporter = const NoopErrorReporter());

  group('listening', () {
    test('starts idle; one tap listens in English (India)', () async {
      final r = await rig();
      expect(r.state.phase, VoicePhase.idle);

      await r.voice.toggle();

      expect(r.state.phase, VoicePhase.listening);
      expect(r.speech.calls, containsAllInOrder(['initialize', 'listen en_IN']));
    });

    test('words appear as they are heard, and the search runs once, debounced, with the city', () async {
      final r = await rig();
      await r.voice.toggle();

      r.speech.hear('kond');
      r.speech.hear('kondapur');
      expect(r.state.transcript, 'kondapur');
      await settle();

      expect(r.searches, hasLength(1), reason: 'partial words are debounced into one search');
      expect(r.searches.single!['search'], 'kondapur');
      expect(r.searches.single!['city'], 'Hyderabad');
    });

    test('the final words search at once, cancel the pending partial search, and end listening', () async {
      final r = await rig();
      await r.voice.toggle();

      r.speech.hear('kondapur');
      r.speech.hearFinal('kondapur boys hostel');
      await settle();

      expect(r.state.phase, VoicePhase.idle);
      expect(r.state.transcript, 'kondapur boys hostel');
      expect(r.searches, hasLength(1), reason: 'the half-finished search must not fire after the final one');
      expect(r.searches.single!['search'], 'kondapur boys hostel');
      expect(r.container.read(searchProvider).recentSearches, contains('kondapur boys hostel'));
    });

    test('tapping while listening stops it', () async {
      final r = await rig();
      await r.voice.toggle();

      await r.voice.toggle();

      expect(r.speech.calls, contains('stop'));
      expect(r.state.phase, VoicePhase.idle);
    });
  });

  group('when it does not work (each state, with its words)', () {
    test('no match: listened but heard nothing', () async {
      final r = await rig();
      await r.voice.toggle();

      r.speech.hearNothing();

      expect(r.state.phase, VoicePhase.issue);
      expect(r.state.issue, SpeechIssue.noMatch);
      expect(speechIssueMessage(r.state.issue!), "Didn't catch that. Tap the mic and try again.");
      expect(r.searches, isEmpty);
    });

    test('no match reported by the engine', () async {
      final r = await rig();
      await r.voice.toggle();

      r.speech.fail(SpeechIssue.noMatch, code: 'error_no_match');

      expect(r.state.issue, SpeechIssue.noMatch);
      expect(reporter.reported, isEmpty, reason: 'silence is normal, not a bug');
    });

    test('permission denied: asks the system, and when refused shows the Allow state', () async {
      final r = await rig(speech: FakeSpeechService(permission: MicPermission.denied, afterRequest: MicPermission.denied));

      await r.voice.toggle();

      expect(r.speech.calls, contains('requestMicPermission'));
      expect(r.state.issue, SpeechIssue.permissionDenied);
      expect(speechIssueMessage(SpeechIssue.permissionDenied), 'Microphone access is needed for voice search.');
      expect(r.speech.calls, isNot(contains('initialize')));
    });

    test('permission denied, then Allow, then granted: listening starts', () async {
      final speech = FakeSpeechService(permission: MicPermission.denied, afterRequest: MicPermission.denied);
      final r = await rig(speech: speech);
      await r.voice.toggle();
      expect(r.state.issue, SpeechIssue.permissionDenied);

      speech.afterRequest = MicPermission.granted;
      await r.voice.allowMicrophone();

      expect(r.state.phase, VoicePhase.listening);
    });

    test('permanently denied: no system prompt; the settings button opens the phone settings', () async {
      final r = await rig(speech: FakeSpeechService(permission: MicPermission.permanentlyDenied));

      await r.voice.toggle();

      expect(r.state.issue, SpeechIssue.permissionPermanentlyDenied);
      expect(r.speech.calls, isNot(contains('requestMicPermission')));
      expect(speechIssueMessage(SpeechIssue.permissionPermanentlyDenied), 'Microphone access is turned off for Hostel Hunt.');

      await r.voice.openSettings();
      expect(r.speech.settingsOpened, isTrue);
    });

    test('permission can also be refused for good by the system prompt itself', () async {
      final r = await rig(speech: FakeSpeechService(permission: MicPermission.denied, afterRequest: MicPermission.permanentlyDenied));

      await r.voice.toggle();

      expect(r.state.issue, SpeechIssue.permissionPermanentlyDenied);
    });

    test('no recognition service installed', () async {
      final r = await rig(speech: FakeSpeechService(recognizerInstalled: false));

      await r.voice.toggle();

      expect(r.state.issue, SpeechIssue.noRecognizer);
      expect(speechIssueMessage(SpeechIssue.noRecognizer), contains('no speech recognition service found'));
      expect(r.speech.calls.where((c) => c.startsWith('listen')), isEmpty);
    });

    test('no connection, and busy', () async {
      final r = await rig();
      await r.voice.toggle();
      r.speech.fail(SpeechIssue.offline, code: 'error_network');
      expect(r.state.issue, SpeechIssue.offline);
      expect(speechIssueMessage(SpeechIssue.offline), startsWith('Voice search needs an internet connection'));

      await r.voice.toggle();
      r.speech.fail(SpeechIssue.busy, code: 'error_busy');
      expect(r.state.issue, SpeechIssue.busy);
      expect(speechIssueMessage(SpeechIssue.busy), 'Voice search is busy. Try again in a moment.');
    });

    test('an unknown engine error says so plainly and is reported with its code only', () async {
      final r = await rig();
      await r.voice.toggle();

      r.speech.fail(SpeechIssue.other, code: 'error_client');

      expect(r.state.issue, SpeechIssue.other);
      expect(speechIssueMessage(SpeechIssue.other), 'Voice search stopped unexpectedly. Please try again.');
      expect(reporter.reported, hasLength(1));
      expect(reporter.reported.single.toString(), contains('error_client'));
      expect(reporter.reported.single.toString(), isNot(contains('hostel')));
    });

    test('dismissing an issue goes back to idle', () async {
      final r = await rig();
      await r.voice.toggle();
      r.speech.hearNothing();

      r.voice.dismiss();

      expect(r.state.phase, VoicePhase.idle);
      expect(r.state.issue, isNull);
    });

    test('every issue has words, and none of them mention internals', () {
      for (final issue in SpeechIssue.values) {
        final text = speechIssueMessage(issue);
        expect(text, isNotEmpty);
        expect(text, isNot(contains('error_')));
        expect(text, isNot(contains('Exception')));
      }
    });
  });

  group('languages', () {
    test('the chooser offers the installed ones (English India, Hindi, Telugu)', () async {
      final r = await rig(speech: FakeSpeechService(locales: {'en_IN', 'te_IN', 'fr_FR'}));
      await r.voice.toggle();

      expect(r.state.availableLocales.map((l) => l.id), ['en_IN', 'te_IN']);
    });

    test('when the phone does not list its languages, all three are offered', () async {
      final r = await rig(speech: FakeSpeechService(locales: {}));
      await r.voice.toggle();

      expect(r.state.availableLocales.map((l) => l.id), ['en_IN', 'hi_IN', 'te_IN']);
    });

    test('Telugu is listened to in Telugu, and the choice is remembered', () async {
      final r = await rig();
      await r.voice.chooseLanguage('te_IN');
      await r.voice.toggle();

      expect(r.speech.listeningLocale, 'te_IN');
      expect(r.prefs.getString('voice_locale'), 'te_IN');
    });

    test('a remembered language is used next time', () async {
      final r = await rig(prefs: {'voice_locale': 'hi_IN'});
      await r.voice.toggle();

      expect(r.state.localeId, 'hi_IN');
      expect(r.speech.listeningLocale, 'hi_IN');
    });

    test('a language that is not installed says so instead of listening to the wrong one', () async {
      final r = await rig(speech: FakeSpeechService(locales: {'en_IN'}), prefs: {'voice_locale': 'te_IN'});

      await r.voice.toggle();

      expect(r.state.issue, SpeechIssue.languageUnavailable);
      expect(r.speech.calls.where((c) => c.startsWith('listen')), isEmpty);
    });

    test('a saved language that is no longer offered falls back to English (India)', () async {
      final r = await rig(prefs: {'voice_locale': 'xx_XX'});
      expect(r.state.localeId, kDefaultVoiceLocale);
    });
  });
}
