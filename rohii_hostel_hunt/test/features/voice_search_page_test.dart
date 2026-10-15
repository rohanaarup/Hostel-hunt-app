import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/storage/shared_prefs_provider.dart';
import 'package:rohii_hostel_hunt/features/search/domain/speech_service.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/pages/search.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/voice_search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api_service.dart';
import '../helpers/fake_speech_service.dart';

/// The search screen with a fake speech engine: every voice state as the person sees it.
Future<FakeSpeechService> pumpSearch(WidgetTester tester, {FakeSpeechService? speech}) async {
  SharedPreferences.setMockInitialValues({'selected_city': 'Hyderabad'});
  final prefs = await SharedPreferences.getInstance();
  final fake = speech ?? FakeSpeechService();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(FakeApiService()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      speechServiceProvider.overrideWithValue(fake),
    ],
    child: const MaterialApp(home: SearchPage()),
  ));
  await tester.pump(const Duration(milliseconds: 500));
  return fake;
}

void main() {
  testWidgets('idle: a mic button, no panel, even before anything is typed', (tester) async {
    await pumpSearch(tester);

    expect(find.byKey(const Key('voice-mic')), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byKey(const Key('voice-panel')), findsNothing);
  });

  testWidgets('listening: the panel says so, then shows the words, which also fill the search box', (tester) async {
    final speech = await pumpSearch(tester);

    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Listening… speak now'), findsOneWidget);
    expect(find.text('Tap the mic to stop'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);

    speech.hear('kondapur boys');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('kondapur boys'), findsWidgets); // in the panel and in the search box
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'kondapur boys');

    speech.hearFinal('kondapur boys');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('voice-panel')), findsNothing);
  });

  testWidgets('the mic stays next to the clear button once there is text', (tester) async {
    await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byKey(const Key('voice-mic')), findsOneWidget);
  });

  testWidgets('no match: the words and a Try again button', (tester) async {
    final speech = await pumpSearch(tester);
    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));

    speech.hearNothing();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Didn't catch that. Tap the mic and try again."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Listening… speak now'), findsOneWidget);
  });

  testWidgets('permission denied: an Allow button that asks again', (tester) async {
    final speech = await pumpSearch(
      tester,
      speech: FakeSpeechService(permission: MicPermission.denied, afterRequest: MicPermission.denied),
    );

    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Microphone access is needed for voice search.'), findsOneWidget);

    speech.afterRequest = MicPermission.granted;
    await tester.tap(find.text('Allow'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Listening… speak now'), findsOneWidget);
  });

  testWidgets('permanently denied: an Open settings button that opens the phone settings', (tester) async {
    final speech = await pumpSearch(tester, speech: FakeSpeechService(permission: MicPermission.permanentlyDenied));

    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Microphone access is turned off for Hostel Hunt.'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(speech.settingsOpened, isTrue);
  });

  testWidgets('no recognition service: the long explanation and no button to press', (tester) async {
    await pumpSearch(tester, speech: FakeSpeechService(recognizerInstalled: false));

    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('no speech recognition service found'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('the panel can be dismissed', (tester) async {
    final speech = await pumpSearch(tester);
    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));
    speech.fail(SpeechIssue.offline);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('voice-panel')), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('voice-panel')), findsNothing);
  });

  testWidgets('the language button shows the installed languages and remembers the pick', (tester) async {
    final speech = await pumpSearch(tester);
    expect(find.text('EN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-language')));
    await tester.pumpAndSettle();
    expect(find.text('English (India)'), findsOneWidget);
    expect(find.text('हिन्दी (Hindi)'), findsOneWidget);
    expect(find.text('తెలుగు (Telugu)'), findsOneWidget);

    await tester.tap(find.text('తెలుగు (Telugu)'));
    await tester.pumpAndSettle();
    expect(find.text('తె'), findsOneWidget);

    await tester.tap(find.byKey(const Key('voice-mic')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(speech.listeningLocale, 'te_IN');
  });
}
