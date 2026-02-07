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

class SavePresetIntent extends Intent {
  const SavePresetIntent();
}

class NewPresetIntent extends Intent {
  const NewPresetIntent();
}

class BrowsePresetsIntent extends Intent {
  const BrowsePresetsIntent();
}

class AddAlgorithmIntent extends Intent {
  const AddAlgorithmIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ShowShortcutHelpIntent extends Intent {
  const ShowShortcutHelpIntent();
}

class SwitchToParametersIntent extends Intent {
  const SwitchToParametersIntent();
}

class SwitchToRoutingIntent extends Intent {
  const SwitchToRoutingIntent();
}

class PreviousSlotIntent extends Intent {
  const PreviousSlotIntent();
}

class NextSlotIntent extends Intent {
  const NextSlotIntent();
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

  /// Returns the global shortcut bindings available on the main screen.
  ///
  /// Includes both Ctrl and Cmd variants for cross-platform support.
  Map<ShortcutActivator, Intent> get globalShortcuts => {
    // Save preset: Mod+S
    const SingleActivator(LogicalKeyboardKey.keyS, control: true):
        const SavePresetIntent(),
    const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
        const SavePresetIntent(),

    // New preset: Mod+N
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const NewPresetIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
        const NewPresetIntent(),

    // Browse presets: Mod+O
    const SingleActivator(LogicalKeyboardKey.keyO, control: true):
        const BrowsePresetsIntent(),
    const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
        const BrowsePresetsIntent(),

    // Add algorithm: Mod+Shift+N
    const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true):
        const AddAlgorithmIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true):
        const AddAlgorithmIntent(),

    // Refresh: Mod+R
    const SingleActivator(LogicalKeyboardKey.keyR, control: true):
        const RefreshIntent(),
    const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
        const RefreshIntent(),

    // Refresh: F5 (Windows convention)
    const SingleActivator(LogicalKeyboardKey.f5): const RefreshIntent(),

    // Show shortcut help: Mod+/
    const SingleActivator(LogicalKeyboardKey.slash, control: true):
        const ShowShortcutHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.slash, meta: true):
        const ShowShortcutHelpIntent(),

    // Switch to Parameters mode: Mod+1
    const SingleActivator(LogicalKeyboardKey.digit1, control: true):
        const SwitchToParametersIntent(),
    const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
        const SwitchToParametersIntent(),

    // Switch to Routing mode: Mod+2
    const SingleActivator(LogicalKeyboardKey.digit2, control: true):
        const SwitchToRoutingIntent(),
    const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
        const SwitchToRoutingIntent(),

    // Previous slot: Mod+[
    const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
        const PreviousSlotIntent(),
    const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
        const PreviousSlotIntent(),

    // Next slot: Mod+]
    const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
        const NextSlotIntent(),
    const SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
        const NextSlotIntent(),
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

  /// Creates the actions map for global shortcut callbacks.
  Map<Type, Action<Intent>> buildGlobalActions({
    required VoidCallback onSavePreset,
    required VoidCallback onNewPreset,
    required VoidCallback onBrowsePresets,
    required VoidCallback onAddAlgorithm,
    required VoidCallback onRefresh,
    required VoidCallback onShowShortcutHelp,
    required VoidCallback onSwitchToParameters,
    required VoidCallback onSwitchToRouting,
    required VoidCallback onPreviousSlot,
    required VoidCallback onNextSlot,
  }) {
    return {
      SavePresetIntent: CallbackAction<SavePresetIntent>(
        onInvoke: (_) {
          onSavePreset();
          return null;
        },
      ),
      NewPresetIntent: CallbackAction<NewPresetIntent>(
        onInvoke: (_) {
          onNewPreset();
          return null;
        },
      ),
      BrowsePresetsIntent: CallbackAction<BrowsePresetsIntent>(
        onInvoke: (_) {
          onBrowsePresets();
          return null;
        },
      ),
      AddAlgorithmIntent: CallbackAction<AddAlgorithmIntent>(
        onInvoke: (_) {
          onAddAlgorithm();
          return null;
        },
      ),
      RefreshIntent: CallbackAction<RefreshIntent>(
        onInvoke: (_) {
          onRefresh();
          return null;
        },
      ),
      ShowShortcutHelpIntent: CallbackAction<ShowShortcutHelpIntent>(
        onInvoke: (_) {
          onShowShortcutHelp();
          return null;
        },
      ),
      SwitchToParametersIntent: CallbackAction<SwitchToParametersIntent>(
        onInvoke: (_) {
          onSwitchToParameters();
          return null;
        },
      ),
      SwitchToRoutingIntent: CallbackAction<SwitchToRoutingIntent>(
        onInvoke: (_) {
          onSwitchToRouting();
          return null;
        },
      ),
      PreviousSlotIntent: CallbackAction<PreviousSlotIntent>(
        onInvoke: (_) {
          onPreviousSlot();
          return null;
        },
      ),
      NextSlotIntent: CallbackAction<NextSlotIntent>(
        onInvoke: (_) {
          onNextSlot();
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
