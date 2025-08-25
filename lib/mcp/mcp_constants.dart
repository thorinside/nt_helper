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
  static const String getPresetHelp =
      'Use `get_current_preset` for parameter numbers';
  static const String getAlgorithmHelp =
      'Use `get_algorithm_details` or `list_algorithms` for GUIDs';
  static const String routingHelp =
      'Use `get_routing` for current bus assignments';

  // MCP Resource Documentation
  static const String busMappingDoc = '''# Bus Mapping Reference

## IO to Bus Conversion Rules

The Disting NT uses a bus-based internal routing system. Physical inputs/outputs map to internal buses as follows:

### Mapping Rules
- **Input N** = Bus N (e.g., Input 1 = Bus 1, Input 2 = Bus 2)
- **Output N** = Bus N+12 (e.g., Output 1 = Bus 13, Output 2 = Bus 14)  
- **Aux N** = Bus N+20 (e.g., Aux 1 = Bus 21, Aux 2 = Bus 22)
- **None** = Bus 0 (used for unused/disconnected signals)

### Bus Range Summary
- **Bus 0**: None/unused
- **Buses 1-12**: Physical inputs (Input 1-12)
- **Buses 13-24**: Physical outputs (Output 1-12)  
- **Buses 21-28**: Aux inputs/outputs (Aux 1-8)

### Important Notes
- Always use physical names (Input N, Output N, Aux N) when communicating with users
- Bus numbers are internal implementation details and should not be exposed to users
- Use the `get_routing` tool to see current bus assignments for loaded algorithms
''';

  static const String mcpUsageGuide = '''# MCP Usage Guide for Disting NT

## Essential Tools for Small LLMs

### Getting Started
1. **`get_current_preset`** - Always start here to understand the current state
2. **`list_algorithms`** - Find available algorithms by category or search
3. **`get_algorithm_details`** - Get detailed info about specific algorithms

### Building Presets
1. **`new_preset`** - Start with a clean slate
2. **`add_algorithm`** - Add algorithms using GUID or name (fuzzy matching ≥70%)
3. **`set_parameter_value`** - Configure algorithm parameters
4. **`save_preset`** - Persist changes to device

### Working with Parameters
- Use `parameter_number` from `get_current_preset` for reliable parameter access
- Alternatively use `parameter_name` if unique within the algorithm
- Values are automatically scaled (use display values, not raw internal values)
- Always check min/max ranges from `get_current_preset`

### Routing and Signal Flow
- **`get_routing`** - See current bus assignments and signal flow
- Algorithms process top-to-bottom (slot 0 → slot N)
- Use `move_algorithm_up`/`move_algorithm_down` to change processing order
- Physical names only: Input N, Output N, Aux N, None

### Batch Operations
- **`set_multiple_parameters`** - Efficient multi-parameter updates
- **`build_preset_from_json`** - Create complete presets from structured data

### Debugging and Diagnostics
- **`mcp_diagnostics`** - Check MCP server health and connection status
- **`get_cpu_usage`** - Monitor device performance
- **`get_module_screenshot`** - Visual confirmation of device state

### Best Practices
- Check device connection status if operations fail
- Use exact algorithm names or GUIDs for reliable results
- Always verify parameter ranges before setting values
- Save presets after making changes to persist them
''';

  static const String algorithmCategories = '''# Algorithm Categories Reference

## Complete List of Available Categories

The Disting NT includes 44 algorithm categories organizing hundreds of algorithms:

### Audio Processing
- **Audio-IO** - Audio input/output utilities
- **Delay** - Echo, tape delay, ping-pong delay, reverse delay
- **Distortion** - Overdrive, fuzz, bit crusher, wave shaper
- **Dynamics** - Compression, gating, limiting, expansion
- **Effect** - General effects processing
- **EQ** - Equalization and tone shaping
- **Filter** - Low-pass, high-pass, band-pass, notch filters
- **Reverb** - Room, hall, plate, spring reverb algorithms

### Synthesis & Generation
- **Chiptune** - Retro 8-bit style sound generation
- **FM** - Frequency modulation synthesis
- **Granular** - Granular synthesis and processing
- **Noise** - White, pink, brown noise generation
- **Oscillator** - Basic waveform oscillators
- **Physical-Modeling** - Plucked string, resonator, modal synthesis
- **Polysynth** - Polyphonic synthesis capabilities
- **Resonator** - Resonant filters and physical modeling
- **Sampler** - Sample playback and manipulation
- **VCO** - Voltage-controlled oscillators
- **Vocoder** - Voice synthesis and vocoding effects
- **Waveshaper** - Waveshaping algorithms
- **Wavetable** - Wavetable synthesis

### Modulation & Control
- **CV** - Control voltage processing and utilities
- **Envelope** - Envelope generators (ADSR, complex envelopes)
- **LFO** - Low-frequency oscillators for modulation
- **Modulation** - Chorus, flanger, phaser, tremolo
- **Random** - Random voltage and stepped random generation
- **VCA** - Voltage-controlled amplifiers

### Sequencing & Timing
- **Clock** - Clock generation, division, multiplication
- **Rhythm** - Rhythm generators and timing utilities
- **Sequencer** - Step sequencers, Euclidean rhythms, Turing machine

### Utility & Processing
- **Convolution** - Convolution-based effects and processing
- **Logic** - Boolean logic, comparators, trigger processing
- **MIDI** - MIDI to CV, CV to MIDI, clock generation
- **Mixer** - Audio/CV mixing, crossfading, VCA functions
- **Pitch** - Pitch shifting, harmonization, tuning
- **Quantizer** - CV and MIDI quantization to scales
- **Routing** - Signal routing, switching, matrix mixing
- **Spectral** - FFT-based spectral processing
- **Tuning** - Tuning references and calibration
- **Utility** - General utility algorithms

### Specialized
- **Looper** - Real-time looping and recording
- **Scripting** - Lua scripting for custom algorithms
- **Source** - Signal sources and generators
- **Visualization** - Oscilloscope, tuner, analysis tools

## Usage in MCP Tools

### Filtering by Category
Use the `list_algorithms` tool with the `category` parameter:
```
list_algorithms(category="Filter")
list_algorithms(category="LFO") 
list_algorithms(category="Reverb")
```

### Category Search
Categories are also searchable with the `query` parameter:
```
list_algorithms(query="delay")      # Finds algorithms in Delay category
list_algorithms(query="modulation") # Finds Modulation category algorithms
```

### Multiple Categories
Many algorithms belong to multiple categories. For example:
- **Quantizer**: ["Pitch", "Utility", "CV"]
- **Looper**: ["Looper", "Sampler", "Effect"]
- **Vocoder**: ["Effect", "Vocoder"]

This categorization helps organize the extensive algorithm library for easier discovery and selection.
''';

  static const String presetFormatDoc = '''# Preset Format Reference

## JSON Structure for `build_preset_from_json`

### Complete Preset Structure
```json
{
  "preset_name": "My Preset",
  "slots": [
    {
      "algorithm": {
        "guid": "algorithm_guid",
        "name": "Algorithm Name"
      },
      "parameters": [
        {
          "parameter_number": 0,
          "value": 1.5
        }
      ]
    }
  ]
}
```

### Required Fields
- **`preset_name`**: String name for the preset
- **`slots`**: Array of slot configurations (max 32 slots)

### Slot Structure
- **`algorithm`**: Algorithm to load in this slot
  - **`guid`**: Exact algorithm GUID (preferred)
  - **`name`**: Algorithm name (fuzzy matching ≥70%)
- **`parameters`**: Array of parameter configurations (optional)

### Parameter Structure  
- **`parameter_number`**: 0-based parameter index (from `get_current_preset`)
- **`value`**: Display value (automatically scaled for device)

### Alternative Parameter Syntax
```json
{
  "parameter_name": "Frequency",
  "value": 440.0
}
```

### Empty Slots
- Use `null` in slots array for empty slots
- Slots are 0-indexed, so slot 4 is `slots[4]` (the 5th slot)

### Example: Audio Processing Chain
```json
{
  "preset_name": "Audio Chain",
  "slots": [
    {
      "algorithm": {"guid": "filt"},
      "parameters": [
        {"parameter_number": 0, "value": 1000},
        {"parameter_number": 1, "value": 0.7}
      ]
    },
    null,
    {
      "algorithm": {"name": "Reverb"},
      "parameters": [
        {"parameter_name": "Size", "value": 0.5}
      ]
    }
  ]
}
```
''';

  static const String routingConcepts = '''# Routing Concepts for Disting NT

## Signal Flow Fundamentals

### Processing Order
- Algorithms execute in slot order: Slot 0 → Slot 1 → ... → Slot N
- **Earlier slots** process signals before later slots
- **Modulation sources** must be in earlier slots than their targets

### Input/Output Behavior
- **Inputs**: Algorithms read from assigned input buses
- **Outputs**: Algorithms write to assigned output buses  
- **Signal Replacement**: When multiple algorithms output to the same bus, later slots replace earlier signals
- **Signal Combination**: Some algorithms can combine/mix signals rather than replace

### Bus Assignment Patterns
- **Audio Processing**: Often Input 1,2 → Output 1,2
- **CV Generation**: Often None → Output N (generating new CV signals)
- **CV Processing**: Often Input N → Output N (processing incoming CV)
- **Mixing**: Multiple inputs → Single output
- **Splitting**: Single input → Multiple outputs

### Routing Visualization
Use `get_routing` to see:
- Which buses each algorithm reads from (inputs)
- Which buses each algorithm writes to (outputs)
- Signal flow through the entire preset

### Common Routing Patterns
1. **Audio Chain**: Input 1,2 → Filter → Reverb → Output 1,2
2. **CV Modulation**: LFO (None → Output 3) → VCA CV Input (Input 3)
3. **Parallel Processing**: Input 1 → [Delay, Chorus] → Mixer → Output 1
4. **Feedback Loops**: Output bus routed back as input to earlier slot

### Troubleshooting Routing
- **No sound**: Check input/output bus assignments
- **Unexpected behavior**: Verify algorithm processing order
- **Missing modulation**: Ensure modulation source is in earlier slot
- **Signal conflicts**: Check for multiple algorithms writing to same bus
''';

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

  AlgorithmResolutionResult.success(this.resolvedGuid)
    : error = null,
      isSuccess = true;
  AlgorithmResolutionResult.error(this.error)
    : resolvedGuid = null,
      isSuccess = false;
}

