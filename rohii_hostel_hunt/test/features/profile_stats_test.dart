import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/core/network/list_body.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

import '../helpers/fake_api_service.dart';

/// Answers the profile screen's calls the way the real backend does.
class _ProfileApi extends FakeApiService {
  _ProfileApi({required this.bookingsBody, required this.wishlistBody});

  final dynamic bookingsBody;
  final dynamic wishlistBody;

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<RawApiResponse> authGetRaw(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    calls.add('GET $path (auth)');
    switch (path) {
      case '/auth/me/':
        return const RawApiResponse(
          success: true,
          message: '',
          statusCode: 200,
          body: {
            'success': true,
            'data': {
              'owner_id': 'u1',
              'display_name': 'Test Student',
              'email': 'student@example.test',
              'phone_number': '9000000001',
              'is_verified': true,
              'created_at': '2026-01-05T10:00:00Z',
              'gender': 'female',
              'date_of_birth': '2001-02-03',
              'profile_photo_url': null,
            },
          },
        );
      case '/bookings/my/':
        return RawApiResponse(
          success: true,
          message: '',
          statusCode: 200,
          body: bookingsBody,
        );
      case '/wishlist/':
        return RawApiResponse(
          success: true,
          message: '',
          statusCode: 200,
          body: wishlistBody,
        );
    }
    return const RawApiResponse(
      success: false,
      message: 'Not found.',
      statusCode: 404,
    );
  }
}

Future<UserProfile?> _loadProfile(_ProfileApi api) async {
  final container = ProviderContainer(
    overrides: [apiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  return container.read(userProvider.future);
}

void main() {
  group('profile stats use the real endpoints', () {
    test('reads the paginated bookings and the wishlist count', () async {
      final api = _ProfileApi(
        bookingsBody: {
          'count': 12,
          'next': 'x',
          'previous': null,
          'results': [
            {'id': 'b1', 'hostel_name': 'A'},
            {'id': 'b2', 'hostel_name': 'B'},
          ],
        },
        wishlistBody: {
          'wishlist': [
            {'id': 'w1'},
            {'id': 'w2'},
            {'id': 'w3'},
          ],
          'count': 3,
        },
      );

      final profile = (await _loadProfile(api))!;

      expect(api.calls, contains('GET /bookings/my/ (auth)'));
      expect(api.calls, contains('GET /wishlist/ (auth)'));
      expect(profile.bookingsCount, 12);
      expect(profile.recentBookings, hasLength(2));
      expect(profile.savedHostelsCount, 3);
      expect(profile.gender, 'female');
    });

    test('still accepts bare lists', () async {
      final api = _ProfileApi(
        bookingsBody: [
          {'id': 'b1'},
        ],
        wishlistBody: [
          {'id': 'w1'},
          {'id': 'w2'},
        ],
      );

      final profile = (await _loadProfile(api))!;

      expect(profile.bookingsCount, 1);
      expect(profile.savedHostelsCount, 2);
    });
  });

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
