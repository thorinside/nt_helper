import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// Regression test for the Poly Multisample "virtual pitch inputs" regression.
///
/// Commit 7e7efa84 switched `extractIOParameters()` from pattern matching to
/// ioFlags-only detection. `Gate $i CV count` is a numeric knob (unit=0,
/// min=0, max=11) with no ioFlags, so it was no longer extracted into
/// `ioParameters`. As a result `PolyAlgorithmRouting.createFromSlot()` always
/// read `cvCount = 0`, and no CV input ports were generated after connected
/// gates — breaking the "virtual pitch inputs" visualization for Poly
/// Multisample and all other poly algorithms.
///
/// The fix reads `Gate $i CV count` directly from the slot (via
/// `AlgorithmRouting.getParameterValue`) instead of from `ioParameters`.
void main() {
  group('Poly gate CV count regression', () {
    /// Builds a poly algorithm slot (guid `pymu`) with a single connected
    /// gate input and a configurable `Gate 1 CV count`.
    ///
    /// `Gate input 1` carries the `isInput` ioFlag (ioFlags=1) so it is picked
    /// up by `extractIOParameters()`. `Gate 1 CV count` deliberately has
    /// **no** ioFlags (ioFlags=0), mirroring the firmware metadata, so it is
    /// NOT picked up by `extractIOParameters()` — the conditions that caused
    /// the regression.
    Slot createPolyMultisampleSlot({
      required int gateInputBus,
      required int gateCvCount,
      int algorithmIndex = 0,
    }) {
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      // Gate input 1 — bus assignment, flagged as isInput (ioFlags=1).
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 0,
          name: 'Gate input 1',
          min: 0,
          max: 28,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 1, // isInput
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 0,
          value: gateInputBus,
        ),
      );

      // Gate 1 CV count — numeric knob, NO ioFlags (the regression condition).
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 1,
          name: 'Gate 1 CV count',
          min: 0,
          max: 11,
          defaultValue: 1,
          unit: 0, // numeric type — not a bus parameter
          powerOfTen: 0,
          ioFlags: 0, // deliberately no ioFlags
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 1,
          value: gateCvCount,
        ),
      );

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'pymu',
          name: 'Poly Multisample',
        ),
        routing: RoutingInfo(
          algorithmIndex: algorithmIndex,
          routingInfo: List.filled(6, 0),
        ),
        // Empty pages → _visibleParameterNumbers falls back to all parameters,
        // matching offline/test fixture behaviour.
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
        parameters: parameters,
        values: values,
        enums: [],
        mappings: [],
        valueStrings: [],
        outputModeMap: {},
      );
    }

    test(
      'connected gate with CV count=1 produces a CV input port on the next bus',
      () {
        final slot = createPolyMultisampleSlot(
          gateInputBus: 3,
          gateCvCount: 1,
        );

        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'pymu_test',
        );

        final inputPorts = routing.inputPorts;

        // Expect a Gate 1 port at bus 3.
        final gatePort = inputPorts.firstWhere(
          (p) => p.name == 'Gate 1',
        );
        expect(gatePort.direction, equals(PortDirection.input));
        expect(gatePort.busValue, equals(3));
        expect(gatePort.isPolyVoice, isTrue);
        expect(gatePort.voiceNumber, equals(1));

        // Expect a CV port (the "virtual pitch input") at bus 4 = gateBus + 1.
        final cvPort = inputPorts.firstWhere(
          (p) => p.name == 'Gate 1 CV1',
        );
        expect(cvPort.direction, equals(PortDirection.input));
        expect(cvPort.busValue, equals(4));
        expect(cvPort.isPolyVoice, isTrue);
        expect(cvPort.voiceNumber, equals(1));
      },
    );

    test('CV count=0 produces no CV input ports after the gate', () {
      final slot = createPolyMultisampleSlot(gateInputBus: 5, gateCvCount: 0);

      final routing = AlgorithmRouting.fromSlot(
        slot,
        algorithmUuid: 'pymu_test',
      );

      final inputPorts = routing.inputPorts;

      // Gate 1 should still be present.
      final gatePort = inputPorts.firstWhere((p) => p.name == 'Gate 1');
      expect(gatePort.busValue, equals(5));

      // No CV ports should be generated.
      final cvPorts = inputPorts.where((p) => p.name.contains('CV'));
      expect(cvPorts, isEmpty);
    });

    test('CV count=2 produces two CV input ports on consecutive busses', () {
      final slot = createPolyMultisampleSlot(
        gateInputBus: 1,
        gateCvCount: 2,
      );

      final routing = AlgorithmRouting.fromSlot(
        slot,
        algorithmUuid: 'pymu_test',
      );

      final inputPorts = routing.inputPorts;

      final cv1 = inputPorts.firstWhere((p) => p.name == 'Gate 1 CV1');
      expect(cv1.busValue, equals(2)); // gateBus(1) + 1

      final cv2 = inputPorts.firstWhere((p) => p.name == 'Gate 1 CV2');
      expect(cv2.busValue, equals(3)); // gateBus(1) + 2
    });

    test(
      'page-prefixed Gate 1 CV count parameter is still read correctly',
      () {
        // Same slot, but parameter names carry a page prefix ("1:Gate 1 CV count"),
        // mirroring what the Disting NT firmware actually sends.
        final parameters = <ParameterInfo>[
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            name: '1:Gate input 1',
            min: 0,
            max: 28,
            defaultValue: 0,
            unit: 1,
            powerOfTen: 0,
            ioFlags: 1,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 1,
            name: '1:Gate 1 CV count',
            min: 0,
            max: 11,
            defaultValue: 1,
            unit: 0,
            powerOfTen: 0,
            ioFlags: 0,
          ),
        ];
        final values = <ParameterValue>[
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 2),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 1),
        ];

        final slot = Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'pymu',
            name: 'Poly Multisample',
          ),
          routing: RoutingInfo(
            algorithmIndex: 0,
            routingInfo: List.filled(6, 0),
          ),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: parameters,
          values: values,
          enums: [],
          mappings: [],
          valueStrings: [],
          outputModeMap: {},
        );

        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'pymu_test',
        );

        final cvPort = routing.inputPorts.firstWhere(
          (p) => p.name == 'Gate 1 CV1',
        );
        // gateBus=2, CV1 on bus 3.
        expect(cvPort.busValue, equals(3));
      },
    );
  });
}
