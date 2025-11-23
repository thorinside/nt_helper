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
  /// in parameter names using hardware format "N:Param"
  static int _discoverNumSteps(Slot slot) {
    // Pattern matches: "1:Pitch", "2:Velocity", etc.
    final stepPattern = RegExp(r'^(\d+):');

    int maxStep = 0;

    for (final param in slot.parameters) {
      final name = param.name;
      final match = stepPattern.firstMatch(name);

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
      final name = param.name;
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

    for (int step = 1; step <= numSteps; step++) {
      if (getPitch(step) != null) pitchCount++;
      if (getVelocity(step) != null) velocityCount++;
      if (getMod(step) != null) modCount++;
      if (getDivision(step) != null) divisionCount++;
      if (getPattern(step) != null) patternCount++;
      if (getTies(step) != null) tiesCount++;
    }

    debugPrint('[StepSequencerParams] Step parameters found:');
    debugPrint('  - Pitch: $pitchCount/$numSteps');
    debugPrint('  - Velocity: $velocityCount/$numSteps');
    debugPrint('  - Mod: $modCount/$numSteps');
    debugPrint('  - Division: $divisionCount/$numSteps');
    debugPrint('  - Pattern: $patternCount/$numSteps');
    debugPrint('  - Ties: $tiesCount/$numSteps');

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
  /// Uses hardware naming pattern: "1:Pitch", "2:Velocity", etc.
  int? getStepParam(int step, String paramType) {
    final paramName = '$step:$paramType'; // Hardware format: "1:Pitch"

    if (_paramIndices.containsKey(paramName)) {
      return _paramIndices[paramName];
    }

    // Parameter not found - log warning
    debugPrint('[StepSequencerParams] WARNING: Parameter not found - $paramName');
    return null;
  }

  // Convenience getters for step parameters (1-indexed)

  int? getPitch(int step) => getStepParam(step, 'Pitch');
  int? getVelocity(int step) => getStepParam(step, 'Velocity');
  int? getMod(int step) => getStepParam(step, 'Mod');
  int? getDivision(int step) => getStepParam(step, 'Division');
  int? getPattern(int step) => getStepParam(step, 'Pattern');
  int? getTies(int step) => getStepParam(step, 'Ties');
  // Note: Probability doesn't exist as step parameter in hardware

  // Global parameter getters (hardware names)

  int? get direction => _paramIndices['Direction'];
  int? get startStep => _paramIndices['Start'];
  int? get endStep => _paramIndices['End'];
  int? get gateLength => _paramIndices['Gate length'];
  int? get triggerLength => _paramIndices['Trigger length'];
  int? get glideTime => _paramIndices['Glide'];
  int? get currentSequence => _paramIndices['Sequence'];
}
