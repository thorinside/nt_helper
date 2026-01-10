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
  /// Algorithm-specific properties, including pre-parsed ports
  final Map<String, dynamic> properties;

  /// Current routing state
  RoutingState _state;

  /// Cached input ports (always empty for USB Audio)
  List<Port>? _cachedInputPorts;

  /// Cached output ports
  List<Port>? _cachedOutputPorts;

  /// Creates a new UsbFromAlgorithmRouting instance.
  ///
  /// Parameters:
  /// - [properties]: Pre-parsed algorithm properties, including output ports
  /// - [algorithmUuid]: Unique identifier for this algorithm instance
  /// - [validator]: Optional port compatibility validator
  /// - [initialState]: Optional initial routing state
  UsbFromAlgorithmRouting({
    required this.properties,
    required String algorithmUuid,
    super.validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState(),
       super(algorithmUuid: algorithmUuid);

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
    return [];
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];
    final declaredOutputs = properties['outputs'];

    if (declaredOutputs is List) {
      for (final item in declaredOutputs) {
        if (item is Map) {
          final id = item['id']?.toString() ?? 'out_${ports.length + 1}';
          final name = item['name']?.toString() ?? 'Output';
          final type = PortType.audio; // Always audio for USB

          final outputMode = parseOutputMode(item['outputMode']);

          ports.add(
            Port(
              id: id,
              name: name,
              type: type,
              direction: PortDirection.output,
              description:
                  item['description']?.toString() ??
                  'USB audio channel from host',
              outputMode: outputMode,
              busValue: coerceInt(item['busValue']),
              busParam: item['busParam']?.toString(),
              parameterNumber: coerceInt(item['parameterNumber']),
              modeParameterNumber: coerceInt(item['modeParameterNumber']),
              channelNumber: coerceInt(item['channelNumber']),
            ),
          );
        }
      }
    }

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
  }

  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
  }

  /// Determines if this routing implementation can handle the given slot.
  ///
  /// Returns true only for the USB Audio (From Host) algorithm with GUID 'usbf'.
  static bool canHandle(Slot slot) {
    return slot.algorithm.guid == 'usbf';
  }

  /// USB-specific extraction of IO parameters.
  ///
  /// Finds the 8 USB channel "to" parameters using robust heuristics and returns a
  /// map of parameter name -> current value. Includes 0 values (None).
  ///
  /// Heuristics and ordering:
  /// - Prefer enum-style bus params whose name contains 'to' and whose range
  ///   matches bus-like values (min 0/1, max 27/28/30/31).
  /// - If fewer than 8 by name, fall back to any bus-like enum params.
  /// - Sort by parameterNumber and keep the first 8 to define channels 1..8.
  static Map<String, int> extractIOParameters(Slot slot) {
    final result = <String, int>{};

    // Build helpers
    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    // Collect candidate 'to' params: enum-style bus params with names hinting at routing
    List<ParameterInfo> toParams = [
      for (final p in slot.parameters)
        if (p.unit == 1 &&
            (p.min == 0 || p.min == 1) &&
            (p.max == 27 || p.max == 28 || p.max == 30 || p.max == 31) &&
            p.name.toLowerCase().contains('to'))
          p,
    ];

    // Fallback: take any bus-like enum params if we didn't find 8
    if (toParams.length != 8) {
      toParams = [
        for (final p in slot.parameters)
          if (p.unit == 1 &&
              (p.min == 0 || p.min == 1) &&
              (p.max == 27 || p.max == 28 || p.max == 30 || p.max == 31))
            p,
      ];
    }

    // Sort stably by parameter number and keep the first 8
    toParams.sort((a, b) => a.parameterNumber.compareTo(b.parameterNumber));
    if (toParams.length > 8) toParams = toParams.sublist(0, 8);

    // Build output map using actual parameter names
    for (final p in toParams) {
      final value = valueByParam[p.parameterNumber] ?? p.defaultValue;
      result[p.name] = value;
    }

    return result;
  }

  /// Creates a UsbFromAlgorithmRouting instance from a slot.
  ///
  /// This factory method is called by AlgorithmRouting.fromSlot() when
  /// the algorithm GUID is 'usbf'. It parses the 8 channel parameters
  /// and their corresponding modes.
  ///
  /// Channel enumeration and mode alignment:
  /// - Output ports are enumerated by ascending parameterNumber of the eight
  ///   USB channel 'to' parameters, producing 'USB Channel 1..8'. This holds even
  ///   if names are generic (e.g., all 'to'/'mode').
  /// - OutputMode for each channel is aligned by index with the sorted mode
  ///   parameters: 0 = Add, 1 = Replace. Missing mode defaults to Add.
  /// - busValue drives connection discovery (e.g., 13–20 => hardware outs O1–O8,
  ///   29–30 => ES-5 L/R). A value of 0 means 'None'.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [ioParameters]: Pre-extracted routing parameters (bus assignments)
  /// - [modeParametersWithNumbers]: Mode parameters with their parameter numbers
  /// - [algorithmUuid]: Optional UUID for the algorithm instance
  static UsbFromAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    final algUuid =
        algorithmUuid ?? 'algo_usbf_${DateTime.now().millisecondsSinceEpoch}';

    final outputPorts = <Map<String, Object?>>[];

    // Build parameter lookup for getting parameter numbers
    final paramsByName = <String, ParameterInfo>{
      for (final p in slot.parameters) p.name: p,
    };

    // Pre-build a value lookup for direct fallback access
    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    // Collect candidate 'to' and 'mode' parameters robustly
    List<ParameterInfo> toParams = [];
    List<ParameterInfo> modeParams = [];

    for (final p in slot.parameters) {
      // Identify USB routing 'to' parameters:
      final isBusParam =
          p.unit == 1 &&
          (p.min == 0 || p.min == 1) &&
          (p.max == 27 || p.max == 28 || p.max == 30 || p.max == 31);
      final nameLower = p.name.toLowerCase();
      final looksLikeTo = nameLower.contains('to');

      if (isBusParam && looksLikeTo) {
        toParams.add(p);
        continue;
      }

      // Identify per-channel mode parameters (Add/Replace)
      if (p.unit == 1 && nameLower.contains('mode')) {
        modeParams.add(p);
        continue;
      }
    }

    // Fallback: some firmwares name all channels as just 'to' or 'mode'.
    // If we didn't find exactly 8 'to' params by name, widen to any bus params.
    if (toParams.length != 8) {
      toParams = [
        for (final p in slot.parameters)
          if (p.unit == 1 &&
              (p.min == 0 || p.min == 1) &&
              (p.max == 27 || p.max == 28 || p.max == 30 || p.max == 31))
            p,
      ];
    }

    // Sort by parameter number to keep channel order stable
    toParams.sort((a, b) => a.parameterNumber.compareTo(b.parameterNumber));
    modeParams.sort((a, b) => a.parameterNumber.compareTo(b.parameterNumber));

    // Keep only first 8 of each list (USB has 8 channels)
    if (toParams.length > 8) toParams = toParams.sublist(0, 8);
    if (modeParams.length > 8) modeParams = modeParams.sublist(0, 8);

    // If we still have fewer than 8 'to' params, try name-based lookup as a last resort
    if (toParams.length < 8) {
      String? findParamName(int channel, String suffix) {
        final candidates = <String>[
          'Ch$channel $suffix',
          'Ch $channel $suffix',
          'Channel $channel $suffix',
          if (suffix == 'to' || suffix == 'mode') 'Ch$channel $suffix',
        ];
        for (final name in candidates) {
          final info = paramsByName[name];
          if (info != null) return name;
        }
        return null;
      }

      final recovered = <ParameterInfo>[];
      for (int i = 1; i <= 8; i++) {
        final name = findParamName(i, 'to');
        if (name != null) {
          final info = paramsByName[name];
          if (info != null) recovered.add(info);
        }
      }
      if (recovered.isNotEmpty) {
        recovered.sort(
          (a, b) => a.parameterNumber.compareTo(b.parameterNumber),
        );
        toParams = recovered;
      }
    }

    // Build ports based on discovered params
    for (int i = 0; i < toParams.length && i < 8; i++) {
      final channel = i + 1;
      final toParam = toParams[i];
      final busValue =
          valueByParam[toParam.parameterNumber] ?? toParam.defaultValue;

      // Mode per index if available
      ({int parameterNumber, int value})? modeInfo;
      if (i < modeParams.length) {
        final modeParam = modeParams[i];
        final value =
            valueByParam[modeParam.parameterNumber] ?? modeParam.defaultValue;
        modeInfo = (parameterNumber: modeParam.parameterNumber, value: value);
      }

      outputPorts.add({
        'id': '${algUuid}_usb_ch$channel',
        'name': 'USB Channel $channel',
        'type': 'audio',
        'busParam': toParam.name,
        'busValue': busValue,
        'parameterNumber': toParam.parameterNumber,
        'channelNumber': channel,
        'outputMode': (modeInfo?.value == 1) ? 'replace' : 'add',
        'modeParameterNumber': modeInfo?.parameterNumber,
      });
    }

    final properties = {
      'algorithmGuid': slot.algorithm.guid,
      'algorithmName': slot.algorithm.name,
      'algorithmUuid': algUuid,
      'outputs': outputPorts,
    };

    return UsbFromAlgorithmRouting(
      properties: properties,
      algorithmUuid: algUuid,
    );
  }
}
