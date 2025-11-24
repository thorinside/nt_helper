import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// Categorizes parameters into logical pages for the Parameter Pages view
///
/// Uses heuristics (parameter names and number ranges) to assign parameters
/// to MIDI, Routing, Modulation, or Global pages.
enum ParamPage {
  midi,
  routing,
  modulation,
  global,
  other,
}

class ParameterPageAssigner {
  /// Assigns a parameter to a specific page based on name patterns and parameter number
  ///
  /// Returns the most appropriate page category for the given parameter.
  static ParamPage assignToPage(ParameterInfo param) {
    final name = param.name.toLowerCase();
    final number = param.parameterNumber;

    // Check name patterns first for better categorization

    // MIDI-related parameters
    if (name.contains('midi') ||
        name.contains('channel') ||
        name.contains('velocity curve') ||
        name.contains('note mode') ||
        name.contains('base note') ||
        name.contains('note off') ||
        name.contains('aftertouch') ||
        name.contains('program change') ||
        name.contains('cc ')) {
      return ParamPage.midi;
    }

    // Routing-related parameters
    if (name.contains('bus') ||
        name.contains('input') && !name.contains('midi') ||
        name.contains('output') && !name.contains('midi') ||
        name.contains('routing') ||
        name.contains('mix level') ||
        name.contains('send') ||
        name.contains('return')) {
      return ParamPage.routing;
    }

    // Modulation/CV-related parameters
    if (name.contains('cv') ||
        name.contains('mod') && !_isStepMod(name) || // Exclude "1:Mod" step params
        name.contains('modulation') ||
        name.contains('lfo') ||
        name.contains('envelope') ||
        name.contains('scale') && !name.contains('quantize') ||
        name.contains('offset') ||
        name.contains('attenuation')) {
      return ParamPage.modulation;
    }

    // Check parameter number ranges (Step Sequencer specific)
    // Parameters 0-159: Per-step parameters (16 steps × 10 params) - SKIP
    // Parameters 160-180: Global playback - covered by custom UI
    // Parameters 180-200: Likely MIDI
    // Parameters 200+: Likely routing/modulation/other

    if (number >= 180 && number < 200) {
      return ParamPage.midi;
    }

    if (number >= 200 && number < 250) {
      return ParamPage.routing;
    }

    if (number >= 250) {
      return ParamPage.modulation;
    }

    // Global parameters (not step-specific, not playback controls)
    // Exclude parameters that start with step numbers or contain colons
    if (!name.contains(':') &&
        !name.startsWith(RegExp(r'\d+')) &&
        number < 180) {
      return ParamPage.global;
    }

    // Default to "other" for uncategorized parameters
    return ParamPage.other;
  }

  /// Helper to detect if this is a step-specific Mod parameter like "1:Mod"
  static bool _isStepMod(String name) {
    return RegExp(r'^\d+:mod$', caseSensitive: false).hasMatch(name);
  }

  /// Returns the set of parameter numbers handled by custom Step Sequencer UI
  ///
  /// These parameters are excluded from Parameter Pages view because they have
  /// dedicated UI components in the Step Sequencer.
  /// Must call _buildCustomUISet first with all parameters.
  static Set<int> getStepSequencerCustomUIParameters() {
    return _customUIParamNumbers ?? {};
  }

  // Cache of parameter numbers handled by custom UI (set by first call to _buildCustomUISet)
  static Set<int>? _customUIParamNumbers;

  /// Builds the set of parameter numbers handled by custom UI
  static Set<int> buildCustomUISet(List<ParameterInfo> allParams) {
    if (_customUIParamNumbers != null) {
      return _customUIParamNumbers!;
    }

    _customUIParamNumbers = allParams
        .where((p) => !shouldShowInParameterPages(p))
        .map((p) => p.parameterNumber)
        .toSet();

    return _customUIParamNumbers!;
  }

  /// Filters parameters that should appear in Parameter Pages
  ///
  /// Excludes parameters already covered by the custom Step Sequencer UI:
  /// - Per-step parameters (Pitch, Velocity, Mod, Division, Pattern, Ties, Mute, Skip, Reset, Repeat)
  /// - Global playback controls (Direction, Start/End, Gate/Trigger Length, Glide, Permutation, Gate Type)
  /// - Randomize parameters (covered by Randomize Settings dialog)
  /// - Current Sequence (covered by sequence selector)
  static bool shouldShowInParameterPages(ParameterInfo param) {
    final name = param.name;
    final nameLower = name.toLowerCase();

    // Exclude per-step parameters (format: "1:Pitch", "2:Velocity", etc.)
    if (RegExp(r'^\d+:').hasMatch(name)) {
      return false; // All step-specific params have custom UI
    }

    // Exclude global playback controls (covered in playback controls widget)
    final playbackControls = [
      'direction',
      'start',
      'end',
      'gate length',
      'trigger length',
      'glide',
      'permutation',
      'permute',
      'gate type',
      'gate/trigger',
      'output type',
    ];
    if (playbackControls.any((control) => nameLower == control)) {
      return false;
    }

    // Exclude randomize parameters (covered in Randomize Settings dialog)
    final randomizeParams = [
      'randomise',
      'randomize',
      'randomise what',
      'randomize what',
      'random what',
      'note distribution',
      'pitch distribution',
      'distribution',
      'min note',
      'minimum note',
      'min pitch',
      'max note',
      'maximum note',
      'max pitch',
      'mean note',
      'average note',
      'mean pitch',
      'note deviation',
      'pitch deviation',
      'deviation',
      'min repeat',
      'minimum repeat',
      'min repeats',
      'max repeat',
      'maximum repeat',
      'max repeats',
      'min ratchet',
      'minimum ratchet',
      'min ratchets',
      'max ratchet',
      'maximum ratchet',
      'max ratchets',
      'note probability',
      'note prob',
      'note %',
      'tie probability',
      'tie prob',
      'tie %',
      'accent probability',
      'accent prob',
      'accent %',
      'repeat probability',
      'repeat prob',
      'repeat %',
      'ratchet probability',
      'ratchet prob',
      'ratchet %',
      'unaccented velocity',
      'base velocity',
      'default velocity',
    ];
    if (randomizeParams.any((rp) => nameLower == rp)) {
      return false;
    }

    // Exclude current sequence (covered by sequence selector)
    if (nameLower == 'sequence' || nameLower == 'current sequence') {
      return false;
    }

    // Show all other parameters
    return true;
  }

  /// Groups parameters by page category
  ///
  /// Returns a map of page categories to lists of parameters.
  /// Only includes parameters that should be shown (filtered by shouldShowInParameterPages).
  static Map<ParamPage, List<ParameterInfo>> groupParametersByPage(
    List<ParameterInfo> allParameters,
  ) {
    final grouped = <ParamPage, List<ParameterInfo>>{
      ParamPage.midi: [],
      ParamPage.routing: [],
      ParamPage.modulation: [],
      ParamPage.global: [],
      ParamPage.other: [],
    };

    for (final param in allParameters) {
      // Skip parameters covered by custom UI
      if (!shouldShowInParameterPages(param)) {
        continue;
      }

      final page = assignToPage(param);
      grouped[page]!.add(param);
    }

    return grouped;
  }

  /// Gets the display name for a page category
  static String getPageName(ParamPage page) {
    switch (page) {
      case ParamPage.midi:
        return 'MIDI';
      case ParamPage.routing:
        return 'Routing';
      case ParamPage.modulation:
        return 'Modulation';
      case ParamPage.global:
        return 'Global';
      case ParamPage.other:
        return 'Other';
    }
  }
}
