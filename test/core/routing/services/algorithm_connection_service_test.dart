import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/services/algorithm_connection_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/algorithm_connection.dart';

void main() {
  group('AlgorithmConnectionService', () {
    late AlgorithmConnectionService service;

    setUp(() {
      service = AlgorithmConnectionService();
    });

    group('initialization', () {
      test('creates service instance', () {
        expect(service, isA<AlgorithmConnectionService>());
      });

      test('starts with empty cache', () {
        final connections = service.discoverAlgorithmConnections([]);
        expect(connections, isEmpty);
      });
    });

    group('basic connection discovery', () {
      test('discovers connection between two slots sharing same bus', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            algorithmName: 'Oscillator',
            parameters: [
              _createParameter('Main output', 13, value: 5), // Bus 5
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            algorithmName: 'Filter',
            parameters: [
              _createParameter('Audio input', 14, value: 5), // Bus 5
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.sourceAlgorithmIndex, 0);
        expect(connections.first.targetAlgorithmIndex, 1);
        expect(connections.first.sourcePortId, 'Main output');
        expect(connections.first.targetPortId, 'Audio input');
        expect(connections.first.busNumber, 5);
        expect(connections.first.connectionType, AlgorithmConnectionType.audioSignal);
      });

      test('does not create connections for different bus numbers', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            algorithmName: 'Oscillator',
            parameters: [
              _createParameter('Main output', 13, value: 5), // Bus 5
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            algorithmName: 'Filter',
            parameters: [
              _createParameter('Audio input', 14, value: 7), // Bus 7 (different)
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, isEmpty);
      });

      test('does not create self-connections', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            algorithmName: 'Oscillator',
            parameters: [
              _createParameter('Main output', 13, value: 5),
              _createParameter('Audio input', 14, value: 5), // Same bus
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, isEmpty);
      });

      test('ignores invalid bus numbers (outside 1-28 range)', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            algorithmName: 'Oscillator',
            parameters: [
              _createParameter('Main output', 13, value: 0), // Bus 0 (invalid)
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            algorithmName: 'Filter',
            parameters: [
              _createParameter('Audio input', 14, value: 0), // Bus 0 (invalid)
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, isEmpty);
      });

      test('ignores bus numbers above maximum (>28)', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            algorithmName: 'Oscillator',
            parameters: [
              _createParameter('Main output', 13, value: 30), // Bus 30 (invalid)
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            algorithmName: 'Filter',
            parameters: [
              _createParameter('Audio input', 14, value: 30), // Bus 30 (invalid)
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, isEmpty);
      });
    });

    group('connection type inference', () {
      test('infers CV connections from parameter names', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('CV output', 13, value: 3),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('CV input', 14, value: 3),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.connectionType, AlgorithmConnectionType.controlVoltage);
      });

      test('infers gate connections from parameter names', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Gate output', 13, value: 8),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Trigger input', 14, value: 8),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.connectionType, AlgorithmConnectionType.gateTrigger);
      });

      test('infers clock connections from parameter names', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Clock output', 13, value: 12),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Clock input', 14, value: 12),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.connectionType, AlgorithmConnectionType.clockTiming);
      });

      test('infers audio connections from parameter names', () {
        final testCases = [
          ('Main output', 'Audio input'),
          ('Left output', 'Wave input'),
          ('Right output', 'Audio input'),
        ];

        for (final (sourceParam, targetParam) in testCases) {
          final slots = [
            _createTestSlot(
              algorithmIndex: 0,
              parameters: [_createParameter(sourceParam, 13, value: 15)],
            ),
            _createTestSlot(
              algorithmIndex: 1,
              parameters: [_createParameter(targetParam, 14, value: 15)],
            ),
          ];

          final connections = service.discoverAlgorithmConnections(slots);

          expect(connections, hasLength(1), reason: 'Failed for $sourceParam -> $targetParam');
          expect(connections.first.connectionType, AlgorithmConnectionType.audioSignal,
              reason: 'Wrong type for $sourceParam -> $targetParam');
        }
      });

      test('defaults to mixed type for unclear parameter names', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Unknown output', 13, value: 20),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Mystery input', 14, value: 20),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.connectionType, AlgorithmConnectionType.mixed);
      });
    });

    group('multiple connections', () {
      test('discovers multiple connections between different slot pairs', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 5),
              _createParameter('CV output', 14, value: 3),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Audio input', 15, value: 5),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 2,
            parameters: [
              _createParameter('CV input', 16, value: 3),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(2));

        // Find audio connection (0 -> 1)
        final audioConnection = connections.firstWhere(
          (c) => c.connectionType == AlgorithmConnectionType.audioSignal,
        );
        expect(audioConnection.sourceAlgorithmIndex, 0);
        expect(audioConnection.targetAlgorithmIndex, 1);
        expect(audioConnection.busNumber, 5);

        // Find CV connection (0 -> 2)
        final cvConnection = connections.firstWhere(
          (c) => c.connectionType == AlgorithmConnectionType.controlVoltage,
        );
        expect(cvConnection.sourceAlgorithmIndex, 0);
        expect(cvConnection.targetAlgorithmIndex, 2);
        expect(cvConnection.busNumber, 3);
      });

      test('discovers multiple connections sharing same bus', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 10),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Audio input', 14, value: 10), // Same bus
            ],
          ),
          _createTestSlot(
            algorithmIndex: 2,
            parameters: [
              _createParameter('Wave input', 15, value: 10), // Same bus
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(2));
        expect(connections[0].busNumber, 10);
        expect(connections[1].busNumber, 10);

        // Both should be from algorithm 0 to different targets
        expect(connections.every((c) => c.sourceAlgorithmIndex == 0), true);
        final targets = connections.map((c) => c.targetAlgorithmIndex).toSet();
        expect(targets, {1, 2});
      });
    });

    group('deterministic sorting', () {
      test('sorts connections deterministically by source, target, bus, and ID', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 2,
            parameters: [
              _createParameter('Audio output', 13, value: 15),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 14, value: 10),
              _createParameter('CV output', 15, value: 5),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Audio input', 16, value: 10),
              _createParameter('CV input', 17, value: 5),
              _createParameter('Wave input', 18, value: 15),
            ],
          ),
        ];

        final connections1 = service.discoverAlgorithmConnections(slots);
        service.clearCache();
        final connections2 = service.discoverAlgorithmConnections(slots);

        // Results should be identical and deterministic
        expect(connections1, hasLength(connections2.length));
        for (int i = 0; i < connections1.length; i++) {
          expect(connections1[i].id, connections2[i].id);
        }

        // Should be sorted by source algorithm index first
        for (int i = 1; i < connections1.length; i++) {
          expect(
            connections1[i - 1].sourceAlgorithmIndex <= connections1[i].sourceAlgorithmIndex,
            true,
            reason: 'Connections not sorted by source algorithm index',
          );
        }
      });
    });

    group('connection discovery for all valid directions', () {
      test('creates connections in both directions via bus system', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 2, // Higher index
            parameters: [
              _createParameter('Audio output', 13, value: 7),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 0, // Lower index
            parameters: [
              _createParameter('Audio input', 14, value: 7),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        // Should create one connection: Algorithm 2 output → Algorithm 0 input
        expect(connections, hasLength(1));
        expect(connections.first.sourceAlgorithmIndex, 2);
        expect(connections.first.targetAlgorithmIndex, 0);
      });

      test('creates connections from earlier to later slots', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0, // Lower index (runs earlier)
            parameters: [
              _createParameter('Audio output', 13, value: 7),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 2, // Higher index (runs later)
            parameters: [
              _createParameter('Audio input', 14, value: 7),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(1));
        expect(connections.first.sourceAlgorithmIndex, 0);
        expect(connections.first.targetAlgorithmIndex, 2);
      });
    });

    group('caching behavior', () {
      test('caches results and returns cached result for same slots', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 12),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Audio input', 14, value: 12),
            ],
          ),
        ];

        // First call should discover and cache
        final connections1 = service.discoverAlgorithmConnections(slots);
        expect(connections1, hasLength(1));

        // Second call should return cached result (same object references)
        final connections2 = service.discoverAlgorithmConnections(slots);
        expect(identical(connections1, connections2), true);
      });

      test('recalculates when slots change', () {
        final slots1 = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 12),
            ],
          ),
        ];

        final slots2 = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 15), // Different value
            ],
          ),
        ];

        final connections1 = service.discoverAlgorithmConnections(slots1);
        final connections2 = service.discoverAlgorithmConnections(slots2);

        // Should not be the same object (cache invalidated)
        expect(identical(connections1, connections2), false);
      });

      test('clearCache forces recalculation', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 12),
            ],
          ),
        ];

        final connections1 = service.discoverAlgorithmConnections(slots);
        service.clearCache();
        final connections2 = service.discoverAlgorithmConnections(slots);

        // Should not be the same object after cache clear
        expect(identical(connections1, connections2), false);
        // But should have same content
        expect(connections1.length, connections2.length);
      });
    });

    group('edge cases', () {
      test('handles empty slot list', () {
        final connections = service.discoverAlgorithmConnections([]);
        expect(connections, isEmpty);
      });

      test('handles slot with no parameters', () {
        final slots = [
          _createTestSlot(algorithmIndex: 0, parameters: []),
          _createTestSlot(algorithmIndex: 1, parameters: []),
        ];

        final connections = service.discoverAlgorithmConnections(slots);
        expect(connections, isEmpty);
      });

      test('handles slots with only input or only output parameters', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 8),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('CV output', 14, value: 8), // Only outputs
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);
        expect(connections, isEmpty);
      });

      test('generates unique IDs for connections', () {
        final slots = [
          _createTestSlot(
            algorithmIndex: 0,
            parameters: [
              _createParameter('Audio output', 13, value: 20),
              _createParameter('CV output', 14, value: 21),
            ],
          ),
          _createTestSlot(
            algorithmIndex: 1,
            parameters: [
              _createParameter('Audio input', 15, value: 20),
              _createParameter('CV input', 16, value: 21),
            ],
          ),
        ];

        final connections = service.discoverAlgorithmConnections(slots);

        expect(connections, hasLength(2));
        expect(connections[0].id, isNot(equals(connections[1].id)));
        expect(connections.map((c) => c.id).toSet(), hasLength(2));
      });
    });

    group('error handling', () {
      test('handles invalid parameter structures gracefully', () {
        // Create slot with mismatched parameter numbers and values
        final slot = Slot(
          algorithm: Algorithm(algorithmIndex: 0, guid: 'test-guid', name: 'Test'),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: List.filled(6, 0)),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 10,
              min: 0,
              max: 28,
              defaultValue: 0,
              unit: 0,
              name: 'Audio output',
              powerOfTen: 0,
            ),
          ],
          values: [], // No values - should use default
          enums: [],
          mappings: [],
          valueStrings: [],
        );

        expect(() => service.discoverAlgorithmConnections([slot]), returnsNormally);
      });
    });
  });
}

/// Helper function to create a test slot with specified parameters.
Slot _createTestSlot({
  required int algorithmIndex,
  String algorithmName = 'Test Algorithm',
  required List<ParameterInfo> parameters,
}) {
  // Create parameter values for all parameters
  final values = parameters.map((p) => 
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.parameterNumber,
      value: p.defaultValue,
    ),
  ).toList();

  return Slot(
    algorithm: Algorithm(algorithmIndex: algorithmIndex, guid: 'test-guid', name: algorithmName),
    routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
    parameters: parameters,
    values: values,
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}

/// Helper function to create a test parameter.
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