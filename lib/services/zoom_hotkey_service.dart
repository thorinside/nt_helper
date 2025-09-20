import 'dart:async';

/// Semantic actions emitted by the macOS native zoom hotkey bridge.
enum ZoomHotkeyAction { zoomIn, zoomOut, resetZoom }

/// Simple pub-sub service that exposes zoom hotkey events from the platform
/// layer to interested widgets.
class ZoomHotkeyService {
  ZoomHotkeyService._();

  static final ZoomHotkeyService instance = ZoomHotkeyService._();

  final StreamController<ZoomHotkeyAction> _controller =
      StreamController<ZoomHotkeyAction>.broadcast(sync: true);

  Stream<ZoomHotkeyAction> get stream => _controller.stream;

  void dispatch(ZoomHotkeyAction action) {
    if (!_controller.isClosed) {
      _controller.add(action);
    }
  }

  void dispose() {
    _controller.close();
  }
}
