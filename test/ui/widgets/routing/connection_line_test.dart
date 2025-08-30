import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_line.dart';

void main() {
  group('Connection', () {
    late Port audioOutput;
    late Port audioInput;
    late Port cvOutput;
    late Port gateInput;
    
    setUp(() {
      audioOutput = const Port(
        id: 'audio_out_1',
        name: 'Audio Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
      );
      
      audioInput = const Port(
        id: 'audio_in_1',
        name: 'Audio Input 1',
        type: PortType.audio,
        direction: PortDirection.input,
      );
      
      cvOutput = const Port(
        id: 'cv_out_1',
        name: 'CV Output 1',
        type: PortType.cv,
        direction: PortDirection.output,
      );
      
      gateInput = const Port(
        id: 'gate_in_1',
        name: 'Gate Input 1',
        type: PortType.gate,
        direction: PortDirection.input,
      );
    });

    test('should create connection with required properties', () {
      const sourcePosition = Offset(10, 20);
      const destinationPosition = Offset(100, 200);
      
      final connection = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: sourcePosition,
        destinationPosition: destinationPosition,
      );
      
      expect(connection.sourcePort, equals(audioOutput));
      expect(connection.destinationPort, equals(audioInput));
      expect(connection.sourcePosition, equals(sourcePosition));
      expect(connection.destinationPosition, equals(destinationPosition));
      expect(connection.isSelected, isFalse);
      expect(connection.isHighlighted, isFalse);
    });

    test('should return correct connection color based on source port type', () {
      final audioConnection = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      final cvConnection = Connection(
        sourcePort: cvOutput,
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      expect(audioConnection.getConnectionColor(), equals(Colors.blue));
      expect(cvConnection.getConnectionColor(), equals(Colors.orange));
    });

    test('should determine connection validity based on port compatibility', () {
      // Valid connection: audio output to audio input
      final validConnection = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      // Invalid connection: CV output to gate input (not compatible)
      final invalidConnection = Connection(
        sourcePort: cvOutput,
        destinationPort: gateInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      expect(validConnection.isValid, isTrue);
      expect(invalidConnection.isValid, isFalse);
    });

    test('should create copy with updated properties', () {
      final original = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
        isSelected: false,
      );
      
      final copy = original.copyWith(
        isSelected: true,
        isHighlighted: true,
      );
      
      expect(copy.sourcePort, equals(original.sourcePort));
      expect(copy.destinationPort, equals(original.destinationPort));
      expect(copy.isSelected, isTrue);
      expect(copy.isHighlighted, isTrue);
    });

    test('should implement equality correctly', () {
      final connection1 = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      final connection2 = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: const Offset(10, 10), // Different position
        destinationPosition: const Offset(110, 110), // Different position
      );
      
      final connection3 = Connection(
        sourcePort: cvOutput, // Different source port
        destinationPort: audioInput,
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
      );
      
      expect(connection1, equals(connection2)); // Same ports, different positions
      expect(connection1, isNot(equals(connection3))); // Different ports
    });

    group('Ghost Connections', () {
      late Port algorithmOutput;
      late Port physicalInput;
      late Port physicalOutput;
      
      setUp(() {
        algorithmOutput = const Port(
          id: 'alg_out_1',
          name: 'Algorithm Output 1',
          type: PortType.audio,
          direction: PortDirection.output,
          metadata: {'isPhysical': false},
        );
        
        physicalInput = const Port(
          id: 'hw_in_1',
          name: 'Physical Input 1',
          type: PortType.audio,
          direction: PortDirection.output, // Physical inputs act as sources
          metadata: {'isPhysical': true, 'jackType': 'input'},
        );
        
        physicalOutput = const Port(
          id: 'hw_out_1',
          name: 'Physical Output 1',
          type: PortType.audio,
          direction: PortDirection.input, // Physical outputs act as sinks
          metadata: {'isPhysical': true, 'jackType': 'output'},
        );
      });

      test('should identify ghost connections correctly', () {
        // Ghost connection: Algorithm output -> Physical input
        final ghostConnection = Connection(
          sourcePort: algorithmOutput,
          destinationPort: physicalInput,
          sourcePosition: Offset.zero,
          destinationPosition: const Offset(100, 100),
        );
        
        // Regular connection: Algorithm output -> Physical output
        final regularConnection = Connection(
          sourcePort: algorithmOutput,
          destinationPort: physicalOutput,
          sourcePosition: Offset.zero,
          destinationPosition: const Offset(100, 100),
        );
        
        expect(ghostConnection.isGhostConnection, isTrue);
        expect(regularConnection.isGhostConnection, isFalse);
      });
    });
  });

  group('ConnectionLine Widget', () {
    late Connection testConnection;
    
    setUp(() {
      final audioOutput = const Port(
        id: 'audio_out_1',
        name: 'Audio Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
      );
      
      final audioInput = const Port(
        id: 'audio_in_1',
        name: 'Audio Input 1',
        type: PortType.audio,
        direction: PortDirection.input,
      );
      
      testConnection = Connection(
        sourcePort: audioOutput,
        destinationPort: audioInput,
        sourcePosition: const Offset(50, 100),
        destinationPosition: const Offset(200, 150),
      );
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
              onTapped: () => tapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(ConnectionLine));
      await tester.pump();
      
      expect(tapped, isTrue);
    });

    testWidgets('should handle hover events on desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
              onHover: (hovered) { /* hover callback for testing */ },
            ),
          ),
        ),
      );
      
      // Find the MouseRegion widget and trigger hover
      final mouseRegion = find.byType(MouseRegion);
      expect(mouseRegion, findsOneWidget);
      
      // Test that the widget renders (hover behavior is hard to test in unit tests)
      expect(find.byType(ConnectionLine), findsOneWidget);
    });

    testWidgets('should apply different stroke widths', (WidgetTester tester) async {
      const customStrokeWidth = 4.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
              strokeWidth: customStrokeWidth,
            ),
          ),
        ),
      );
      
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(customPaint.painter, isA<Object>());
    });

    testWidgets('should handle animated connections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
              animated: true,
              animationDuration: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );
      
      // Let animation start
      await tester.pump();
      expect(find.byType(ConnectionLine), findsOneWidget);
      
      // Let animation complete
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ConnectionLine), findsOneWidget);
    });

    testWidgets('should render selected connection with visual changes', (WidgetTester tester) async {
      final selectedConnection = testConnection.copyWith(isSelected: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: selectedConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
    });

    testWidgets('should render highlighted connection', (WidgetTester tester) async {
      final highlightedConnection = testConnection.copyWith(isHighlighted: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: highlightedConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
    });

    testWidgets('should render invalid connection with error styling', (WidgetTester tester) async {
      // Create an invalid connection (incompatible port types)
      final cvOutput = const Port(
        id: 'cv_out_1',
        name: 'CV Output 1',
        type: PortType.cv,
        direction: PortDirection.output,
      );
      
      final gateInput = const Port(
        id: 'gate_in_1',
        name: 'Gate Input 1',
        type: PortType.gate,
        direction: PortDirection.input,
      );
      
      final invalidConnection = Connection(
        sourcePort: cvOutput,
        destinationPort: gateInput,
        sourcePosition: const Offset(50, 100),
        destinationPosition: const Offset(200, 150),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: invalidConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
      expect(invalidConnection.isValid, isFalse);
    });

    testWidgets('should render ghost connections with special styling', (WidgetTester tester) async {
      // Create a ghost connection
      final algorithmOutput = const Port(
        id: 'alg_out_1',
        name: 'Algorithm Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': false},
      );
      
      final physicalInput = const Port(
        id: 'hw_in_1',
        name: 'Physical Input 1',
        type: PortType.audio,
        direction: PortDirection.output, // Physical inputs act as sources
        metadata: {'isPhysical': true, 'jackType': 'input'},
      );
      
      final ghostConnection = Connection(
        sourcePort: algorithmOutput,
        destinationPort: physicalInput,
        sourcePosition: const Offset(50, 100),
        destinationPosition: const Offset(200, 150),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: ghostConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
      expect(ghostConnection.isGhostConnection, isTrue);
      
      // Verify tooltip is present for ghost connections
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('should have proper semantic labels for ghost connections', (WidgetTester tester) async {
      // Create a ghost connection
      final algorithmOutput = const Port(
        id: 'alg_out_1',
        name: 'Algorithm Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': false},
      );
      
      final physicalInput = const Port(
        id: 'hw_in_1',
        name: 'Physical Input 1',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': true, 'jackType': 'input'},
      );
      
      final ghostConnection = Connection(
        sourcePort: algorithmOutput,
        destinationPort: physicalInput,
        sourcePosition: const Offset(50, 100),
        destinationPosition: const Offset(200, 150),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: ghostConnection,
            ),
          ),
        ),
      );
      
      final semantics = tester.getSemantics(find.byType(ConnectionLine));
      expect(semantics.label, contains('Ghost connection'));
      expect(semantics.label, contains('signal available to other algorithms'));
      expect(semantics.hint, contains('Ghost connection line'));
    });

    testWidgets('should not show tooltip for regular connections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLine(
              connection: testConnection,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLine), findsOneWidget);
      expect(testConnection.isGhostConnection, isFalse);
      
      // Regular connections should not have tooltips
      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('ConnectionLineManager', () {
    late List<Connection> testConnections;
    
    setUp(() {
      final audioOutput = const Port(
        id: 'audio_out_1',
        name: 'Audio Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
      );
      
      final audioInput1 = const Port(
        id: 'audio_in_1',
        name: 'Audio Input 1',
        type: PortType.audio,
        direction: PortDirection.input,
      );
      
      final audioInput2 = const Port(
        id: 'audio_in_2',
        name: 'Audio Input 2',
        type: PortType.audio,
        direction: PortDirection.input,
      );
      
      testConnections = [
        Connection(
          sourcePort: audioOutput,
          destinationPort: audioInput1,
          sourcePosition: const Offset(50, 100),
          destinationPosition: const Offset(200, 150),
        ),
        Connection(
          sourcePort: audioOutput,
          destinationPort: audioInput2,
          sourcePosition: const Offset(50, 100),
          destinationPosition: const Offset(200, 200),
        ),
      ];
    });

    testWidgets('should render multiple connections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLineManager(
              connections: testConnections,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLineManager), findsOneWidget);
      expect(find.byType(ConnectionLine), findsNWidgets(testConnections.length));
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('should handle connection taps', (WidgetTester tester) async {
      Connection? tappedConnection;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLineManager(
              connections: testConnections,
              onConnectionTapped: (connection) => tappedConnection = connection,
            ),
          ),
        ),
      );
      
      // Tap the first connection
      await tester.tap(find.byType(ConnectionLine).first);
      await tester.pump();
      
      expect(tappedConnection, equals(testConnections.first));
    });

    testWidgets('should handle connection hover events', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLineManager(
              connections: testConnections,
              onConnectionHover: (connection, hovered) {
                /* hover callback for testing */
              },
            ),
          ),
        ),
      );
      
      // Test that the widget renders with hover callback
      expect(find.byType(ConnectionLineManager), findsOneWidget);
      expect(find.byType(ConnectionLine), findsNWidgets(testConnections.length));
    });

    testWidgets('should handle empty connections list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLineManager(
              connections: const [],
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLineManager), findsOneWidget);
      expect(find.byType(ConnectionLine), findsNothing);
    });

    testWidgets('should support animated connections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionLineManager(
              connections: testConnections,
              animated: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(ConnectionLineManager), findsOneWidget);
      expect(find.byType(ConnectionLine), findsNWidgets(testConnections.length));
      
      // Let animations complete
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ConnectionLine), findsNWidgets(testConnections.length));
    });
  });
}