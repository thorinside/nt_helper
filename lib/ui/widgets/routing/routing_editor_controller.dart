import 'package:flutter/foundation.dart';

/// Controller to expose imperative actions on RoutingEditorWidget.
class RoutingEditorController {
  VoidCallback? _fitToView;
  VoidCallback? _resetPanZoom;
  Future<void> Function()? _copyCanvasImage;
  Future<void> Function()? _copyCanvasImageFit;

  void attach({
    required VoidCallback fitToView,
    required VoidCallback resetPanZoom,
    required Future<void> Function() copyCanvasImage,
    required Future<void> Function() copyCanvasImageFit,
  }) {
    _fitToView = fitToView;
    _resetPanZoom = resetPanZoom;
    _copyCanvasImage = copyCanvasImage;
    _copyCanvasImageFit = copyCanvasImageFit;
  }

  void fitToView() => _fitToView?.call();
  void resetPanZoom() => _resetPanZoom?.call();
  Future<void> copyCanvasImage() async => await _copyCanvasImage?.call();
  Future<void> copyCanvasImageFit() async => await _copyCanvasImageFit?.call();
}
