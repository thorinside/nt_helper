import 'dart:convert';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/util/case_converter.dart';
import 'package:nt_helper/util/routing_analyzer.dart';
import 'package:nt_helper/mcp/mcp_constants.dart';

/// Class containing methods representing MCP tools.
/// Requires DistingCubit for accessing application state.
class MCPAlgorithmTools {
  // Make service instance-based if needed, or keep static if stateless
  static final _metadataService = AlgorithmMetadataService();
  final DistingCubit _distingCubit;

  MCPAlgorithmTools(this._distingCubit);

  /// MCP Tool: Retrieves full metadata for a specific algorithm.
  /// Parameters:
  ///   - algorithm_guid (string): The unique identifier of the algorithm.
  ///   - algorithm_name (string): The name of the algorithm (alternative to GUID).
  ///   - expand_features (bool, optional, default: false): Expand feature parameters.
  /// Returns:
  ///   A JSON string representing the AlgorithmMetadata, or an error JSON if not found or ambiguous.
  Future<String> getAlgorithmDetails(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    final String? algorithmName = params['algorithm_name'];
    final bool expandFeatures = params['expand_features'] ?? false;

    // Use shared algorithm resolver
    final algorithms = _metadataService.getAllAlgorithms();
    final resolution = AlgorithmResolver.resolveAlgorithm(
      guid: algorithmGuid,
      algorithmName: algorithmName,
      allAlgorithms: algorithms,
    );

    if (!resolution.isSuccess) {
      return jsonEncode(convertToSnakeCaseKeys(resolution.error!));
    }

    final algorithm =
        _metadataService.getAlgorithmByGuid(resolution.resolvedGuid!);
    if (algorithm == null) {
      return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
          '${MCPConstants.notFoundError}: Algorithm with GUID "${resolution.resolvedGuid!}"',
          helpCommand: MCPConstants.getAlgorithmHelp)));
    }

    AlgorithmMetadata algoToProcess;
    if (expandFeatures) {
      final expandedParams =
          _metadataService.getExpandedParameters(resolution.resolvedGuid!);
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

  /// MCP Tool: Lists algorithms, optionally filtered by category or a text query.
  /// Parameters:
  ///   - category (string, optional): Filter by category.
  ///   - query (string, optional): Filter by a text search query.
  /// Returns:
  ///   A JSON string representing a list of AlgorithmMetadata objects, containing
  ///   only guid, name, and the first sentence of the description.
  Future<String> listAlgorithms(Map<String, dynamic> params) async {
    final String? category = params['category'];
    final String? query = params['query']; // Added query parameter

    List<AlgorithmMetadata> algorithms = _metadataService.getAllAlgorithms();

    // Apply filters
    if (category != null && category.isNotEmpty) {
      algorithms = algorithms
          .where((alg) => alg.categories.any((cat) =>
              cat.toLowerCase() == category.toLowerCase() ||
              MCPUtils.similarity(cat, category) >= 0.7))
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      algorithms = algorithms.where((alg) {
        return alg.name.toLowerCase().contains(lowercaseQuery) ||
            alg.description.toLowerCase().contains(lowercaseQuery) ||
            alg.categories
                .any((cat) => cat.toLowerCase().contains(lowercaseQuery)) ||
            alg.features.any(
                (feature) => feature.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }

    List<Map<String, dynamic>> resultList = [];
    for (var alg in algorithms) {
      String firstSentenceDescription = '';
      if (alg.description.isNotEmpty) {
        int firstPeriod = alg.description.indexOf('.');
        if (firstPeriod != -1) {
          firstSentenceDescription =
              alg.description.substring(0, firstPeriod + 1);
        } else {
          firstSentenceDescription =
              alg.description; // No period, take whole description
        }
      }
      resultList.add({
        'guid': alg.guid,
        'name': alg.name,
        'description': firstSentenceDescription,
      });
    }
    return jsonEncode(convertToSnakeCaseKeys(resultList));
  }

  /// MCP Tool: Retrieves the current routing state decoded into RoutingInformation objects.
  /// Parameters: None
  /// Returns:
  ///   A JSON string representing the input and output busses of each slot.
  ///   Returns an empty list '[]' if the state is not synchronized.
  Future<String> getCurrentRoutingState(Map<String, dynamic> params) async {
    try {
      // First, actively refresh routing information from hardware
      await _distingCubit.refreshRouting();
    } catch (e) {
      // If hardware refresh fails, continue with cached data
      // This handles offline/mock modes gracefully
    }

    // Access the injected DistingCubit instance to get updated routing info
    final routingInfoList = _distingCubit.buildRoutingInformation();

    RoutingAnalyzer analyzer = RoutingAnalyzer(
        routing: routingInfoList, showSignals: true, showMappings: false);

    return jsonEncode(
      convertToSnakeCaseKeys(analyzer.generateSlotBusUsageJson()),
    );
  }
}
