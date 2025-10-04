import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
class MockDistingCubit extends Mock implements DistingCubit {}

class MockNodeLayoutAlgorithm extends Mock implements NodeLayoutAlgorithm {}

void main() {
  group('RoutingEditorCubit Layout Integration', () {
    late RoutingEditorCubit cubit;
    late MockDistingCubit mockDistingCubit;
    late MockNodeLayoutAlgorithm mockLayoutAlgorithm;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      mockDistingCubit = MockDistingCubit();
      mockLayoutAlgorithm = MockNodeLayoutAlgorithm();

      // Set up mock stream
      when(
        () => mockDistingCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => mockDistingCubit.state,
      ).thenReturn(const DistingState.initial());

      cubit = RoutingEditorCubit(mockDistingCubit);

      // Inject the layout algorithm service
      cubit.injectLayoutAlgorithm(mockLayoutAlgorithm);
    });

    tearDown(() {
      cubit.close();
    });

    group('applyLayoutAlgorithm', () {
      test('does nothing when routing editor not loaded', () async {
        // Initial state - not loaded
        expect(cubit.state, isA<RoutingEditorStateInitial>());

        await cubit.applyLayoutAlgorithm();

        // Should still be in initial state
        expect(cubit.state, isA<RoutingEditorStateInitial>());

        // Layout algorithm should not have been called
        verifyNever(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        );
      });

      test('applies layout algorithm when routing editor is loaded', () async {
        // Set up a loaded state
        final physicalInputs = [
          const Port(
            id: 'hw_in_1',
            name: 'I1',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        ];

        final physicalOutputs = [
          const Port(
            id: 'hw_out_1',
            name: 'O1',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
        ];

        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [
              Port(
                id: 'algo_0_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_0_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        ];

        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'algo_0_in',
            connectionType: ConnectionType.hardwareInput,
          ),
        ];

        final loadedState = RoutingEditorState.loaded(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          algorithms: algorithms,
          connections: connections,
        );

        // Emit the loaded state
        cubit.emit(loadedState);

        // Mock the layout algorithm result
        final layoutResult = LayoutResult(
          physicalInputPositions: {
            'hw_in_1': const NodePosition(x: 50.0, y: 100.0),
          },
          physicalOutputPositions: {
            'hw_out_1': const NodePosition(x: 750.0, y: 100.0),
          },
          es5InputPositions: {},
          algorithmPositions: {
            'algo_0': const NodePosition(x: 400.0, y: 100.0),
          },
          reducedOverlaps: [],
          totalOverlapReduction: 0.5,
        );

        when(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        ).thenReturn(layoutResult);

        await cubit.applyLayoutAlgorithm();

        // Verify layout algorithm was called with correct parameters
        verify(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: physicalInputs,
            physicalOutputs: physicalOutputs,
            algorithms: algorithms,
            connections: connections,
          ),
        ).called(1);

        // Verify state was updated with new positions
        final newState = cubit.state as RoutingEditorStateLoaded;
        expect(newState.nodePositions, isNotEmpty);
        expect(
          newState.nodePositions['hw_in_1'],
          equals(const NodePosition(x: 50.0, y: 100.0)),
        );
        expect(
          newState.nodePositions['hw_out_1'],
          equals(const NodePosition(x: 750.0, y: 100.0)),
        );
        expect(
          newState.nodePositions['algo_0'],
          equals(const NodePosition(x: 400.0, y: 100.0)),
        );
      });

      test('handles layout calculation errors gracefully', () async {
        // Set up a loaded state
        final loadedState = RoutingEditorState.loaded(
          physicalInputs: const [
            Port(
              id: 'hw_in_1',
              name: 'I1',
              type: PortType.cv,
              direction: PortDirection.output,
            ),
          ],
          physicalOutputs: const [],
          algorithms: const [],
          connections: const [],
        );

        cubit.emit(loadedState);

        // Mock the layout algorithm to throw an exception
        when(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        ).thenThrow(Exception('Layout calculation failed'));

        await cubit.applyLayoutAlgorithm();

        // Verify state indicates an error occurred
        final newState = cubit.state as RoutingEditorStateLoaded;
        expect(newState.lastError, contains('Layout calculation failed'));
        expect(newState.subState, equals(SubState.error));
      });

      test('applies layout and updates state correctly', () async {
        // Set up a loaded state
        final loadedState = RoutingEditorState.loaded(
          physicalInputs: const [
            Port(
              id: 'hw_in_1',
              name: 'I1',
              type: PortType.cv,
              direction: PortDirection.output,
            ),
          ],
          physicalOutputs: const [],
          algorithms: const [],
          connections: const [],
        );

        cubit.emit(loadedState);

        final layoutResult = LayoutResult(
          physicalInputPositions: {
            'hw_in_1': const NodePosition(x: 50.0, y: 100.0),
          },
          physicalOutputPositions: {},
          es5InputPositions: {},
          algorithmPositions: {},
          reducedOverlaps: [],
          totalOverlapReduction: 0.0,
        );

        when(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        ).thenReturn(layoutResult);

        await cubit.applyLayoutAlgorithm();

        // Verify final state
        final finalState = cubit.state as RoutingEditorStateLoaded;
        expect(finalState.subState, equals(SubState.idle));
        expect(finalState.nodePositions, isNotEmpty);
        expect(
          finalState.nodePositions['hw_in_1'],
          equals(const NodePosition(x: 50.0, y: 100.0)),
        );
      });
    });

    group('layout algorithm service injection', () {
      test('allows injection of layout algorithm service', () {
        final newCubit = RoutingEditorCubit(mockDistingCubit);
        final newLayoutAlgorithm = MockNodeLayoutAlgorithm();

        expect(
          () => newCubit.injectLayoutAlgorithm(newLayoutAlgorithm),
          returnsNormally,
        );

        newCubit.close();
      });

      test('prevents multiple injections of layout algorithm service', () {
        final newCubit = RoutingEditorCubit(mockDistingCubit);
        final layoutAlgorithm1 = MockNodeLayoutAlgorithm();
        final layoutAlgorithm2 = MockNodeLayoutAlgorithm();

        newCubit.injectLayoutAlgorithm(layoutAlgorithm1);

        expect(
          () => newCubit.injectLayoutAlgorithm(layoutAlgorithm2),
          throwsA(isA<StateError>()),
        );

        newCubit.close();
      });
    });

    group('node positions state management', () {
      test(
        'preserves existing node positions when not applying layout',
        () async {
          // Set up a loaded state with existing positions
          final initialPositions = {
            'algo_0': const NodePosition(x: 200.0, y: 150.0),
            'hw_in_1': const NodePosition(x: 100.0, y: 100.0),
          };

          final loadedState = RoutingEditorState.loaded(
            physicalInputs: const [
              Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
            physicalOutputs: const [],
            algorithms: const [],
            connections: const [],
            nodePositions: initialPositions,
          );

          cubit.emit(loadedState);

          // Positions should be preserved
          final state = cubit.state as RoutingEditorStateLoaded;
          expect(state.nodePositions, equals(initialPositions));
        },
      );

      test('updates only algorithm positions when applying layout', () async {
        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [],
            outputPorts: const [],
          ),
        ];

        // Set up initial state with some positions
        final initialPositions = {
          'algo_0': const NodePosition(x: 200.0, y: 150.0),
          'hw_in_1': const NodePosition(x: 100.0, y: 100.0),
          'custom_node': const NodePosition(
            x: 300.0,
            y: 200.0,
          ), // Non-algorithm node
        };

        final loadedState = RoutingEditorState.loaded(
          physicalInputs: const [
            Port(
              id: 'hw_in_1',
              name: 'I1',
              type: PortType.cv,
              direction: PortDirection.output,
            ),
          ],
          physicalOutputs: const [],
          algorithms: algorithms,
          connections: const [],
          nodePositions: initialPositions,
        );

        cubit.emit(loadedState);

        // Mock layout result with new algorithm position
        final layoutResult = LayoutResult(
          physicalInputPositions: {
            'hw_in_1': const NodePosition(x: 50.0, y: 120.0),
          },
          physicalOutputPositions: {},
          es5InputPositions: {},
          algorithmPositions: {
            'algo_0': const NodePosition(x: 400.0, y: 180.0),
          },
          reducedOverlaps: [],
          totalOverlapReduction: 0.3,
        );

        when(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        ).thenReturn(layoutResult);

        await cubit.applyLayoutAlgorithm();

        final updatedState = cubit.state as RoutingEditorStateLoaded;

        // Algorithm and physical positions should be updated from layout result
        expect(
          updatedState.nodePositions['algo_0'],
          equals(const NodePosition(x: 400.0, y: 180.0)),
        );
        expect(
          updatedState.nodePositions['hw_in_1'],
          equals(const NodePosition(x: 50.0, y: 120.0)),
        );

        // Custom node position should be preserved (not managed by layout algorithm)
        expect(
          updatedState.nodePositions['custom_node'],
          equals(const NodePosition(x: 300.0, y: 200.0)),
        );
      });

      test('positions ES-5 input node when present', () async {
        final physicalInputPorts = <Port>[
          const Port(
            id: 'hw_in_1',
            name: 'Input 1',
            direction: PortDirection.input,
            type: PortType.audio,
          ),
        ];

        final physicalOutputPorts = <Port>[
          const Port(
            id: 'hw_out_1',
            name: 'Output 1',
            direction: PortDirection.output,
            type: PortType.audio,
          ),
        ];

        final es5InputPorts = <Port>[
          const Port(
            id: 'es5_in_1',
            name: 'ES-5 In 1',
            direction: PortDirection.input,
            type: PortType.cv,
          ),
        ];

        final algorithmPorts = <Port>[
          const Port(
            id: 'algo_0_in_1',
            name: 'Algo Input',
            direction: PortDirection.input,
            type: PortType.audio,
          ),
        ];

        final loadedState = RoutingEditorStateLoaded(
          physicalInputs: physicalInputPorts,
          physicalOutputs: physicalOutputPorts,
          es5Inputs: es5InputPorts,
          algorithms: [
            RoutingAlgorithm(
              id: 'algo_0',
              index: 0,
              algorithm: Algorithm(
                algorithmIndex: 0,
                guid: 'test-guid',
                name: 'Test Algorithm',
              ),
              inputPorts: algorithmPorts,
              outputPorts: [],
            ),
          ],
          connections: [],
        );

        cubit.emit(loadedState);

        // Mock layout result with ES-5 position
        final layoutResult = LayoutResult(
          physicalInputPositions: {
            'hw_in_1': const NodePosition(x: 50.0, y: 100.0),
          },
          physicalOutputPositions: {
            'hw_out_1': const NodePosition(x: 750.0, y: 100.0),
          },
          es5InputPositions: {
            'es5_node': const NodePosition(x: 50.0, y: 500.0),
          },
          algorithmPositions: {
            'algo_0': const NodePosition(x: 400.0, y: 100.0),
          },
          reducedOverlaps: [],
          totalOverlapReduction: 0.0,
        );

        when(
          () => mockLayoutAlgorithm.calculateLayout(
            physicalInputs: any(named: 'physicalInputs'),
            physicalOutputs: any(named: 'physicalOutputs'),
            es5Inputs: any(named: 'es5Inputs'),
            algorithms: any(named: 'algorithms'),
            connections: any(named: 'connections'),
          ),
        ).thenReturn(layoutResult);

        await cubit.applyLayoutAlgorithm();

        final updatedState = cubit.state as RoutingEditorStateLoaded;

        // Verify ES-5 node position was applied
        expect(
          updatedState.nodePositions['es5_node'],
          equals(const NodePosition(x: 50.0, y: 500.0)),
        );

        // Verify other positions were also applied
        expect(
          updatedState.nodePositions['hw_in_1'],
          equals(const NodePosition(x: 50.0, y: 100.0)),
        );
        expect(
          updatedState.nodePositions['algo_0'],
          equals(const NodePosition(x: 400.0, y: 100.0)),
        );
      });
    });
  });
}