/// Utility class for resolving algorithms by GUID or name
class AlgorithmResolver {
  /// Resolves algorithm GUID from provided guid or algorithm_name parameters
  /// Returns AlgorithmResolutionResult with either resolved GUID or error
  static AlgorithmResolutionResult resolveAlgorithm({
    required String? guid,
    required String? algorithmName,
    required List<dynamic>
    allAlgorithms, // List of algorithms with .guid and .name properties
  }) {
    // Validate that at least one parameter is provided
    if (!MCPUtils.validateParam(guid) &&
        !MCPUtils.validateParam(algorithmName)) {
      return AlgorithmResolutionResult.error(
        MCPUtils.buildError(
          '${MCPConstants.missingParamError}: "guid" or "algorithm_name"',
          helpCommand: MCPConstants.getAlgorithmHelp,
        ),
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
  static AlgorithmResolutionResult _resolveByName(
    String algorithmName,
    List<dynamic> allAlgorithms,
  ) {
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
          MCPUtils.buildError(
            '${MCPConstants.ambiguousError}: "$algorithmName" matches: $candidates',
            helpCommand: 'Use GUID or be more specific',
          ),
        );
      }
    }

    // No exact match, try fuzzy matching
    final fuzzyMatches = allAlgorithms.where((alg) {
      return MCPUtils.similarity(alg.name, algorithmName) >=
          MCPConstants.fuzzyMatchThreshold;
    }).toList();

    if (fuzzyMatches.isEmpty) {
      return AlgorithmResolutionResult.error(
        MCPUtils.buildError(
          '${MCPConstants.notFoundError}: No algorithm named "$algorithmName"',
          helpCommand: MCPConstants.getAlgorithmHelp,
        ),
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
        MCPUtils.buildError(
          '${MCPConstants.ambiguousError}: "$algorithmName" matches: $candidates',
          helpCommand: 'Use GUID or be more specific',
        ),
      );
    }
  }
}

