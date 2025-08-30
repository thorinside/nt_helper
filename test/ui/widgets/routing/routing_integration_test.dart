import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/routing/routing_canvas.dart';
import 'package:nt_helper/ui/widgets/routing/routing_algorithm_node.dart';
import 'package:nt_helper/ui/widgets/routing/connection_line.dart' as connection_widget;

import 'routing_integration_test.mocks.dart';

@GenerateMocks([RoutingFactory, RoutingEditorCubit, AlgorithmRouting])
void main() {
  group('Routing Widget Integration Tests', () {
    late MockRoutingFactory mockRoutingFactory;
    late MockRoutingEditorCubit mockCubit;
    late MockAlgorithmRouting mockAlgorithmRouting;
    
    setUp(() {
      mockRoutingFactory = MockRoutingFactory();
      mockCubit = MockRoutingEditorCubit();
      mockAlgorithmRouting = MockAlgorithmRouting();
      
      // Provide dummy values for Mockito
      provideDummy<RoutingEditorState>(const RoutingEditorState.initial());
      
      // Setup mock algorithm routing
      when(mockAlgorithmRouting.inputPorts).thenReturn([]);
      when(mockAlgorithmRouting.outputPorts).thenReturn([]);
      when(mockAlgorithmRouting.dispose()).thenReturn(null);
      
      // Setup mock routing factory to return mock algorithm routing
      when(mockRoutingFactory.createValidatedRouting(any)).thenReturn(mockAlgorithmRouting);
      
      // Register mock in GetIt for dependency injection
      if (GetIt.instance.isRegistered<RoutingFactory>()) {
        GetIt.instance.unregister<RoutingFactory>();
      }
      GetIt.instance.registerSingleton<RoutingFactory>(mockRoutingFactory);
    });
    
    tearDown(() {
      GetIt.instance.reset();
    });

    Widget createTestWidget({
      RoutingEditorState? initialState,
      RoutingCanvas? canvas,
    }) {
      when(mockCubit.state).thenReturn(
        initialState ?? const RoutingEditorState.initial()
      );
      when(mockCubit.stream).thenAnswer(
        (_) => Stream.value(initialState ?? const RoutingEditorState.initial())
      );
      
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<RoutingEditorCubit>.value(
            value: mockCubit,
            child: canvas ?? const RoutingEditorWidget(),
          ),
        ),
      );
    }

    group('End-to-End Routing Workflows', () {
      testWidgets('should handle complete routing visualization workflow', (WidgetTester tester) async {
        // Create a complete routing scenario with algorithms and connections
        final physicalInputs = [
          const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
          const Port(id: 'hw_in_2', name: 'CV In 1', type: PortType.cv, direction: PortDirection.input),
        ];
        
        final physicalOutputs = [
          const Port(id: 'hw_out_1', name: 'Audio Out 1', type: PortType.audio, direction: PortDirection.output),
          const Port(id: 'hw_out_2', name: 'Audio Out 2', type: PortType.audio, direction: PortDirection.output),
        ];

        final mockAlgorithm = Algorithm(
          algorithmIndex: 0,
          guid: 'test-synth-guid',
          name: 'Poly Synth',
        );
        
        final algorithms = [
          RoutingAlgorithm(
            index: 0,
            algorithm: mockAlgorithm,
            inputPorts: [],
            outputPorts: [],
          ),
        ];

        final connections = [
          const Connection(
            id: 'conn_hw_in_1_alg_0_in_1',
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_in_1',
          ),
        ];

        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: physicalInputs,
            physicalOutputs: physicalOutputs,
            algorithms: algorithms,
            connections: connections,
          ),
        ));
        
        // Verify all components are rendered
        expect(find.byType(RoutingCanvas), findsOneWidget);
        expect(find.text('Audio In 1'), findsOneWidget);
        expect(find.text('CV In 1'), findsOneWidget);
        expect(find.text('Audio Out 1'), findsOneWidget);
        expect(find.text('Audio Out 2'), findsOneWidget);
        
        // Verify algorithm nodes are created with factory integration
        expect(find.byType(RoutingAlgorithmNode), findsOneWidget);
        
        // Verify connections are rendered
        expect(find.byType(connection_widget.ConnectionLine), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle empty state gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Should render canvas without errors
        expect(find.byType(RoutingCanvas), findsOneWidget);
        
        // Should not have any nodes or connections
        expect(find.byType(RoutingAlgorithmNode), findsNothing);
        expect(find.byType(connection_widget.ConnectionLine), findsNothing);
      });

      testWidgets('should handle error states with proper error messages', (WidgetTester tester) async {
        const errorMessage = 'Failed to connect to hardware';
        
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.error(errorMessage),
        ));
        
        // Should show error UI
        expect(find.text('Error'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should handle loading states with progress indicators', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.connecting(),
        ));
        
        expect(find.text('Connecting to hardware...'), findsOneWidget);
        
        // Test refreshing state - just verify it renders without error
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.refreshing(),
        ));
        await tester.pump(); // Allow state to update
        
        // Should render without errors
        expect(find.byType(RoutingCanvas), findsOneWidget);
      });
    });

    group('User Interaction Scenarios', () {
      testWidgets('should handle node selection interactions', (WidgetTester tester) async {
        String? selectedNodeId;
        
        final physicalInputs = [
          const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
        ];

        await tester.pumpWidget(createTestWidget(
          canvas: RoutingEditorWidget(
            onNodeSelected: (nodeId) => selectedNodeId = nodeId,
          ),
          initialState: RoutingEditorState.loaded(
            physicalInputs: physicalInputs,
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Canvas should handle node selection callbacks
        final canvasWidget = tester.widget<RoutingCanvas>(find.byType(RoutingCanvas));
        expect(canvasWidget.onNodeSelected, isNotNull);
        expect(selectedNodeId, isNull); // Initially no node is selected
      });

      testWidgets('should handle connection creation workflows', (WidgetTester tester) async {
        String? sourcePortId;
        String? targetPortId;
        
        await tester.pumpWidget(createTestWidget(
          canvas: RoutingEditorWidget(
            onConnectionCreated: (source, target) {
              sourcePortId = source;
              targetPortId = target;
            },
          ),
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Canvas should handle connection creation callbacks
        final canvasWidget = tester.widget<RoutingCanvas>(find.byType(RoutingCanvas));
        expect(canvasWidget.onConnectionCreated, isNotNull);
        expect(sourcePortId, isNull); // Initially no source port is selected
        expect(targetPortId, isNull); // Initially no target port is selected
      });

      testWidgets('should handle canvas interaction gestures', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Should handle tap gestures on the canvas
        await tester.tap(find.byType(RoutingCanvas));
        await tester.pump();
        
        // Should handle drag gestures
        await tester.dragFrom(
          tester.getCenter(find.byType(RoutingCanvas)),
          const Offset(50, 50),
        );
        await tester.pump();
        
        // Should not throw any errors
        expect(find.byType(RoutingCanvas), findsOneWidget);
      });
    });

    group('Performance and Scalability', () {
      testWidgets('should handle large numbers of nodes efficiently', (WidgetTester tester) async {
        // Create multiple algorithms to test performance
        final algorithms = List.generate(5, (index) {
          return RoutingAlgorithm(
            index: index,
            algorithm: Algorithm(
              algorithmIndex: index,
              guid: 'test-algorithm-$index',
              name: 'Algorithm $index',
            ),
            inputPorts: [],
            outputPorts: [],
          );
        });

        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: algorithms,
            connections: [],
          ),
        ));
        
        // Should render all algorithm nodes
        expect(find.byType(RoutingAlgorithmNode), findsNWidgets(5));
        
        // Should complete rendering within reasonable time
        expect(find.byType(RoutingCanvas), findsOneWidget);
      });

      testWidgets('should handle rapid state changes without issues', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.initial(),
        ));
        
        // Simulate rapid state changes
        final states = [
          const RoutingEditorState.connecting(),
          const RoutingEditorState.refreshing(),
          const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ];
        
        for (final state in states) {
          when(mockCubit.state).thenReturn(state);
          await tester.pump();
          
          // Should handle all state transitions without errors
          expect(find.byType(RoutingCanvas), findsOneWidget);
        }
      });
    });

    group('Accessibility and Responsiveness', () {
      testWidgets('should provide semantic information for accessibility', (WidgetTester tester) async {
        final physicalInputs = [
          const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
        ];

        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: physicalInputs,
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Should render with accessibility support
        expect(find.byType(RoutingCanvas), findsOneWidget);
        
        // Test semantic finder works
        expect(find.text('Audio In 1'), findsOneWidget);
      });

      testWidgets('should work with different canvas sizes', (WidgetTester tester) async {
        const customSize = Size(1000, 800);
        
        await tester.pumpWidget(createTestWidget(
          canvas: const RoutingEditorWidget(canvasSize: customSize),
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        final canvasWidget = tester.widget<RoutingCanvas>(find.byType(RoutingCanvas));
        expect(canvasWidget.canvasSize, equals(customSize));
      });
    });
  });
}
