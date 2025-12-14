import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nt_helper/services/settings_service.dart';

class DraggableResizableOverlay extends StatefulWidget {
  final Widget child;
  final OverlayEntry overlayEntry;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double maxWidth;
  final double aspectRatio; // width / height
  final Duration controlsHideDelay;

  const DraggableResizableOverlay({
    super.key,
    required this.child,
    required this.overlayEntry,
    this.initialWidth = 256.0,
    this.initialHeight = 64.0,
    this.minWidth = 128.0, // 0.5x scale (256 * 0.5)
    this.maxWidth = 1024.0, // 4x scale (256 * 4)
    this.aspectRatio = 4.0, // 4:1 aspect ratio for Disting NT display
    this.controlsHideDelay = const Duration(seconds: 10),
  });

  @override
  State<DraggableResizableOverlay> createState() =>
      _DraggableResizableOverlayState();
}

class _DraggableResizableOverlayState extends State<DraggableResizableOverlay> {
  late double _width;
  late double _height;
  late double _x;
  late double _y;
  bool _isDragging = false;
  bool _isResizing = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    _x = 0;
    _y = 0;

    // Load settings after the first frame to ensure MediaQuery is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });

    // Start the hide timer
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.controlsHideDelay, () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _controlsVisible = true;
    });
    _startHideTimer();
  }

  void _loadSettings() {
    // Load saved position and size from settings
    final savedX = _settings.overlayPositionX;
    final savedY = _settings.overlayPositionY;
    final savedScale = _settings.overlaySizeScale;

    // Calculate size from scale
    _width = widget.initialWidth * savedScale;
    _height = _width / widget.aspectRatio; // Maintain aspect ratio

    // Use saved position if available, otherwise use default
    if (savedX >= 0 && savedY >= 0) {
      _x = savedX;
      _y = savedY;
    } else {
      // Default positioning (bottom-right)
      final screenSize = MediaQuery.of(context).size;
      _x = screenSize.width - _width - 16;
      _y = screenSize.height - kBottomNavigationBarHeight - _height - 16;
    }

    // Ensure overlay stays within screen bounds
    setState(() {
      _constrainToScreen();
    });
  }

  void _constrainToScreen() {
    final screenSize = MediaQuery.of(context).size;
    _x = _x.clamp(0, screenSize.width - _width);
    _y = _y.clamp(0, screenSize.height - _height);
  }

  void _saveSettings() {
    final scale = _width / widget.initialWidth;
    _settings.setOverlayPositionX(_x);
    _settings.setOverlayPositionY(_y);
    _settings.setOverlaySizeScale(scale);
  }

  void _onPanStart(DragStartDetails details) {
    _showControls();
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
      _constrainToScreen();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _saveSettings();
  }

  void _onResizeStart(DragStartDetails details) {
    _showControls();
    setState(() {
      _isResizing = true;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    setState(() {
      // Calculate new width based on drag delta
      final newWidth = (_width + details.delta.dx).clamp(
        widget.minWidth,
        widget.maxWidth,
      );
      _width = newWidth;
      _height = _width / widget.aspectRatio; // Maintain aspect ratio

      // Ensure overlay stays within screen bounds after resize
      _constrainToScreen();
    });
  }

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final showControls = _controlsVisible || _isResizing || _isDragging;

    return Positioned(
      left: _x,
      top: _y,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: GestureDetector(
                onTap: _showControls,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _isDragging ? 0.3 : 0.2,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Opacity(
                      opacity: _isDragging ? 0.8 : 1.0,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),

            // Close button (top-right corner)
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    widget.overlayEntry.remove();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Resize handle (bottom-right corner)
            Positioned(
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onPanStart: _onResizeStart,
                  onPanUpdate: _onResizeUpdate,
                  onPanEnd: _onResizeEnd,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
