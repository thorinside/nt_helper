import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/services/algorithm_connection_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/algorithm_connection.dart';

void main() {
  group('Algorithm Connection Service Integration', () {
    group('real slot data scenarios', () {
      late AlgorithmConnectionService realService;

      setUp(() {
        realService = AlgorithmConnectionService();
      });

      test('discovers connections with realistic slot data', () {
        final slots = <Slot>[
          _createRealisticSlot(
            algorithmIndex: 0,
            algorithmName: 'Dual VCO',
            parameters: [
              _createParameter('Left output', 10, value: 13), // Output bus 13
              _createParameter('Right output', 11, value: 14), // Output bus 14
            ],
          ),
          _createRealisticSlot(
            algorithmIndex: 1,
            algorithmName: 'Dual VCF',
            parameters: [
              _createParameter('Left input', 12, value: 13), // Input bus 13 (matches left output)
              _createParameter('Right input', 13, value: 14), // Input bus 14 (matches right output)
              _createParameter('Left output', 14, value: 15), // Output bus 15
            ],
          ),
          _createRealisticSlot(
            algorithmIndex: 2,
            algorithmName: 'Reverb',
            parameters: [
              _createParameter('Audio input', 15, value: 15), // Input bus 15 (matches filter output)
              _createParameter('Audio output', 16, value: 16), // Output bus 16
            ],
          ),
        ];

        final connections = realService.discoverAlgorithmConnections(slots);

        // Expect 3 connections:
        // 1. VCO Left -> VCF Left (bus 13)
        // 2. VCO Right -> VCF Right (bus 14) 
        // 3. VCF -> Reverb (bus 15)
        expect(connections, hasLength(3));

        // Check first connection (VCO Left -> VCF Left)
        final connection1 = connections.firstWhere((c) => c.busNumber == 13);
        expect(connection1.sourceAlgorithmIndex, 0);
        expect(connection1.targetAlgorithmIndex, 1);
        expect(connection1.sourcePortId, 'Left output');
        expect(connection1.targetPortId, 'Left input');
        expect(connection1.connectionType, AlgorithmConnectionType.audioSignal);

        // Verify all connections are valid (no self-connections)
        for (final connection in connections) {
          expect(connection.sourceAlgorithmIndex != connection.targetAlgorithmIndex, true,
              reason: 'Connection ${connection.id} should not be a self-connection');
        }
      });

      test('handles mixed connection types correctly', () {
        final slots = <Slot>[
          _createRealisticSlot(
            algorithmIndex: 0,
            algorithmName: 'LFO',
            parameters: [
              _createParameter('CV output', 10, value: 3), // CV bus 3
              _createParameter('Gate output', 11, value: 8), // Gate bus 8
            ],
          ),
          _createRealisticSlot(
            algorithmIndex: 1,
            algorithmName: 'VCO',
            parameters: [
              _createParameter('CV input', 12, value: 3), // CV bus 3 (matches LFO CV)
              _createParameter('Audio output', 13, value: 13), // Audio bus 13
            ],
          ),
          _createRealisticSlot(
            algorithmIndex: 2,
            algorithmName: 'ADSR',
            parameters: [
              _createParameter('Trigger input', 14, value: 8), // Gate bus 8 (matches LFO Gate)
              _createParameter('CV output', 15, value: 5), // CV bus 5
            ],
          ),
        ];

        final connections = realService.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(2));

        // Find CV connection
        final cvConnection = connections.firstWhere((c) => c.busNumber == 3);
        expect(cvConnection.connectionType, AlgorithmConnectionType.controlVoltage);
        expect(cvConnection.sourceAlgorithmIndex, 0);
        expect(cvConnection.targetAlgorithmIndex, 1);

        // Find gate connection
        final gateConnection = connections.firstWhere((c) => c.busNumber == 8);
        expect(gateConnection.connectionType, AlgorithmConnectionType.gateTrigger);
        expect(gateConnection.sourceAlgorithmIndex, 0);
        expect(gateConnection.targetAlgorithmIndex, 2);
      });

      test('ignores invalid bus assignments', () {
        final slots = <Slot>[
          _createRealisticSlot(
            algorithmIndex: 0,
            algorithmName: 'Test Source',
            parameters: [
              _createParameter('Output 1', 10, value: 0), // Bus 0 (None/Invalid)
              _createParameter('Output 2', 11, value: 30), // Bus 30 (Out of range)
            ],
          ),
          _createRealisticSlot(
            algorithmIndex: 1,
            algorithmName: 'Test Target',
            parameters: [
              _createParameter('Input 1', 12, value: 0), // Bus 0 (None/Invalid)
              _createParameter('Input 2', 13, value: 30), // Bus 30 (Out of range)
            ],
          ),
        ];

        final connections = realService.discoverAlgorithmConnections(slots);

        expect(connections, isEmpty, reason: 'Should ignore invalid bus assignments');
      });
    });
  });
}

/// Helper function to create a realistic slot with parameters
Slot _createRealisticSlot({
  required int algorithmIndex,
  required String algorithmName,
  required List<ParameterInfo> parameters,
}) {
  final values = parameters
      .map((p) => ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: p.parameterNumber,
            value: p.defaultValue,
          ))
      .toList();

  return Slot(
    algorithm: Algorithm(
      algorithmIndex: algorithmIndex,
      guid: 'realistic-guid-$algorithmIndex',
      name: algorithmName,
    ),
    routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
    parameters: parameters,
    values: values,
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}

/// Helper function to create a parameter
ParameterInfo _createParameter(
  String name,
  int parameterNumber, {
  int value = 0,
  int min = 0,
  int max = 28,
}) {
  return ParameterInfo(
    algorithmIndex: 0,
    parameterNumber: parameterNumber,
    min: min,
    max: max,
    defaultValue: value,
    unit: 0,
    name: name,
    powerOfTen: 0,
  );
}

// Mock classes that might be needed
class MockIDistingMidiManager {}