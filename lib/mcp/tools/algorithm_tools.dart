import 'dart:convert';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show ParameterInfo, ParameterValue, Mapping;
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
  ///   A JSON string representing the AlgorithmMetaor an error JSON if not found or ambiguous.
  Future<String> getAlgorithmDetails(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    final String? algorithmName = params['algorithm_name'];
    final bool expandFeatures = params['expand_features'] ?? false;

    // Use shared algorithm resolver
    List<AlgorithmMetadata> algorithms;
    try {
      algorithms = _metadataService.getAllAlgorithms();
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'AlgorithmMetadataService error: ${e.toString()}',
        }),
      );
    }
    final resolution = AlgorithmResolver.resolveAlgorithm(
      guid: algorithmGuid,
      algorithmName: algorithmName,
      allAlgorithms: algorithms,
    );

    if (!resolution.isSuccess) {
      return jsonEncode(convertToSnakeCaseKeys(resolution.error!));
    }

    final algorithm = _metadataService.getAlgorithmByGuid(
      resolution.resolvedGuid!,
    );
    if (algorithm == null) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            '${MCPConstants.notFoundError}: Algorithm with GUID "${resolution.resolvedGuid!}"',
            helpCommand: MCPConstants.getAlgorithmHelp,
          ),
        ),
      );
    }

    AlgorithmMetadata algoToProcess;
    if (expandFeatures) {
      final expandedParams = _metadataService.getExpandedParameters(
        resolution.resolvedGuid!,
      );
      algoToProcess = algorithm.copyWith(parameters: expandedParams);
    } else {
      algoToProcess = algorithm;
    }

    Map<String, dynamic> algoJson;
    try {
      algoJson = algoToProcess.toJson();
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to serialize algorithm: ${e.toString()}',
        }),
      );
    }

    // Remove parameterNumber from params to clean up response
    try {
      if (algoJson['parameters'] is List) {
        List<dynamic> paramsList = algoJson['parameters'] as List<dynamic>;
        for (var param in paramsList) {
          if (param is Map<String, dynamic>) {
            param.remove('parameterNumber');
          }
        }
      }
    } catch (e) {
      // If parameter processing fails, return the algorithm without modification
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to process parameters: ${e.toString()}',
        }),
      );
    }

    try {
      return jsonEncode(convertToSnakeCaseKeys(algoJson));
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to encode response: ${e.toString()}',
        }),
      );
    }
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

    List<AlgorithmMetadata> algorithms;
    try {
      algorithms = _metadataService.getAllAlgorithms();
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'AlgorithmMetadataService error: ${e.toString()}',
        }),
      );
    }

    // Apply filters
    if (category != null && category.isNotEmpty) {
      algorithms = algorithms
          .where(
            (alg) => alg.categories.any(
              (cat) =>
                  cat.toLowerCase() == category.toLowerCase() ||
                  MCPUtils.similarity(cat, category) >= 0.7,
            ),
          )
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      algorithms = algorithms.where((alg) {
        return alg.name.toLowerCase().contains(lowercaseQuery) ||
            alg.description.toLowerCase().contains(lowercaseQuery) ||
            alg.categories.any(
              (cat) => cat.toLowerCase().contains(lowercaseQuery),
            ) ||
            alg.features.any(
              (feature) => feature.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
    }

    List<Map<String, dynamic>> resultList = [];
    for (var alg in algorithms) {
      String firstSentenceDescription = '';
      if (alg.description.isNotEmpty) {
        int firstPeriod = alg.description.indexOf('.');
        if (firstPeriod != -1) {
          firstSentenceDescription = alg.description.substring(
            0,
            firstPeriod + 1,
          );
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
      routing: routingInfoList,
      showSignals: true,
      showMappings: false,
    );

    return jsonEncode(
      convertToSnakeCaseKeys(analyzer.generateSlotBusUsageJson()),
    );
  }

  /// MCP Tool: Search for algorithms by name/category with fuzzy matching.
  /// Parameters:
  ///   - type (string, required): Type of search. Currently only "algorithm" is supported.
  ///   - query (string, required): Search query (algorithm name, partial name, or category).
  /// Returns:
  ///   A JSON string representing an array of matching algorithms sorted by relevance.
  ///   Each result contains: guid, name, category, description, general_parameters
  ///   Maximum 10 results returned. Empty array with helpful message if no matches found.
  Future<String> searchAlgorithms(Map<String, dynamic> params) async {
    final String? type = params['type'];
    final String? query = params['query'];

    // Validate required parameters
    if (type == null || type.isEmpty) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            '${MCPConstants.missingParamError}: "type" is required and must be "algorithm"',
          ),
        ),
      );
    }

    if (type != 'algorithm') {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            'Invalid type: "$type". Currently only "algorithm" is supported.',
          ),
        ),
      );
    }

    if (query == null || query.isEmpty) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            '${MCPConstants.missingParamError}: "query" is required',
          ),
        ),
      );
    }

    // Get all algorithms
    List<AlgorithmMetadata> algorithms;
    try {
      algorithms = _metadataService.getAllAlgorithms();
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'AlgorithmMetadataService error: ${e.toString()}',
        }),
      );
    }

    // Score and filter algorithms
    final List<_SearchResult> results = [];
    final lowerQuery = query.toLowerCase();

    for (final algorithm in algorithms) {
      double score = _calculateSearchScore(algorithm, lowerQuery);

      // Only include results that meet minimum threshold
      if (score >= 50) {
        results.add(
          _SearchResult(
            algorithm: algorithm,
            score: score,
          ),
        );
      }
    }

    // Sort by relevance score (descending)
    results.sort((a, b) => b.score.compareTo(a.score));

    // Limit to top 10 results
    final limitedResults = results.take(10).toList();

    // Build response
    if (limitedResults.isEmpty) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'results': [],
          'message': 'No algorithms found matching "$query". Try searching by algorithm name or category.',
          'suggestions': 'Use `list_algorithms` to browse by category or `get_algorithm_details` for specific algorithms.',
        }),
      );
    }

    final List<Map<String, dynamic>> resultList = [];
    for (final result in limitedResults) {
      final algorithm = result.algorithm;
      final generalParams = _generateGeneralParameterDescription(algorithm);

      resultList.add({
        'guid': algorithm.guid,
        'name': algorithm.name,
        'category': algorithm.categories.isNotEmpty ? algorithm.categories[0] : 'Unknown',
        'categories': algorithm.categories,
        'description': algorithm.description,
        'general_parameters': generalParams,
      });
    }

    return jsonEncode(
      convertToSnakeCaseKeys({
        'results': resultList,
        'count': resultList.length,
        'message': 'Found ${resultList.length} matching algorithm(s)',
      }),
    );
  }

  /// Calculate relevance score for algorithm based on query.
  /// Returns score between 0-100.
  /// Exact name match = 100
  /// High similarity (>=70%) = 70-99
  /// Category match = 50-69
  double _calculateSearchScore(AlgorithmMetadata algorithm, String lowerQuery) {
    final lowerName = algorithm.name.toLowerCase();

    // Exact GUID match = 100
    if (algorithm.guid.toLowerCase() == lowerQuery) {
      return 100.0;
    }

    // Exact name match = 100
    if (lowerName == lowerQuery) {
      return 100.0;
    }

    // Partial exact match in name = 85
    if (lowerName.contains(lowerQuery)) {
      return 85.0;
    }

    // Fuzzy name matching >= 70% similarity = 70-99
    final similarity = MCPUtils.similarity(algorithm.name, lowerQuery);
    if (similarity >= 0.70) {
      // Map similarity range [0.70, 1.0] to score range [70, 99]
      final score = 70.0 + (similarity - 0.70) * (99.0 - 70.0) / (1.0 - 0.70);
      return score;
    }

    // Category match = 50-69
    for (final category in algorithm.categories) {
      final catSimilarity = MCPUtils.similarity(category, lowerQuery);
      if (catSimilarity >= 0.70 || category.toLowerCase().contains(lowerQuery)) {
        // Category match gets lower score than name match
        return 60.0 + (catSimilarity * 9.0);
      }
    }

    // No match
    return 0.0;
  }

  /// Generate general parameter description without specific indices.
  /// Describes what kinds of parameters the algorithm has.
  String _generateGeneralParameterDescription(AlgorithmMetadata algorithm) {
    if (algorithm.parameters.isEmpty) {
      return 'No parameters available';
    }

    // Categorize parameters by their names to provide meaningful descriptions
    final paramCategories = <String>[];
    final paramNames = <String>{};

    for (final param in algorithm.parameters) {
      paramNames.add(param.name.toLowerCase());
    }

    // Check for common parameter patterns
    if (paramNames.any((name) => name.contains('freq') || name.contains('pitch'))) {
      paramCategories.add('frequency/pitch controls');
    }
    if (paramNames.any((name) =>
        name.contains('resonance') ||
        name.contains('q') ||
        name.contains('filter'))) {
      paramCategories.add('resonance/filter emphasis controls');
    }
    if (paramNames.any((name) =>
        name.contains('attack') ||
        name.contains('decay') ||
        name.contains('sustain') ||
        name.contains('release'))) {
      paramCategories.add('envelope controls');
    }
    if (paramNames.any((name) =>
        name.contains('amount') ||
        name.contains('depth') ||
        name.contains('level') ||
        name.contains('volume') ||
        name.contains('gain'))) {
      paramCategories.add('level/amplitude controls');
    }
    if (paramNames.any((name) =>
        name.contains('rate') ||
        name.contains('speed') ||
        name.contains('tempo'))) {
      paramCategories.add('rate/speed controls');
    }
    if (paramNames.any((name) =>
        name.contains('mix') ||
        name.contains('balance') ||
        name.contains('blend'))) {
      paramCategories.add('mix/blend controls');
    }
    if (paramNames.any((name) =>
        name.contains('mode') ||
        name.contains('type') ||
        name.contains('shape') ||
        name.contains('form'))) {
      paramCategories.add('mode/type selectors');
    }
    if (paramNames.any((name) => name.contains('time') || name.contains('duration'))) {
      paramCategories.add('time/duration controls');
    }

    if (paramCategories.isEmpty) {
      return 'Algorithm has ${algorithm.parameters.length} parameters';
    }

    return 'Parameters: ${paramCategories.join(', ')}';
  }

  /// MCP Tool: Show tool for flexible state inspection with multiple target types.
  /// Parameters:
  ///   - target (string, required): One of "preset", "slot", "parameter", "screen", "routing"
  ///   - identifier (string or int, optional): Required for slot and parameter targets
  /// Returns:
  ///   Target-specific JSON response with state information
  Future<String> show(Map<String, dynamic> params) async {
    try {
      final String? target = params['target'];
      final dynamic identifier = params['identifier'];

      // Validate target parameter
      if (target == null || target.isEmpty) {
        return jsonEncode(
          convertToSnakeCaseKeys({
            'success': false,
            'error': 'Missing required parameter: target',
            'valid_targets': ['preset', 'slot', 'parameter', 'screen', 'routing'],
          }),
        );
      }

      switch (target.toLowerCase()) {
        case 'preset':
          return _showPreset();
        case 'slot':
          return _showSlot(identifier);
        case 'parameter':
          return _showParameter(identifier);
        case 'screen':
          return _showScreen();
        case 'routing':
          return _showRouting();
        default:
          return jsonEncode(
            convertToSnakeCaseKeys({
              'success': false,
              'error': 'Invalid target: $target',
              'valid_targets': ['preset', 'slot', 'parameter', 'screen', 'routing'],
            }),
          );
      }
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Tool execution failed: ${e.toString()}',
        }),
      );
    }
  }

  /// Show complete preset with all slots, parameters, and enabled mappings.
  Future<String> _showPreset() async {
    final state = _distingCubit.state;
    if (state is! DistingStateSynchronized) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Device not synchronized',
        }),
      );
    }

    final slots = state.slots;
    final slotsJson = <Map<String, dynamic>>[];

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final slotJson = _buildSlotJson(i, slot);
      slotsJson.add(slotJson);
    }

    return jsonEncode(
      convertToSnakeCaseKeys({
        'name': state.presetName,
        'slots': slotsJson,
      }),
    );
  }

  /// Show single slot with all parameters and enabled mappings.
  Future<String> _showSlot(dynamic identifier) async {
    if (identifier == null) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Missing required parameter: identifier (slot index)',
        }),
      );
    }

    int slotIndex = -1;
    try {
      slotIndex = (identifier is int) ? identifier : int.parse(identifier.toString());
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid identifier format. Expected integer slot index.',
        }),
      );
    }

    if (slotIndex < 0 || slotIndex >= 32) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid slot index: $slotIndex. Must be 0-31.',
        }),
      );
    }

    final state = _distingCubit.state;
    if (state is! DistingStateSynchronized) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Device not synchronized',
        }),
      );
    }

    if (slotIndex >= state.slots.length) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Slot index $slotIndex out of range',
        }),
      );
    }

    final slot = state.slots[slotIndex];
    return jsonEncode(convertToSnakeCaseKeys(_buildSlotJson(slotIndex, slot)));
  }

  /// Show single parameter with value and optional mapping.
  Future<String> _showParameter(dynamic identifier) async {
    if (identifier == null) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Missing required parameter: identifier (format: slot_index:parameter_number)',
        }),
      );
    }

    // Parse identifier in format "slot_index:parameter_number"
    final parts = identifier.toString().split(':');
    if (parts.length != 2) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid identifier format. Expected "slot_index:parameter_number" (e.g., "0:5")',
        }),
      );
    }

    int slotIndex = -1;
    int parameterNumber = -1;
    try {
      slotIndex = int.parse(parts[0]);
      parameterNumber = int.parse(parts[1]);
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid identifier format. Both slot_index and parameter_number must be integers.',
        }),
      );
    }

    if (slotIndex < 0 || slotIndex >= 32) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid slot index: $slotIndex. Must be 0-31.',
        }),
      );
    }

    final state = _distingCubit.state;
    if (state is! DistingStateSynchronized) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Device not synchronized',
        }),
      );
    }

    if (slotIndex >= state.slots.length) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Slot index $slotIndex out of range',
        }),
      );
    }

    final slot = state.slots[slotIndex];
    if (parameterNumber < 0 || parameterNumber >= slot.parameters.length) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Invalid parameter number: $parameterNumber. Slot has ${slot.parameters.length} parameters (0-${slot.parameters.length - 1}).',
        }),
      );
    }

    final parameter = slot.parameters[parameterNumber];
    final value = slot.values[parameterNumber];
    final mapping = slot.mappings[parameterNumber];

    final paramJson = _buildParameterJson(
      parameterNumber,
      parameter,
      value,
      mapping,
    );

    return jsonEncode(convertToSnakeCaseKeys(paramJson));
  }

  /// Show current device screen as base64 JPEG image.
  Future<String> _showScreen() async {
    final state = _distingCubit.state;
    if (state is! DistingStateSynchronized) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Device not synchronized',
        }),
      );
    }

    try {
      final manager = state.disting;
      final screenshotData = await manager.encodeTakeScreenshot();

      if (screenshotData == null) {
        return jsonEncode(
          convertToSnakeCaseKeys({
            'success': false,
            'error': 'Screenshot not supported in current mode',
          }),
        );
      }

      // Convert to base64
      final base64Data = _base64Encode(screenshotData);

      return jsonEncode(
        convertToSnakeCaseKeys({
          'type': 'image/jpeg',
          'data': base64Data,
          'size': screenshotData.length,
        }),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to capture screenshot: ${e.toString()}',
        }),
      );
    }
  }

  /// Show current routing state using physical names.
  Future<String> _showRouting() async {
    try {
      // Reuse existing routing implementation
      return await getCurrentRoutingState({});
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to get routing state: ${e.toString()}',
        }),
      );
    }
  }

  /// Build JSON representation of a slot with all parameters and enabled mappings.
  Map<String, dynamic> _buildSlotJson(int slotIndex, Slot slot) {
    final parametersJson = <Map<String, dynamic>>[];
    for (int i = 0; i < slot.parameters.length; i++) {
      final param = slot.parameters[i];
      final value = slot.values[i];
      final mapping = slot.mappings[i];
      parametersJson.add(_buildParameterJson(i, param, value, mapping));
    }

    return {
      'slot_index': slotIndex,
      'algorithm': {
        'guid': slot.algorithm.guid,
        'name': slot.algorithm.name,
      },
      'parameters': parametersJson,
    };
  }

  /// Build JSON representation of a parameter with optional mapping.
  Map<String, dynamic> _buildParameterJson(
    int parameterNumber,
    ParameterInfo parameter,
    ParameterValue value,
    Mapping mapping,
  ) {
    final paramJson = {
      'parameter_number': parameterNumber,
      'parameter_name': parameter.name,
      'value': value.value,
      'min': parameter.min,
      'max': parameter.max,
      'unit': parameter.unit,
    };

    // Include mapping only if at least one type is enabled
    final mappingJson = _buildMappingJson(mapping);
    if (mappingJson.isNotEmpty) {
      paramJson['mapping'] = mappingJson;
    }

    return paramJson;
  }

  /// Build mapping JSON with only enabled mapping types included.
  /// Returns empty map if all types disabled.
  Map<String, dynamic> _buildMappingJson(Mapping mapping) {
    final data = mapping.packedMappingData;
    final result = <String, dynamic>{};

    // Check CV mapping enabled: cv_input > 0 OR source > 0
    final cvEnabled = data.cvInput > 0 || data.source > 0;
    if (cvEnabled) {
      result['cv'] = {
        'source': data.source,
        'cv_input': data.cvInput,
        'is_unipolar': data.isUnipolar,
        'is_gate': data.isGate,
        'volts': data.volts,
        'delta': data.delta,
      };
    }

    // Check MIDI mapping enabled
    if (data.isMidiEnabled) {
      result['midi'] = {
        'is_midi_enabled': data.isMidiEnabled,
        'midi_channel': data.midiChannel,
        'midi_type': data.midiMappingType.name,
        'midi_cc': data.midiCC,
        'is_midi_symmetric': data.isMidiSymmetric,
        'is_midi_relative': data.isMidiRelative,
        'midi_min': data.midiMin,
        'midi_max': data.midiMax,
      };
    }

    // Check i2c mapping enabled
    if (data.isI2cEnabled) {
      result['i2c'] = {
        'is_i2c_enabled': data.isI2cEnabled,
        'i2c_cc': data.i2cCC,
        'is_i2c_symmetric': data.isI2cSymmetric,
        'i2c_min': data.i2cMin,
        'i2c_max': data.i2cMax,
      };
    }

    // Check performance page assigned: perfPageIndex > 0 (1-15)
    if (data.perfPageIndex > 0) {
      result['performance_page'] = data.perfPageIndex;
    }

    return result;
  }

  /// Helper to encode bytes to base64 string.
  String _base64Encode(List<int> bytes) {
    return base64.encode(bytes);
  }
}

/// Internal class to hold search results with relevance scores
class _SearchResult {
  final AlgorithmMetadata algorithm;
  final double score;

  _SearchResult({
    required this.algorithm,
    required this.score,
  });
}
