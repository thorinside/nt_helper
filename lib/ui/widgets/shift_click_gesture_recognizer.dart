import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// A [OneSequenceGestureRecognizer] that claims a pointer only when a Shift
/// key is held at the moment the pointer goes down.
///
/// When Shift is held, the recognizer calls [onShiftTap] and immediately
/// resolves the gesture arena as [GestureDisposition.accepted]. Winning the
/// arena causes any competing recognizer (e.g. the [TabBar]'s tap recognizer
/// on a slot tab) to be rejected, so the active tab does not switch while the
/// user is multi-selecting slots for the algorithm clipboard.
///
/// When Shift is not held, the recognizer resolves as
/// [GestureDisposition.rejected] immediately, yielding the arena to competing
/// recognizers so normal tap behaviour (tab selection) proceeds unchanged.
class ShiftClickGestureRecognizer extends OneSequenceGestureRecognizer {
  ShiftClickGestureRecognizer({required this.onShiftTap});

  /// Invoked exactly once per accepted shift-click, before the arena resolves.
  final void Function() onShiftTap;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftHeld =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (shiftHeld) {
      onShiftTap();
      resolve(GestureDisposition.accepted);
    } else {
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    // The shift decision is made at pointer-down; keep tracking only until the
    // pointer sequence ends so the recognizer does not retain stale pointers.
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'shift-click';
}
