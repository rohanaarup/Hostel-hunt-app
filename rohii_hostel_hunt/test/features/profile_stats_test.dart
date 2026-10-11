import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/list_body.dart';

// The profile counts now come from GET /dashboard/student/stats/ (see profile_provider_test.dart).
// What is left here are the helpers for list responses, which other screens still use.
void main() {
  group('list_body helpers', () {
    test('itemsFromBody reads a bare list, results, or a named key', () {
      expect(itemsFromBody([1, 2]), [1, 2]);
      expect(itemsFromBody({'results': [1]}), [1]);
      expect(itemsFromBody({'wishlist': [7, 8]}, keys: ['wishlist']), [7, 8]);
      expect(itemsFromBody({'other': 1}), isEmpty);
      expect(itemsFromBody(null), isEmpty);
    });

    test('countFromBody prefers the server count, else the item count', () {
      expect(countFromBody({'count': 40, 'results': [1, 2]}), 40);
      expect(countFromBody([1, 2, 3]), 3);
      expect(countFromBody({'wishlist': [1, 2]}, keys: ['wishlist']), 2);
      expect(countFromBody('nonsense'), 0);
    });
  });
}
