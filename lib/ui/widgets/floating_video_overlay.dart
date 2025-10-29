import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/video_frame_cubit.dart';
import 'package:nt_helper/cubit/video_frame_state.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/ui/widgets/draggable_resizable_overlay.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uvccamera/uvccamera.dart';

class FloatingVideoOverlay extends StatefulWidget {
  final OverlayEntry overlayEntry;
  final DistingCubit cubit;
  final VideoFrameCubit videoFrameCubit;

  const FloatingVideoOverlay({
    super.key,
    required this.overlayEntry,
    required this.cubit,
    required this.videoFrameCubit,
  });

  @override
  State<FloatingVideoOverlay> createState() => _FloatingVideoOverlayState();
}

class _FloatingVideoOverlayState extends State<FloatingVideoOverlay> {
  Uint8List? _lastFrame;
  Uint8List? _displayFrame; // Stable frame buffer for display
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[FloatingVideoOverlay] initState called - starting video stream',
    );
    debugPrint('[FloatingVideoOverlay] Widget cubit: ${widget.cubit}');
    debugPrint(
      '[FloatingVideoOverlay] VideoFrame cubit: ${widget.videoFrameCubit}',
    );
    // Start video stream when widget is created
    widget.cubit.startVideoStream();
    debugPrint('[FloatingVideoOverlay] startVideoStream() called');

    // Connect VideoFrameCubit to the raw video stream when it becomes available
    // Only for non-Android platforms (Android uses UvcCameraPreview widget directly)
    if (!Platform.isAndroid) {
      _connectVideoFrameCubit();
    }
  }

  void _connectVideoFrameCubit() {
    // Don't reconnect if already connected
    if (_isConnected) {
      debugPrint(
        '[FloatingVideoOverlay] Already connected, skipping reconnection',
      );
      return;
    }

    // Listen for video manager state changes to connect VideoFrameCubit
    // Get the video manager directly from the DistingCubit
    final videoManager = widget.cubit.videoManager;
    if (videoManager != null) {
      // Check if we have an Android controller first
      final androidController = videoManager.getAndroidCameraController();
      if (androidController != null) {
        debugPrint(
          '[FloatingVideoOverlay] Android controller available, skipping VideoFrameCubit connection',
        );
        return; // Don't connect VideoFrameCubit on Android when using UvcCameraPreview
      }

      final rawStream = videoManager.getRawVideoStream();
      if (rawStream != null) {
        debugPrint(
          '[FloatingVideoOverlay] Connecting VideoFrameCubit to raw stream',
        );
        widget.videoFrameCubit.connectToStream(rawStream);
        _isConnected = true;
        return;
      }
    }

    debugPrint(
      '[FloatingVideoOverlay] Video stream not available yet, will retry in 500ms',
    );
    // Retry after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _connectVideoFrameCubit();
    });
  }

  @override
  void dispose() {
    // Reset connection flag
    _isConnected = false;
    // Stop video stream when widget is disposed
    widget.videoFrameCubit.disconnect();
    widget.cubit.stopVideoStream();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    if (_lastFrame != null) {
      Pasteboard.writeImage(_lastFrame);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video frame copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableResizableOverlay(
      overlayEntry: widget.overlayEntry,
      child: FloatingVideoContent(
        cubit: widget.cubit,
        videoFrameCubit: widget.videoFrameCubit,
        overlayEntry: widget.overlayEntry,
        lastFrame: _lastFrame,
        displayFrame: _displayFrame,
        onCopyToClipboard: _copyToClipboard,
        onFrameUpdate: (frameData) {
          // Callback to update frame data
          _lastFrame = frameData;
          if (_displayFrame == null || frameData != _displayFrame) {
            _displayFrame = frameData;
            // Schedule update for next frame instead of calling setState
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
        },
      ),
    );
  }
}

class FloatingVideoContent extends StatelessWidget {
  final DistingCubit cubit;
  final VideoFrameCubit videoFrameCubit;
  final OverlayEntry overlayEntry;
  final Uint8List? lastFrame;
  final Uint8List? displayFrame;
  final VoidCallback onCopyToClipboard;
  final ValueChanged<Uint8List> onFrameUpdate;

  const FloatingVideoContent({
    super.key,
    required this.cubit,
    required this.videoFrameCubit,
    required this.overlayEntry,
    required this.lastFrame,
    required this.displayFrame,
    required this.onCopyToClipboard,
    required this.onFrameUpdate,
  });

  Widget _buildAndroidCameraPreview(UvcCameraController controller) {
    // Use ValueListenableBuilder to react to controller state changes
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final deviceName = value.device.name;
        debugPrint(
          '[FloatingVideoContent] Controller state: isInitialized=${value.isInitialized}, '
          'previewMode=${value.previewMode}, device=$deviceName',
        );

        if (value.isInitialized) {
          debugPrint(
            '[FloatingVideoContent] Controller initialized - displaying UvcCameraPreview',
          );
          // Wrap in a Container to ensure proper sizing
          return Container(
            color: Colors.black, // Add background to see if widget is there
            child: UvcCameraPreview(controller),
          );
        } else {
          debugPrint(
            '[FloatingVideoContent] Controller not ready - waiting for initialization',
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Initializing camera...\n'
                  'Device: ${value.device.name}\n'
                  'Initialized: ${value.isInitialized}',
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCrossPlatformVideoContent(BuildContext context) {
    // Use VideoFrameCubit for all other platforms
    return BlocBuilder<VideoFrameCubit, VideoFrameState>(
      bloc: videoFrameCubit,
      builder: (context, frameState) {
        return frameState.when(
          // Regular frame state with frame data
          (frameData, frameCounter, lastFrameTime, fps) {
            if (frameData != null && frameData.isNotEmpty) {
              // Validate frame data before using it
              if (frameData.length > 10) {
                // Basic size check
                onFrameUpdate(frameData);
              }
            }

            // Always show the stable display frame
            if (displayFrame != null) {
              return GestureDetector(
                onLongPress: onCopyToClipboard,
                child: SizedBox.expand(
                  child: RepaintBoundary(
                    child: Image.memory(
                      displayFrame!,
                      key: const ValueKey('stable_frame'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Frame error'));
                      },
                    ),
                  ),
                ),
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Waiting for video frames...'),
                  ],
                ),
              );
            }
          },
          // Initial state - check connection status from main cubit
          initial: () {
            return BlocBuilder<DistingCubit, DistingState>(
              bloc: cubit,
              builder: (context, cubitState) {
                final videoState = cubitState.maybeWhen(
                  synchronized:
                      (_, _, _, _, _, _, _, _, _, _, _, _, _, videoStream) =>
                          videoStream,
                  orElse: () => null,
                );

                return videoState?.maybeWhen(
                      connecting: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Connecting to USB video...'),
                          ],
                        ),
                      ),
                      error: (message) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Checking for device automatically...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => cubit.startVideoStream(),
                              child: const Text('Retry Now'),
                            ),
                          ],
                        ),
                      ),
                      orElse: () => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'USB video not available',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Waiting for connection...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ) ??
                    const Center(child: Text('Initializing...'));
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on Android and have a UvcCameraController
    UvcCameraController? androidController;
    bool useAndroidPreview = false;

    if (Platform.isAndroid) {
      androidController = cubit.videoManager?.getAndroidCameraController();
      useAndroidPreview = androidController != null;
      debugPrint(
        '[FloatingVideoContent] Android platform detected:\n'
        '  - videoManager: ${cubit.videoManager != null ? "Available" : "NULL"}\n'
        '  - controller: ${androidController != null ? "Available" : "NULL"}\n'
        '  - useAndroidPreview: $useAndroidPreview',
      );

      // Additional debug info about the controller state
      if (androidController != null) {
        final state = androidController.value;
        debugPrint(
          '[FloatingVideoContent] Controller details:\n'
          '  - isInitialized: ${state.isInitialized}\n'
          '  - device: ${state.device.name}\n'
          '  - previewMode: ${state.previewMode}',
        );
      }
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Stack(
          children: [
            // Main video content
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: useAndroidPreview
                  ? _buildAndroidCameraPreview(androidController!)
                  : _buildCrossPlatformVideoContent(context),
            ),

            // Close button positioned on the right side
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
