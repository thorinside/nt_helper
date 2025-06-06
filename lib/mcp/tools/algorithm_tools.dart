import 'dart:convert';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/util/case_converter.dart';

/// Class containing methods representing MCP tools.
/// Requires DistingCubit for accessing application state.
class MCPAlgorithmTools {
  // Make service instance-based if needed, or keep static if stateless
  static final _metadataService = AlgorithmMetadataService();
  final DistingCubit _distingCubit;

  MCPAlgorithmTools(this._distingCubit);

  static int _levenshteinDistance(String s, String t) {
    final int sLen = s.length;
    final int tLen = t.length;
    if (sLen == 0) return tLen;
    if (tLen == 0) return sLen;
    final v = List.generate(sLen + 1, (_) => List<int>.filled(tLen + 1, 0));
    for (var i = 0; i <= sLen; i++) {
      v[i][0] = i;
    }
    for (var j = 0; j <= tLen; j++) {
      v[0][j] = j;
    }
    for (var i = 1; i <= sLen; i++) {
      for (var j = 1; j <= tLen; j++) {
        final cost = s[i - 1].toLowerCase() == t[j - 1].toLowerCase() ? 0 : 1;
        v[i][j] = [
          v[i - 1][j] + 1,
          v[i][j - 1] + 1,
          v[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return v[sLen][tLen];
  }

  static double _similarity(String s, String t) {
    final dist = _levenshteinDistance(s, t);
    final maxLen = s.length > t.length ? s.length : t.length;
    if (maxLen == 0) return 1.0;
    return (maxLen - dist) / maxLen;
  }

  /// MCP Tool: Retrieves full metadata for a specific algorithm.
  /// Parameters:
  ///   - guid (string): The unique identifier of the algorithm.
  ///   - expand_features (bool, optional, default: false): Expand feature parameters.
  /// Returns:
  ///   A JSON string representing the AlgorithmMetadata, or an error JSON if not found or ambiguous.
  Future<String> get_algorithm_details(Map<String, dynamic> params) async {
    final String? guid = params['guid'];
    final String? algorithmName = params['algorithm_name'];
    final bool expandFeatures = params['expand_features'] ?? false;

    if ((guid == null || guid.isEmpty) &&
        (algorithmName == null || algorithmName.isEmpty)) {
      return jsonEncode(convertToSnakeCaseKeys({
        'success': false,
        'error': 'Missing required parameter: "guid" or "algorithm_name".'
      }));
    }

    String usedGuid = guid ?? '';
    if (guid == null || guid.isEmpty) {
      final algorithms = _metadataService.getAllAlgorithms();
      final exactMatches = algorithms
          .where((alg) => alg.name.toLowerCase() == algorithmName!.toLowerCase())
          .toList();
      if (exactMatches.isEmpty) {
        final fuzzyMatches = algorithms.where((alg) {
          return _similarity(alg.name, algorithmName!) >= 0.7;
        }).toList();
        if (fuzzyMatches.isEmpty) {
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error': 'No algorithm named "$algorithmName" found.'
          }));
        }
        if (fuzzyMatches.length > 1) {
          final candidates = fuzzyMatches
              .map((alg) => {'name': alg.name, 'guid': alg.guid})
              .toList();
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error':
                'Ambiguous algorithm name "$algorithmName". Fuzzy matches (>=70%): $candidates. Please specify more precisely or use the GUID.'
          }));
        }
        usedGuid = fuzzyMatches.first.guid;
      } else if (exactMatches.length > 1) {
        final candidates = exactMatches
            .map((alg) => {'name': alg.name, 'guid': alg.guid})
            .toList();
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error':
              'Ambiguous algorithm name "$algorithmName". Matches: $candidates. Please specify more precisely.'
        }));
      } else {
        usedGuid = exactMatches.first.guid;
      }
    }

    final algorithm = _metadataService.getAlgorithmByGuid(usedGuid);
    if (algorithm == null) {
      return jsonEncode(convertToSnakeCaseKeys({
        'success': false,
        'error': 'Algorithm with GUID "$usedGuid" not found.'
      }));
    }

    AlgorithmMetadata algoToProcess;
    if (expandFeatures) {
      final expandedParams = _metadataService.getExpandedParameters(usedGuid);
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
  Future<String> list_algorithms(Map<String, dynamic> params) async {
    final String? category = params['category'];
    final String? query = params['query']; // Added query parameter

    List<AlgorithmMetadata> algorithms = _metadataService.getAllAlgorithms();

    // Apply filters
    if (category != null && category.isNotEmpty) {
      algorithms = algorithms
          .where((alg) => alg.categories
              .any((cat) => cat.toLowerCase() == category.toLowerCase()))
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
  ///   A JSON string representing a list of RoutingInformation objects.
  ///   Returns an empty list '[]' if the state is not synchronized.
  Future<String> get_current_routing_state(Map<String, dynamic> params) async {
    // Access the injected DistingCubit instance
    final routingInfoList = _distingCubit.buildRoutingInformation();

    // Convert to JSON, then convert keys to snake_case
    final jsonList = routingInfoList.map((info) => info.toJson()).toList();
    return jsonEncode(convertToSnakeCaseKeys(jsonList));
  }
}
