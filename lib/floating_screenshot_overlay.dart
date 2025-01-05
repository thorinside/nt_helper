import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

class FloatingScreenshotOverlay extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final DistingCubit cubit;

  const FloatingScreenshotOverlay({
    super.key,
    required this.overlayEntry,
    required this.cubit,
  });

  @override
  State<FloatingScreenshotOverlay> createState() =>
      _FloatingScreenshotOverlayState();
}

class _FloatingScreenshotOverlayState extends State<FloatingScreenshotOverlay> {
  Timer? _updateTimer;
  Uint8List? _screenshot;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
    _fetchScreenshot();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchScreenshot();
    });
  }

  void _fetchScreenshot() async {
    await widget.cubit.updateScreenshot();

    final screenshot = widget.cubit.state.screenshot;
    if (mounted) {
      setState(() {
        _screenshot = screenshot;
      });
    }
  }

  void _toggleSize() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSize,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Toolbar with close button
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.overlayEntry.remove();
                },
              ),
            ),
            // Screenshot display
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: _isExpanded ? 512 : 256,
              height: _isExpanded ? 150 : 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _screenshot != null
                    ? Image.memory(
                        _screenshot!,
                        fit: BoxFit.fitHeight,
                  gaplessPlayback: true,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
