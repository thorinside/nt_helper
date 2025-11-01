import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

// Define the schema for algorithm metadata
class AlgorithmMetadata {
  final String name;
  final String guid;
  final String description;
  final List<String> possibleUses;
  final Map<String, dynamic> specifications;
  final List<AlgorithmParameter> parameters;

  AlgorithmMetadata({
    required this.name,
    required this.guid,
    required this.description,
    required this.possibleUses,
    required this.specifications,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'guid': guid,
      'description': description,
      'possible_uses': possibleUses,
      'specifications': specifications,
      'parameters': parameters.map((param) => param.toJson()).toList(),
    };
  }
}

class AlgorithmParameter {
  final String name;
  final dynamic min;
  final dynamic max;
  final dynamic defaultValue;
  final String unit;
  final String description;
  final bool isEnum;
  final List<String> possibleEnumValues;
  final bool isInput;
  final bool isOutput;

  AlgorithmParameter({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.unit,
    required this.description,
    this.isEnum = false,
    this.possibleEnumValues = const [],
    this.isInput = false,
    this.isOutput = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min': min,
      'max': max,
      'default': defaultValue,
      'unit': unit,
      'description': description,
      'is_enum': isEnum,
      'possible_enum_values': possibleEnumValues,
      'is_input': isInput,
      'is_output': isOutput,
    };
  }
}

// Common features shared across algorithms
Map<String, dynamic> commonFeatures = {};
Map<String, dynamic> commonPolysynthFeatures = {};

// Main function to extract algorithm metadata
Future<void> main() async {
  // Get the project root directory
  final projectRoot = Directory.current.path;

  // Define the path to the manual file
  final manualPath = path.join(
    projectRoot,
    'test',
    'doc',
    'disting_nt_manual_1.8.0.md',
  );

  // Define the output path for the JSON file
  final outputPath = path.join(projectRoot, 'test', 'doc', 'algorithms.json');

  // Read the manual content
  final File manualFile = File(manualPath);
  if (!await manualFile.exists()) {
    exit(1);
  }

  final String manualContent = await manualFile.readAsString();

  // Extract common features
  commonFeatures = await extractCommonFeatures(manualContent);
  commonPolysynthFeatures = await extractPolysynthFeatures(manualContent);

  // Extract all algorithm metadata
  final algorithms = await extractAllAlgorithms(manualContent);

  // Create the full JSON structure
  final outputJson = {
    'common_features': commonFeatures,
    'common_polysynth_features': commonPolysynthFeatures,
    'algorithms': algorithms,
  };

  // Write to the output file
  final outputFile = File(outputPath);
  await outputFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(outputJson),
  );
}

// Function to extract common features from the manual
Future<Map<String, dynamic>> extractCommonFeatures(String manualContent) async {
  // This will be implemented in Task #45
  return {}; // Placeholder
}

// Function to extract polysynth features from the manual
Future<Map<String, dynamic>> extractPolysynthFeatures(
  String manualContent,
) async {
  // This will be implemented in Task #46
  return {}; // Placeholder
}

// Function to extract all algorithms from the manual
Future<List<Map<String, dynamic>>> extractAllAlgorithms(
  String manualContent,
) async {
  final List<Map<String, dynamic>> algorithms = [];

  // This will contain the regex and logic to extract each algorithm
  // For now, it's a placeholder that will be filled in by the individual tasks

  return algorithms; // Placeholder
}

// Function to extract a specific algorithm by its section title
Future<Map<String, dynamic>?> extractAlgorithm(
  String manualContent,
  String algorithmName,
  String guid,
) async {
  // This will be implemented in the individual algorithm tasks
  return null; // Placeholder
}

// Helper function to parse parameter tables from the manual
List<AlgorithmParameter> parseParameterTable(String tableContent) {
  final List<AlgorithmParameter> parameters = [];

  // This will be implemented to parse the parameter tables
  // For now, it's a placeholder

  return parameters;
}

// Utility function to clean and normalize strings
String cleanString(String input) {
  return input.trim().replaceAll(RegExp(r'\s+'), ' ');
}

// Utility function to guess parameter type and range if not specified
AlgorithmParameter guessParameterDetails(String name, String description) {
  // This will contain logic to infer parameter details when they're not explicitly stated
  // For now, it's a placeholder

  return AlgorithmParameter(
    name: name,
    min: 0,
    max: 1,
    defaultValue: 0,
    unit: '',
    description: description,
  );
}
