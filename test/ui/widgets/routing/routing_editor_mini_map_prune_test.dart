import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart' as state;
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/mini_map_widget.dart';

// Reuse existing mocks from the main widget test
import 'routing_editor_widget_test.mocks.dart';

void main() {
  group('MiniMap node pruning on routing structure change', () {
    setUpAll(() {
      // Provide a default dummy for mockito to construct mock streams/state
      provideDummy<state.RoutingEditorState>(
        const state.RoutingEditorStateInitial(),
      );
      provideDummy<DistingState>(const DistingState.initial());
    });
    late MockRoutingEditorCubit mockRoutingCubit;
    late MockDistingCubit mockDistingCubit;
    late StreamController<state.RoutingEditorState> controller;

    setUp(() {
      mockRoutingCubit = MockRoutingEditorCubit();
      mockDistingCubit = MockDistingCubit();
      controller = StreamController<state.RoutingEditorState>.broadcast();
    });

    tearDown(() async {
      await controller.close();
    });

    testWidgets('old algorithm nodes are removed and new ones initialized', (
      tester,
    ) async {
      // Build two routing states with different algorithm IDs
      final algo1 = state.RoutingAlgorithm(
        id: 'algo_1',
        index: 0,
        algorithm: Algorithm(algorithmIndex: 0, guid: 'g1', name: 'A1'),
        inputPorts: const [],
        outputPorts: const [],
      );
      final algo2 = state.RoutingAlgorithm(
        id: 'algo_2',
        index: 1,
        algorithm: Algorithm(algorithmIndex: 1, guid: 'g2', name: 'A2'),
        inputPorts: const [],
        outputPorts: const [],
      );
      final algo3 = state.RoutingAlgorithm(
        id: 'algo_3',
        index: 0,
        algorithm: Algorithm(algorithmIndex: 0, guid: 'g3', name: 'A3'),
        inputPorts: const [],
        outputPorts: const [],
      );

      state.RoutingEditorState currentState = state.RoutingEditorStateLoaded(
        physicalInputs: const [
          Port(id: 'hw_in_1', name: 'I1', type: PortType.cv, direction: PortDirection.output),
        ],
        physicalOutputs: const [
          Port(id: 'hw_out_1', name: 'O1', type: PortType.audio, direction: PortDirection.input),
        ],
        algorithms: [algo1, algo2],
        connections: const [],
        buses: const [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );

      // Stub cubit getters/stream
      when(mockRoutingCubit.stream).thenAnswer((_) => controller.stream);
      when(mockRoutingCubit.state).thenAnswer((_) => currentState);

      // Disting cubit can be minimal; widget won’t use it for this test path
      when(mockDistingCubit.stream).thenAnswer((_) => const Stream.empty());
      when(mockDistingCubit.state).thenReturn(const DistingState.initial());

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
            ],
            child: RoutingEditorWidget(canvasSize: const Size(800, 600)),
          ),
        ),
      );

      // Emit first state (algo_1, algo_2) and settle
      controller.add(currentState);
      await tester.pumpAndSettle();

      // Read minimap’s nodePositions via the widget instance
      final miniMap = tester.widget<MiniMapWidget>(find.byType(MiniMapWidget));
      final positions1 = miniMap.nodePositions!;
      expect(positions1.keys, containsAll(['physical_inputs', 'physical_outputs', 'algo_1', 'algo_2']));

      // Now change routing structure: only algo_3
      currentState = state.RoutingEditorStateLoaded(
        physicalInputs: const [
          Port(id: 'hw_in_1', name: 'I1', type: PortType.cv, direction: PortDirection.output),
        ],
        physicalOutputs: const [
          Port(id: 'hw_out_1', name: 'O1', type: PortType.audio, direction: PortDirection.input),
        ],
        algorithms: [algo3],
        connections: const [],
        buses: const [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );
      // Update mock getter to return the new currentState
      when(mockRoutingCubit.state).thenAnswer((_) => currentState);

      controller.add(currentState);
      await tester.pumpAndSettle();

      // Grab latest minimap widget and assert stale nodes were pruned
      final miniMap2 = tester.widget<MiniMapWidget>(find.byType(MiniMapWidget));
      final positions2 = miniMap2.nodePositions!;
      expect(positions2.keys, containsAll(['physical_inputs', 'physical_outputs', 'algo_3']));
      expect(positions2.keys, isNot(contains('algo_1')));
      expect(positions2.keys, isNot(contains('algo_2')));
    });
  });
}
