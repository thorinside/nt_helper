import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/algorithm_parameter.dart';
import 'package:nt_helper/models/algorithm_specification.dart';
import 'package:nt_helper/models/algorithm_port.dart';

part 'algorithm_metadata.freezed.dart';
part 'algorithm_metadata.g.dart';

// Helper function to handle deserialization of potentially mixed list
List<AlgorithmPort> _portsFromJson(List<dynamic> jsonList) =>
    jsonList.map((item) {
      if (item is String) {
        // Create a basic AlgorithmPort from the string name
        return AlgorithmPort(name: item);
      } else if (item is Map<String, dynamic>) {
        // Parse the map using the standard factory
        return AlgorithmPort.fromJson(item);
      } else {
        // Handle unexpected type - return a default port
        return AlgorithmPort(name: 'Unknown Port');
      }
    }).toList();

List<AlgorithmParameter> _parametersFromJson(List<dynamic>? jsonList) {
  if (jsonList == null) return [];
  final List<AlgorithmParameter> allParams = [];
  for (final item in jsonList) {
    if (item is Map<String, dynamic>) {
      if (item.containsKey('params') && item['params'] is List) {
        // It's a page object with nested params array
        final pageParams = item['params'] as List;
        for (final paramJson in pageParams) {
          if (paramJson is Map<String, dynamic>) {
            try {
              allParams.add(AlgorithmParameter.fromJson(paramJson));
            } catch (e) {
              // Skip invalid parameters
            }
          }
        }
      } else if (item.containsKey('page') && !item.containsKey('params')) {
        // It's a page object but params might be missing (malformed)
        // Skip this page
        continue;
      } else if (item.containsKey('name')) {
        // It's a parameter directly in the list (flat structure)
        try {
          allParams.add(AlgorithmParameter.fromJson(item));
        } catch (e) {
          // Skip invalid parameters
        }
      }
    }
  }
  return allParams;
}

// Custom converters for JSON serialization

@freezed
sealed class AlgorithmMetadata with _$AlgorithmMetadata {
  const factory AlgorithmMetadata({
    required String guid,
    required String name,
    required List<String> categories,
    required String description,
    @JsonKey(name: 'short_description') String? shortDescription,
    @JsonKey(name: 'gui_description') String? guiDescription,
    @JsonKey(name: 'use_cases') @Default([]) List<String> useCases,
    @Default([]) List<AlgorithmSpecification> specifications,
    @JsonKey(fromJson: _parametersFromJson)
    @Default([])
    List<AlgorithmParameter> parameters,
    @Default([]) List<String> features, // List of feature GUIDs
    @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
    @Default([])
    List<AlgorithmPort> inputPorts,
    @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
    @Default([])
    List<AlgorithmPort> outputPorts,
  }) = _AlgorithmMetadata;

  factory AlgorithmMetadata.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmMetadataFromJson(json);
}
