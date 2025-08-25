import 'package:freezed_annotation/freezed_annotation.dart';

part 'algorithm_parameter.freezed.dart';
part 'algorithm_parameter.g.dart';

@freezed
sealed class AlgorithmParameter with _$AlgorithmParameter {
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
    List<String>? enumValues,
    String?
    type, // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
    String? busIdRef,
    String? channelCountRef,
    bool? isPerChannel,
    bool? isCommon,
    int? parameterNumber,
  }) = _AlgorithmParameter;

  factory AlgorithmParameter.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmParameterFromJson(json);
}
