import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'multi_channel_algorithm_routing.dart';
import 'models/port.dart';

/// Base class for algorithms that support ES-5 direct output routing.
///
/// Algorithms extending this class support multiple output channels that can route to either:
/// 1. Normal Output buses (when ES-5 Expander = 0)
/// 2. Direct ES-5 expander ports (when ES-5 Expander > 0)
///
/// When ES-5 Expander is active (1-6), the Output parameter is completely ignored
/// and the ES-5 Output parameter (1-8) determines which ES-5 port receives the signal.
abstract class Es5DirectOutputAlgorithmRouting
    extends MultiChannelAlgorithmRouting {
  /// Special marker for ES-5 direct output connections
  static const String es5DirectBusParam = 'es5_direct';

  /// The slot containing all algorithm data
  final Slot slot;

  /// The name of the algorithm (for debug messages)
  String get algorithmName;

  /// Creates a new Es5DirectOutputAlgorithmRouting instance.
  Es5DirectOutputAlgorithmRouting({
    required this.slot,
    required super.config,
    super.validator,
  }) {
    debugPrint('$algorithmName: Initialized for ${slot.algorithm.name}');
  }

  /// Generates output ports based on ES-5 configuration for each channel.
  ///
  /// For each channel:
  /// - If ES-5 Expander > 0: Create ES-5 direct output port (ignoring Output parameter)
  /// - If ES-5 Expander = 0: Create normal output port using Output parameter
  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];

    for (int channel = 1; channel <= config.channelCount; channel++) {
      // Get ES-5 Expander value (0=Off, 1-6=Active)
      final es5ExpanderValue = getChannelParameter(channel, 'ES-5 Expander');

      if (es5ExpanderValue != null && es5ExpanderValue > 0) {
        // ES-5 MODE: Ignore Output parameter completely
        final es5OutputValue =
            getChannelParameter(channel, 'ES-5 Output') ?? channel;

        ports.add(
          Port(
            id: '${algorithmUuid}_channel_${channel}_es5_output',
            name: 'Ch$channel → ES-5 $es5OutputValue',
            type: PortType.gate,
            direction: PortDirection.output,
            description: 'Direct to ES-5 Output $es5OutputValue',
            busParam: es5DirectBusParam, // Special marker
            channelNumber: es5OutputValue, // ES-5 port number
          ),
        );

        debugPrint(
          '$algorithmName: Channel $channel → ES-5 direct output $es5OutputValue',
        );
      } else {
        // NORMAL MODE: Use Output parameter
        final outputBus = getChannelParameter(channel, 'Output') ?? 0;

        if (outputBus > 0) {
          ports.add(
            Port(
              id: '${algorithmUuid}_channel_${channel}_output',
              name: 'Channel $channel',
              type: PortType.gate,
              direction: PortDirection.output,
              description: 'Gate output for channel $channel',
              busValue: outputBus,
              channelNumber: channel,
            ),
          );

          debugPrint(
            '$algorithmName: Channel $channel → normal output bus $outputBus',
          );
        } else {
          debugPrint(
            '$algorithmName: Channel $channel has no output assignment',
          );
        }
      }
    }

    debugPrint('$algorithmName: Generated ${ports.length} output ports');
    return ports;
  }

  /// Gets the value of a parameter for a specific channel.
  ///
  /// Parameters are prefixed with channel number (e.g., "1:Output", "2:ES-5 Expander").
  /// For single-channel algorithms, falls back to non-prefixed parameter names.
  ///
  /// Parameters:
  /// - [channel]: The channel number (1-based)
  /// - [paramName]: The parameter name to find (without channel prefix)
  ///
  /// Returns the parameter value, or null if not found
  @protected
  int? getChannelParameter(int channel, String paramName) {
    // Look for parameter with channel prefix (e.g., "1:Output")
    final prefixedName = '$channel:$paramName';

    var param = slot.parameters.firstWhere(
      (p) => p.name == prefixedName,
      orElse: () => ParameterInfo.filler(),
    );

    // For single-channel algorithms, fall back to non-prefixed parameter name
    if (param.parameterNumber < 0 && config.channelCount == 1) {
      param = slot.parameters.firstWhere(
        (p) => p.name == paramName,
        orElse: () => ParameterInfo.filler(),
      );

      if (param.parameterNumber < 0) {
        debugPrint('$algorithmName: Parameter "$paramName" not found');
        return null;
      }

      // Get the parameter value
      final value = slot.values
          .firstWhere(
            (v) => v.parameterNumber == param.parameterNumber,
            orElse: () => ParameterValue(
              algorithmIndex: 0,
              parameterNumber: param.parameterNumber,
              value: param.defaultValue,
            ),
          )
          .value;

      debugPrint('$algorithmName: Found $paramName = $value');
      return value;
    }

    if (param.parameterNumber < 0) {
      debugPrint('$algorithmName: Parameter "$prefixedName" not found');
      return null;
    }

    // Get the parameter value
    final value = slot.values
        .firstWhere(
          (v) => v.parameterNumber == param.parameterNumber,
          orElse: () => ParameterValue(
            algorithmIndex: 0,
            parameterNumber: param.parameterNumber,
            value: param.defaultValue,
          ),
        )
        .value;

    debugPrint('$algorithmName: Found $prefixedName = $value');
    return value;
  }

  /// Creates an instance from a slot using the common pattern.
  ///
  /// This static method provides shared creation logic for ES-5 direct output algorithms.
  /// It counts channels, extracts input ports, and creates the configuration.
  ///
  /// Subclasses should call this and then construct their specific instance type.
  static ({
    int channelCount,
    List inputPorts,
    MultiChannelAlgorithmConfig config,
  })
  createConfigFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
    required String debugName,
  }) {
    // Count channels by finding highest channel prefix in parameter names
    int channelCount = 0;
    for (final param in slot.parameters) {
      final match = RegExp(r'^(\d+):').firstMatch(param.name);
      if (match != null) {
        final channelNum = int.parse(match.group(1)!);
        if (channelNum > channelCount) {
          channelCount = channelNum;
        }
      }
    }

    debugPrint('$debugName: Creating with $channelCount channels');

    // Use base class to process normal inputs (non-channel-prefixed parameters)
    final baseRouting = MultiChannelAlgorithmRouting.createFromSlot(
      slot,
      ioParameters: ioParameters,
      modeParameters: modeParameters,
      modeParametersWithNumbers: modeParametersWithNumbers,
      algorithmUuid: algorithmUuid,
    );

    // Extract input ports from base routing
    final inputPorts = baseRouting.config.algorithmProperties['inputs'] as List;

    // Create configuration, preserving inputs
    final config = MultiChannelAlgorithmConfig(
      channelCount: channelCount > 0 ? channelCount : 1,
      supportsStereoChannels: false, // Gate outputs, not stereo
      allowsIndependentChannels: true,
      supportedPortTypes: [PortType.gate],
      portNamePrefix: 'Channel',
      createMasterMix: false, // No master mix for gate outputs
      algorithmProperties: {
        'algorithmGuid': slot.algorithm.guid,
        'algorithmName': slot.algorithm.name,
        'algorithmUuid': algorithmUuid,
        'channelCount': channelCount,
        'inputs': inputPorts, // Preserve normal input ports
        'outputs': [], // Will be generated by generateOutputPorts()
      },
    );

    return (channelCount: channelCount, inputPorts: inputPorts, config: config);
  }
}
