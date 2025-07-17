import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart' show Slot;
import 'package:nt_helper/domain/disting_nt_sysex.dart' show ParameterInfo;
import 'package:nt_helper/ui/widgets/file_parameter_editor.dart';

/// Modes for different types of file/string parameter selection
enum FileSelectionMode {
  /// Select folder only (e.g., sample folder selection)
  folderOnly,
  
  /// Select file only (e.g., sample file within folder)
  fileOnly,
  
  /// Direct file selection (e.g., script files)
  directFile,
  
  /// Folder then file hierarchy (e.g., samples workflow)
  folderThenFile,
  
  /// Free text input (e.g., mixer channel names)
  textInput,
}

/// Rule definition for parameter editor selection
class ParameterEditorRule {
  /// Algorithm GUID to match (null = any algorithm)
  final String? algorithmGuid;
  
  /// Parameter name pattern to match (supports regex)
  final String? parameterNamePattern;
  
  /// Unit type to match (null = any unit)
  final int? unit;
  
  /// Base directory for file selection
  final String? baseDirectory;
  
  /// File selection mode
  final FileSelectionMode mode;
  
  /// Directories to exclude from selection
  final List<String> excludeDirs;
  
  /// File extensions to filter (null = all files)
  final List<String>? allowedExtensions;
  
  /// Description for debugging/logging
  final String description;
  
  /// Whether to search subdirectories recursively
  final bool recursive;
  
  /// Default folder to select (relative to baseDirectory)
  final String? defaultFolder;

  const ParameterEditorRule({
    this.algorithmGuid,
    this.parameterNamePattern,
    this.unit,
    this.baseDirectory,
    required this.mode,
    this.excludeDirs = const [],
    this.allowedExtensions,
    required this.description,
    this.recursive = false,
    this.defaultFolder,
  });

  /// Check if this rule matches the given parameter
  bool matches({
    required String algorithmGuid,
    required String parameterName,
    required int unit,
  }) {
    // Check algorithm GUID
    if (this.algorithmGuid != null && this.algorithmGuid != algorithmGuid) {
      return false;
    }
    
    // Check unit
    if (this.unit != null && this.unit != unit) {
      return false;
    }
    
    // Check parameter name pattern
    if (parameterNamePattern != null) {
      final regex = RegExp(parameterNamePattern!);
      if (!regex.hasMatch(parameterName)) {
        return false;
      }
    }
    
    return true;
  }
}

