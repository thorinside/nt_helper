import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/video_frame_cubit.dart';
import 'package:nt_helper/cubit/video_frame_state.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:pasteboard/pasteboard.dart';

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
  bool _isExpanded = false;
  Uint8List? _lastFrame;
  Uint8List? _displayFrame;  // Stable frame buffer for display

  @override
  void initState() {
    super.initState();
    debugPrint('[FloatingVideoOverlay] initState called - starting video stream');
    debugPrint('[FloatingVideoOverlay] Widget cubit: ${widget.cubit}');
    debugPrint('[FloatingVideoOverlay] VideoFrame cubit: ${widget.videoFrameCubit}');
    // Start video stream when widget is created
    widget.cubit.startVideoStream();
    debugPrint('[FloatingVideoOverlay] startVideoStream() called');
    
    // Connect VideoFrameCubit to the raw video stream when it becomes available
    _connectVideoFrameCubit();
  }

  void _connectVideoFrameCubit() {
    // Listen for video manager state changes to connect VideoFrameCubit
    // Get the video manager directly from the DistingCubit
    final videoManager = widget.cubit.videoManager;
    if (videoManager != null) {
      final rawStream = videoManager.getRawVideoStream();
      if (rawStream != null) {
        debugPrint('[FloatingVideoOverlay] Connecting VideoFrameCubit to raw stream');
        widget.videoFrameCubit.connectToStream(rawStream);
        return;
      }
    }
    
    debugPrint('[FloatingVideoOverlay] Video stream not available yet, will retry');
    // Retry after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _connectVideoFrameCubit();
    });
  }

  @override
  void dispose() {
    // Stop video stream when widget is disposed
    widget.videoFrameCubit.disconnect();
    widget.cubit.stopVideoStream();
    super.dispose();
  }

  void _toggleSize() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
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
    return SafeArea(
      child: GestureDetector(
        onTap: _toggleSize,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Video indicator
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: BlocBuilder<DistingCubit, DistingState>(
                        bloc: widget.cubit,
                        builder: (context, cubitState) {
                          final videoState = cubitState.maybeWhen(
                            synchronized: (disting, distingVersion, firmwareVersion, presetName, algorithms, slots, unitStrings, inputDevice, outputDevice, loading, offline, screenshot, demo, videoStream) => videoStream,
                            orElse: () => null,
                          );
                          
                          if (videoState != null && videoState.maybeMap(
                              streaming: (_) => true,
                              orElse: () => false)) {
                            return const Icon(
                              Icons.videocam,
                              color: Colors.green,
                              size: 16,
                            );
                          } else if (videoState != null && videoState.maybeMap(
                              connecting: (_) => true,
                              orElse: () => false)) {
                            return const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          } else if (videoState != null && videoState.maybeMap(
                              error: (_) => true,
                              orElse: () => false)) {
                            return const Icon(
                              Icons.videocam_off,
                              color: Colors.red,
                              size: 16,
                            );
                          } else {
                            return const Icon(
                              Icons.videocam_off,
                              color: Colors.grey,
                              size: 16,
                            );
                          }
                        },
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        widget.overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _isExpanded ? 384 : 256,
                height: _isExpanded ? 96 : 64,  // Maintain 4:1 aspect ratio (256:64)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: BlocBuilder<VideoFrameCubit, VideoFrameState>(
                    bloc: widget.videoFrameCubit,
                    builder: (context, frameState) {
                      return frameState.when(
                        // Regular frame state with frame data
                        (frameData, frameCounter, lastFrameTime, fps) {
                          if (frameData != null && frameData.isNotEmpty) {
                            // Validate frame data before using it
                            if (frameData.length > 10) {  // Basic size check
                              _lastFrame = frameData;
                              // Update display frame without setState during build
                              if (_displayFrame == null || frameData != _displayFrame) {
                                _displayFrame = frameData;
                                // Schedule update for next frame instead of calling setState
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() {});
                                });
                              }
                            }
                          }
                          
                          // Always show the stable display frame
                          if (_displayFrame != null) {
                            return GestureDetector(
                              onLongPress: _copyToClipboard,
                              child: RepaintBoundary(
                                child: Image.memory(
                                  _displayFrame!,
                                  key: ValueKey('stable_frame'),  // Use stable key
                                  fit: BoxFit.contain,  // Show entire image without cropping
                                  gaplessPlayback: true, // Enable for smoother playback
                                  excludeFromSemantics: true,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Text('Frame error'));
                                  },
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
                            bloc: widget.cubit,
                            builder: (context, cubitState) {
                              final videoState = cubitState.maybeWhen(
                                synchronized: (_, _, _, _, _, _, _, _, _, _, _, _, _, videoStream) => videoStream,
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
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () => widget.cubit.startVideoStream(),
                                        child: const Text('Retry'),
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
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ) ?? const Center(
                                child: Text('Initializing...'),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}