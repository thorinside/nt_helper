import 'dart:async';

/// Controller that broadcasts page navigation requests for parameter sections.
///
/// Used to allow keyboard shortcuts (1-4) to expand/jump to specific
/// parameter pages in the SectionParameterListView.
class SectionParameterController {
  final _controller = StreamController<int>.broadcast();

  /// Stream of page indices to navigate to (0-based).
  Stream<int> get stream => _controller.stream;

  /// Request navigation to the given page index (0-based).
  void goToPage(int pageIndex) {
    _controller.add(pageIndex);
  }

  void dispose() {
    _controller.close();
  }
}
