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
  core.PortType type = core.PortType.audio,
}) {
  return core.Port(
    id: id,
    name: id,
    type: type,
    direction: core.PortDirection.output,
    busValue: bus,
    parameterNumber: 2,
  );
}

void main() {
  group('ConnectionDiscoveryService', () {
    test('creates algo→algo and hardware input connections on bus 2', () {
      final a = _FakeRouting(id: 'algo_A', outputs: [_outPort('A_out_b2', 2)]);
      final b = _FakeRouting(id: 'algo_B', inputs: [_inPort('B_in_b2', 2)]);

      final conns = ConnectionDiscoveryService.discoverConnections([a, b]);

      // One hardware input connection on bus 2 (from hw_in_2 to an algo input)
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput &&
              c.busNumber == 2,
        ),
        isTrue,
      );

      // One algo→algo connection from A_out_b2 to B_in_b2
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.sourcePortId == 'A_out_b2' &&
              c.destinationPortId == 'B_in_b2' &&
              c.busNumber == 2,
        ),
        isTrue,
      );

      // Hardware input edges go from hw_in_* to algorithm inputs (already verified above)
    });

    test('creates algo→algo and hardware output connections on bus 18', () {
      final a = _FakeRouting(
        id: 'algo_A',
        outputs: [_outPort('A_out_b18', 18)],
      );
      final b = _FakeRouting(id: 'algo_B', inputs: [_inPort('B_in_b18', 18)]);

      final conns = ConnectionDiscoveryService.discoverConnections([a, b]);

      // Hardware output connection from A_out_b18 to hw_out_6 (bus 18 ⇒ 18-12 = 6)
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.busNumber == 18 &&
              c.destinationPortId == 'hw_out_6',
        ),
        isTrue,
      );

      // Algo→algo connection exists
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.busNumber == 18 &&
              c.sourcePortId == 'A_out_b18' &&
              c.destinationPortId == 'B_in_b18',
        ),
        isTrue,
      );
    });

    test('aux bus 25 yields only algo→algo (no hardware edges)', () {
      final a = _FakeRouting(
        id: 'algo_A',
        outputs: [_outPort('A_out_b25', 25)],
      );
      final b = _FakeRouting(id: 'algo_B', inputs: [_inPort('B_in_b25', 25)]);

      final conns = ConnectionDiscoveryService.discoverConnections([a, b]);

      // Algo→algo present
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.busNumber == 25,
        ),
        isTrue,
      );

      // No hardware input/output edges on aux
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput &&
              c.busNumber == 25,
        ),
        isFalse,
      );
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.busNumber == 25,
        ),
        isFalse,
      );
    });

    test('ES-5 bus 29 creates connection to es5_L port', () {
      final a = _FakeRouting(
        id: 'algo_A',
        outputs: [_outPort('A_out_b29', 29)],
      );

      final conns = ConnectionDiscoveryService.discoverConnections([a]);

      // Hardware output connection from A_out_b29 to es5_L
      final es5Conn = conns.firstWhere(
        (c) =>
            c.connectionType == ConnectionType.hardwareOutput &&
            c.busNumber == 29 &&
            c.destinationPortId == 'es5_L',
      );

      expect(es5Conn.sourcePortId, 'A_out_b29');
      expect(es5Conn.signalType, SignalType.audio);
      expect(es5Conn.isOutput, isTrue);
    });

    test('ES-5 bus 30 creates connection to es5_R port', () {
      final a = _FakeRouting(
        id: 'algo_A',
        outputs: [_outPort('A_out_b30', 30)],
      );

      final conns = ConnectionDiscoveryService.discoverConnections([a]);

      // Hardware output connection from A_out_b30 to es5_R
      final es5Conn = conns.firstWhere(
        (c) =>
            c.connectionType == ConnectionType.hardwareOutput &&
            c.busNumber == 30 &&
            c.destinationPortId == 'es5_R',
      );

      expect(es5Conn.sourcePortId, 'A_out_b30');
      expect(es5Conn.signalType, SignalType.audio);
      expect(es5Conn.isOutput, isTrue);
    });

    test(
      'mixed USB outputs (ES-5 and standard) create correct connections',
      () {
        final usbFromHost = _FakeRouting(
          id: 'usb_from_host',
          outputs: [
            _outPort('usb_ch1', 13), // Standard output 1
            _outPort('usb_ch2', 29), // ES-5 L
            _outPort('usb_ch3', 30), // ES-5 R
            _outPort('usb_ch4', 14), // Standard output 2
          ],
        );

        final conns = ConnectionDiscoveryService.discoverConnections([
          usbFromHost,
        ]);

        // Standard output to hw_out_1 (bus 13)
        expect(
          conns.any(
            (c) =>
                c.connectionType == ConnectionType.hardwareOutput &&
                c.busNumber == 13 &&
                c.destinationPortId == 'hw_out_1',
          ),
          isTrue,
        );

        // ES-5 L connection (bus 29)
        expect(
          conns.any(
            (c) =>
                c.connectionType == ConnectionType.hardwareOutput &&
                c.busNumber == 29 &&
                c.destinationPortId == 'es5_L' &&
                c.signalType == SignalType.audio,
          ),
          isTrue,
        );

        // ES-5 R connection (bus 30)
        expect(
          conns.any(
            (c) =>
                c.connectionType == ConnectionType.hardwareOutput &&
                c.busNumber == 30 &&
                c.destinationPortId == 'es5_R' &&
                c.signalType == SignalType.audio,
          ),
          isTrue,
        );

        // Standard output to hw_out_2 (bus 14)
        expect(
          conns.any(
            (c) =>
                c.connectionType == ConnectionType.hardwareOutput &&
                c.busNumber == 14 &&
                c.destinationPortId == 'hw_out_2',
          ),
          isTrue,
        );
      },
    );

    test('ES-5 connections do not affect standard output routing', () {
      final a = _FakeRouting(
        id: 'algo_A',
        outputs: [
          _outPort('A_out_b13', 13), // Standard
          _outPort('A_out_b20', 20), // Standard
        ],
      );

      final conns = ConnectionDiscoveryService.discoverConnections([a]);

      // Verify standard outputs still work correctly
      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.busNumber == 13 &&
              c.destinationPortId == 'hw_out_1',
        ),
        isTrue,
      );

      expect(
        conns.any(
          (c) =>
              c.connectionType == ConnectionType.hardwareOutput &&
              c.busNumber == 20 &&
              c.destinationPortId == 'hw_out_8',
        ),
        isTrue,
      );

      // No ES-5 connections should exist
      expect(
        conns.any(
          (c) =>
              c.destinationPortId == 'es5_L' || c.destinationPortId == 'es5_R',
        ),
        isFalse,
      );
    });
  });
}
