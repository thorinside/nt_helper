import 'dart:async';

/// Controller that broadcasts page navigation requests for parameter sections.
///
/// Used to allow keyboard shortcuts (digit keys) to expand/jump to specific
/// parameter pages in the SectionParameterListView.
class SectionParameterController {
  final _controller =
      StreamController<({int slotIndex, int pageIndex})>.broadcast();

  /// Stream of targeted page navigation events (0-based indices).
  Stream<({int slotIndex, int pageIndex})> get stream => _controller.stream;

  /// Request navigation to the given page index (0-based) for a specific slot.
  void goToPage(int slotIndex, int pageIndex) {
    _controller.add((slotIndex: slotIndex, pageIndex: pageIndex));
  }

  void dispose() {
    _controller.close();
  }
}
