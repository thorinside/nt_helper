import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';

/// Configuration data for multi-channel algorithm routing.
///
/// Defines the properties needed to configure width-based routing behavior,
/// including the number of channels and channel-specific properties.
@immutable
class MultiChannelAlgorithmConfig {
  /// Number of channels supported by this algorithm
  /// Default is 1 for normal algorithms, N for width-based algorithms
  final int channelCount;

  /// Whether this algorithm supports stereo channel pairing
  final bool supportsStereoChannels;

  /// Whether channels can be independently routed
  final bool allowsIndependentChannels;

  /// Port types supported by this algorithm
  final List<PortType> supportedPortTypes;

  /// Base name prefix for generated ports
  final String portNamePrefix;

  /// Whether to create a master mix output
  final bool createMasterMix;

  /// Additional algorithm-specific properties
  final Map<String, dynamic> algorithmProperties;

  const MultiChannelAlgorithmConfig({
    this.channelCount = 1,
    this.supportsStereoChannels = false,
    this.allowsIndependentChannels = true,
    this.supportedPortTypes = const [PortType.audio, PortType.cv],
    this.portNamePrefix = 'Ch',
    this.createMasterMix = true,
    this.algorithmProperties = const {},
  });

  /// Factory constructor for normal (single-channel) algorithms
  factory MultiChannelAlgorithmConfig.normal({
    String portNamePrefix = 'Main',
    List<PortType> supportedPortTypes = const [PortType.audio, PortType.cv],
  }) {
    return MultiChannelAlgorithmConfig(
      channelCount: 1,
      supportsStereoChannels: false,
      allowsIndependentChannels: true,
      supportedPortTypes: supportedPortTypes,
      portNamePrefix: portNamePrefix,
      createMasterMix: false,
    );
  }

  /// Factory constructor for width-based (multi-channel) algorithms
  factory MultiChannelAlgorithmConfig.widthBased({
    required int width,
    bool supportsStereo = true,
    String portNamePrefix = 'Ch',
    List<PortType> supportedPortTypes = const [PortType.audio, PortType.cv],
  }) {
    return MultiChannelAlgorithmConfig(
      channelCount: width,
      supportsStereoChannels: supportsStereo,
      allowsIndependentChannels: true,
      supportedPortTypes: supportedPortTypes,
      portNamePrefix: portNamePrefix,
      createMasterMix: true,
    );
  }
}

/// Concrete implementation of AlgorithmRouting for multi-channel routing.
///
/// This class handles width-based routing with configurable channel count.
/// It supports both normal algorithms (default width=1) and width-based
/// algorithms with multiple channels.
///
/// Channel configurations can include:
/// - Single channel for normal algorithms
/// - Multiple independent channels for width-based algorithms
/// - Stereo channel pairing when supported
/// - Master mix outputs for multi-channel setups
///
/// Example usage:
/// ```dart
/// // Normal single-channel algorithm
/// final normalConfig = MultiChannelAlgorithmConfig.normal();
/// final normalRouting = MultiChannelAlgorithmRouting(config: normalConfig);
///
/// // Width-based multi-channel algorithm
/// final widthConfig = MultiChannelAlgorithmConfig.widthBased(width: 4);
/// final widthRouting = MultiChannelAlgorithmRouting(config: widthConfig);
/// ```
class MultiChannelAlgorithmRouting extends AlgorithmRouting {
  /// Configuration for this multi-channel routing instance
  final MultiChannelAlgorithmConfig config;

  /// Current routing state
  RoutingState _state;

  /// Cached input ports to avoid regeneration
  List<Port>? _cachedInputPorts;

  /// Cached output ports to avoid regeneration
  List<Port>? _cachedOutputPorts;

