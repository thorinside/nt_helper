import 'package:flutter/foundation.dart';

/// Enum representing different interaction types based on platform capabilities
enum InteractionType {
  /// Touch-based interaction for mobile devices (tap, long press)
  tap,

  /// Pointer-based interaction for desktop devices (hover, click)
  hover,
}

/// Service for detecting platform capabilities and determining appropriate
/// interaction methods for connection deletion UI
class PlatformInteractionService {
  /// Returns the current target platform detected by Flutter.
  @visibleForTesting
  TargetPlatform get currentPlatform => defaultTargetPlatform;

  /// Returns true if the current platform is a mobile device (iOS/Android)
  bool isMobilePlatform() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Returns true if the current platform is a desktop device (macOS/Windows/Linux/Web)
  bool isDesktopPlatform() {
    return !isMobilePlatform();
  }

  /// Determines the preferred interaction type based on the current platform
  ///
  /// Returns:
  /// - [InteractionType.tap] for mobile platforms (iOS, Android)
  /// - [InteractionType.hover] for desktop platforms (macOS, Windows, Linux, Web)
  InteractionType getPreferredInteractionType() {
    return isMobilePlatform() ? InteractionType.tap : InteractionType.hover;
  }

  /// Returns true if the platform supports hover interactions
  bool supportsHoverInteractions() {
    return isDesktopPlatform();
  }

  /// Returns true if the platform should use touch-based interactions
  bool shouldUseTouchInteractions() {
    return isMobilePlatform();
  }

  /// Returns the minimum touch target size in logical pixels for accessibility
  ///
  /// Following Material Design guidelines:
  /// - Mobile: 44px minimum touch target
  /// - Desktop: Can be smaller since pointer precision is higher
  double getMinimumTouchTargetSize() {
    return isMobilePlatform() ? 44.0 : 24.0;
  }

  /// Indicates whether the Command/Meta key should be treated as the primary
  /// shortcut modifier (currently macOS).
  bool usesCommandModifier() {
    return currentPlatform == TargetPlatform.macOS;
  }
}
