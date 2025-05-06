import 'package:freezed_annotation/freezed_annotation.dart';

part 'algorithm_port.freezed.dart';
part 'algorithm_port.g.dart';

@freezed
class AlgorithmPort with _$AlgorithmPort {
  const factory AlgorithmPort({
    String? id,
    required String name,
    String? description,
    @JsonKey(name: 'busIdRef') String? busIdRef,
    @JsonKey(name: 'channelCountRef') String? channelCountRef,
    @JsonKey(name: 'isPerChannel') bool? isPerChannel,
  }) = _AlgorithmPort;

  factory AlgorithmPort.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmPortFromJson(json);
}