  /// Creates a new MultiChannelAlgorithmRouting instance.
  ///
  /// Parameters:
  /// - [config]: Configuration defining the multi-channel routing behavior
  /// - [validator]: Optional port compatibility validator (uses default if not provided)
  /// - [initialState]: Optional initial routing state
  MultiChannelAlgorithmRouting({
    required this.config,
    super.validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState(),
       super(
         algorithmUuid: config.algorithmProperties['algorithmUuid'] as String?,
       ) {
    debugPrint(
      'MultiChannelAlgorithmRouting: Initialized with ${config.channelCount} channels, '
      'stereo: ${config.supportsStereoChannels}, mix: ${config.createMasterMix}',
    );
  }

  @override
  RoutingState get state => _state;

  @override
  List<Port> get inputPorts => _cachedInputPorts ??= generateInputPorts();

  @override
  List<Port> get outputPorts => _cachedOutputPorts ??= generateOutputPorts();

  @override
  List<Connection> get connections => _state.connections;

  @override
  List<Port> generateInputPorts() {
    final ports = <Port>[];

    // If explicit inputs are defined in algorithm properties, use them.
    final declaredInputs = config.algorithmProperties['inputs'];
    if (declaredInputs is List) {
      // If the list is explicitly empty, return empty ports (no fallback)
      if (declaredInputs.isEmpty) {
        debugPrint(
          'MultiChannelAlgorithmRouting: No input ports declared - returning empty',
        );
        return ports;
      }

      // Process declared inputs
      for (final item in declaredInputs) {
        if (item is Map) {
          final id = item['id']?.toString() ?? 'in_${ports.length + 1}';
          final name = item['name']?.toString() ?? 'Input';
          final typeStr = item['type']?.toString().toLowerCase();
          final type = _parsePortType(typeStr) ?? PortType.audio;
          ports.add(
            Port(
              id: id,
              name: name,
              type: type,
              direction: PortDirection.input,
              description: item['description']?.toString(),
              // Direct properties
              busValue: item['busValue'] as int?,
              busParam: item['busParam']?.toString(),
              parameterNumber: item['parameterNumber'] as int?,
              channelNumber: item['channelNumber'] is int
                  ? item['channelNumber'] as int
                  : null,
              isMultiChannel: item['channelNumber'] != null,
            ),
          );
        }
      }
      debugPrint(
        'MultiChannelAlgorithmRouting: Generated ${ports.length} input ports (declared)',
      );
      return ports;
    }

    // Generate ports for each channel
    for (int channel = 0; channel < config.channelCount; channel++) {
      final channelNumber = channel + 1; // 1-based channel numbering

      // Generate ports for each supported type
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);

        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Generate stereo pair for audio channels
          ports.add(
            Port(
              id: 'multi_${portType.name}_in_${channelNumber}_l',
              name: '${config.portNamePrefix} $channelNumber $portTypeName L',
              type: portType,
              direction: PortDirection.input,
              description:
                  'Left $portTypeName input for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: true,
              stereoSide: 'left',
            ),
          );

          ports.add(
            Port(
              id: 'multi_${portType.name}_in_${channelNumber}_r',
              name: '${config.portNamePrefix} $channelNumber $portTypeName R',
              type: portType,
              direction: PortDirection.input,
              description:
                  'Right $portTypeName input for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: true,
              stereoSide: 'right',
            ),
          );
        } else {
          // Generate mono port
          ports.add(
            Port(
              id: 'multi_${portType.name}_in_$channelNumber',
              name: '${config.portNamePrefix} $channelNumber $portTypeName In',
              type: portType,
              direction: PortDirection.input,
              description: '$portTypeName input for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: false,
            ),
          );
        }
      }
    }

