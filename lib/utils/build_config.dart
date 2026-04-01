/// Compile-time build configuration flags.
///
/// Pass `--dart-define=PLAY_STORE_BUILD=true` when building the Play Store AAB
/// to exclude features that conflict with Google Play's Device and Network Abuse
/// policy (plugin installation, firmware flashing).
const kPlayStoreBuild = bool.fromEnvironment('PLAY_STORE_BUILD');
