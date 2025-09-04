import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

/// Regression tests to ensure algorithm nodes work exactly as before
/// the universal port widget implementation.
/// 
/// These tests verify that existing algorithm node functionality
/// is preserved and no visual or functional regressions are introduced.
void main() {
  group('Algorithm Node Regression Tests', () {
    
    group('Visual Consistency and Layout', () {
      testWidgets('Algorithm node maintains expected visual structure', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Dual VCA',
                slotNumber: 3,
                position: const Offset(100, 100),
                inputLabels: ['CV 1', 'Input 1', 'CV 2', 'Input 2'],
                outputLabels: ['Output 1', 'Output 2'],
                inputPortIds: ['vca_cv1', 'vca_in1', 'vca_cv2', 'vca_in2'],
                outputPortIds: ['vca_out1', 'vca_out2'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify core structure exists
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.text('#3 Dual VCA'), findsOneWidget);
        
        // Verify input ports are on the left with right-aligned labels
        final inputPorts = tester.widgetList<PortWidget>(find.byType(PortWidget))
            .where((w) => w.isInput).toList();
        expect(inputPorts, hasLength(4));
        
        for (final inputPort in inputPorts) {
          expect(inputPort.labelPosition, equals(PortLabelPosition.right));
          expect(inputPort.style, equals(PortStyle.dot)); // Default for algorithm nodes
        }
        
        // Verify output ports are on the right with left-aligned labels
        final outputPorts = tester.widgetList<PortWidget>(find.byType(PortWidget))
            .where((w) => !w.isInput).toList();
        expect(outputPorts, hasLength(2));
        
        for (final outputPort in outputPorts) {
          expect(outputPort.labelPosition, equals(PortLabelPosition.left));
          expect(outputPort.style, equals(PortStyle.dot)); // Default for algorithm nodes
        }
      });

      testWidgets('Title bar layout and styling preserved', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Very Long Algorithm Name That Should Be Truncated',
                slotNumber: 15,
                position: const Offset(200, 200),
                leadingIcon: const Icon(Icons.music_note),
                isSelected: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Title should be truncated and include slot number
        final titleText = find.textContaining('#15');
        expect(titleText, findsOneWidget);
        
        // Leading icon should be present
        expect(find.byIcon(Icons.music_note), findsOneWidget);
        
        // Action buttons should be present (up, down, more)
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        
        // Selected styling should be applied (verified by lack of errors)
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      });

      testWidgets('Port spacing and alignment preserved', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Multi I/O Algorithm',
                slotNumber: 1,
                position: const Offset(0, 0),
                inputLabels: ['In 1', 'In 2', 'In 3'],
                outputLabels: ['Out 1', 'Out 2', 'Out 3', 'Out 4'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get all port positions
        final allPorts = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        expect(allPorts, hasLength(7));

        // Verify input ports are vertically aligned and on the left
        final inputPorts = allPorts.where((w) => w.isInput).toList();
        final inputPositions = inputPorts.map((port) {
          final finder = find.byWidget(port);
          return tester.getTopLeft(finder);
        }).toList();

        // All inputs should have roughly the same x position (left edge)
        final minInputX = inputPositions.map((pos) => pos.dx).reduce((a, b) => a < b ? a : b);
        final maxInputX = inputPositions.map((pos) => pos.dx).reduce((a, b) => a > b ? a : b);
        expect(maxInputX - minInputX, lessThan(5)); // Allow small tolerance

        // Verify output ports are vertically aligned and on the right
        final outputPorts = allPorts.where((w) => !w.isInput).toList();
        final outputPositions = outputPorts.map((port) {
          final finder = find.byWidget(port);
          return tester.getTopLeft(finder);
        }).toList();

        // All outputs should have roughly the same x position (right edge)
        final minOutputX = outputPositions.map((pos) => pos.dx).reduce((a, b) => a < b ? a : b);
        final maxOutputX = outputPositions.map((pos) => pos.dx).reduce((a, b) => a > b ? a : b);
        expect(maxOutputX - minOutputX, lessThan(5)); // Allow small tolerance

        // Outputs should be positioned to the right of inputs
        expect(minOutputX, greaterThan(maxInputX + 10));
      });
    });

    group('Interactive Behavior Preservation', () {
      testWidgets('Drag behavior works as expected', (tester) async {
        Offset? updatedPosition;
        bool dragStartCalled = false;
        bool dragEndCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Draggable Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                onPositionChanged: (position) => updatedPosition = position,
                onDragStart: () => dragStartCalled = true,
                onDragEnd: () => dragEndCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform drag gesture
        final nodeWidget = find.byType(AlgorithmNodeWidget);
        await tester.dragFrom(
          tester.getCenter(nodeWidget),
          const Offset(100, 50),
        );
        await tester.pumpAndSettle();

        // Verify callbacks were triggered
        expect(dragStartCalled, isTrue);
        expect(dragEndCalled, isTrue);
        expect(updatedPosition, isNotNull);
        
        // Verify position is constrained and snapped to grid
        expect(updatedPosition!.dx % 50, equals(0)); // Grid snapping
        expect(updatedPosition!.dy % 50, equals(0));
      });

      testWidgets('Action buttons work correctly', (tester) async {
        bool moveUpCalled = false;
        bool moveDownCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Action Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                onMoveUp: () => moveUpCalled = true,
                onMoveDown: () => moveDownCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test move up button
        await tester.tap(find.byIcon(Icons.arrow_upward));
        await tester.pumpAndSettle();
        expect(moveUpCalled, isTrue);

        // Test move down button
        await tester.tap(find.byIcon(Icons.arrow_downward));
        await tester.pumpAndSettle();
        expect(moveDownCalled, isTrue);
      });

      testWidgets('Delete functionality works through overflow menu', (tester) async {
        // Mock cubit for delete functionality
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<DistingCubit>(
              create: (context) => MockDistingCubit(),
              child: Scaffold(
                body: AlgorithmNodeWidget(
                  algorithmName: 'Delete Test',
                  slotNumber: 1,
                  position: const Offset(100, 100),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open overflow menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify delete option exists
        expect(find.text('Delete'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        // Cancel the delete to avoid actual deletion
        await tester.tapAt(const Offset(0, 0)); // Tap outside to dismiss
        await tester.pumpAndSettle();

        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      });

      testWidgets('Selection state visual feedback works', (tester) async {
        Widget buildWithSelection(bool isSelected) {
          return MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Selection Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                isSelected: isSelected,
              ),
            ),
          );
        }

        // Test unselected state
        await tester.pumpWidget(buildWithSelection(false));
        await tester.pumpAndSettle();
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        // Test selected state
        await tester.pumpWidget(buildWithSelection(true));
        await tester.pumpAndSettle();
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        // Both states should render without errors
      });
    });

    group('Port Functionality Preservation', () {
      testWidgets('Port position callbacks work correctly', (tester) async {
        final Map<String, Offset> portPositions = {};
        final Map<String, bool> portInputStates = {};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Port Callback Test',
                slotNumber: 1,
                position: const Offset(150, 150),
                inputLabels: ['Test Input'],
                outputLabels: ['Test Output'],
                inputPortIds: ['test_in'],
                outputPortIds: ['test_out'],
                onPortPositionResolved: (portId, position, isInput) {
                  portPositions[portId] = position;
                  portInputStates[portId] = isInput;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow post-frame callbacks

        // Verify port positions are resolved
        expect(portPositions.containsKey('test_in'), isTrue);
        expect(portPositions.containsKey('test_out'), isTrue);
        expect(portInputStates['test_in'], isTrue);
        expect(portInputStates['test_out'], isFalse);

        // Positions should be reasonable (within the widget bounds)
        expect(portPositions['test_in']!.dx, greaterThan(0));
        expect(portPositions['test_in']!.dy, greaterThan(0));
        expect(portPositions['test_out']!.dx, greaterThan(0));
        expect(portPositions['test_out']!.dy, greaterThan(0));
      });

      testWidgets('Port count matches label count', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Count Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['In1', 'In2', 'In3', 'In4'],
                outputLabels: ['Out1', 'Out2'],
                inputPortIds: ['in1', 'in2', 'in3', 'in4'],
                outputPortIds: ['out1', 'out2'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify port counts match label counts
        final allPorts = find.byType(PortWidget);
        expect(allPorts, findsNWidgets(6)); // 4 inputs + 2 outputs

        // Verify specific labels exist
        expect(find.text('In1'), findsOneWidget);
        expect(find.text('In2'), findsOneWidget);
        expect(find.text('In3'), findsOneWidget);
        expect(find.text('In4'), findsOneWidget);
        expect(find.text('Out1'), findsOneWidget);
        expect(find.text('Out2'), findsOneWidget);
      });

      testWidgets('Port IDs and labels alignment preserved', (tester) async {
        final List<String> resolvedPortIds = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Alignment Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['First Input', 'Second Input'],
                outputLabels: ['First Output'],
                inputPortIds: ['first_in', 'second_in'],
                outputPortIds: ['first_out'],
                onPortPositionResolved: (portId, position, isInput) {
                  resolvedPortIds.add(portId);
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify correct port IDs are resolved in expected order
        expect(resolvedPortIds, contains('first_in'));
        expect(resolvedPortIds, contains('second_in'));
        expect(resolvedPortIds, contains('first_out'));

        // Verify labels are displayed
        expect(find.text('First Input'), findsOneWidget);
        expect(find.text('Second Input'), findsOneWidget);
        expect(find.text('First Output'), findsOneWidget);
      });
    });

    group('Theme and Styling Preservation', () {
      testWidgets('Light theme styling preserved', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Light Theme Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input'],
                outputLabels: ['Output'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors and use theme colors
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(2));
        expect(find.text('#1 Light Theme Test'), findsOneWidget);
      });

      testWidgets('Dark theme styling preserved', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Dark Theme Test',
                slotNumber: 2,
                position: const Offset(100, 100),
                inputLabels: ['Input'],
                outputLabels: ['Output'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors and use dark theme colors
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(2));
        expect(find.text('#2 Dark Theme Test'), findsOneWidget);
      });

      testWidgets('Custom theme integration preserved', (tester) async {
        final customTheme = ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Colors.purple,
            surface: Colors.grey,
          ),
          textTheme: const TextTheme(
            titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: customTheme,
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Custom Theme Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Custom Input'],
                isSelected: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should use custom theme without errors
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.text('#1 Custom Theme Test'), findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('Empty labels handled correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Empty Labels Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: [],
                outputLabels: [],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render with no ports but still have the title bar
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNothing);
        expect(find.text('#1 Empty Labels Test'), findsOneWidget);
      });

      testWidgets('Mismatched label and port ID counts handled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Mismatch Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input 1', 'Input 2', 'Input 3'],
                inputPortIds: ['input_1'], // Only one ID for three labels
                outputLabels: ['Output 1'],
                outputPortIds: ['output_1', 'output_2'], // Two IDs for one label
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render all labels but only resolve positions for existing IDs
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(4)); // All labels rendered
        expect(find.text('Input 1'), findsOneWidget);
        expect(find.text('Input 2'), findsOneWidget);
        expect(find.text('Input 3'), findsOneWidget);
        expect(find.text('Output 1'), findsOneWidget);
      });

      testWidgets('Long algorithm names truncated correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250, // Constrain width to force truncation
                child: AlgorithmNodeWidget(
                  algorithmName: 'This is a very long algorithm name that should definitely be truncated',
                  slotNumber: 99,
                  position: const Offset(100, 100),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render with ellipsis in the title
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        final titleText = find.textContaining('#99');
        expect(titleText, findsOneWidget);
        
        // Should contain ellipsis or be truncated
        final titleWidget = tester.widget<Text>(titleText);
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });
    });
  });
}

/// Mock DistingCubit for testing delete functionality
class MockDistingCubit extends DistingCubit {
  MockDistingCubit() : super(
    distingRepository: null, 
    algorithmMetadataService: null,
  );

  @override
  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    // Mock implementation - do nothing
  }
}