import 'package:flutter/foundation.dart';

/// Controller to expose imperative actions on RoutingEditorWidget.
class RoutingEditorController {
  VoidCallback? _fitToView;
  Future<void> Function()? _copyCanvasImage;
  Future<void> Function()? _copyCanvasImageFit;
  Future<void> Function()? _copyNodesImage;

  void attach({
    required VoidCallback fitToView,
    required Future<void> Function() copyCanvasImage,
    required Future<void> Function() copyCanvasImageFit,
    required Future<void> Function() copyNodesImage,
  }) {
    _fitToView = fitToView;
    _copyCanvasImage = copyCanvasImage;
    _copyCanvasImageFit = copyCanvasImageFit;
    _copyNodesImage = copyNodesImage;
  }

  void fitToView() => _fitToView?.call();
  Future<void> copyCanvasImage() async => await _copyCanvasImage?.call();
  Future<void> copyCanvasImageFit() async => await _copyCanvasImageFit?.call();
  Future<void> copyNodesImage() async => await _copyNodesImage?.call();
}
