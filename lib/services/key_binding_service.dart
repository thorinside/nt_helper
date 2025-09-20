import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:nt_helper/core/platform/platform_interaction_service.dart';

/// Intent triggered when the user requests a zoom-in action.
class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

/// Intent triggered when the user requests a zoom-out action.
class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

/// Intent triggered when the user requests to reset the zoom level.
class ResetZoomIntent extends Intent {
  const ResetZoomIntent();
}

/// Abstracts access to the hardware keyboard to facilitate testing and
/// deterministic modifier checks.
abstract class HardwareKeyboardAdapter {
  Set<LogicalKeyboardKey> get logicalKeysPressed;
}

/// Default adapter that proxies to Flutter's [HardwareKeyboard] singleton.
class FlutterHardwareKeyboardAdapter implements HardwareKeyboardAdapter {
  @override
  Set<LogicalKeyboardKey> get logicalKeysPressed =>
      HardwareKeyboard.instance.logicalKeysPressed;
}

/// Service responsible for describing keyboard shortcut bindings and related
/// modifier queries for the routing editor.
class KeyBindingService {
  KeyBindingService({
    PlatformInteractionService? platformInteractionService,
    HardwareKeyboardAdapter? hardwareKeyboard,
  }) : _platformService =
           platformInteractionService ?? PlatformInteractionService(),
       _hardwareKeyboard = hardwareKeyboard ?? FlutterHardwareKeyboardAdapter();

  final PlatformInteractionService _platformService;
  final HardwareKeyboardAdapter _hardwareKeyboard;

  /// Returns the desktop shortcut bindings for zoom in/out/reset actions.
  Map<ShortcutActivator, Intent> get desktopZoomShortcuts => {
    // Zoom in
    const SingleActivator(LogicalKeyboardKey.equal, control: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.add, control: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.equal, meta: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.equal, meta: true, shift: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadAdd, meta: true):
        const ZoomInIntent(),
    const SingleActivator(LogicalKeyboardKey.add, meta: true):
        const ZoomInIntent(),

    // Zoom out
    const SingleActivator(LogicalKeyboardKey.minus, control: true):
        const ZoomOutIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true):
        const ZoomOutIntent(),
    const SingleActivator(LogicalKeyboardKey.minus, meta: true):
        const ZoomOutIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadSubtract, meta: true):
        const ZoomOutIntent(),

    // Reset zoom
    const SingleActivator(LogicalKeyboardKey.digit0, control: true):
        const ResetZoomIntent(),
    const SingleActivator(LogicalKeyboardKey.numpad0, control: true):
        const ResetZoomIntent(),
    const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
        const ResetZoomIntent(),
    const SingleActivator(LogicalKeyboardKey.numpad0, meta: true):
        const ResetZoomIntent(),
  };

  /// Creates the actions map for zoom in/out/reset callbacks.
  Map<Type, Action<Intent>> buildZoomActions({
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
    required VoidCallback onResetZoom,
  }) {
    return {
      ZoomInIntent: CallbackAction<ZoomInIntent>(
        onInvoke: (_) {
          onZoomIn();
          return null;
        },
      ),
      ZoomOutIntent: CallbackAction<ZoomOutIntent>(
        onInvoke: (_) {
          onZoomOut();
          return null;
        },
      ),
      ResetZoomIntent: CallbackAction<ResetZoomIntent>(
        onInvoke: (_) {
          onResetZoom();
          return null;
        },
      ),
    };
  }

  /// Returns `true` when the appropriate shortcut modifier (Cmd on macOS,
  /// Ctrl elsewhere) is currently pressed.
  bool isZoomModifierPressed() {
    final pressed = _hardwareKeyboard.logicalKeysPressed;

    if (_platformService.usesCommandModifier()) {
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }

    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }
}
