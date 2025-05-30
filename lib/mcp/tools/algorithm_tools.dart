import 'dart:convert';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/util/case_converter.dart';
import 'package:nt_helper/util/routing_analyzer.dart';

/// Class containing methods representing MCP tools.
/// Requires DistingCubit for accessing application state.
class MCPAlgorithmTools {
  // Make service instance-based if needed, or keep static if stateless
  static final _metadataService = AlgorithmMetadataService();
  final DistingCubit _distingCubit;

  MCPAlgorithmTools(this._distingCubit);

  /// MCP Tool: Retrieves full metadata for a specific algorithm.
  /// Parameters:
  ///   - guid (string): The unique identifier of the algorithm.
  ///   - expand_features (bool, optional, default: false): Expand feature parameters.
  /// Returns:
  ///   A JSON string representing the AlgorithmMetadata, or null if not found.
  Future<String?> get_algorithm_details(Map<String, dynamic> params) async {
    final String? guid = params['guid'];
    final bool expandFeatures = params['expand_features'] ?? false;

    if (guid == null || guid.isEmpty) {
      // TODO: Return proper MCP error format
      print(
          'Error: Missing or invalid guid parameter for get_algorithm_details');
      return null;
    }

    // Access static service for now
    final algorithm = _metadataService.getAlgorithmByGuid(guid);
    if (algorithm == null) {
      return null; // Not found
    }

    AlgorithmMetadata algoToProcess;
    if (expandFeatures) {
      // Access static service for now
      final expandedParams = _metadataService.getExpandedParameters(guid);
      // Create a new AlgorithmMetadata object with expanded parameters
      algoToProcess = algorithm.copyWith(parameters: expandedParams);
    } else {
      algoToProcess = algorithm;
    }

    Map<String, dynamic> algoJson = algoToProcess.toJson();
    if (algoJson['parameters'] is List) {
      List<dynamic> paramsList = algoJson['parameters'] as List<dynamic>;
      for (var param in paramsList) {
        if (param is Map<String, dynamic>) {
          param.remove('parameterNumber');
        }
      }
    }
    return jsonEncode(convertToSnakeCaseKeys(algoJson));
  }

  /// MCP Tool: Lists algorithms, optionally filtered.
  /// Parameters:
  ///   - category (string, optional): Filter by category.
  ///   - feature_guid (string, optional): Filter by feature GUID.
  /// Returns:
  ///   A JSON string representing a list of AlgorithmMetadata objects.
  Future<String> list_algorithms(Map<String, dynamic> params) async {
    final String? category = params['category'];
    final String? featureGuid = params['feature_guid'];

    // Access static service for now
    List<AlgorithmMetadata> algorithms = _metadataService.getAllAlgorithms();

    if (category != null && category.isNotEmpty) {
      algorithms = algorithms
          .where((alg) => alg.categories
              .any((cat) => cat.toLowerCase() == category.toLowerCase()))
          .toList();
    }

    if (featureGuid != null && featureGuid.isNotEmpty) {
      algorithms = algorithms
          .where((alg) => alg.features.contains(featureGuid))
          .toList();
    }

    // Return full metadata for now
    // return jsonEncode(algorithms.map((a) => a.toJson()).toList());
    List<Map<String, dynamic>> resultList = [];
    for (var alg in algorithms) {
      Map<String, dynamic> algoJson = alg.toJson();
      if (algoJson['parameters'] is List) {
        List<dynamic> paramsList = algoJson['parameters'] as List<dynamic>;
        for (var param in paramsList) {
          if (param is Map<String, dynamic>) {
            param.remove('parameterNumber');
          }
        }
      }
      resultList.add(algoJson);
    }
    return jsonEncode(convertToSnakeCaseKeys(resultList));
  }

  /// MCP Tool: Finds algorithms based on a text query.
  /// Parameters:
  ///   - query (string): The search query.
  /// Returns:
  ///   A JSON string representing a list of matching AlgorithmMetadata objects.
  Future<String> find_algorithms(Map<String, dynamic> params) async {
    final String? query = params['query'];

    if (query == null || query.isEmpty) {
      // Return all algorithms if query is empty?
      // Or return error/empty list? Returning empty list for now.
      print('Warning: Empty query for find_algorithms');
      return jsonEncode([]);
    }

    // Access static service for now
    final results = _metadataService.findAlgorithmsByQuery(query);

    List<Map<String, dynamic>> resultList = [];
    for (var alg in results) {
      resultList.add({
        'guid': alg.guid,
        'name': alg.name,
        'description': alg.description,
      });
    }
    return jsonEncode(convertToSnakeCaseKeys(resultList));
  }

  /// MCP Tool: Retrieves the current routing state decoded into RoutingInformation objects.
  /// Parameters: None
  /// Returns:
  ///   A JSON string representing the input and output busses of each slot.
  ///   Returns an empty list '[]' if the state is not synchronized.
  Future<String> get_current_routing_state(Map<String, dynamic> params) async {
    // Access the injected DistingCubit instance
    final routingInfoList = _distingCubit.buildRoutingInformation();

    RoutingAnalyzer analyzer = RoutingAnalyzer(
        routing: routingInfoList, showSignals: true, showMappings: false);

    return jsonEncode(
      convertToSnakeCaseKeys(analyzer.generateSlotBusUsageJson()),
    );
  }
}
