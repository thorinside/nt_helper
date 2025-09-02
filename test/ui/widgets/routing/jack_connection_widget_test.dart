import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/jack_connection_widget.dart';

void main() {
  group('JackConnectionWidget', () {
    late Port testPort;

    setUp(() {
      testPort = const Port(
        id: 'test_port_1',
        name: 'Test Port',
        type: PortType.audio,
        direction: PortDirection.input,
      );
    });

    Widget createTestWidget({
      Port? port,
      VoidCallback? onTap,
      VoidCallback? onDragStart,
      ValueChanged<Offset>? onDragUpdate,
      ValueChanged<Offset>? onDragEnd,
      bool? isHovered,
      bool? isSelected,
      bool isConnected = false,
      double? customWidth,
      FocusNode? focusNode,
      bool canRequestFocus = true,
      bool enableHapticFeedback = false, // Disabled for tests
    }) {
      return MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Center(
            child: JackConnectionWidget(
              port: port ?? testPort,
              onTap: onTap,
              onDragStart: onDragStart,
              onDragUpdate: onDragUpdate,
              onDragEnd: onDragEnd,
              isHovered: isHovered,
              isSelected: isSelected,
              isConnected: isConnected,
              customWidth: customWidth,
              focusNode: focusNode,
              canRequestFocus: canRequestFocus,
              enableHapticFeedback: enableHapticFeedback,
            ),
          ),
        ),
      );
    }

    testWidgets('renders correctly with port', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(JackConnectionWidget), findsOneWidget);
      // The widget uses CustomPaint internally, checking for its presence
      expect(find.descendant(
        of: find.byType(JackConnectionWidget),
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
    });

    testWidgets('displays correct semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('Test Port'));
      expect(semantics.label, contains('audio'));
      expect(semantics.label, contains('input'));
      expect(semantics.label, contains('not connected'));
      expect(semantics.hint, contains('Tap to select'));
      expect(semantics.hint, contains('D key to start drag'));
    });

    testWidgets('shows connected state in semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isConnected: true));

      final semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('connected'));
    });

    testWidgets('handles tap gesture', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(createTestWidget(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('toggles internal selection state on tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initial state should be unselected
      final initialSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(initialSemantics.hasFlag(SemanticsFlag.isSelected), isFalse);

      // Tap to select
      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      // Should now be selected
      final selectedSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(selectedSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);

      // Tap again to deselect
      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      // Should now be unselected again
      final deselectedSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(deselectedSemantics.hasFlag(SemanticsFlag.isSelected), isFalse);
    });

    testWidgets('respects external selection state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));

      final semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);

      // Tap should not change external selection
      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      final afterTapSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(afterTapSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('handles hover state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Create a hover event
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over widget
      await gesture.moveTo(tester.getCenter(find.byType(JackConnectionWidget)));
      await tester.pump();

      // Move mouse away
      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
    });

    testWidgets('handles drag gestures from jack area', (WidgetTester tester) async {
      bool dragStarted = false;
      Offset? dragUpdatePosition;

      await tester.pumpWidget(createTestWidget(
        onDragStart: () => dragStarted = true,
        onDragUpdate: (offset) => dragUpdatePosition = offset,
        onDragEnd: (velocity) {},
      ));

      // Start drag from the left side (input jack area)
      final widget = find.byType(JackConnectionWidget);
      final topLeft = tester.getTopLeft(widget);
      final dragStart = topLeft + const Offset(10, 16); // Within jack area

      await tester.dragFrom(dragStart, const Offset(100, 0));
      await tester.pump();

      expect(dragStarted, isTrue);
      expect(dragUpdatePosition, isNotNull);
    });

    testWidgets('ignores drag gestures from label area', (WidgetTester tester) async {
      bool dragStarted = false;

      await tester.pumpWidget(createTestWidget(
        onDragStart: () => dragStarted = true,
      ));

      // Start drag from the middle (label area)
      final widget = find.byType(JackConnectionWidget);
      final center = tester.getCenter(widget);

      await tester.dragFrom(center, const Offset(100, 0));
      await tester.pump();

      expect(dragStarted, isFalse);
    });

    testWidgets('handles keyboard navigation', (WidgetTester tester) async {
      bool tapped = false;
      final focusNode = FocusNode();

      await tester.pumpWidget(createTestWidget(
        onTap: () => tapped = true,
        focusNode: focusNode,
      ));

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      // Simulate Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tapped, isTrue);

      // Reset and test Space key
      tapped = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles D key for drag initiation', (WidgetTester tester) async {
      bool dragStarted = false;
      final focusNode = FocusNode();

      await tester.pumpWidget(createTestWidget(
        onDragStart: () => dragStarted = true,
        focusNode: focusNode,
      ));

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      // Simulate D key
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();

      expect(dragStarted, isTrue);
    });

    testWidgets('shows focus indicator when focused', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(createTestWidget(
        focusNode: focusNode,
      ));

      // Initial state - not focused
      final initialSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(initialSemantics.hasFlag(SemanticsFlag.isFocused), isFalse);

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      // Should now show focused state
      final focusedSemantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(focusedSemantics.hasFlag(SemanticsFlag.isFocused), isTrue);
    });

    testWidgets('requests focus on tap when canRequestFocus is true', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(createTestWidget(
        focusNode: focusNode,
        canRequestFocus: true,
      ));

      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('does not request focus when canRequestFocus is false', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(createTestWidget(
        focusNode: focusNode,
        canRequestFocus: false,
      ));

      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('respects custom width', (WidgetTester tester) async {
      const customWidth = 200.0;
      
      await tester.pumpWidget(createTestWidget(
        customWidth: customWidth,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(customWidth));
    });

    testWidgets('uses default width when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(120.0));
    });

    testWidgets('handles different port types correctly', (WidgetTester tester) async {
      // Test with CV port
      final cvPort = const Port(
        id: 'cv_port',
        name: 'CV Port',
        type: PortType.cv,
        direction: PortDirection.output,
      );

      await tester.pumpWidget(createTestWidget(port: cvPort));
      
      var semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('cv'));
      expect(semantics.label, contains('output'));

      // Test with gate port
      final gatePort = const Port(
        id: 'gate_port',
        name: 'Gate Port',
        type: PortType.gate,
        direction: PortDirection.bidirectional,
      );

      await tester.pumpWidget(createTestWidget(port: gatePort));
      await tester.pump();
      
      semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('gate'));
      expect(semantics.label, contains('bidirectional'));

      // Test with clock port
      final clockPort = const Port(
        id: 'clock_port',
        name: 'Clock Port',
        type: PortType.clock,
        direction: PortDirection.input,
      );

      await tester.pumpWidget(createTestWidget(port: clockPort));
      await tester.pump();
      
      semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('clock'));
      expect(semantics.label, contains('input'));
    });

    testWidgets('drag from output jack area works correctly', (WidgetTester tester) async {
      bool dragStarted = false;

      final outputPort = const Port(
        id: 'output_port',
        name: 'Output Port',
        type: PortType.audio,
        direction: PortDirection.output,
      );

      await tester.pumpWidget(createTestWidget(
        port: outputPort,
        onDragStart: () => dragStarted = true,
      ));

      // Start drag from the right side (output jack area)
      final widget = find.byType(JackConnectionWidget);
      final topRight = tester.getTopRight(widget);
      final dragStart = topRight + const Offset(-10, 16); // Within jack area

      await tester.dragFrom(dragStart, const Offset(100, 0));
      await tester.pump();

      expect(dragStarted, isTrue);
    });

    // Golden tests would go here but require setup
    // Example structure for golden tests:
    /*
    testWidgets('matches golden image for audio input port', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await expectLater(
        find.byType(JackConnectionWidget),
        matchesGoldenFile('goldens/jack_connection_widget_audio_input.png'),
      );
    });

    testWidgets('matches golden image for selected state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));
      
      await expectLater(
        find.byType(JackConnectionWidget),
        matchesGoldenFile('goldens/jack_connection_widget_selected.png'),
      );
    });
    */
  });

  group('JackConnectionWidget Performance', () {
    testWidgets('animation controller is properly disposed', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JackConnectionWidget(
            port: const Port(
              id: 'test',
              name: 'Test',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ),
        ),
      ));

      // Navigate away to trigger disposal
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
        ),
      ));

      // If the animation controller wasn't disposed properly,
      // this would throw an error
      await tester.pump();
    });

    testWidgets('focus node is properly managed', (WidgetTester tester) async {
      // Test with internal focus node
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JackConnectionWidget(
            port: const Port(
              id: 'test1',
              name: 'Test1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ),
        ),
      ));

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));
      await tester.pump();

      // Test with external focus node
      final externalFocusNode = FocusNode();
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: JackConnectionWidget(
            port: const Port(
              id: 'test2',
              name: 'Test2',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
            focusNode: externalFocusNode,
          ),
        ),
      ));

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));
      await tester.pump();

      // External focus node should not be disposed by widget
      expect(externalFocusNode.canRequestFocus, isTrue);
      
      externalFocusNode.dispose();
    });
  });
}
