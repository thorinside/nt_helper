import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/video_frame_state.dart';

class VideoFrameCubit extends Cubit<VideoFrameState> {
  VideoFrameCubit() : super(const VideoFrameState.initial());

  StreamSubscription<dynamic>? _frameSubscription;
  DateTime? _lastFrameTime;
  int _frameCounter = 0;
  final List<double> _fpsBuffer = [];
  static const int _fpsBufferSize = 10;

  /// Connect to a video stream and start receiving frames
  void connectToStream(Stream<dynamic> videoStream) {
    debugPrint('[VideoFrameCubit] Connecting to video stream');
    
    // Cancel any existing subscription
    _frameSubscription?.cancel();
    
    // Reset counters
    _frameCounter = 0;
    _lastFrameTime = null;
    _fpsBuffer.clear();
    
    // Subscribe to the video stream
    _frameSubscription = videoStream.listen(
      _onFrameReceived,
      onError: (error) {
        debugPrint('[VideoFrameCubit] Stream error: $error');
        emit(const VideoFrameState.initial());
      },
      onDone: () {
        debugPrint('[VideoFrameCubit] Stream ended');
        emit(const VideoFrameState.initial());
      },
    );
  }

  /// Handle incoming video frame
  void _onFrameReceived(dynamic data) {
    // Cast data to Uint8List (EventChannel provides correct type for binary data)
    final frameData = data as Uint8List;
    
    final now = DateTime.now();
    _frameCounter++;
    
    // Calculate FPS
    double currentFps = 0.0;
    if (_lastFrameTime != null) {
      final timeDiff = now.difference(_lastFrameTime!).inMicroseconds;
      if (timeDiff > 0) {
        final instantFps = 1000000.0 / timeDiff; // Convert microseconds to FPS
        _fpsBuffer.add(instantFps);
        
        // Keep buffer size limited
        if (_fpsBuffer.length > _fpsBufferSize) {
          _fpsBuffer.removeAt(0);
        }
        
        // Calculate average FPS
        currentFps = _fpsBuffer.reduce((a, b) => a + b) / _fpsBuffer.length;
      }
    }
    
    _lastFrameTime = now;
    
    // Emit new frame state
    emit(VideoFrameState(
      frameData: frameData,
      frameCounter: _frameCounter,
      lastFrameTime: now,
      fps: currentFps,
    ));
    
  }

  /// Disconnect from the video stream
  void disconnect() {
    debugPrint('[VideoFrameCubit] Disconnecting from video stream');
    _frameSubscription?.cancel();
    _frameSubscription = null;
    emit(const VideoFrameState.initial());
  }

  @override
  Future<void> close() {
    _frameSubscription?.cancel();
    return super.close();
  }
}