import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';

/// Routing implementation for USB Audio (From Host) algorithm.
///
/// The USB Audio algorithm has a unique parameter structure where
/// it uses 8 'to' parameters (Ch1 to - Ch8 to) to define output
/// routing destinations, and 8 'mode' parameters (Ch1 mode - Ch8 mode)
/// to define Add/Replace modes for each channel.
///
/// This implementation:
/// - Has no input ports (USB audio comes from the host)
/// - Has 8 fixed output ports representing USB channels 1-8
/// - Supports extended bus values 0-30 (including ES-5 L/R at 29-30)
/// - Extracts mode information for each channel
class UsbFromAlgorithmRouting extends AlgorithmRouting {
  /// The slot data containing algorithm and parameter information
  final Slot slot;

  /// The unique identifier for this algorithm instance
  final String algorithmUuid;

  /// Current routing state
  RoutingState _state;

  /// Cached input ports (always empty for USB Audio)
  List<Port>? _cachedInputPorts;

  /// Cached output ports
  List<Port>? _cachedOutputPorts;

  /// Creates a new UsbFromAlgorithmRouting instance.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [algorithmUuid]: Unique identifier for this algorithm instance
  /// - [validator]: Optional port compatibility validator
  /// - [initialState]: Optional initial routing state
  UsbFromAlgorithmRouting({
    required this.slot,
    required this.algorithmUuid,
    super.validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState() {
    debugPrint(
      'UsbFromAlgorithmRouting: Initialized for ${slot.algorithm.name} '
      'with UUID $algorithmUuid',
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
    // USB Audio (From Host) has no input ports
    debugPrint('UsbFromAlgorithmRouting: No input ports (USB from host)');
    return [];
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];

    // Extract 8 output ports from Ch1-Ch8 'to' parameters
    for (int channel = 1; channel <= 8; channel++) {
      final toParamName = 'Ch$channel to';
      final modeParamName = 'Ch$channel mode';

      // Find the 'to' parameter
      final toParam = slot.parameters.firstWhere(
        (p) => p.name == toParamName,
        orElse: () => ParameterInfo.filler(),
      );

      // Find the 'mode' parameter
      final modeParam = slot.parameters.firstWhere(
        (p) => p.name == modeParamName,
        orElse: () => ParameterInfo.filler(),
      );

      // Get the bus value for this channel
      int busValue = 0;
      if (toParam.parameterNumber >= 0) {
        final value = slot.values.firstWhere(
          (v) => v.parameterNumber == toParam.parameterNumber,
          orElse: () => ParameterValue(
            algorithmIndex: 0,
            parameterNumber: toParam.parameterNumber,
            value: toParam.defaultValue,
          ),
        );
        busValue = value.value;
      }

      // Get the mode value for this channel (0=Add, 1=Replace)
      OutputMode outputMode = OutputMode.add;
      if (modeParam.parameterNumber >= 0) {
        final value = slot.values.firstWhere(
          (v) => v.parameterNumber == modeParam.parameterNumber,
          orElse: () => ParameterValue(
            algorithmIndex: 0,
            parameterNumber: modeParam.parameterNumber,
            value: modeParam.defaultValue,
          ),
        );
        outputMode = value.value == 1 ? OutputMode.replace : OutputMode.add;
      }

      // Create the output port
      final port = Port(
        id: '${algorithmUuid}_usb_ch$channel',
        name: 'USB Channel $channel',
        type: PortType.audio,
        direction: PortDirection.output,
        description: 'USB audio channel $channel from host',
        outputMode: outputMode,
        // Direct properties
        busValue: busValue,
        busParam: toParamName,
        parameterNumber: toParam.parameterNumber >= 0 ? toParam.parameterNumber : null,
        // Mark as USB channel
        channelNumber: channel,
      );

      ports.add(port);

      debugPrint(
        'UsbFromAlgorithmRouting: Ch$channel -> bus $busValue '
        '(${outputMode == OutputMode.replace ? "Replace" : "Add"})',
      );
    }

    debugPrint('UsbFromAlgorithmRouting: Generated ${ports.length} output ports');
    return ports;
  }

  @override
  void updateState(RoutingState newState) {
    _state = newState;

    // Clear port caches if ports have changed
    if (_state.inputPorts.isNotEmpty || _state.outputPorts.isNotEmpty) {
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
    }

    debugPrint('UsbFromAlgorithmRouting: State updated');
  }

  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
    debugPrint('UsbFromAlgorithmRouting: Disposed');
  }

  /// Determines if this routing implementation can handle the given slot.
  ///
  /// Returns true only for the USB Audio (From Host) algorithm with GUID 'usbf'.
  static bool canHandle(Slot slot) {
    return slot.algorithm.guid == 'usbf';
  }

  /// Creates a UsbFromAlgorithmRouting instance from a slot.
  ///
  /// This factory method is called by AlgorithmRouting.fromSlot() when
  /// the algorithm GUID is 'usbf'.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [algorithmUuid]: Optional UUID for the algorithm instance
  static UsbFromAlgorithmRouting createFromSlot(
    Slot slot, {
    String? algorithmUuid,
  }) {
    debugPrint('UsbFromAlgorithmRouting.createFromSlot: Algorithm ${slot.algorithm.name}');

    return UsbFromAlgorithmRouting(
      slot: slot,
      algorithmUuid: algorithmUuid ?? 'algo_usbf_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}