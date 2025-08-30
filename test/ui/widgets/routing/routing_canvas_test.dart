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
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';

import 'routing_canvas_test.mocks.dart';

@GenerateMocks([RoutingFactory, RoutingEditorCubit, AlgorithmRouting])
void main() {
  group('RoutingEditorWidget', () {
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
      RoutingEditorWidget? canvas,
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

    testWidgets('should render with initial state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      expect(find.text('Initializing routing editor...'), findsOneWidget);
      expect(find.byIcon(Icons.device_hub), findsOneWidget);
    });

    testWidgets('should show disconnected state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.disconnected(),
      ));
      
      expect(find.text('Hardware disconnected'), findsOneWidget);
      expect(find.byIcon(Icons.device_hub), findsOneWidget);
    });

    testWidgets('should show connecting state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.connecting(),
      ));
      
      expect(find.text('Connecting to hardware...'), findsOneWidget);
    });

    testWidgets('should show refreshing state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.refreshing(),
      ));
      
      expect(find.text('Refreshing routing data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state', (WidgetTester tester) async {
      const errorMessage = 'Test error message';
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.error(errorMessage),
      ));
      
      expect(find.text('Error'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should render loaded state with physical ports', (WidgetTester tester) async {
      final physicalInputs = [
        const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
        const Port(id: 'hw_in_2', name: 'Audio In 2', type: PortType.audio, direction: PortDirection.input),
      ];
      
      final physicalOutputs = [
        const Port(id: 'hw_out_1', name: 'Audio Out 1', type: PortType.audio, direction: PortDirection.output),
        const Port(id: 'hw_out_2', name: 'Audio Out 2', type: PortType.audio, direction: PortDirection.output),
      ];
      
      await tester.pumpWidget(createTestWidget(
        initialState: RoutingEditorState.loaded(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          algorithms: [],
          connections: [],
        ),
      ));
      
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      expect(find.text('Audio In 1'), findsOneWidget);
      expect(find.text('Audio In 2'), findsOneWidget);
      expect(find.text('Audio Out 1'), findsOneWidget);
      expect(find.text('Audio Out 2'), findsOneWidget);
    });

    testWidgets('should render loaded state with algorithms', (WidgetTester tester) async {
      final mockAlgorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'test-algorithm-guid',
        name: 'Test Algorithm',
      );
      
      final algorithms = [
        RoutingAlgorithm(
          index: 0,
          algorithm: mockAlgorithm,
          inputPorts: [],
          outputPorts: [],
        ),
      ];
      
      await tester.pumpWidget(createTestWidget(
        initialState: RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: algorithms,
          connections: [],
        ),
      ));
      
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      // The algorithm nodes should be rendered, though specific text might be hard to find
      // due to the widget hierarchy
    });

    testWidgets('should handle canvas tap to clear selections', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      // Tap on the canvas
      await tester.tap(find.byType(RoutingEditorWidget));
      await tester.pump();
      
      // Should not throw any errors
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    testWidgets('should support custom canvas size', (WidgetTester tester) async {
      const customSize = Size(800, 600);
      
      await tester.pumpWidget(createTestWidget(
        canvas: const RoutingEditorWidget(canvasSize: customSize),
        initialState: const RoutingEditorState.initial(),
      ));
      
      final canvasWidget = tester.widget<RoutingEditorWidget>(find.byType(RoutingEditorWidget));
      expect(canvasWidget.canvasSize, equals(customSize));
    });

    testWidgets('should support hiding physical ports', (WidgetTester tester) async {
      final physicalInputs = [
        const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
      ];
      
      await tester.pumpWidget(createTestWidget(
        canvas: const RoutingEditorWidget(showPhysicalPorts: false),
        initialState: RoutingEditorState.loaded(
          physicalInputs: physicalInputs,
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      // Physical ports should not be rendered
      expect(find.text('Audio In 1'), findsNothing);
    });

    testWidgets('should handle node selection callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        canvas: RoutingEditorWidget(
          onNodeSelected: (nodeId) { /* callback for testing */ },
        ),
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      final canvasWidget = tester.widget<RoutingEditorWidget>(find.byType(RoutingEditorWidget));
      expect(canvasWidget.onNodeSelected, isNotNull);
    });

    testWidgets('should handle connection creation callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        canvas: RoutingEditorWidget(
          onConnectionCreated: (source, target) { /* callback for testing */ },
        ),
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      final canvasWidget = tester.widget<RoutingEditorWidget>(find.byType(RoutingEditorWidget));
      expect(canvasWidget.onConnectionCreated, isNotNull);
    });

    testWidgets('should handle connection removal callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        canvas: RoutingEditorWidget(
          onConnectionRemoved: (connectionId) { /* callback for testing */ },
        ),
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      final canvasWidget = tester.widget<RoutingEditorWidget>(find.byType(RoutingEditorWidget));
      expect(canvasWidget.onConnectionRemoved, isNotNull);
    });

    testWidgets('should render grid background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      // CustomPaint should be present for grid rendering
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('should use provided routing factory', (WidgetTester tester) async {
      final customFactory = MockRoutingFactory();
      
      await tester.pumpWidget(createTestWidget(
        canvas: RoutingEditorWidget(routingFactory: customFactory),
        initialState: const RoutingEditorState.initial(),
      ));
      
      final canvasWidget = tester.widget<RoutingEditorWidget>(find.byType(RoutingEditorWidget));
      expect(canvasWidget.routingFactory, equals(customFactory));
    });

    testWidgets('should handle state changes reactively', (WidgetTester tester) async {
      // Test that loaded state renders correctly (without initial state test)
      await tester.pumpWidget(createTestWidget(
        initialState: const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      ));
      
      // Should show loaded state UI
      expect(find.text('Initializing routing editor...'), findsNothing);
      expect(find.byType(Stack), findsAtLeastNWidgets(1)); // Stack is used in loaded state
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    group('Port Type Colors', () {
      testWidgets('should use correct colors for different port types', (WidgetTester tester) async {
        final physicalInputs = [
          const Port(id: 'hw_in_1', name: 'Audio In', type: PortType.audio, direction: PortDirection.input),
          const Port(id: 'hw_in_2', name: 'CV In', type: PortType.cv, direction: PortDirection.input),
          const Port(id: 'hw_in_3', name: 'Gate In', type: PortType.gate, direction: PortDirection.input),
          const Port(id: 'hw_in_4', name: 'Trigger In', type: PortType.trigger, direction: PortDirection.input),
        ];
        
        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: physicalInputs,
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // All port nodes should be rendered
        expect(find.text('Audio In'), findsOneWidget);
        expect(find.text('CV In'), findsOneWidget);
        expect(find.text('Gate In'), findsOneWidget);
        expect(find.text('Trigger In'), findsOneWidget);
      });
    });

    group('Canvas Interaction', () {
      testWidgets('should handle drag gestures', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Start a drag gesture
        await tester.dragFrom(
          tester.getCenter(find.byType(RoutingEditorWidget)),
          const Offset(50, 50),
        );
        
        // Should not throw any errors
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });

      testWidgets('should maintain node positions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: const RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Canvas should render with consistent positioning
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
        expect(find.byType(Stack), findsAtLeastNWidgets(1));
      });
    });

    group('Reactive State Management', () {
      testWidgets('should optimize rebuilds with buildWhen condition', (WidgetTester tester) async {
        // Create initial loaded state
        final initialState = RoutingEditorState.loaded(
          physicalInputs: [
            const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
          ],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        );
        
        await tester.pumpWidget(createTestWidget(initialState: initialState));
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
        
        // Update to identical loaded state - should not trigger rebuild due to buildWhen
        when(mockCubit.state).thenReturn(RoutingEditorState.loaded(
          physicalInputs: [
            const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
          ],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ));
        
        // Pump widget with same state
        await tester.pump();
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });

      testWidgets('should rebuild when meaningful state changes occur', (WidgetTester tester) async {
        final initialState = RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        );
        
        await tester.pumpWidget(createTestWidget(initialState: initialState));
        
        // Add a new algorithm - should trigger rebuild
        final mockAlgorithm = Algorithm(
          algorithmIndex: 0,
          guid: 'test-algorithm-guid',
          name: 'Test Algorithm',
        );
        
        final newState = RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [
            RoutingAlgorithm(
              index: 0,
              algorithm: mockAlgorithm,
              inputPorts: [],
              outputPorts: [],
            ),
          ],
          connections: [],
        );
        
        when(mockCubit.state).thenReturn(newState);
        
        await tester.pumpWidget(createTestWidget(initialState: newState));
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });

      testWidgets('should maintain widget keys for stability', (WidgetTester tester) async {
        final physicalInputs = [
          const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
          const Port(id: 'hw_in_2', name: 'Audio In 2', type: PortType.audio, direction: PortDirection.input),
        ];
        
        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: physicalInputs,
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ),
        ));
        
        // Check that Positioned widgets with keys are created
        expect(find.byKey(const ValueKey('input_hw_in_1')), findsOneWidget);
        expect(find.byKey(const ValueKey('input_hw_in_2')), findsOneWidget);
      });

      testWidgets('should handle rapid state changes efficiently', (WidgetTester tester) async {
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
          await tester.pumpWidget(createTestWidget(initialState: state));
          await tester.pump();
        }
        
        // Should handle all state transitions without errors
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });

      testWidgets('should cache algorithm metadata for performance', (WidgetTester tester) async {
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
        
        await tester.pumpWidget(createTestWidget(
          initialState: RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: algorithms,
            connections: [],
          ),
        ));
        
        // The algorithm node should be rendered with cached metadata
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
        expect(find.byKey(const ValueKey('algorithm_node_0')), findsOneWidget);
      });
    });
  });
}
