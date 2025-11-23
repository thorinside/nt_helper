import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart' show Slot;
import 'package:nt_helper/domain/disting_nt_sysex.dart' show ParameterInfo;

/// Parameter discovery service for Step Sequencer algorithm
///
/// Discovers parameter structure from slot data by analyzing parameter names
/// and building an index map for efficient lookups.
///
/// Supports multiple naming patterns:
/// - "1. Pitch", "2. Pitch" (step-prefixed with period)
/// - "Step 1 Pitch", "Step 2 Pitch"
/// - "1_Pitch", "2_Pitch"
class StepSequencerParams {
  final int numSteps;
  final Map<String, int> _paramIndices = {};

  StepSequencerParams.fromSlot(Slot slot) : numSteps = _discoverNumSteps(slot) {
    _buildParameterMap(slot.parameters);
    _logDiscoveryResults();
  }

  /// Discovers the number of steps by finding the highest step number
  /// in parameter names using regex pattern matching
  static int _discoverNumSteps(Slot slot) {
    // Pattern matches step numbers at start of parameter names
    final stepPattern = RegExp(r'^(\d+)\s*[\._]');
    final stepWordPattern = RegExp(r'^Step\s+(\d+)', caseSensitive: false);

    int maxStep = 0;

    for (final param in slot.parameters) {
      final name = param.name;

      // Try pattern 1: "1. Pitch" or "1_Pitch"
      var match = stepPattern.firstMatch(name);
      if (match != null) {
        final step = int.tryParse(match.group(1)!) ?? 0;
        if (step > maxStep) maxStep = step;
        continue;
      }

      // Try pattern 2: "Step 1 Pitch"
      match = stepWordPattern.firstMatch(name);
      if (match != null) {
        final step = int.tryParse(match.group(1)!) ?? 0;
        if (step > maxStep) maxStep = step;
      }
    }

    final discovered = maxStep > 0 ? maxStep : 16;
    debugPrint('[StepSequencerParams] Discovered $discovered steps');
    return discovered;
  }

  /// Builds parameter index map for O(1) lookups
  void _buildParameterMap(List<ParameterInfo> parameters) {
    for (int i = 0; i < parameters.length; i++) {
      final param = parameters[i];
      final name = param.name as String;
      _paramIndices[name] = i;
    }
  }

  /// Logs discovery results for debugging
  void _logDiscoveryResults() {
    debugPrint('[StepSequencerParams] Total parameters indexed: ${_paramIndices.length}');

    // Count step parameters
    int pitchCount = 0;
    int velocityCount = 0;
    int modCount = 0;
    int divisionCount = 0;
    int patternCount = 0;
    int tiesCount = 0;
    int probabilityCount = 0;

    for (int step = 1; step <= numSteps; step++) {
      if (getPitch(step) != null) pitchCount++;
      if (getVelocity(step) != null) velocityCount++;
      if (getMod(step) != null) modCount++;
      if (getDivision(step) != null) divisionCount++;
      if (getPattern(step) != null) patternCount++;
      if (getTies(step) != null) tiesCount++;
      if (getProbability(step) != null) probabilityCount++;
    }

    debugPrint('[StepSequencerParams] Step parameters found:');
    debugPrint('  - Pitch: $pitchCount/$numSteps');
    debugPrint('  - Velocity: $velocityCount/$numSteps');
    debugPrint('  - Mod: $modCount/$numSteps');
    debugPrint('  - Division: $divisionCount/$numSteps');
    debugPrint('  - Pattern: $patternCount/$numSteps');
    debugPrint('  - Ties: $tiesCount/$numSteps');
    debugPrint('  - Probability: $probabilityCount/$numSteps');

    // Check global parameters
    final globalParams = <String, bool>{
      'Direction': direction != null,
      'Start Step': startStep != null,
      'End Step': endStep != null,
      'Gate Length': gateLength != null,
      'Trigger Length': triggerLength != null,
      'Glide Time': glideTime != null,
      'Current Sequence': currentSequence != null,
    };

    debugPrint('[StepSequencerParams] Global parameters found:');
    globalParams.forEach((name, found) {
      debugPrint('  - $name: ${found ? "✓" : "✗"}');
      if (!found) {
        debugPrint('    [WARNING] Global parameter "$name" not found');
      }
    });
  }

  /// Gets parameter index for a specific step and parameter type
  ///
  /// Tries multiple naming patterns to find the parameter
  int? getStepParam(int step, String paramType) {
    // Try common naming patterns
    final patterns = [
      '$step. $paramType', // "1. Pitch"
      'Step $step $paramType', // "Step 1 Pitch"
      '${step}_$paramType', // "1_Pitch"
      '$step.$paramType', // "1.Pitch" (no space)
    ];

    for (final pattern in patterns) {
      if (_paramIndices.containsKey(pattern)) {
        return _paramIndices[pattern];
      }
    }

    // Parameter not found - log warning
    debugPrint('[StepSequencerParams] WARNING: Parameter not found - step=$step, type=$paramType');
    return null;
  }

  // Convenience getters for step parameters (1-indexed)

  int? getPitch(int step) => getStepParam(step, 'Pitch');
  int? getVelocity(int step) => getStepParam(step, 'Velocity');
  int? getMod(int step) => getStepParam(step, 'Mod');
  int? getDivision(int step) => getStepParam(step, 'Division');
  int? getPattern(int step) => getStepParam(step, 'Pattern');
  int? getTies(int step) => getStepParam(step, 'Ties');
  int? getProbability(int step) => getStepParam(step, 'Probability');

  // Global parameter getters (exact name match)

  int? get direction => _paramIndices['Direction'];
  int? get startStep => _paramIndices['Start Step'];
  int? get endStep => _paramIndices['End Step'];
  int? get gateLength => _paramIndices['Gate Length'];
  int? get triggerLength => _paramIndices['Trigger Length'];
  int? get glideTime => _paramIndices['Glide Time'];
  int? get currentSequence => _paramIndices['Current Sequence'];
}
