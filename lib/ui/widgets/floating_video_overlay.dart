import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/video_frame_cubit.dart';
import 'package:nt_helper/cubit/video_frame_state.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/ui/widgets/draggable_resizable_overlay.dart';
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
  Uint8List? _lastFrame;
  Uint8List? _displayFrame; // Stable frame buffer for display
  StreamSubscription<VideoStreamState?>? _videoStateSubscription;
  Stream<dynamic>? _connectedStream;

  @override
  void initState() {
    super.initState();
    _videoStateSubscription = widget.cubit.videoStreamState.listen(
      _onVideoStateChanged,
    );

    // Start video stream when widget is created
    widget.cubit.startVideoStream();
    _onVideoStateChanged(widget.cubit.currentVideoState);
  }

  void _onVideoStateChanged(VideoStreamState? videoState) {
    final stream = videoState?.maybeWhen(
      streaming: (videoStream, width, height, fps) => videoStream,
      orElse: () => null,
    );

    if (stream == null) {
      _connectedStream = null;
      widget.videoFrameCubit.disconnect();
      return;
    }

    if (!identical(stream, _connectedStream)) {
      _connectedStream = stream;
      widget.videoFrameCubit.connectToStream(stream);
    }
  }

  @override
  void dispose() {
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    _connectedStream = null;

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
        lastFrame: _lastFrame,
        displayFrame: _displayFrame,
        onCopyToClipboard: _copyToClipboard,
        onFrameUpdate: (frameData) {
          // Callback to update frame data
          final stableBytes = Uint8List.fromList(frameData);
          final previousFrame = _displayFrame;

          _lastFrame = stableBytes;
          _displayFrame = stableBytes;

          if (previousFrame != null) {
            MemoryImage(previousFrame).evict();
          }

          // Schedule update for next frame instead of calling setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        },
      ),
    );
  }
}

class FloatingVideoContent extends StatelessWidget {
  final DistingCubit cubit;
  final VideoFrameCubit videoFrameCubit;
  final Uint8List? lastFrame;
  final Uint8List? displayFrame;
  final VoidCallback onCopyToClipboard;
  final ValueChanged<Uint8List> onFrameUpdate;

  static const int _fadeInFrames = 8;

  const FloatingVideoContent({
    super.key,
    required this.cubit,
    required this.videoFrameCubit,
    required this.lastFrame,
    required this.displayFrame,
    required this.onCopyToClipboard,
    required this.onFrameUpdate,
  });

  Widget _buildVideoContent(BuildContext context) {
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
            final bytesToDisplay = displayFrame ?? frameData;
            if (bytesToDisplay != null) {
              // Start at 30% opacity so first frame is visible, fade to 100%
              final framesIntoFade = frameCounter.clamp(0, _fadeInFrames);
              final fadeT = (framesIntoFade / _fadeInFrames).clamp(0.0, 1.0);
              final opacity = 0.3 + 0.7 * Curves.easeOut.transform(fadeT);

              return GestureDetector(
                onLongPress: onCopyToClipboard,
                child: SizedBox.expand(
                  child: RepaintBoundary(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Opacity(
                        opacity: opacity,
                        child: Image.memory(
                          bytesToDisplay,
                          key: const ValueKey('stable_frame'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Frame error',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return const ColoredBox(color: Colors.black);
            }
          },
          // Initial state - check connection status from main cubit
          initial: () {
            return BlocBuilder<DistingCubit, DistingState>(
              bloc: cubit,
              builder: (context, cubitState) {
                final videoState = cubitState.maybeWhen(
                  synchronized:
                      (_, _, _, _, _, _, _, _, _, _, _, _, _, videoStream, _) =>
                          videoStream,
                  orElse: () => null,
                );

                final errorMessage = videoState?.maybeWhen(
                  error: (message) => message,
                  orElse: () => null,
                );

                if (errorMessage == null) {
                  return const ColoredBox(color: Colors.black);
                }

                return ColoredBox(
                  color: Colors.black,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, opacity, child) =>
                        Opacity(opacity: opacity, child: child),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => cubit.startVideoStream(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildVideoContent(context),
        ),
      ),
    );
  }
}