/// Utility class for common MCP operations
class MCPUtils {
  /// Builds standardized error response
  static Map<String, dynamic> buildError(
    String message, {
    String? helpCommand,
  }) {
    final error = <String, dynamic>{'success': false, 'error': message};
    if (helpCommand != null) {
      error['help_command'] = helpCommand;
    }
    return error;
  }

  /// Builds standardized success response
  static Map<String, dynamic> buildSuccess(
    String message, {
    Map<String, dynamic>? data,
  }) {
    final result = <String, dynamic>{'success': true, 'message': message};
    if (data != null) {
      result.addAll(data);
    }
    return result;
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
  static Map<String, dynamic>? validateRequiredParam(
    dynamic param,
    String paramName, {
    String? helpCommand,
  }) {
    if (!validateParam(param)) {
      return buildError(
        '${MCPConstants.missingParamError}: "$paramName"',
        helpCommand: helpCommand,
      );
    }
    return null;
  }

  /// Validates slot index is within valid range
  static Map<String, dynamic>? validateSlotIndex(int? slotIndex) {
    if (slotIndex == null) {
      return buildError('${MCPConstants.missingParamError}: "slot_index"');
    }
    if (slotIndex < 0 || slotIndex >= MCPConstants.maxSlots) {
      return buildError(
        '${MCPConstants.invalidRangeError}: slot_index must be between 0 and ${MCPConstants.maxSlots - 1}',
      );
    }
    return null;
  }

  /// Validates parameter number is within valid range for given slot
  static Map<String, dynamic>? validateParameterNumber(
    int? parameterNumber,
    int maxParams,
    int slotIndex,
  ) {
    if (parameterNumber == null) {
      return buildError(
        '${MCPConstants.missingParamError}: "parameter_number"',
      );
    }
    if (parameterNumber < 0 || parameterNumber >= maxParams) {
      return buildError(
        '${MCPConstants.invalidRangeError}: parameter_number must be between 0 and ${maxParams - 1} for slot $slotIndex',
      );
    }
    return null;
  }

  /// Validates mutually exclusive parameters (only one should be provided)
  static Map<String, dynamic>? validateMutuallyExclusive(
    Map<String, dynamic> params,
    List<String> paramNames,
  ) {
    final providedParams = paramNames
        .where((name) => validateParam(params[name]))
        .toList();

    if (providedParams.isEmpty) {
      return buildError(
        '${MCPConstants.missingParamError}: One of ${paramNames.join(', ')} is required',
      );
    }

    if (providedParams.length > 1) {
      return buildError(
        '${MCPConstants.ambiguousError}: Provide only one of ${paramNames.join(', ')}, not multiple',
      );
    }

    return null;
  }

  /// Validates that exactly one of the required parameters is provided
  static Map<String, dynamic>? validateExactlyOne(
    Map<String, dynamic> params,
    List<String> paramNames, {
    String? helpCommand,
  }) {
    final providedParams = paramNames
        .where((name) => validateParam(params[name]))
        .toList();

    if (providedParams.isEmpty) {
      return buildError(
        '${MCPConstants.missingParamError}: One of ${paramNames.join(' or ')} is required',
        helpCommand: helpCommand,
      );
    }

    if (providedParams.length > 1) {
      return buildError(
        'Provide only one of ${paramNames.join(' or ')}, not both',
        helpCommand: helpCommand,
      );
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
