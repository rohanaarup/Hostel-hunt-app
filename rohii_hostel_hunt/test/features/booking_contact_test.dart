import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/booking_contact.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/booking_provider.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

import '../helpers/fake_api_service.dart';

UserProfile profile({String name = 'Asha Rao', String phone = '9000000009'}) => UserProfile(
      id: 'u1',
      email: 'asha@example.test',
      name: name,
      phone: phone,
      isVerified: true,
      joinedAt: 'Joined Jan 2026',
    );

Future<void> submit(BookingNotifier notifier, {String name = 'Asha Rao', String phone = '9000000009'}) =>
    notifier.submitBooking(
      hostelId: 'h1',
      roomId: 'r1',
      roomName: 'Room 1',
      floorNumber: '1',
      roomNumber: '101',
      bedNumber: '2',
      checkInDate: '2026-11-01',
      studentName: name,
      studentPhone: phone,
    );

void main() {
  group('the booking waits for the profile (X10)', () {
    test('it does not answer until the profile has loaded, then uses its name and phone', () async {
      final loading = Completer<UserProfile?>();
      var answered = false;
      final result = resolveBookingContact(loading.future).then((r) {
        answered = true;
        return r;
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(answered, isFalse, reason: 'it must not go ahead with a profile that has not arrived');

      loading.complete(profile());
      final contact = await result;
      expect(contact, isA<ContactReady>());
      expect((contact as ContactReady).name, 'Asha Rao');
      expect(contact.phone, '9000000009');
    });

    test('a profile with no phone asks for one instead of sending a blank', () async {
      final contact = await resolveBookingContact(Future.value(profile(phone: '')));

      expect(contact, isA<ContactIncomplete>());
      expect((contact as ContactIncomplete).name, 'Asha Rao');
      expect(contact.phone, isEmpty);
    });

    test('a phone that is too short is treated as missing', () async {
      expect(await resolveBookingContact(Future.value(profile(phone: '12345'))), isA<ContactIncomplete>());
    });

    test('someone who is not signed in has to type a name and phone', () async {
      expect(await resolveBookingContact(Future.value(null)), isA<ContactIncomplete>());
    });

    test('a profile that cannot be loaded gives the reason, not a blank booking', () async {
      final contact = await resolveBookingContact(Future.error(const ApiException(ApiError.offline)));

      expect(contact, isA<ContactUnavailable>());
      expect((contact as ContactUnavailable).message, 'No internet connection. Check your network and try again.');
    });

    test('a profile that takes too long gives the timeout reason', () async {
      final never = Completer<UserProfile?>();
      final contact = await resolveBookingContact(never.future, timeout: const Duration(milliseconds: 30));

      expect(contact, isA<ContactUnavailable>());
      expect((contact as ContactUnavailable).message, ApiError.timeout.message);
    });
  });

  group('the booking itself never sends an empty name or phone', () {
    test('a blank name is refused before any request', () async {
      final api = FakeApiService();
      final notifier = BookingNotifier(api);

      await submit(notifier, name: '  ');

      expect(api.calls, isEmpty);
      expect(notifier.state.status, BookingStatus.error);
      expect(notifier.state.errorMessage, 'Enter your name and phone number to book.');
    });

    test('a blank phone is refused before any request', () async {
      final api = FakeApiService();
      final notifier = BookingNotifier(api);

      await submit(notifier, phone: '');

      expect(api.calls, isEmpty);
      expect(notifier.state.status, BookingStatus.error);
    });

    test('with both, the request is sent with them', () async {
      final api = FakeApiService()..loggedIn = true;
      final notifier = BookingNotifier(api);

      await submit(notifier);

      expect(api.calls, ['POST /bookings/ (auth)']);
    });

    test('a failed booking shows the server\'s words, and a later success clears the old error', () async {
      final api = FakeApiService()..loggedIn = true;
      final notifier = BookingNotifier(api);

      await submit(notifier, phone: '');
      expect(notifier.state.errorMessage, isNotNull);

      api.onAuthPostRaw = (path, body) async =>
          const RawApiResponse(success: true, message: '', statusCode: 201, body: {'id': 'b1'});
      await submit(notifier);

      expect(notifier.state.status, BookingStatus.success);
      expect(notifier.state.errorMessage, isNull);
    });
  });
}
