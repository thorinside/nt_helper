import 'dart:math' show pow;

/// Constants and utilities for MCP tools
class MCPConstants {
  // Bus mapping constants
  static const String busMapping = '''
Physical name to bus mapping:
- Input N = Bus N
- Output N = Bus N+12  
- Aux N = Bus N+20
- None = Bus 0

Never show bus numbers to users - use physical names only.''';

  // Common tool help references
  static const String getPresetHelp = 'Use `get_current_preset` for parameter numbers';
  static const String getAlgorithmHelp = 'Use `get_algorithm_details` or `list_algorithms` for GUIDs';
  static const String routingHelp = 'Use `get_routing` for current bus assignments';
  
  // Error message templates
  static const String missingParamError = 'Missing required parameter';
  static const String invalidRangeError = 'Value out of range';
  static const String ambiguousError = 'Ambiguous input - be more specific';
  static const String notFoundError = 'Resource not found';
  
  // Validation constants
  static const double fuzzyMatchThreshold = 0.7;
  static const int maxNotesLines = 7;
  static const int maxNotesLineLength = 31;
  static const int maxSlots = 32;
}

/// Result of algorithm resolution
class AlgorithmResolutionResult {
  final String? resolvedGuid;
  final Map<String, dynamic>? error;
  final bool isSuccess;
  
  AlgorithmResolutionResult.success(this.resolvedGuid) : error = null, isSuccess = true;
  AlgorithmResolutionResult.error(this.error) : resolvedGuid = null, isSuccess = false;
}

/// Utility class for resolving algorithms by GUID or name
class AlgorithmResolver {
  /// Resolves algorithm GUID from provided guid or algorithm_name parameters
  /// Returns AlgorithmResolutionResult with either resolved GUID or error
  static AlgorithmResolutionResult resolveAlgorithm({
    required String? guid,
    required String? algorithmName,
    required List<dynamic> allAlgorithms, // List of algorithms with .guid and .name properties
  }) {
    // Validate that at least one parameter is provided
    if (!MCPUtils.validateParam(guid) && !MCPUtils.validateParam(algorithmName)) {
      return AlgorithmResolutionResult.error(
        MCPUtils.buildError('${MCPConstants.missingParamError}: "guid" or "algorithm_name"', 
          helpCommand: MCPConstants.getAlgorithmHelp)
      );
    }

    // If GUID is provided and valid, use it directly
    if (MCPUtils.validateParam(guid)) {
      return AlgorithmResolutionResult.success(guid!);
    }

    // Resolve by algorithm name
    return _resolveByName(algorithmName!, allAlgorithms);
  }

  /// Resolves algorithm by name using exact matching first, then fuzzy matching
  static AlgorithmResolutionResult _resolveByName(String algorithmName, List<dynamic> allAlgorithms) {
    // Try exact match first (case-insensitive)
    final exactMatches = allAlgorithms
        .where((alg) => alg.name.toLowerCase() == algorithmName.toLowerCase())
        .toList();
    
    if (exactMatches.isNotEmpty) {
      if (exactMatches.length == 1) {
        return AlgorithmResolutionResult.success(exactMatches.first.guid);
      } else {
        // Multiple exact matches - ambiguous
        final candidates = exactMatches
            .map((alg) => {'name': alg.name, 'guid': alg.guid})
            .toList();
        return AlgorithmResolutionResult.error(
          MCPUtils.buildError('${MCPConstants.ambiguousError}: "$algorithmName" matches: $candidates', 
            helpCommand: 'Use GUID or be more specific')
        );
      }
    }

    // No exact match, try fuzzy matching
    final fuzzyMatches = allAlgorithms.where((alg) {
      return MCPUtils.similarity(alg.name, algorithmName) >= MCPConstants.fuzzyMatchThreshold;
    }).toList();

    if (fuzzyMatches.isEmpty) {
      return AlgorithmResolutionResult.error(
        MCPUtils.buildError('${MCPConstants.notFoundError}: No algorithm named "$algorithmName"', 
          helpCommand: MCPConstants.getAlgorithmHelp)
      );
    }

    if (fuzzyMatches.length == 1) {
      return AlgorithmResolutionResult.success(fuzzyMatches.first.guid);
    } else {
      // Multiple fuzzy matches - ambiguous
      final candidates = fuzzyMatches
          .map((alg) => {'name': alg.name, 'guid': alg.guid})
          .toList();
      return AlgorithmResolutionResult.error(
        MCPUtils.buildError('${MCPConstants.ambiguousError}: "$algorithmName" matches: $candidates', 
          helpCommand: 'Use GUID or be more specific')
      );
    }
  }
}

