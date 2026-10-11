/// Features that exist in the code but are switched off until they work end to end.
///
/// Turn one on for a run or build with --dart-define, for example:
///   flutter run --dart-define=ENABLE_AUTO_DETECT=true
///
/// Auto Detect needs location permissions in AndroidManifest.xml (only INTERNET is declared today)
/// and a decision on GPS and geocoding, so it stays hidden by default.
const bool kEnableAutoDetect = bool.fromEnvironment('ENABLE_AUTO_DETECT');
