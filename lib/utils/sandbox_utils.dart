import 'dart:io';

/// Utility class for detecting macOS App Sandbox environment
class SandboxUtils {
  /// Detects if the app is running in macOS App Sandbox
  ///
  /// The APP_SANDBOX_CONTAINER_ID environment variable is set by macOS
  /// when an app is running inside the App Sandbox (TestFlight/App Store builds).
  static bool get isSandboxed {
    if (!Platform.isMacOS) return false;
    return Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID');
  }
}
