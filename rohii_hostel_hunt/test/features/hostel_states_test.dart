import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/features/home/presentation/widgets/hostel_list_states.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/widgets/search_result_card.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('empty state', () {
    testWidgets('inside a locality it offers to widen to the whole city', (tester) async {
      var widened = 0;
      await tester.pumpWidget(host(HostelListEmptyState(
        city: 'Hyderabad',
        locality: 'Kondapur',
        isDark: false,
        onShowAll: () => widened++,
      )));

      expect(find.text('No hostels in Kondapur'), findsOneWidget);
      await tester.tap(find.text('Show all in Hyderabad'));
      expect(widened, 1);
    });

    testWidgets('with no locality there is nothing to widen', (tester) async {
      await tester.pumpWidget(host(HostelListEmptyState(
        city: 'Hyderabad',
        locality: null,
        isDark: false,
        onShowAll: () {},
      )));

      expect(find.text('No hostels available'), findsOneWidget);
      expect(find.textContaining('Show all in'), findsNothing);
    });
  });

  group('error state', () {
    testWidgets('shows the reason and a Retry button that retries', (tester) async {
      var retries = 0;
      await tester.pumpWidget(host(HostelListErrorState(
        message: 'The server answered 503.',
        isDark: false,
        onRetry: () => retries++,
      )));

      expect(find.text('Could not load hostels'), findsOneWidget);
      expect(find.text('The server answered 503.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });

  group('search result card image', () {
    final json = jsonDecode(File('test/fixtures/hostels_list.json').readAsStringSync())['results'][0]
        as Map<String, dynamic>;

    testWidgets('a network cover that fails to load shows the placeholder, not an asset error', (tester) async {
      final hostel = Hostel.fromJson(json);
      expect(hostel.image, startsWith('https://'));

      await tester.pumpWidget(host(SearchResultCard(hostel: hostel, isDark: false)));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.apartment_rounded), findsWidgets);
    });

    testWidgets('it asks the network for a URL and the asset bundle for a local path', (tester) async {
      await tester.pumpWidget(host(SearchResultCard(hostel: Hostel.fromJson(json), isDark: false)));

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.any((i) => i.image is NetworkImage), isTrue);
      expect(images.any((i) => i.image is AssetImage && (i.image as AssetImage).assetName.startsWith('http')), isFalse);
    });
  });
}
