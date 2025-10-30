import 'package:flutter/foundation.dart';

/// Controller to expose imperative actions on RoutingEditorWidget.
class RoutingEditorController {
  VoidCallback? _fitToView;
  Future<void> Function()? _copyCanvasImage;
  Future<void> Function()? _copyCanvasImageFit;
  Future<void> Function()? _copyNodesImage;
  Future<void> Function()? _shareCanvasImage;
  Future<void> Function()? _shareNodesImage;

  void attach({
    required VoidCallback fitToView,
    required Future<void> Function() copyCanvasImage,
    required Future<void> Function() copyCanvasImageFit,
    required Future<void> Function() copyNodesImage,
    Future<void> Function()? shareCanvasImage,
    Future<void> Function()? shareNodesImage,
  }) {
    _fitToView = fitToView;
    _copyCanvasImage = copyCanvasImage;
    _copyCanvasImageFit = copyCanvasImageFit;
    _copyNodesImage = copyNodesImage;
    _shareCanvasImage = shareCanvasImage;
    _shareNodesImage = shareNodesImage;
  }

  void fitToView() => _fitToView?.call();
  Future<void> copyCanvasImage() async => await _copyCanvasImage?.call();
  Future<void> copyCanvasImageFit() async => await _copyCanvasImageFit?.call();
  Future<void> copyNodesImage() async => await _copyNodesImage?.call();
  Future<void> shareCanvasImage() async => await _shareCanvasImage?.call();
  Future<void> shareNodesImage() async => await _shareNodesImage?.call();
}
