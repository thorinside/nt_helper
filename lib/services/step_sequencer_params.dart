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
    int muteCount = 0;
    int skipCount = 0;
    int resetCount = 0;
    int repeatCount = 0;

    for (int step = 1; step <= numSteps; step++) {
      if (getPitch(step) != null) pitchCount++;
      if (getVelocity(step) != null) velocityCount++;
      if (getMod(step) != null) modCount++;
      if (getDivision(step) != null) divisionCount++;
      if (getPattern(step) != null) patternCount++;
      if (getTies(step) != null) tiesCount++;
      if (getMute(step) != null) muteCount++;
      if (getSkip(step) != null) skipCount++;
      if (getReset(step) != null) resetCount++;
      if (getRepeat(step) != null) repeatCount++;
    }

    debugPrint('[StepSequencerParams] Step parameters found:');
    debugPrint('  - Pitch: $pitchCount/$numSteps');
    debugPrint('  - Velocity: $velocityCount/$numSteps');
    debugPrint('  - Mod: $modCount/$numSteps');
    debugPrint('  - Division: $divisionCount/$numSteps');
    debugPrint('  - Pattern: $patternCount/$numSteps');
    debugPrint('  - Ties: $tiesCount/$numSteps');
    debugPrint('  - Mute: $muteCount/$numSteps');
    debugPrint('  - Skip: $skipCount/$numSteps');
    debugPrint('  - Reset: $resetCount/$numSteps');
    debugPrint('  - Repeat: $repeatCount/$numSteps');

    // Check global parameters
    final globalParams = <String, bool>{
      'Direction': direction != null,
      'Start Step': startStep != null,
      'End Step': endStep != null,
      'Gate Length': gateLength != null,
      'Trigger Length': triggerLength != null,
      'Glide Time': glideTime != null,
      'Current Sequence': currentSequence != null,
      'Permutation': permutation != null,
      'Gate Type': gateType != null,
    };

    debugPrint('[StepSequencerParams] Global parameters found:');
    globalParams.forEach((name, found) {
      debugPrint('  - $name: ${found ? "✓" : "✗"}');
      if (!found) {
        debugPrint('    [WARNING] Global parameter "$name" not found');
      }
    });

    // Check randomize parameters
    final randomizeParams = <String, bool>{
      'Randomise': randomise != null,
      'Randomise what': randomiseWhat != null,
      'Note distribution': noteDistribution != null,
      'Min note': minNote != null,
      'Max note': maxNote != null,
      'Mean note': meanNote != null,
      'Note deviation': noteDeviation != null,
      'Min repeat': minRepeat != null,
      'Max repeat': maxRepeat != null,
      'Min ratchet': minRatchet != null,
      'Max ratchet': maxRatchet != null,
      'Note probability': noteProbability != null,
      'Tie probability': tieProbability != null,
      'Accent probability': accentProbability != null,
      'Repeat probability': repeatProbability != null,
      'Ratchet probability': ratchetProbability != null,
      'Unaccented velocity': unaccentedVelocity != null,
    };

    debugPrint('[StepSequencerParams] Randomize parameters found:');
    randomizeParams.forEach((name, found) {
      debugPrint('  - $name: ${found ? "✓" : "✗"}');
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

  // Probability parameters (per-step, 0-100%)
  int? getMute(int step) => getStepParam(step, 'Mute');
  int? getSkip(int step) => getStepParam(step, 'Skip');
  int? getReset(int step) => getStepParam(step, 'Reset');
  int? getRepeat(int step) => getStepParam(step, 'Repeat');

  // Global parameter getters (hardware names)

  int? get direction => _paramIndices['Direction'];
  int? get startStep => _paramIndices['Start'];
  int? get endStep => _paramIndices['End'];
  int? get gateLength => _paramIndices['Gate length'];
  int? get triggerLength => _paramIndices['Trigger length'];
  int? get glideTime => _paramIndices['Glide'];
  int? get currentSequence => _paramIndices['Sequence'];

  // Permutation and Gate Type parameters (global playback controls)
  int? get permutation => _findParameter('Permutation') ?? _findParameter('Permute');
  int? get gateType =>
      _findParameter('Gate type') ?? // Firmware uses lowercase 't'
      _findParameter('Gate Type') ?? // Legacy fallback
      _findParameter('Gate/Trigger') ??
      _findParameter('Output Type');

  // Randomize parameters (17 total)
  // Trigger parameter
  int? get randomise => _findParameter('Randomise') ?? _findParameter('Randomize');

  // What to randomize (0-3: Nothing, Pitches, Rhythm, Both)
  int? get randomiseWhat =>
      _findParameter('Randomise what') ??
      _findParameter('Randomize what') ??
      _findParameter('Random what');

  // Note distribution (0-1: Uniform, Normal)
  int? get noteDistribution =>
      _findParameter('Note distribution') ??
      _findParameter('Pitch distribution') ??
      _findParameter('Distribution');

  // Pitch range parameters for Uniform distribution
  int? get minNote =>
      _findParameter('Min note') ??
      _findParameter('Minimum note') ??
      _findParameter('Min pitch');

  int? get maxNote =>
      _findParameter('Max note') ??
      _findParameter('Maximum note') ??
      _findParameter('Max pitch');

  // Pitch range parameters for Normal distribution
  int? get meanNote =>
      _findParameter('Mean note') ??
      _findParameter('Average note') ??
      _findParameter('Mean pitch');

  int? get noteDeviation =>
      _findParameter('Note deviation') ??
      _findParameter('Pitch deviation') ??
      _findParameter('Deviation');

  // Rhythm repeat range
  int? get minRepeat =>
      _findParameter('Min repeat') ??
      _findParameter('Minimum repeat') ??
      _findParameter('Min repeats');

  int? get maxRepeat =>
      _findParameter('Max repeat') ??
      _findParameter('Maximum repeat') ??
      _findParameter('Max repeats');

  // Rhythm ratchet range
  int? get minRatchet =>
      _findParameter('Min ratchet') ??
      _findParameter('Minimum ratchet') ??
      _findParameter('Min ratchets');

  int? get maxRatchet =>
      _findParameter('Max ratchet') ??
      _findParameter('Maximum ratchet') ??
      _findParameter('Max ratchets');

  // Probability parameters (0-127 firmware, displayed as 0-100%)
  int? get noteProbability =>
      _findParameter('Note probability') ??
      _findParameter('Note prob') ??
      _findParameter('Note %');

  int? get tieProbability =>
      _findParameter('Tie probability') ??
      _findParameter('Tie prob') ??
      _findParameter('Tie %');

  int? get accentProbability =>
      _findParameter('Accent probability') ??
      _findParameter('Accent prob') ??
      _findParameter('Accent %');

  int? get repeatProbability =>
      _findParameter('Repeat probability') ??
      _findParameter('Repeat prob') ??
      _findParameter('Repeat %');

  int? get ratchetProbability =>
      _findParameter('Ratchet probability') ??
      _findParameter('Ratchet prob') ??
      _findParameter('Ratchet %');

  // Velocity parameter
  int? get unaccentedVelocity =>
      _findParameter('Unaccented velocity') ??
      _findParameter('Base velocity') ??
      _findParameter('Default velocity');

  /// Helper to find parameter by name, checking _paramIndices map
  int? _findParameter(String name) {
    return _paramIndices[name];
  }
}