/// Registry for finding appropriate parameter editors based on algorithm and parameter context
class ParameterEditorRegistry {
  static final List<ParameterEditorRule> _rules = [
    // Sample player - Folder selection
    ParameterEditorRule(
      algorithmGuid: 'samp',
      parameterNamePattern: r'.*:Folder',
      unit: 14,
      baseDirectory: '/samples',
      mode: FileSelectionMode.folderOnly,
      description: 'Sample player folder selection',
    ),
    
    // Sample player - Sample file selection
    ParameterEditorRule(
      algorithmGuid: 'samp',
      parameterNamePattern: r'.*:Sample',
      unit: 14,
      baseDirectory: '/samples', // Will be dynamically resolved with folder
      mode: FileSelectionMode.fileOnly,
      allowedExtensions: ['.wav', '.aif', '.aiff'],
      description: 'Sample player file selection',
    ),
    
    // Generic sample players - Folder selection
    ParameterEditorRule(
      parameterNamePattern: r'Folder',
      unit: 14,
      baseDirectory: '/samples',
      mode: FileSelectionMode.folderOnly,
      description: 'Generic sample player folder selection',
    ),
    
    // Generic sample players - Sample file selection
    ParameterEditorRule(
      parameterNamePattern: r'Sample',
      unit: 14,
      baseDirectory: '/samples', // Will be dynamically resolved with folder
      mode: FileSelectionMode.fileOnly,
      allowedExtensions: ['.wav', '.aif', '.aiff'],
      description: 'Generic sample player file selection',
    ),
    
    // Convolver - Folder selection
    ParameterEditorRule(
      algorithmGuid: 'conv',
      parameterNamePattern: r'Folder',
      unit: 13,
      baseDirectory: '/samples',
      mode: FileSelectionMode.folderOnly,
      defaultFolder: 'impulses',
      description: 'Convolver impulse folder selection',
    ),
    
    // Convolver - Sample file selection
    ParameterEditorRule(
      algorithmGuid: 'conv',
      parameterNamePattern: r'Sample',
      unit: 13,
      baseDirectory: '/samples', // Will be dynamically resolved with folder
      mode: FileSelectionMode.fileOnly,
      allowedExtensions: ['.wav', '.aif', '.aiff'],
      description: 'Convolver impulse file selection',
    ),
    
    // Lua Script - Program selection
    ParameterEditorRule(
      algorithmGuid: 'lua ',
      parameterNamePattern: r'Program',
      unit: 13,
      baseDirectory: '/programs/lua',
      mode: FileSelectionMode.directFile,
      excludeDirs: ['libs'],
      allowedExtensions: ['.lua'],
      description: 'Lua script program selection',
    ),
    
    // Three Pot - Program selection
    ParameterEditorRule(
      algorithmGuid: 'spin',
      parameterNamePattern: r'Program',
      unit: 13,
      baseDirectory: '/programs/three_pot',
      mode: FileSelectionMode.directFile,
      allowedExtensions: ['.3pot'],
      recursive: true,
      description: 'Three Pot program selection',
    ),
    
    // VCO Wavetable - Wavetable folder selection (unit 13)
    ParameterEditorRule(
      algorithmGuid: 'vcot',
      parameterNamePattern: r'.*[Ww]avetable.*',
      unit: 13,
      baseDirectory: '/wavetables',
      mode: FileSelectionMode.folderOnly,
      description: 'VCO Wavetable folder selection (unit 13)',
    ),
    
    // Generic wavetable oscillator - Wavetable folder selection (unit 13)
    ParameterEditorRule(
      parameterNamePattern: r'.*[Ww]avetable.*',
      unit: 13,
      baseDirectory: '/wavetables',
      mode: FileSelectionMode.folderOnly,
      description: 'Wavetable folder selection (unit 13)',
    ),
    
    // Wavetable oscillator - Wavetable folder selection (unit 14)
    ParameterEditorRule(
      parameterNamePattern: r'.*[Ww]avetable.*',
      unit: 14,
      baseDirectory: '/wavetables',
      mode: FileSelectionMode.folderOnly,
      description: 'Wavetable folder selection (unit 14)',
    ),
    
    // Multisample - Folder selection
    ParameterEditorRule(
      parameterNamePattern: r'.*[Mm]ultisample.*',
      unit: 14,
      baseDirectory: '/multisamples',
      mode: FileSelectionMode.folderOnly,
      description: 'Multisample folder selection',
    ),
    
    // Tuner - Scala scale files
    ParameterEditorRule(
      algorithmGuid: 'tunf',
      parameterNamePattern: r'.*\.scl',
      unit: 14,
      baseDirectory: '/scala',
      mode: FileSelectionMode.directFile,
      allowedExtensions: ['.scl'],
      description: 'Scala scale file selection',
    ),
    
    // Tuner - Scala keyboard mapping files
    ParameterEditorRule(
      algorithmGuid: 'tunf',
      parameterNamePattern: r'.*\.kbm',
      unit: 14,
      baseDirectory: '/scala',
      mode: FileSelectionMode.directFile,
      allowedExtensions: ['.kbm'],
      description: 'Scala keyboard mapping file selection',
    ),
    
    // Tuner - MTS tuning files
    ParameterEditorRule(
      algorithmGuid: 'tunf',
      parameterNamePattern: r'.*\.syx',
      unit: 14,
      baseDirectory: '/mts',
      mode: FileSelectionMode.directFile,
      allowedExtensions: ['.syx'],
      description: 'MTS tuning file selection',
    ),
    
    // Poly FM - Bank selection (.syx files)
    ParameterEditorRule(
      algorithmGuid: 'pyfm',
      parameterNamePattern: r'Bank',
      unit: 14,
      baseDirectory: '/FMSYX',
      mode: FileSelectionMode.directFile,
      allowedExtensions: ['.syx'],
      recursive: false,
      description: 'Poly FM bank selection',
    ),
    
    // MIDI Player - Folder selection
    ParameterEditorRule(
      algorithmGuid: 'midp',
      parameterNamePattern: r'Folder',
      unit: 13,
      baseDirectory: '/MIDI',
      mode: FileSelectionMode.folderOnly,
      description: 'MIDI Player folder selection',
    ),
    
    // MIDI Player - File selection
    ParameterEditorRule(
      algorithmGuid: 'midp',
      parameterNamePattern: r'File',
      unit: 13,
      baseDirectory: '/MIDI',
      mode: FileSelectionMode.fileOnly,
      allowedExtensions: ['.mid', '.midi'],
      description: 'MIDI Player file selection',
    ),
    
    // Generic mixer names and other editable text parameters
    ParameterEditorRule(
      parameterNamePattern: r'.*[Nn]ame.*',
      unit: 17,
      mode: FileSelectionMode.textInput,
      description: 'Editable text parameter (names, labels)',
    ),
    
    // Fallback for any unit 17 parameter
    ParameterEditorRule(
      unit: 17,
      mode: FileSelectionMode.textInput,
      description: 'Generic text input parameter',
    ),
  ];

  /// Find appropriate parameter editor for the given context
  /// Returns null if no special editor is needed (falls back to default slider/+- editor)
  static Widget? findEditorFor({
    required Slot slot,
    required ParameterInfo parameterInfo,
    required int parameterNumber,
    required int currentValue,
    required Function(int) onValueChanged,
  }) {
    final algorithmGuid = slot.algorithm.guid;
    final parameterName = parameterInfo.name;
    final unit = parameterInfo.unit;
    
    debugPrint('[ParameterEditorRegistry] Looking for editor: algorithm=$algorithmGuid, parameter=$parameterName, unit=$unit');
    
    // Find first matching rule
    for (final rule in _rules) {
      if (rule.matches(
        algorithmGuid: algorithmGuid,
        parameterName: parameterName,
        unit: unit,
      )) {
        debugPrint('[ParameterEditorRegistry] ✅ Found matching rule: ${rule.description}');
        // Return appropriate editor widget based on rule
        return FileParameterEditor(
          slot: slot,
          parameterInfo: parameterInfo,
          parameterNumber: parameterNumber,
          currentValue: currentValue,
          onValueChanged: onValueChanged,
          rule: rule,
        );
      }
    }
    
    debugPrint('[ParameterEditorRegistry] No matching rule found');
    return null; // No special editor needed
  }
  
  /// Get all registered rules (for debugging/testing)
  static List<ParameterEditorRule> get rules => List.unmodifiable(_rules);
  
  /// Add a custom rule (for extensions or testing)
  static void addRule(ParameterEditorRule rule) {
    _rules.add(rule);
  }
  
  /// Clear all rules (for testing)
  static void clearRules() {
    _rules.clear();
  }
}