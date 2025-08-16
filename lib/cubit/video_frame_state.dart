import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_frame_state.freezed.dart';

@freezed
class VideoFrameState with _$VideoFrameState {
  const factory VideoFrameState({
    Uint8List? frameData,
    @Default(0) int frameCounter,
    DateTime? lastFrameTime,
    @Default(0.0) double fps,
  }) = _VideoFrameState;
  
  const factory VideoFrameState.initial() = _Initial;
}