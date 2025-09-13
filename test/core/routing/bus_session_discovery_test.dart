import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core;
import 'package:nt_helper/core/routing/models/routing_state.dart';

/// Minimal fake routing for testing discovery; provides only ports/state.
class _FakeRouting extends AlgorithmRouting {
  final String _id;
  final List<core.Port> _inputs;
  final List<core.Port> _outputs;

  RoutingState _state = const RoutingState();

  _FakeRouting({
    required String id,
    List<core.Port>? inputs,
    List<core.Port>? outputs,
  }) : _id = id,
       _inputs = inputs ?? const [],
       _outputs = outputs ?? const [] {
    algorithmUuid = _id;
  }

  @override
  RoutingState get state => _state;

  @override
  List<core.Port> get inputPorts => _inputs;

  @override
  List<core.Port> get outputPorts => _outputs;

  @override
  List<Connection> get connections => const [];

  @override
  List<core.Port> generateInputPorts() => _inputs;

  @override
  List<core.Port> generateOutputPorts() => _outputs;

  @override
  void updateState(RoutingState newState) => _state = newState;
}

core.Port _inPort(
  String id,
  int bus, {
  core.PortType type = core.PortType.audio,
}) {
  return core.Port(
    id: id,
    name: id,
    type: type,
    direction: core.PortDirection.input,
    busValue: bus,
    parameterNumber: 1,
  );
}

core.Port _outPort(
  String id,
  int bus, {
  core.OutputMode? mode,
  core.PortType type = core.PortType.audio,
}) {
  return core.Port(
    id: id,
    name: id,
    type: type,
    direction: core.PortDirection.output,
    busValue: bus,
    parameterNumber: 2,
    outputMode: mode,
  );
}

void main() {
  group('Session-aware discovery', () {
    test('replace starts a new session and prunes earlier writers', () {
      // Slots 0..3
      final s0 = _FakeRouting(
        id: 'slot0',
        outputs: [
          _outPort(
            's0_out_b1',
            1 /* hw input bus */,
            mode: core.OutputMode.add,
          ),
        ],
      );
      final s1 = _FakeRouting(id: 'slot1', inputs: [_inPort('s1_in_b1', 1)]);
      final s2 = _FakeRouting(
        id: 'slot2',
        outputs: [_outPort('s2_out_b1', 1, mode: core.OutputMode.replace)],
      );
      final s3 = _FakeRouting(id: 'slot3', inputs: [_inPort('s3_in_b1', 1)]);

      final conns = ConnectionDiscoveryService.discoverConnections([
        s0,
        s1,
        s2,
        s3,
      ]);

      // s1 input sees s0 add (and hardware input), since replace occurs later at slot2
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.sourcePortId == 's0_out_b1' &&
              c.destinationPortId == 's1_in_b1',
        ),
        isTrue,
      );
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput &&
              c.busNumber == 1 &&
              c.destinationPortId == 's1_in_b1',
        ),
        isTrue,
      );

      // s3 input should NOT see s0 (it was replaced at slot2), but should see s2
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.sourcePortId == 's0_out_b1' &&
              c.destinationPortId == 's3_in_b1',
        ),
        isFalse,
      );
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.sourcePortId == 's2_out_b1' &&
              c.destinationPortId == 's3_in_b1',
        ),
        isTrue,
      );

      // Hardware input should NOT connect to s3, since slot2 replace masks it
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput &&
              c.busNumber == 1 &&
              c.destinationPortId == 's3_in_b1',
        ),
        isFalse,
      );
    });

    test('hardware output uses final contributors only', () {
      // Bus 18 (hardware output index 6). Final contributors should be s2 (replace) and s3 (add).
      final s0 = _FakeRouting(
        id: 'slot0',
        outputs: [_outPort('s0_out_b18', 18, mode: core.OutputMode.add)],
      );
      final s1 = _FakeRouting(id: 'slot1');
      final s2 = _FakeRouting(
        id: 'slot2',
        outputs: [_outPort('s2_out_b18', 18, mode: core.OutputMode.replace)],
      );
      final s3 = _FakeRouting(
        id: 'slot3',
        outputs: [_outPort('s3_out_b18', 18, mode: core.OutputMode.add)],
      );

      final conns = ConnectionDiscoveryService.discoverConnections([
        s0,
        s1,
        s2,
        s3,
      ]);

      // No hardware output edge from s0 (replaced later)
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.sourcePortId == 's0_out_b18',
        ),
        isFalse,
      );

      // Hardware output edges exist from s2 and s3
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.sourcePortId == 's2_out_b18' &&
              c.busNumber == 18,
        ),
        isTrue,
      );
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.sourcePortId == 's3_out_b18' &&
              c.busNumber == 18,
        ),
        isTrue,
      );
    });
  });
}
