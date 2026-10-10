import 'package:flutter/foundation.dart';

/// Debug-only logging. Does nothing in profile and release builds, so nothing
/// logged here can reach a device log in production.
///
/// Never pass personal data (emails, phone numbers, tokens, OTPs, response
/// bodies, location) to this function either; debug logs get pasted into chats.
void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
