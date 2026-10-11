import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';

/// Parses a recorded sample of the real GET /hostels/ list response (the same file the backend
/// checks against its serializer) and asserts the model reads what the cards show.
void main() {
  final body =
      jsonDecode(File('test/fixtures/hostels_list.json').readAsStringSync())
          as Map<String, dynamic>;
  final hostels = (body['results'] as List)
      .map((e) => Hostel.fromJson(e as Map<String, dynamic>))
      .toList();

  test('the sample is the paginated list envelope', () {
    expect(body.keys, containsAll(['count', 'next', 'previous', 'results']));
    expect(hostels, hasLength(2));
  });

  test('id, name and city are read', () {
    for (final h in hostels) {
      expect(h.id, isNotEmpty);
      expect(h.name, startsWith('Seed '));
      expect(h.city, 'Hyderabad');
    }
  });

  test('the cover image is read', () {
    expect(hostels.first.image, 'https://example.test/seed/alpha.jpg');
    expect(hostels.last.image, 'https://example.test/seed/beta.jpg');
  });

  test('the locality and the amenities are read', () {
    expect(hostels.first.locality, 'Gachibowli');
    expect(hostels.last.locality, 'Kondapur');
    expect(hostels.first.amenities, ['wifi', 'ac']);
    expect(hostels.last.amenities, ['wifi']);
  });

  test('the starting price is read', () {
    expect(hostels.first.pricePerMonth, 6500);
    expect(hostels.first.price, '₹6500/mo');
    expect(hostels.last.pricePerMonth, 5200);
    expect(hostels.last.price, isNot('Contact for price'));
  });
}
