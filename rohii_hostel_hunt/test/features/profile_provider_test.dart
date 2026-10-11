import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

import '../helpers/fake_api_service.dart';

Map<String, dynamic> recorded(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

RawApiResponse ok(dynamic body) => RawApiResponse(success: true, message: '', statusCode: 200, body: body);

/// Answers the profile screen's calls with responses recorded from the real backend
/// (test/fixtures/auth_me.json and student_stats.json).
FakeApiService profileApi({Map<String, dynamic>? stats, RawApiResponse? statsReply, RawApiResponse? meReply}) {
  final api = FakeApiService()..loggedIn = true;
  api.onAuthGetRaw = (path) async {
    switch (path) {
      case '/auth/me/':
        return meReply ?? ok(recorded('auth_me.json'));
      case '/dashboard/student/stats/':
        return statsReply ?? ok(stats ?? recorded('student_stats.json'));
    }
    return const RawApiResponse(success: false, message: 'Not found.', statusCode: 404);
  };
  return api;
}

ProviderContainer containerFor(FakeApiService api) {
  final container = ProviderContainer(overrides: [apiServiceProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('the profile', () {
    test('shows the photo the server sends as profile_photo_url (X08: the app read profile_photo)', () async {
      final profile = (await containerFor(profileApi()).read(userProvider.future))!;

      expect(profile.profilePhotoUrl, startsWith('https://res.cloudinary.com/'));
      expect(profile.name, 'Asha Example');
      expect(profile.gender, 'female');
      expect(profile.dateOfBirth, '2001-02-03');
    });

    test('counts come from the student stats route: one call, no lists downloaded (X10)', () async {
      final api = profileApi();
      final profile = (await containerFor(api).read(userProvider.future))!;

      expect(api.calls, ['GET /auth/me/ (auth)', 'GET /dashboard/student/stats/ (auth)']);
      expect(profile.statsAvailable, isTrue);
      expect(profile.bookingsCount, 3);
      expect(profile.savedHostelsCount, 0);
      expect(profile.recentBookings, hasLength(3));
      expect((profile.recentBookings.first as Map)['hostel_name'], 'Sunrise PG');
    });

    test('the saved count is the server\'s wishlist_count', () async {
      final stats = recorded('student_stats.json')..['wishlist_count'] = 7;
      final profile = (await containerFor(profileApi(stats: stats)).read(userProvider.future))!;

      expect(profile.savedHostelsCount, 7);
    });

    test('when the counts cannot be loaded the profile still opens and says the counts are unavailable', () async {
      final api = profileApi(
        statsReply: const RawApiResponse(success: false, message: 'The server had a problem.', statusCode: 500),
      );
      final profile = (await containerFor(api).read(userProvider.future))!;

      expect(profile.name, 'Asha Example');
      expect(profile.statsAvailable, isFalse, reason: 'a failed request must not show as "0 bookings"');
    });

    test('when /auth/me/ fails the error carries words for the user, not "Exception: ..."', () async {
      final api = profileApi(
        meReply: RawApiResponse.fromError(const ApiError(
          kind: ApiErrorKind.unavailable,
          statusCode: 503,
          message: 'The server is starting up. Please try again in a few seconds.',
        )),
      );
      final container = containerFor(api);

      await expectLater(container.read(userProvider.future), throwsA(isA<ApiException>()));
      expect(userMessageOf(container.read(userProvider).error!), 'The server is starting up. Please try again in a few seconds.');
    });

    test('refreshing twice does not crash (build used to assign a late final field again)', () async {
      final container = containerFor(profileApi());
      await container.read(userProvider.future);

      container.invalidate(userProvider);
      await container.read(userProvider.future);
      container.invalidate(userProvider);
      final profile = await container.read(userProvider.future);

      expect(profile?.name, 'Asha Example');
    });

    test('someone who is not signed in has no profile and no requests are made', () async {
      final api = profileApi()..loggedIn = false;

      expect(await containerFor(api).read(userProvider.future), isNull);
      expect(api.calls, isEmpty);
    });
  });

  group('editing', () {
    test('a refused change returns the server\'s reason and leaves the profile alone', () async {
      final api = profileApi()
        ..onAuthPatch = (path, body) async => ApiResponse.fromError(const ApiError(
              kind: ApiErrorKind.validation,
              statusCode: 400,
              message: "Changing your phone number needs verification, which isn't available yet.",
            ));
      final container = containerFor(api);
      await container.read(userProvider.future);

      final error = await container.read(userProvider.notifier).updateProfile({'phone_number': '9111111111'});

      expect(error?.message, contains('needs verification'));
      expect(container.read(userProvider).value?.phone, '9000000009');
    });

    test('a saved change updates the profile, and null clears gender and date of birth', () async {
      final api = profileApi()
        ..onAuthPatch = (path, body) async => ApiResponse(
              success: true,
              message: 'Profile updated.',
              statusCode: 200,
              data: {
                ...(recorded('auth_me.json')['data'] as Map<String, dynamic>),
                'display_name': 'Asha Rao',
                'gender': null,
                'date_of_birth': null,
              },
            );
      final container = containerFor(api);
      await container.read(userProvider.future);

      final error = await container.read(userProvider.notifier).updateProfile({'display_name': 'Asha Rao', 'gender': null});

      expect(error, isNull);
      final profile = container.read(userProvider).value!;
      expect(profile.name, 'Asha Rao');
      expect(profile.gender, isNull);
      expect(profile.dateOfBirth, isNull);
      expect(profile.bookingsCount, 3, reason: 'the counts are kept');
    });
  });

  group('the photo', () {
    final jpeg = List<int>.filled(64, 1);

    test('a failed upload returns the server\'s reason and the screen keeps the old photo', () async {
      final api = profileApi()
        ..onMultipart = (path, bytes) async => ApiResponse.fromError(const ApiError(
              kind: ApiErrorKind.validation,
              statusCode: 400,
              message: 'The file is not a valid image.',
            ));
      final container = containerFor(api);
      final before = (await container.read(userProvider.future))!.profilePhotoUrl;

      final error = await container.read(userProvider.notifier).uploadPhoto(jpeg, 'a.jpg', 'image/jpeg');

      expect(error?.message, 'The file is not a valid image.');
      expect(container.read(userProvider).value?.profilePhotoUrl, before);
    });

    test('after a good upload the new URL shows, with no loading flash (the profile is refreshed quietly)', () async {
      const newUrl = 'https://res.cloudinary.com/democloud/image/upload/v2/profiles/new.jpg';
      final api = profileApi();
      var meCalls = 0;
      api.onAuthGetRaw = (path) async {
        if (path == '/dashboard/student/stats/') return ok(recorded('student_stats.json'));
        meCalls++;
        final me = recorded('auth_me.json');
        if (meCalls > 1) (me['data'] as Map<String, dynamic>)['profile_photo_url'] = newUrl;
        return ok(me);
      };
      api.onMultipart = (path, bytes) async {
        expect(path, '/auth/me/photo/');
        return ApiResponse(
          success: true,
          message: 'Profile photo updated.',
          statusCode: 200,
          data: {...(recorded('auth_me.json')['data'] as Map<String, dynamic>), 'profile_photo_url': newUrl},
        );
      };
      final container = containerFor(api);
      await container.read(userProvider.future);
      final states = <AsyncValue<UserProfile?>>[];
      container.listen(userProvider, (_, next) => states.add(next));

      final error = await container.read(userProvider.notifier).uploadPhoto(jpeg, 'a.jpg', 'image/jpeg');

      expect(error, isNull);
      expect(container.read(userProvider).value?.profilePhotoUrl, newUrl);
      expect(meCalls, 2, reason: 'the profile is re-read from the server after the upload');
      expect(states.any((s) => s.isLoading), isFalse, reason: 'the page must not flash a spinner');
    });

    test('a cancelled upload is not an error to show', () async {
      final api = profileApi()
        ..onMultipart = (path, bytes) async => ApiResponse.fromError(ApiError.cancelled);
      final container = containerFor(api);
      await container.read(userProvider.future);

      final error = await container.read(userProvider.notifier).uploadPhoto(jpeg, 'a.jpg', 'image/jpeg');

      expect(error?.kind, ApiErrorKind.cancelled);
    });
  });

  group('signing out', () {
    test('clears the saved tokens and forgets the profile', () async {
      final api = profileApi();
      final container = containerFor(api);
      await container.read(userProvider.future);

      await container.read(userProvider.notifier).signOut();

      expect(api.tokensCleared, isTrue);
      expect(container.read(userProvider).value, isNull);
    });
  });
}
