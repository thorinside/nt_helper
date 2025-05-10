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
        // Handle unexpected type
        print('Warning: Unexpected type in ports list: ${item.runtimeType}');
        // Returning a default/empty port or throwing might be better
        return AlgorithmPort(name: 'Invalid Port');
      }
    }).toList();

// Helper function to handle serialization of potentially mixed list
List<dynamic> _portsToJson(List<AlgorithmPort> ports) => ports.map((port) {
      // Check if it's a "simple" port (only name is non-null/default)
      if (port.id == null &&
          port.description == null &&
          port.busIdRef == null &&
          port.channelCountRef == null &&
          port.isPerChannel == null) {
        return port.name; // Serialize as simple string
      } else {
        return port.toJson(); // Otherwise, serialize as full object
      }
    }).toList();

List<AlgorithmParameter> _parametersFromJson(List<dynamic>? jsonList) {
  if (jsonList == null) return [];
  final List<AlgorithmParameter> allParams = [];
  for (final item in jsonList) {
    if (item is Map<String, dynamic>) {
      if (item.containsKey('params') && item['params'] is List) {
        // It's a page object
        final pageParams = item['params'] as List;
        for (final paramJson in pageParams) {
          if (paramJson is Map<String, dynamic>) {
            try {
              // Attempt to read parameterNumber, defaults to null if not present
              final int? pNum = paramJson['parameterNumber'] as int?;
              allParams.add(AlgorithmParameter.fromJson(paramJson)
                  .copyWith(parameterNumber: pNum));
            } catch (e) {
              print(
                  'Error parsing parameter within page ${item['page']}: $paramJson\nError: $e');
            }
          }
        }
      } else if (item.containsKey('name')) {
        // It might be a parameter directly in the list
        try {
          // Attempt to read parameterNumber, defaults to null if not present
          final int? pNum = item['parameterNumber'] as int?;
          allParams.add(AlgorithmParameter.fromJson(item)
              .copyWith(parameterNumber: pNum));
        } catch (e) {
          print('Error parsing parameter directly in list: $item\nError: $e');
        }
      }
    }
  }
  return allParams;
}

// We don't need a custom _parametersToJson unless the serialization needs modification

@freezed
class AlgorithmMetadata with _$AlgorithmMetadata {
  const factory AlgorithmMetadata({
    required String guid,
    required String name,
    required List<String> categories,
    required String description,
    @Default([]) List<AlgorithmSpecification> specifications,
    @JsonKey(fromJson: _parametersFromJson)
    @Default([])
    List<AlgorithmParameter> parameters, // Use custom parser
    @Default([]) List<String> features, // List of feature GUIDs
    @JsonKey(
        name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
    @Default([])
    List<AlgorithmPort> inputPorts,
    @JsonKey(
        name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
    @Default([])
    List<AlgorithmPort> outputPorts,
  }) = _AlgorithmMetadata;

  // Modify the factory to use the generated one internally but handle parameters separately
  factory AlgorithmMetadata.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmMetadataFromJson(json);
}
