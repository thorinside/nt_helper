import 'package:freezed_annotation/freezed_annotation.dart';

part 'algorithm_specification.freezed.dart';
part 'algorithm_specification.g.dart';

@freezed
sealed class AlgorithmSpecification with _$AlgorithmSpecification {
  const factory AlgorithmSpecification({
    required String name,
    String? unit,
    // Using dynamic for value fields as structure varies (min/max/default or just value)
    dynamic value,
    String? description,
    dynamic min, // For older format
    dynamic max, // For older format
  }) = _AlgorithmSpecification;

  factory AlgorithmSpecification.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmSpecificationFromJson(json);
}
