import 'dart:async';

import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

/// Who to put on a booking. The owner sees this name and phone, so a booking must never go out
/// with either one blank.
sealed class BookingContact {
  const BookingContact();
}

/// Name and phone are known: book with them.
class ContactReady extends BookingContact {
  const ContactReady({required this.name, required this.phone});
  final String name;
  final String phone;
}

/// Something is missing (a phone for someone who signed up with an email, or nobody is signed
/// in): ask for it. [name] and [phone] hold whatever is already known, possibly empty.
class ContactIncomplete extends BookingContact {
  const ContactIncomplete({this.name = '', this.phone = ''});
  final String name;
  final String phone;
}

/// The profile could not be loaded. Show [message] and let the person try again.
class ContactUnavailable extends BookingContact {
  const ContactUnavailable(this.message);
  final String message;
}

/// Digits only, at least this many: a real phone number, not "1".
const int kMinPhoneDigits = 10;

bool isUsablePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '').length >= kMinPhoneDigits;

/// Waits for the profile to load, then decides who the booking is for.
///
/// Pass `ref.read(userProvider.future)`. Waiting is the point: reading the provider's value before
/// the profile arrived is what used to send bookings with an empty name and phone.
Future<BookingContact> resolveBookingContact(
  Future<UserProfile?> profile, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final UserProfile? loaded;
  try {
    loaded = await profile.timeout(timeout);
  } on TimeoutException {
    return ContactUnavailable(ApiError.timeout.message);
  } on ApiException catch (e) {
    return ContactUnavailable(e.message);
  } catch (e, st) {
    errorReporter.report(e, st, hint: 'booking: load profile');
    return ContactUnavailable(userMessageOf(e));
  }

  if (loaded == null) return const ContactIncomplete();
  final name = loaded.name.trim();
  final phone = loaded.phone.trim();
  if (name.isNotEmpty && isUsablePhone(phone)) return ContactReady(name: name, phone: phone);
  return ContactIncomplete(name: name, phone: isUsablePhone(phone) ? phone : '');
}
