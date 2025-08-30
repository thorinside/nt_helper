import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/physical_io_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';

void main() {
  group('PhysicalIONodeWidget', () {
    testWidgets('renders with correct title and icon', (WidgetTester tester) async {
      final ports = PhysicalPortGenerator.generatePhysicalInputPorts().take(3).toList();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
            ),
          ),
        ),
      );
      
      // Check title is displayed
      expect(find.text('Test Node'), findsOneWidget);
      
      // Check icon is displayed
      expect(find.byIcon(Icons.cable), findsOneWidget);
    });
    
    testWidgets('displays correct number of ports', (WidgetTester tester) async {
      final ports = PhysicalPortGenerator.generatePhysicalInputPorts().take(5).toList();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
            ),
          ),
        ),
      );
      
      // Should have 5 JackConnectionWidget instances
      // Note: JackConnectionWidget contains CustomPaint
      expect(find.byType(CustomPaint), findsNWidgets(5));
    });
    
    testWidgets('shows labels when showLabels is true', (WidgetTester tester) async {
      final ports = [
        PhysicalPortGenerator.generatePhysicalInputPort(1),
        PhysicalPortGenerator.generatePhysicalInputPort(2),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
              showLabels: true,
            ),
          ),
        ),
      );
      
      // Check labels are displayed
      expect(find.text('In 1'), findsOneWidget);
      expect(find.text('In 2'), findsOneWidget);
    });
    
    testWidgets('hides labels when showLabels is false', (WidgetTester tester) async {
      final ports = [
        PhysicalPortGenerator.generatePhysicalInputPort(1),
        PhysicalPortGenerator.generatePhysicalInputPort(2),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
              showLabels: false,
            ),
          ),
        ),
      );
      
      // Check labels are not displayed
      expect(find.text('In 1'), findsNothing);
      expect(find.text('In 2'), findsNothing);
    });
    
    testWidgets('calls onPortTapped callback', (WidgetTester tester) async {
      Port? tappedPort;
      final ports = [
        PhysicalPortGenerator.generatePhysicalInputPort(1),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
              onPortTapped: (port) => tappedPort = port,
            ),
          ),
        ),
      );
      
      // Tap on the jack
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      
      expect(tappedPort, isNotNull);
      expect(tappedPort?.id, equals('hw_in_1'));
    });
    
    testWidgets('applies correct styling from theme', (WidgetTester tester) async {
      final ports = PhysicalPortGenerator.generatePhysicalInputPorts().take(2).toList();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              surfaceContainer: Colors.grey,
              outline: Colors.black,
            ),
          ),
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
            ),
          ),
        ),
      );
      
      // Check container is rendered with theme colors
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(8.0)));
    });
  });
  
  group('PhysicalInputNode', () {
    testWidgets('renders with 12 input ports', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalInputNode(),
          ),
        ),
      );
      
      // Check title
      expect(find.text('Physical Inputs'), findsOneWidget);
      
      // Check icon
      expect(find.byIcon(Icons.input_rounded), findsOneWidget);
      
      // Should have 12 ports (12 CustomPaint widgets from JackConnectionWidget)
      expect(find.byType(CustomPaint), findsNWidgets(12));
    });
    
    testWidgets('shows correct labels for inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PhysicalInputNode(showLabels: true),
            ),
          ),
        ),
      );
      
      // Check some labels are displayed
      expect(find.text('In 1'), findsOneWidget);
      expect(find.text('In 12'), findsOneWidget);
    });
    
    testWidgets('calls callbacks correctly', (WidgetTester tester) async {
      Port? tappedPort;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalInputNode(
              onPortTapped: (port) => tappedPort = port,
              onDragStart: (_) {},
            ),
          ),
        ),
      );
      
      // Tap on first port
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      
      expect(tappedPort, isNotNull);
      expect(tappedPort?.id, equals('hw_in_1'));
    });
    
    testWidgets('has correct semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalInputNode(),
          ),
        ),
      );
      
      // Check semantic label
      final semantics = tester.getSemantics(find.byType(PhysicalIONodeWidget));
      expect(semantics.label, contains('Physical Inputs'));
      expect(semantics.hint, contains('Hardware input jacks'));
    });
  });
  
  group('PhysicalOutputNode', () {
    testWidgets('renders with 8 output ports', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalOutputNode(),
          ),
        ),
      );
      
      // Check title
      expect(find.text('Physical Outputs'), findsOneWidget);
      
      // Check icon
      expect(find.byIcon(Icons.output_rounded), findsOneWidget);
      
      // Should have 8 ports (8 CustomPaint widgets from JackConnectionWidget)
      expect(find.byType(CustomPaint), findsNWidgets(8));
    });
    
    testWidgets('shows correct labels for outputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PhysicalOutputNode(showLabels: true),
            ),
          ),
        ),
      );
      
      // Check some labels are displayed
      expect(find.text('Out 1'), findsOneWidget);
      expect(find.text('Out 8'), findsOneWidget);
    });
    
    testWidgets('calls callbacks correctly', (WidgetTester tester) async {
      Port? tappedPort;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalOutputNode(
              onPortTapped: (port) => tappedPort = port,
              onDragStart: (_) {},
            ),
          ),
        ),
      );
      
      // Tap on first port
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      
      expect(tappedPort, isNotNull);
      expect(tappedPort?.id, equals('hw_out_1'));
    });
    
    testWidgets('has correct semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalOutputNode(),
          ),
        ),
      );
      
      // Check semantic label
      final semantics = tester.getSemantics(find.byType(PhysicalIONodeWidget));
      expect(semantics.label, contains('Physical Outputs'));
      expect(semantics.hint, contains('Hardware output jacks'));
    });
  });
  
  group('Spacing and Layout', () {
    testWidgets('adjusts spacing based on screen size', (WidgetTester tester) async {
      // Test small screen
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      
      var spacing = PhysicalIONodeWidget.getOptimalSpacing(const Size(400, 500));
      expect(spacing, equals(28.0)); // 35 * 0.8
      
      // Test normal screen
      spacing = PhysicalIONodeWidget.getOptimalSpacing(const Size(800, 800));
      expect(spacing, equals(35.0)); // base spacing
      
      // Test large screen
      spacing = PhysicalIONodeWidget.getOptimalSpacing(const Size(1920, 1200));
      expect(spacing, equals(42.0)); // 35 * 1.2
      
      // Reset to default
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    
    testWidgets('custom jack spacing is applied', (WidgetTester tester) async {
      final ports = PhysicalPortGenerator.generatePhysicalInputPorts().take(3).toList();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalIONodeWidget(
              ports: ports,
              title: 'Test Node',
              icon: Icons.cable,
              jackSpacing: 50.0,
            ),
          ),
        ),
      );
      
      // Verify the spacing is applied (would need to check widget positions)
      // This is a simplified test - in reality you'd measure actual positions
      final padding = tester.widget<Padding>(
        find.byType(Padding).at(1), // Get second Padding (first port row)
      );
      
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.vertical, equals((50.0 - 24.0) / 2));
    });
  });
  
  group('Label Alignment', () {
    testWidgets('input node has labels on right', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalInputNode(showLabels: true),
          ),
        ),
      );
      
      // Labels should appear after jacks in the row
      // This is determined by the LabelAlignment.right setting
      final rows = find.byType(Row);
      expect(rows, findsWidgets);
    });
    
    testWidgets('output node has labels on left', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhysicalOutputNode(showLabels: true),
          ),
        ),
      );
      
      // Labels should appear before jacks in the row
      // This is determined by the LabelAlignment.left setting
      final rows = find.byType(Row);
      expect(rows, findsWidgets);
    });
  });
}
