import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_stream_state.freezed.dart';

@freezed
class VideoStreamState with _$VideoStreamState {
  const factory VideoStreamState.disconnected() = _Disconnected;
  const factory VideoStreamState.connecting() = _Connecting;
  const factory VideoStreamState.streaming({
    required Stream<dynamic> videoStream,
    required int width,
    required int height,
    required double fps,
  }) = _Streaming;
  const factory VideoStreamState.error(String message) = _Error;
}