/// Utility class for common MCP operations
class MCPUtils {
  /// Builds standardized error response
  static Map<String, dynamic> buildError(String message, {String? helpCommand}) {
    final error = <String, dynamic>{
      'success': false,
      'error': message,
    };
    if (helpCommand != null) {
      error['help_command'] = helpCommand;
    }
    return error;
  }
  
  /// Builds standardized success response
  static Map<String, dynamic> buildSuccess(String message, {Map<String, dynamic>? data}) {
    final response = <String, dynamic>{
      'success': true,
      'message': message,
    };
    if (data != null) {
      response.addAll(data);
    }
    return response;
  }
  
  /// Calculates Levenshtein distance for fuzzy matching
  static int levenshteinDistance(String s, String t) {
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
  
  /// Calculates similarity score (0.0 to 1.0)
  static double similarity(String s, String t) {
    final dist = levenshteinDistance(s, t);
    final maxLen = s.length > t.length ? s.length : t.length;
    if (maxLen == 0) return 1.0;
    return (maxLen - dist) / maxLen;
  }
  
  /// Validates parameter exists and is not empty
  static bool validateParam(dynamic param) {
    return param != null && param.toString().isNotEmpty;
  }

  /// Validates required parameter and returns error if invalid
  static Map<String, dynamic>? validateRequiredParam(dynamic param, String paramName, {String? helpCommand}) {
    if (!validateParam(param)) {
      return buildError('${MCPConstants.missingParamError}: "$paramName"', helpCommand: helpCommand);
    }
    return null;
  }

  /// Validates slot index is within valid range
  static Map<String, dynamic>? validateSlotIndex(int? slotIndex) {
    if (slotIndex == null) {
      return buildError('${MCPConstants.missingParamError}: "slot_index"');
    }
    if (slotIndex < 0 || slotIndex >= MCPConstants.maxSlots) {
      return buildError('${MCPConstants.invalidRangeError}: slot_index must be between 0 and ${MCPConstants.maxSlots - 1}');
    }
    return null;
  }

  /// Validates parameter number is within valid range for given slot
  static Map<String, dynamic>? validateParameterNumber(int? parameterNumber, int maxParams, int slotIndex) {
    if (parameterNumber == null) {
      return buildError('${MCPConstants.missingParamError}: "parameter_number"');
    }
    if (parameterNumber < 0 || parameterNumber >= maxParams) {
      return buildError('${MCPConstants.invalidRangeError}: parameter_number must be between 0 and ${maxParams - 1} for slot $slotIndex');
    }
    return null;
  }

  /// Validates mutually exclusive parameters (only one should be provided)
  static Map<String, dynamic>? validateMutuallyExclusive(Map<String, dynamic> params, List<String> paramNames) {
    final providedParams = paramNames.where((name) => validateParam(params[name])).toList();
    
    if (providedParams.isEmpty) {
      return buildError('${MCPConstants.missingParamError}: One of ${paramNames.join(', ')} is required');
    }
    
    if (providedParams.length > 1) {
      return buildError('${MCPConstants.ambiguousError}: Provide only one of ${paramNames.join(', ')}, not multiple');
    }
    
    return null;
  }

  /// Validates that exactly one of the required parameters is provided
  static Map<String, dynamic>? validateExactlyOne(Map<String, dynamic> params, List<String> paramNames, {String? helpCommand}) {
    final providedParams = paramNames.where((name) => validateParam(params[name])).toList();
    
    if (providedParams.isEmpty) {
      return buildError('${MCPConstants.missingParamError}: One of ${paramNames.join(' or ')} is required', helpCommand: helpCommand);
    }
    
    if (providedParams.length > 1) {
      return buildError('Provide only one of ${paramNames.join(' or ')}, not both', helpCommand: helpCommand);
    }
    
    return null;
  }
  
  /// Scales value for display using powerOfTen
  static num scaleForDisplay(int value, int? powerOfTen) {
    if (powerOfTen != null && powerOfTen > 0) {
      return value / pow(10, powerOfTen);
    }
    return value;
  }
}