    debugPrint(
      'MultiChannelAlgorithmRouting: Generated ${ports.length} input ports',
    );
    return ports;
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];

    // If outputs are explicitly defined in algorithm properties, use them.
    final declared = config.algorithmProperties['outputs'];
    if (declared is List) {
      // If the list is explicitly empty, return empty ports (no fallback)
      if (declared.isEmpty) {
        debugPrint(
          'MultiChannelAlgorithmRouting: No output ports declared - returning empty',
        );
        return ports;
      }

      // Process declared outputs
      for (final item in declared) {
        if (item is Map) {
          final id = item['id']?.toString() ?? 'out_${ports.length + 1}';
          final name = item['name']?.toString() ?? 'Output';
          final typeStr = item['type']?.toString().toLowerCase();
          final type = _parsePortType(typeStr) ?? PortType.audio;
          // Determine output mode if available
          OutputMode? outputMode;
          if (item['outputMode'] != null) {
            final modeStr = item['outputMode'].toString().toLowerCase();
            if (modeStr == 'replace') {
              outputMode = OutputMode.replace;
            } else if (modeStr == 'add') {
              outputMode = OutputMode.add;
            }
          }

          // Get mode parameter number from the item metadata (already stored during createFromSlot)
          int? modeParameterNumber = item['modeParameterNumber'] as int?;

          // Fallback to looking it up from base class if not in metadata
          if (modeParameterNumber == null) {
            final busParam = item['busParam']?.toString();
            if (busParam != null) {
              modeParameterNumber = getModeParameterNumber(busParam);
            }
          }

          if (modeParameterNumber != null) {
            debugPrint(
              'MultiChannelRouting: Found mode parameter for ${item['name']}: $modeParameterNumber',
            );
          }

          ports.add(
            Port(
              id: id,
              name: name,
              type: type,
              direction: PortDirection.output,
              description: item['description']?.toString(),
              outputMode: outputMode,
              // Direct properties
              busValue: item['busValue'] as int?,
              busParam: item['busParam']?.toString(),
              parameterNumber: item['parameterNumber'] as int?,
              modeParameterNumber: modeParameterNumber,
              channelNumber: item['channel'] is int
                  ? item['channel'] as int
                  : null,
              isStereoChannel: item['channel'] != null,
              stereoSide: item['channel']?.toString(),
            ),
          );
        }
      }
      debugPrint(
        'MultiChannelAlgorithmRouting: Generated ${ports.length} output ports (declared)',
      );
      return ports;
    }

    // Generate ports for each channel
    for (int channel = 0; channel < config.channelCount; channel++) {
      final channelNumber = channel + 1;

      // Generate ports for each supported type
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);

        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Generate stereo pair for audio channels
          ports.add(
            Port(
              id: 'multi_${portType.name}_out_${channelNumber}_l',
              name: '${config.portNamePrefix} $channelNumber $portTypeName L',
              type: portType,
              direction: PortDirection.output,
              description:
                  'Left $portTypeName output for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: true,
              stereoSide: 'left',
            ),
          );

          ports.add(
            Port(
              id: 'multi_${portType.name}_out_${channelNumber}_r',
              name: '${config.portNamePrefix} $channelNumber $portTypeName R',
              type: portType,
              direction: PortDirection.output,
              description:
                  'Right $portTypeName output for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: true,
              stereoSide: 'right',
            ),
          );
        } else {
          // Generate mono port
          ports.add(
            Port(
              id: 'multi_${portType.name}_out_$channelNumber',
              name: '${config.portNamePrefix} $channelNumber $portTypeName Out',
              type: portType,
              direction: PortDirection.output,
              description: '$portTypeName output for channel $channelNumber',
              // Direct properties
              channelNumber: channelNumber,
              isMultiChannel: true,
              isStereoChannel: false,
            ),
          );
        }
      }
    }

    // Create master mix outputs if enabled and we have multiple channels
    if (config.createMasterMix && config.channelCount > 1) {
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);

        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Stereo master mix
          ports.add(
            Port(
              id: 'multi_mix_${portType.name}_out_l',
              name: 'Master Mix $portTypeName L',
              type: portType,
              direction: PortDirection.output,
              description: 'Left master mix $portTypeName output',
              // Direct properties
              isMasterMix: true,
              isStereoChannel: true,
              stereoSide: 'left',
            ),
          );

          ports.add(
            Port(
              id: 'multi_mix_${portType.name}_out_r',
              name: 'Master Mix $portTypeName R',
              type: portType,
              direction: PortDirection.output,
              description: 'Right master mix $portTypeName output',
              // Direct properties
              isMasterMix: true,
              isStereoChannel: true,
              stereoSide: 'right',
            ),
          );
        } else {
          // Mono master mix
          ports.add(
            Port(
              id: 'multi_mix_${portType.name}_out',
              name: 'Master Mix $portTypeName Out',
              type: portType,
              direction: PortDirection.output,
              description: 'Master mix $portTypeName output',
              // Direct properties
              isMasterMix: true,
            ),
          );
        }
      }
    }

    debugPrint(
      'MultiChannelAlgorithmRouting: Generated ${ports.length} output ports',
    );
    return ports;
  }

  PortType? _parsePortType(String? name) {
    switch (name) {
      case 'audio':
        return PortType.audio;
      case 'cv':
        return PortType.cv;
      case 'gate':
        return PortType.gate;
      case 'clock':
        return PortType.clock;
    }
    return null;
  }

  @override
  bool validateConnection(Port source, Port destination) {
    // First, use the base validation
    if (!super.validateConnection(source, destination)) {
      return false;
    }

    // Master mix connections have special rules (check first)
    if (_isMasterMixPort(source) || _isMasterMixPort(destination)) {
      return _validateMasterMixConnection(source, destination);
    }

    // Stereo channel validation
    if (_isStereoPort(source) || _isStereoPort(destination)) {
      return _validateStereoConnection(source, destination);
    }

    // Additional multi-channel specific validation
    if (_isMultiChannelPort(source) && _isMultiChannelPort(destination)) {
      return _validateMultiChannelConnection(source, destination);
    }

    return true;
  }

  @override
  void updateState(RoutingState newState) {
    _state = newState;

    // Clear port caches if ports have changed
    if (_state.inputPorts.isNotEmpty || _state.outputPorts.isNotEmpty) {
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
    }

    debugPrint('MultiChannelAlgorithmRouting: State updated');
  }

  /// Validates multi-channel specific connections
  bool _validateMultiChannelConnection(Port source, Port destination) {
    // If both ports are from specific channels, they should be compatible
    final sourceChannel = _getChannelNumber(source);
    final destChannel = _getChannelNumber(destination);

    // Allow connections between any channels if independent routing is enabled
    if (config.allowsIndependentChannels) {
      return true;
    }

    // Otherwise, channels must match
    if (sourceChannel != null && destChannel != null) {
      return sourceChannel == destChannel;
    }

    return true;
  }

  /// Validates stereo channel connections
  bool _validateStereoConnection(Port source, Port destination) {
    // If this routing doesn't support stereo, defer to base validation
    if (!config.supportsStereoChannels) {
      return true; // Let base validation handle it
    }

    // Stereo sides should match (left-to-left, right-to-right)
    final sourceSide = _getStereoSide(source);
    final destSide = _getStereoSide(destination);

    // If both have stereo sides, they must match
    if (sourceSide != null && destSide != null) {
      return sourceSide == destSide;
    }

    // Allow mono to stereo connections (source has no side, destination has side)
    // Allow stereo to mono connections (source has side, destination has no side)
    return true;
  }

  /// Validates master mix connections
  bool _validateMasterMixConnection(Port source, Port destination) {
    // Master mix outputs should only connect to external destinations
    if (_isMasterMixPort(source) && _isMultiChannelPort(destination)) {
      debugPrint(
        'MultiChannelAlgorithmRouting: Master mix should not connect back to channels',
      );
      return false;
    }

    return true;
  }

  /// Gets a human-readable name for a port type
  String _getPortTypeName(PortType type) {
    switch (type) {
      case PortType.audio:
        return 'Audio';
      case PortType.cv:
        return 'CV';
      case PortType.gate:
        return 'Gate';
      case PortType.clock:
        return 'Clock';
    }
  }

  /// Checks if a port is a multi-channel port
  bool _isMultiChannelPort(Port port) {
    return port.isMultiChannel;
  }

  /// Checks if a port is a stereo port
  bool _isStereoPort(Port port) {
    return port.isStereoChannel;
  }

  /// Checks if a port is a master mix port
  bool _isMasterMixPort(Port port) {
    return port.isMasterMix;
  }

  /// Gets the channel number from a multi-channel port
  int? _getChannelNumber(Port port) {
    return port.channelNumber;
  }

  /// Gets the stereo side from a stereo port
  String? _getStereoSide(Port port) {
    return port.stereoSide;
  }

  /// Updates the channel count and regenerates ports
  void updateChannelCount(int newChannelCount) {
    if (newChannelCount != config.channelCount && newChannelCount > 0) {
      // Clear cached ports to force regeneration
      _cachedInputPorts = null;
      _cachedOutputPorts = null;

      debugPrint(
        'MultiChannelAlgorithmRouting: Channel count updated from '
        '${config.channelCount} to $newChannelCount',
      );
    }
  }

  /// Gets all ports for a specific channel
  List<Port> getPortsForChannel(int channelNumber) {
    final allPorts = [...inputPorts, ...outputPorts];
    return allPorts
        .where((port) => _getChannelNumber(port) == channelNumber)
        .toList();
  }

  /// Gets all master mix ports
  List<Port> getMasterMixPorts() {
    return outputPorts.where(_isMasterMixPort).toList();
  }

  /// Checks if the configuration supports the given channel count
  bool supportsChannelCount(int channelCount) {
    return channelCount > 0 && channelCount <= config.channelCount;
  }

  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
    debugPrint('MultiChannelAlgorithmRouting: Disposed');
  }

  /// Determines if this routing implementation can handle the given slot.
  ///
  /// Returns true for all algorithms (this is the default fallback).
  /// Poly algorithms are handled by PolyAlgorithmRouting first.
  static bool canHandle(Slot slot) {
    // This is the fallback for all non-poly algorithms
    return true;
  }

  /// Get the width/channel count from various possible parameter names
  ///
  /// Checks multiple common parameter names that indicate width or channel count.
  /// Returns 1 if no width parameter is found.
  static int getWidthFromSlot(Slot slot) {
    // List of possible width parameter names (in priority order)
    final widthParameterNames = [
      'Width',
      'width',
      'Channels',
      'channels',
      'Channel count',
      'channel count',
      'Poly',
      'poly',
      'Voices',
      'voices',
    ];

    for (final paramName in widthParameterNames) {
      if (AlgorithmRouting.hasParameter(slot, paramName)) {
        final value = AlgorithmRouting.getParameterValue(slot, paramName);
        if (value > 0) {
          debugPrint(
            'MultiChannelAlgorithmRouting: Found width parameter "$paramName" = $value',
          );
          return value;
        }
      }
    }

    return 1; // Default to 1 if no width parameter found
  }

  /// Creates a MultiChannelAlgorithmRouting instance from a slot.
  ///
  /// Converts all routing parameters to input/output ports based on their names.
  /// Checks for a 'Width' parameter to determine channel count for multi-channel algorithms.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [ioParameters]: Pre-extracted routing parameters (bus assignments)
  /// - [modeParameters]: Pre-extracted mode parameters (Add/Replace modes)
  /// - [modeParametersWithNumbers]: Mode parameters with their parameter numbers
  /// - [algorithmUuid]: Optional UUID for the algorithm instance
  static MultiChannelAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    // Process routing parameters as regular ports
    final inputPorts = <Map<String, Object?>>[];
    final outputPorts = <Map<String, Object?>>[];

    // Build parameter lookup for getting parameter numbers
    final paramsByName = <String, ParameterInfo>{
      for (final p in slot.parameters) p.name: p,
    };

    // Build a map of parameter numbers to their send page (if any)
    final parameterToSendPage = <int, String>{};
    for (final page in slot.pages.pages) {
      // Check if this is a send page (e.g., "Send 1", "Send 2")
      if (page.name.startsWith('Send ') &&
          RegExp(r'Send \d+').hasMatch(page.name)) {
        // Map all parameters in this page to the send name
        for (final paramNum in page.parameters) {
          parameterToSendPage[paramNum] = page.name;
        }
      }
    }

    // Group send parameters by send number
    final sendGroups = <String, Map<String, dynamic>>{};

    // First pass: collect all send-related parameters (including non-bus ones like width/mode)
    for (final param in slot.parameters) {
      final sendPage = parameterToSendPage[param.parameterNumber];
      if (sendPage != null) {
        sendGroups[sendPage] ??= {};
        final lowerName = param.name.toLowerCase();

        if (lowerName.contains('width')) {
          // Get the actual width value from parameter values
          // Width is an enum: 0 = Mono, 1 = Stereo
          final widthValue = slot.values
              .firstWhere((v) => v.parameterNumber == param.parameterNumber,
                  orElse: () => ParameterValue(
                      algorithmIndex: 0,
                      parameterNumber: param.parameterNumber,
                      value: param.defaultValue))
              .value;
          sendGroups[sendPage]!['width'] = widthValue;
        } else if (lowerName.contains('output mode')) {
          // Get the actual mode value
          final modeValue = slot.values
              .firstWhere((v) => v.parameterNumber == param.parameterNumber,
                  orElse: () => ParameterValue(
                      algorithmIndex: 0,
                      parameterNumber: param.parameterNumber,
                      value: param.defaultValue))
              .value;
          sendGroups[sendPage]!['outputMode'] = modeValue;
          sendGroups[sendPage]!['modeParameterNumber'] = param.parameterNumber;
        }
      }
    }

    // Process routing parameters as regular ports
    for (final entry in ioParameters.entries) {
      final paramName = entry.key;
      final busValue = entry.value;

      // Get parameter number for unique ID generation
      final paramInfo = paramsByName[paramName];
      final paramNumber = paramInfo?.parameterNumber ?? 0;

      // Check if this parameter belongs to a send page
      final sendPage = parameterToSendPage[paramNumber];
      if (sendPage != null) {
        // This is a send parameter - handle destination
        sendGroups[sendPage] ??= {};
        final lowerName = paramName.toLowerCase();

        if (lowerName.contains('destination')) {
          sendGroups[sendPage]!['destination'] = busValue;
          sendGroups[sendPage]!['destinationParam'] = paramName;
          sendGroups[sendPage]!['destinationNumber'] = paramNumber;
        }
        // Skip normal processing for send parameters
        continue;
      }

      // Determine if this is an input or output based on parameter name
      final lowerName = paramName.toLowerCase();
      // Check if this parameter has a matching mode parameter (definitive output indicator)
      final hasMatchingModeParameter = modeParameters?.containsKey('$paramName mode') ?? false;
      final isOutput =
          hasMatchingModeParameter ||
          (lowerName.contains('output') && !lowerName.contains('mode')) ||
          lowerName.contains('out') && !lowerName.contains('input');

      // Infer port type from parameter name
      String portType = 'audio';
      if (lowerName.contains('cv') ||
          lowerName.contains('pitchbend') ||
          lowerName.contains('wave')) {
        portType = 'cv';
      } else if (lowerName.contains('gate') ||
          lowerName.contains('reset') ||
          lowerName.contains('trigger')) {
        portType = 'gate';
      } else if (lowerName.contains('clock')) {
        portType = 'clock';
      }

      // Create a sanitized version of the parameter name for the port ID
      // This preserves numbered prefixes like "1:" in "1:Trigger input"
      final sanitizedName = paramName
          .replaceAll(' ', '_')
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .replaceAll('(', '')
          .replaceAll(')', '');

      final port = {
        'id': '${algorithmUuid ?? 'algo'}_${sanitizedName}_$paramNumber',
        // Use algorithm UUID, sanitized name, and parameter number for uniqueness
        'name': paramName,  // Keep original name for display
        'type': portType,
        'busParam': paramName,
        'busValue': busValue,
        // Store bus value for connection discovery
        'parameterNumber': paramNumber,
        // Store parameter number for reference
      };

      if (isOutput) {
        // Add channel metadata for stereo outputs
        if (lowerName.contains('left')) {
          port['channel'] = 'left';
        } else if (lowerName.contains('right')) {
          port['channel'] = 'right';
        } else if (lowerName.contains('mono')) {
          port['channel'] = 'mono';
        }

        // Determine possible mode names
        final List<String> possibleModeNames = [
          '$paramName mode',
        ]; // Full name mode
        final firstWord = paramName.split(' ').first;
        if (firstWord.isNotEmpty && firstWord != paramName) {
          possibleModeNames.add('$firstWord mode'); // First word mode
        }
        // Add generic "Output mode" as fallback for any output parameter
        // This handles cases like Reverb (Clouds) where a single "Output mode"
        // controls both "Left output" and "Right output"
        if (isOutput) {
          possibleModeNames.add('Output mode');
        }
        final uniquePossibleModeNames = possibleModeNames.toSet().toList();

        // Apply output mode if available
        if (modeParameters != null) {
          String? actualModeName;
          int? modeValue;

          for (final name in uniquePossibleModeNames) {
            if (modeParameters.containsKey(name)) {
              actualModeName = name;
              modeValue = modeParameters[name];
              break; // Found the mode parameter
            }
          }

          if (actualModeName != null && modeValue != null) {
            port['outputMode'] = (modeValue == 1)
                ? 'replace'
                : 'add'; // 0 = Add, 1 = Replace
            debugPrint(
              'Found output mode "$actualModeName" for output "$paramName" with value $modeValue',
            );
          } else {
            // Optional: Log if no mode parameter was found for the value
            // debugPrint('No output mode value parameter found for "$paramName" among candidates: $uniquePossibleModeNames. Available: ${modeParameters.keys}');
          }
        }

        // Store mode parameter number if available
        if (modeParametersWithNumbers != null) {
          String? actualModeNameForNumber;
          ({int parameterNumber, int value})? modeInfo;

          // Use the same list of possible mode names that we built above
          // This ensures we check for generic "Output mode" as well
          for (final name in uniquePossibleModeNames) {
            if (modeParametersWithNumbers.containsKey(name)) {
              actualModeNameForNumber = name;
              modeInfo = modeParametersWithNumbers[name];
              break; // Found the mode parameter for its number
            }
          }

          // Debugging log to see what's being searched for and what's available
          // Can be noisy, so enable when debugging mode parameter discovery
          /*
          debugPrint(
            'Searching for mode param number for output "$paramName". Candidates: $uniquePossibleModeNames. Available mode params with numbers: ${modeParametersWithNumbers.keys.toList()}',
          );
          */

          if (actualModeNameForNumber != null && modeInfo != null) {
            port['modeParameterNumber'] = modeInfo.parameterNumber;
            debugPrint(
              'Found mode parameter number mapping for "$paramName" using key "$actualModeNameForNumber". Parameter number: ${modeInfo.parameterNumber}',
            );
          } else {
            // Optional: Log if no mode parameter was found for the number
            // debugPrint('Mode parameter number not found for "$paramName" among candidates: $uniquePossibleModeNames');
          }
        }

        outputPorts.add(port);
      } else {
        inputPorts.add(port);
      }
    }

    // Process send groups to create output ports
    for (final entry in sendGroups.entries) {
      final sendName = entry.key;
      final sendData = entry.value;

      final destination = sendData['destination'] as int?;
      final width = sendData['width'] as int? ?? 0; // Default to 0 (Mono)
      final outputMode = sendData['outputMode'] as int? ?? 0;
      final destinationParam = sendData['destinationParam'] as String? ?? sendName;
      final destinationNumber = sendData['destinationNumber'] as int? ?? 0;
      final modeParamNumber = sendData['modeParameterNumber'] as int?;

      if (destination == null || destination == 0) {
        // Skip sends with no destination
        continue;
      }

      // Extract send number from name (e.g., "Send 1" -> "1")
      final sendNumber = sendName.replaceAll(RegExp(r'[^0-9]'), '');

      // Width is an enum: 0 = Mono, 1 = Stereo
      if (width == 1) {
        // Stereo send - create L and R outputs
        outputPorts.add({
          'id': '${algorithmUuid ?? 'algo'}_send_${sendNumber}_l',
          'name': '$sendName L',
          'type': 'audio',
          'busParam': destinationParam,
          'busValue': destination,
          'parameterNumber': destinationNumber,
          'outputMode': outputMode == 1 ? 'replace' : 'add',
          'modeParameterNumber': modeParamNumber,
          'channel': 'left',
        });
        outputPorts.add({
          'id': '${algorithmUuid ?? 'algo'}_send_${sendNumber}_r',
          'name': '$sendName R',
          'type': 'audio',
          'busParam': '$destinationParam R',
          'busValue': destination + 1, // Right channel uses next bus
          'parameterNumber': destinationNumber,
          'outputMode': outputMode == 1 ? 'replace' : 'add',
          'modeParameterNumber': modeParamNumber,
          'channel': 'right',
        });
      } else {
        // Mono send - create single output
        outputPorts.add({
          'id': '${algorithmUuid ?? 'algo'}_send_$sendNumber',
          'name': sendName,
          'type': 'audio',
          'busParam': destinationParam,
          'busValue': destination,
          'parameterNumber': destinationNumber,
          'outputMode': outputMode == 1 ? 'replace' : 'add',
          'modeParameterNumber': modeParamNumber,
        });
      }

    }

    // Check for Width parameter to determine channel count
    final channelCount = getWidthFromSlot(slot);

    // Duplicate Audio input for width-based algorithms
    if (channelCount > 1) {
      // Find the original Audio input port
      final audioInputIndex = inputPorts.indexWhere(
        (port) => port['name'] == 'Audio input',
      );

      if (audioInputIndex >= 0) {
        final audioInputPort = inputPorts[audioInputIndex];
        final baseBusValue = audioInputPort['busValue'] as int? ?? 0;

        // Only duplicate if the original Audio input has a valid bus assignment
        if (baseBusValue > 0) {
          debugPrint(
            'MultiChannelAlgorithmRouting: Duplicating Audio input for $channelCount channels',
          );

          // Create virtual ports and insert them right after the original
          final virtualPorts = <Map<String, Object?>>[];
          for (int channel = 2; channel <= channelCount; channel++) {
            final virtualPort = {
              'id': '${algorithmUuid ?? 'algo'}_audio_input_$channel',
              'name': 'Audio input $channel',
              'type': 'audio',
              'busParam': null, // No actual parameter for virtual ports
              'busValue': baseBusValue + (channel - 1),
              'parameterNumber': -channel, // Negative to indicate virtual port
              'isVirtualPort': true,
              'channelNumber': channel,
              'basedOn': 'Audio input',
            };
            virtualPorts.add(virtualPort);
            debugPrint(
              '  Added virtual Audio input $channel on bus ${baseBusValue + (channel - 1)}',
            );
          }

          // Insert all virtual ports right after the original Audio input
          inputPorts.insertAll(audioInputIndex + 1, virtualPorts);
        }
      }
    }

    // Determine if this is a multi-channel algorithm
    final isMultiChannel = channelCount > 1;

    // Create appropriate configuration
    final MultiChannelAlgorithmConfig config;
    if (isMultiChannel) {
      config = MultiChannelAlgorithmConfig.widthBased(
        width: channelCount,
        supportsStereo: outputPorts.any(
          (p) => p['channel'] == 'left' || p['channel'] == 'right',
        ),
      );
    } else {
      config = MultiChannelAlgorithmConfig.normal();
    }

    // Store the ports in algorithm properties
    final properties = {
      'algorithmGuid': slot.algorithm.guid,
      'algorithmName': slot.algorithm.name,
      'algorithmUuid': algorithmUuid,
      'inputs': inputPorts,
      'outputs': outputPorts,
      'channelCount': channelCount,
      'isMultiChannel': isMultiChannel,
    };


    return MultiChannelAlgorithmRouting(
      config: MultiChannelAlgorithmConfig(
        channelCount: config.channelCount,
        supportsStereoChannels: config.supportsStereoChannels,
        allowsIndependentChannels: config.allowsIndependentChannels,
        supportedPortTypes: config.supportedPortTypes,
        portNamePrefix: config.portNamePrefix,
        createMasterMix: config.createMasterMix,
        algorithmProperties: properties,
      ),
    );
  }
}
