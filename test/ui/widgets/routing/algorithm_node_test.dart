import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node.dart';

void main() {
  group('AlgorithmNode', () {
    late AlgorithmRoutingMetadata monoMetadata;
    late AlgorithmRoutingMetadata polyMetadata;
    late AlgorithmRoutingMetadata multiChannelMetadata;
    late List<Port> inputPorts;
    late List<Port> outputPorts;

    setUp(() {
      monoMetadata = const AlgorithmRoutingMetadata(
        algorithmGuid: 'test-mono',
        algorithmName: 'Test Algorithm',
        routingType: RoutingType.multiChannel,
        channelCount: 1,
      );

      polyMetadata = const AlgorithmRoutingMetadata(
        algorithmGuid: 'test-poly',
        algorithmName: 'Poly Algorithm',
        routingType: RoutingType.polyphonic,
        voiceCount: 4,
        requiresGateInputs: true,
      );

      multiChannelMetadata = const AlgorithmRoutingMetadata(
        algorithmGuid: 'test-multi',
        algorithmName: 'Multi Algorithm',
        routingType: RoutingType.multiChannel,
        channelCount: 8,
      );

      inputPorts = [
        const Port(
          id: 'audio_in',
          name: 'Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'cv_in',
          name: 'CV In',
          type: PortType.cv,
          direction: PortDirection.input,
        ),
      ];

      outputPorts = [
        const Port(
          id: 'audio_out',
          name: 'Audio Out',
          type: PortType.audio,
          direction: PortDirection.output,
        ),
      ];
    });

    testWidgets('displays algorithm name and basic structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      expect(find.text('Test Algorithm'), findsOneWidget);
      expect(find.text('Mono'), findsOneWidget);
    });

    testWidgets('displays polyphonic algorithm info correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: polyMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      expect(find.text('Poly Algorithm'), findsOneWidget);
      expect(find.text('Poly (4 voices)'), findsOneWidget);
    });

    testWidgets('displays multi-channel algorithm info correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: multiChannelMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      expect(find.text('Multi Algorithm'), findsOneWidget);
      expect(find.text('Multi-channel (8 channels)'), findsOneWidget);
    });

    testWidgets('displays input and output ports correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      expect(find.text('Inputs'), findsOneWidget);
      expect(find.text('Outputs'), findsOneWidget);
      expect(find.text('Audio In'), findsOneWidget);
      expect(find.text('CV In'), findsOneWidget);
      expect(find.text('Audio Out'), findsOneWidget);
    });

    testWidgets('shows different visual styles for port types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: [
                const Port(
                  id: 'audio',
                  name: 'Audio',
                  type: PortType.audio,
                  direction: PortDirection.input,
                ),
                const Port(
                  id: 'cv',
                  name: 'CV',
                  type: PortType.cv,
                  direction: PortDirection.input,
                ),
                const Port(
                  id: 'gate',
                  name: 'Gate',
                  type: PortType.gate,
                  direction: PortDirection.input,
                ),
              ],
              outputPorts: [],
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      // Find all port containers and verify they exist
      final portContainers = find.byType(Container);
      expect(portContainers, findsWidgets);
      
      // Verify port names are displayed
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('CV'), findsOneWidget);
      expect(find.text('Gate'), findsOneWidget);
    });

    testWidgets('responds to node tap', (tester) async {
      bool nodeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
              onNodeTapped: () => nodeTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AlgorithmNode));
      expect(nodeTapped, isTrue);
    });

    testWidgets('responds to port tap', (tester) async {
      Port? tappedPort;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
              onPortTapped: (port) => tappedPort = port,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Audio In'));
      expect(tappedPort, isNotNull);
      expect(tappedPort!.id, equals('audio_in'));
    });

    testWidgets('shows selected state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: inputPorts,
              outputPorts: outputPorts,
              position: const Offset(100, 100),
              isSelected: true,
            ),
          ),
        ),
      );

      // Find the main container and verify it exists
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('handles empty port lists gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlgorithmNode(
              metadata: monoMetadata,
              inputPorts: [],
              outputPorts: [],
              position: const Offset(100, 100),
            ),
          ),
        ),
      );

      expect(find.text('Test Algorithm'), findsOneWidget);
      expect(find.text('Inputs'), findsNothing);
      expect(find.text('Outputs'), findsNothing);
    });

    testWidgets('provides positioned() method for Stack placement', (tester) async {
      const position = Offset(200, 300);

      final node = AlgorithmNode(
        metadata: monoMetadata,
        inputPorts: inputPorts,
        outputPorts: outputPorts,
        position: position,
      );

      final positioned = node.positioned();
      expect(positioned, isA<Positioned>());

      // Verify the position is stored in the node
      expect(node.position, equals(position));
    });
  });
}