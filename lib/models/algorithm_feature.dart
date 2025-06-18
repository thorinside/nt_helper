import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/algorithm_parameter.dart';

part 'algorithm_feature.freezed.dart';
part 'algorithm_feature.g.dart';

@freezed
sealed class AlgorithmFeature with _$AlgorithmFeature {
  const factory AlgorithmFeature({
    required String guid,
    required String name,
    String? description,
    @Default([]) List<AlgorithmParameter> parameters,
  }) = _AlgorithmFeature;

  factory AlgorithmFeature.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmFeatureFromJson(json);
}
