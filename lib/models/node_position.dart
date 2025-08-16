import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_position.freezed.dart';
part 'node_position.g.dart';

@freezed
sealed class NodePosition with _$NodePosition {
  const factory NodePosition({
    required int algorithmIndex,
    required double x,
    required double y,
    @Default(200.0) double width,
    @Default(100.0) double height,
  }) = _NodePosition;

  factory NodePosition.fromJson(Map<String, dynamic> json) =>
      _$NodePositionFromJson(json);
}