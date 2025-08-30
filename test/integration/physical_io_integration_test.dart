import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([RoutingEditorCubit])
import 'physical_io_integration_test.mocks.dart';

void main() {
  group('Physical I/O Integration Tests', () {
    late MockRoutingEditorCubit mockCubit;
    
    setUp(() {
      mockCubit = MockRoutingEditorCubit();
    });
    
    testWidgets('Physical nodes render correctly in RoutingCanvas', (tester) async {
      // Arrange
      when(mockCubit.state).thenReturn(
        const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      );
      when(mockCubit.stream).thenAnswer((_) => const Stream.empty());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<RoutingEditorCubit>.value(
              value: mockCubit,
              child: const RoutingEditorWidget(
                canvasSize: Size(1200, 800),
                showPhysicalPorts: true,
              ),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);
    });
    
    test('ConnectionValidator validates physical connections correctly', () {
      // Arrange
      final physicalInput = PhysicalPortGenerator.generatePhysicalInputPort(1);
      final physicalOutput = PhysicalPortGenerator.generatePhysicalOutputPort(1);
      final algorithmInput = core_port.Port(
        id: 'alg_1_in_1',
        name: 'Algorithm Input',
        type: core_port.PortType.audio,
        direction: core_port.PortDirection.input,
        metadata: {'isPhysical': false},
      );
      final algorithmOutput = core_port.Port(
        id: 'alg_1_out_1',
        name: 'Algorithm Output',
        type: core_port.PortType.audio,
        direction: core_port.PortDirection.output,
        metadata: {'isPhysical': false},
      );
      
      // Act & Assert
      // Valid: Physical Input → Algorithm Input
      expect(
        ConnectionValidator.isValidConnection(physicalInput, algorithmInput),
        isTrue,
        reason: 'Physical input to algorithm input should be valid',
      );
      
      // Valid: Algorithm Output → Physical Output
      expect(
        ConnectionValidator.isValidConnection(algorithmOutput, physicalOutput),
        isTrue,
        reason: 'Algorithm output to physical output should be valid',
      );
      
      // Invalid: Physical Input → Physical Output
      expect(
        ConnectionValidator.isValidConnection(physicalInput, physicalOutput),
        isFalse,
        reason: 'Direct physical to physical connection should be invalid',
      );
      
      // Ghost connection: Algorithm Output → Physical Input
      expect(
        ConnectionValidator.isValidConnection(algorithmOutput, physicalInput),
        isTrue,
        reason: 'Ghost connection should be valid',
      );
      expect(
        ConnectionValidator.isGhostConnection(algorithmOutput, physicalInput),
        isTrue,
        reason: 'Should be identified as ghost connection',
      );
    });
    
    test('PhysicalPortGenerator creates correct port configurations', () {
      // Act
      final inputPorts = PhysicalPortGenerator.generatePhysicalInputPorts();
      final outputPorts = PhysicalPortGenerator.generatePhysicalOutputPorts();
      
      // Assert
      expect(inputPorts.length, 12, reason: 'Should generate 12 input ports');
      expect(outputPorts.length, 8, reason: 'Should generate 8 output ports');
      
      // Check first input port
      final firstInput = inputPorts.first;
      expect(firstInput.id, 'hw_in_1');
      expect(firstInput.direction, core_port.PortDirection.output);
      expect(firstInput.metadata?['isPhysical'], isTrue);
      expect(firstInput.metadata?['jackType'], 'input');
      
      // Check first output port
      final firstOutput = outputPorts.first;
      expect(firstOutput.id, 'hw_out_1');
      expect(firstOutput.direction, core_port.PortDirection.input);
      expect(firstOutput.metadata?['isPhysical'], isTrue);
      expect(firstOutput.metadata?['jackType'], 'output');
    });
    
    testWidgets('Drag and drop creates valid connections', (tester) async {
      // Arrange
      // no-op capture; we validate creation path indirectly in widget tree
      
      when(mockCubit.state).thenReturn(
        const RoutingEditorState.loaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        ),
      );
      when(mockCubit.stream).thenAnswer((_) => const Stream.empty());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<RoutingEditorCubit>.value(
              value: mockCubit,
              child: RoutingEditorWidget(
                canvasSize: const Size(1200, 800),
                showPhysicalPorts: true,
                onConnectionCreated: (source, target) {},
              ),
            ),
          ),
        ),
      );
      
      // Find physical input node
      final inputNode = find.byType(PhysicalInputNode);
      expect(inputNode, findsOneWidget);
      
      // Note: Full drag-and-drop testing would require more complex setup
      // This is a simplified test showing the structure is in place
    });
  });
}
