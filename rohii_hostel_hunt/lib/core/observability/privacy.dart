// Text scrubbing for error reports. A safety net: the first rule is not to
// put personal data into messages at all.

final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');

// A standalone run of digits with optional +, spaces or dashes. Treated as a
// phone number only with 9+ digits, so dates and small numbers survive.
final RegExp _phone = RegExp(r'(?<![\w.])\+?\d[\d\s-]{7,}\d(?!\w)');

final RegExp _urlWithQuery = RegExp(r'(https?://[^\s?#]+)[?#]\S*');

final RegExp _idSegment = RegExp(
  r'^(\d+|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|[0-9a-fA-F]{16,})$',
);

String maskText(String text) {
  return text.replaceAll(_email, '[email]').replaceAllMapped(_phone, (m) {
    final digits = m[0]!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 ? '[phone]' : m[0]!;
  });
}

/// [maskText] plus removal of URL query strings.
String scrubText(String text) {
  return maskText(text.replaceAllMapped(_urlWithQuery, (m) => m[1]!));
}

/// `/hostels/42/?q=x` -> `/hostels/:id/` : no query, ids replaced, low cardinality.
String routeTemplate(String pathOrUrl) {
  var path = pathOrUrl;
  final cut = path.indexOf(RegExp(r'[?#]'));
  if (cut >= 0) path = path.substring(0, cut);
  if (path.startsWith('http')) path = Uri.parse(path).path;
  return path
      .split('/')
      .map((segment) => _idSegment.hasMatch(segment) ? ':id' : segment)
      .join('/');
}

const Set<String> _sensitiveKeys = {
  'otp',
  'otp_code',
  'identifier',
  'email',
  'phone',
  'phone_number',
  'verification_token',
  'access',
  'refresh',
  'razorpay_signature',
};

bool isSensitiveKey(String key) {
  final k = key.toLowerCase();
  return _sensitiveKeys.contains(k) ||
      k.contains('password') ||
      k.contains('token') ||
      k.contains('secret') ||
      k.contains('authorization') ||
      k.contains('signature');
}
