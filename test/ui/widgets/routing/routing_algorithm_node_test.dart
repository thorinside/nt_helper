import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/ui/widgets/routing/routing_algorithm_node.dart';

// Generate mocks
@GenerateMocks([RoutingFactory, AlgorithmRouting])
import 'routing_algorithm_node_test.mocks.dart';

void main() {
  group('RoutingAlgorithmNode', () {
    late MockRoutingFactory mockRoutingFactory;
    late MockAlgorithmRouting mockAlgorithmRouting;
    late AlgorithmRoutingMetadata polyMetadata;
    late AlgorithmRoutingMetadata multiChannelMetadata;
    late List<Port> mockInputPorts;
    late List<Port> mockOutputPorts;

    setUp(() {
      mockRoutingFactory = MockRoutingFactory();
      mockAlgorithmRouting = MockAlgorithmRouting();

      polyMetadata = const AlgorithmRoutingMetadata(
        algorithmGuid: 'test-poly',
        algorithmName: 'Poly Synth',
        routingType: RoutingType.polyphonic,
        voiceCount: 4,
        requiresGateInputs: true,
      );

      multiChannelMetadata = const AlgorithmRoutingMetadata(
        algorithmGuid: 'test-multi',
        algorithmName: 'Stereo Effect',
        routingType: RoutingType.multiChannel,
        channelCount: 2,
      );

      mockInputPorts = [
        const Port(
          id: 'poly_audio_in_1',
          name: 'Voice 1 Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'poly_gate_in_1',
          name: 'Voice 1 Gate',
          type: PortType.gate,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'poly_audio_in_2',
          name: 'Voice 2 Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'poly_gate_in_2',
          name: 'Voice 2 Gate',
          type: PortType.gate,
          direction: PortDirection.input,
        ),
      ];

      mockOutputPorts = [
        const Port(
          id: 'poly_audio_out_1',
          name: 'Voice 1 Audio Out',
          type: PortType.audio,
          direction: PortDirection.output,
        ),
        const Port(
          id: 'poly_audio_out_2',
          name: 'Voice 2 Audio Out',
          type: PortType.audio,
          direction: PortDirection.output,
        ),
      ];
    });

    void setupMockRouting() {
      when(mockRoutingFactory.createValidatedRouting(any))
          .thenReturn(mockAlgorithmRouting);
      when(mockAlgorithmRouting.inputPorts).thenReturn(mockInputPorts);
      when(mockAlgorithmRouting.outputPorts).thenReturn(mockOutputPorts);
    }

    testWidgets('creates routing instance and displays generated ports', (tester) async {
      setupMockRouting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify routing factory was called with correct metadata
      verify(mockRoutingFactory.createValidatedRouting(polyMetadata)).called(1);

      // Verify algorithm name is displayed
      expect(find.text('Poly Synth'), findsOneWidget);

      // Verify generated ports are displayed
      expect(find.text('Voice 1 Audio In'), findsOneWidget);
      expect(find.text('Voice 1 Gate'), findsOneWidget);
      expect(find.text('Voice 2 Audio In'), findsOneWidget);
      expect(find.text('Voice 2 Gate'), findsOneWidget);
      expect(find.text('Voice 1 Audio Out'), findsOneWidget);
      expect(find.text('Voice 2 Audio Out'), findsOneWidget);
    });

    testWidgets('displays different ports for different routing types', (tester) async {
      // Setup for multi-channel routing
      final multiChannelInputPorts = [
        const Port(
          id: 'ch_audio_in_1',
          name: 'Ch 1 Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'ch_audio_in_2',
          name: 'Ch 2 Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
      ];

      when(mockRoutingFactory.createValidatedRouting(multiChannelMetadata))
          .thenReturn(mockAlgorithmRouting);
      when(mockAlgorithmRouting.inputPorts).thenReturn(multiChannelInputPorts);
      when(mockAlgorithmRouting.outputPorts).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: multiChannelMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify multi-channel specific ports
      expect(find.text('Ch 1 Audio In'), findsOneWidget);
      expect(find.text('Ch 2 Audio In'), findsOneWidget);
      expect(find.text('Stereo Effect'), findsOneWidget);
    });

    testWidgets('handles routing factory errors gracefully', (tester) async {
      when(mockRoutingFactory.createValidatedRouting(any))
          .thenThrow(const RoutingFactoryException('Test error', AlgorithmRoutingMetadata(
            algorithmGuid: 'test',
            routingType: RoutingType.polyphonic,
          ), null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify error state is displayed
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Routing Error'), findsOneWidget);
      expect(find.text('Poly Synth'), findsOneWidget); // Algorithm name still shown
    });

    testWidgets('recreates routing when metadata changes', (tester) async {
      setupMockRouting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify initial routing creation
      verify(mockRoutingFactory.createValidatedRouting(polyMetadata)).called(1);

      // Update to different metadata
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: multiChannelMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify new routing was created
      verify(mockRoutingFactory.createValidatedRouting(multiChannelMetadata)).called(1);
    });

    testWidgets('responds to port tap callbacks', (tester) async {
      setupMockRouting();
      Port? tappedPort;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
              onPortTapped: (port) => tappedPort = port,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Voice 1 Audio In'));
      expect(tappedPort, isNotNull);
      expect(tappedPort!.id, equals('poly_audio_in_1'));
    });

    testWidgets('responds to node tap callbacks', (tester) async {
      setupMockRouting();
      bool nodeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
              onNodeTapped: () => nodeTapped = true,
            ),
          ),
        ),
      );

      // Tap on the algorithm name which should trigger the node tap
      await tester.tap(find.text('Poly Synth'));
      expect(nodeTapped, isTrue);
    });

    testWidgets('shows selected state correctly', (tester) async {
      setupMockRouting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
              isSelected: true,
            ),
          ),
        ),
      );

      // Find the AlgorithmNode widget and verify it exists
      expect(find.text('Poly Synth'), findsOneWidget);
    });

    testWidgets('creates routing instance successfully', (tester) async {
      setupMockRouting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Verify that the routing instance was created
      verify(mockRoutingFactory.createValidatedRouting(polyMetadata)).called(1);
      verify(mockAlgorithmRouting.inputPorts).called(1);
      verify(mockAlgorithmRouting.outputPorts).called(1);
    });

    testWidgets('disposes routing instance correctly', (tester) async {
      setupMockRouting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutingAlgorithmNode(
              metadata: polyMetadata,
              routingFactory: mockRoutingFactory,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Trigger widget disposal
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Verify dispose was called on the routing instance
      verify(mockAlgorithmRouting.dispose()).called(1);
    });

    testWidgets('provides positioned() method for Stack placement', (tester) async {
      setupMockRouting();
      const position = Offset(200, 300);

      final node = RoutingAlgorithmNode(
        metadata: polyMetadata,
        routingFactory: mockRoutingFactory,
        position: position,
      );

      final positioned = node.positioned();
      expect(positioned, isA<Positioned>());

      // Verify the position is stored in the node
      expect(node.position, equals(position));
    });
  });
}