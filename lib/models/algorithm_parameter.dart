import 'package:freezed_annotation/freezed_annotation.dart';

part 'algorithm_parameter.freezed.dart';
part 'algorithm_parameter.g.dart';

@freezed
class AlgorithmParameter with _$AlgorithmParameter {
  const factory AlgorithmParameter({
    required String name,
    String? unit,
    // Using dynamic for min/max/default as they can be int, double, or null
    dynamic min,
    dynamic max,
    dynamic defaultValue,
    String?
        scope, // e.g., "global", "per-channel", "per-trigger", "operator", "program", "mix", "routing", "vco", "gain", "filter", "animate"
    String? description,
    @JsonKey(name: 'enumValues') List<String>? values,
    String?
        type, // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
    @JsonKey(name: 'busIdRef') String? busIdRef,
    @JsonKey(name: 'channelCountRef') String? channelCountRef,
    @JsonKey(name: 'isPerChannel') bool? isPerChannel,
    @JsonKey(name: 'isCommon') bool? isCommon,
  }) = _AlgorithmParameter;

  factory AlgorithmParameter.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmParameterFromJson(json);
}
