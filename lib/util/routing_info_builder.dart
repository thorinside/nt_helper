import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/models/routing_information.dart';

/// Builds [RoutingInformation] entries (one per algorithm, sorted by slot
/// index) from routing-editor algorithm/port data.
///
/// `routingInfo` packs bit masks where bit N corresponds to bus N:
/// [0] input buses read, [1] output buses written, [2] output buses written
/// in Replace mode, [3..5] reserved (0). This mirrors the packing the OG
/// signal-flow table and [RoutingAnalyzer] consume.
///
/// Bus identity is encoded as `1 << busNumber`, so buses above 63 are not
/// representable here — a pre-existing limitation shared with the table and
/// RoutingAnalyzer. Logic that must handle the full extended range (up to
/// [BusSpec.extendedMax]) should work with bus numbers directly instead.
List<RoutingInformation> buildRoutingInfoFromEditor(
  List<RoutingAlgorithm> algorithms,
  Map<String, OutputMode> portOutputModes,
) {
  final sorted = List<RoutingAlgorithm>.from(algorithms)
    ..sort((a, b) => a.index.compareTo(b.index));

  return sorted.map((algo) {
    int inputMask = 0;
    int outputMask = 0;
    int replaceMask = 0;

    for (final port in algo.inputPorts) {
      final bus = port.busValue;
      if (bus != null && bus > 0 && bus <= BusSpec.extendedMax) {
        inputMask |= (1 << bus);
      }
    }

    for (final port in algo.outputPorts) {
      final bus = port.busValue;
      if (bus != null && bus > 0 && bus <= BusSpec.extendedMax) {
        outputMask |= (1 << bus);
        final mode = portOutputModes[port.id] ?? port.outputMode;
        if (mode == OutputMode.replace) {
          replaceMask |= (1 << bus);
        }
      }
    }

    return RoutingInformation(
      algorithmIndex: algo.index,
      routingInfo: [inputMask, outputMask, replaceMask, 0, 0, 0],
      algorithmName: algo.algorithm.name,
    );
  }).toList();
}
