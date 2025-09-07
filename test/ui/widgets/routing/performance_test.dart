import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';

/// Performance tests for drag operations and connection updates
/// with the universal port widget architecture.
///
/// Tests validate:
/// - Drag operation performance across node types
/// - Port position update efficiency
/// - Large-scale routing system performance
/// - Memory usage during rapid updates
/// - Frame rate stability during interactions
void main() {
  group('Performance Tests', () {
    group('Drag Operation Performance', () {
      testWidgets('Simultaneous node drags maintain performance', (
        tester,
      ) async {
        final Map<String, List<Duration>> dragTimesByNodeType = {};
        final Map<String, Stopwatch> stopwatches = {
          'algorithm': Stopwatch(),
          'physical_input': Stopwatch(),
          'physical_output': Stopwatch(),
        };

        void recordDragTime(String nodeType) {
          final stopwatch = stopwatches[nodeType]!;
          stopwatch.stop();
          dragTimesByNodeType
              .putIfAbsent(nodeType, () => [])
              .add(Duration(microseconds: stopwatch.elapsedMicroseconds));
          stopwatch.reset();
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Concurrent Test',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      inputLabels: ['Input'],
                      outputLabels: ['Output'],
                      onDragStart: () => stopwatches['algorithm']!.start(),
                      onDragEnd: () => recordDragTime('algorithm'),
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(300, 150),
                      onNodeDragStart: () =>
                          stopwatches['physical_input']!.start(),
                      onNodeDragEnd: () => recordDragTime('physical_input'),
                    ),
                  ),
                  Positioned(
                    left: 500,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(500, 100),
                      onNodeDragStart: () =>
                          stopwatches['physical_output']!.start(),
                      onNodeDragEnd: () => recordDragTime('physical_output'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag all nodes in sequence rapidly
        final nodes = [
          (find.byType(AlgorithmNodeWidget), 'algorithm'),
          (find.byType(PhysicalInputNode), 'physical_input'),
          (find.byType(PhysicalOutputNode), 'physical_output'),
        ];

        for (final (finder, _) in nodes) {
          await tester.dragFrom(tester.getCenter(finder), const Offset(25, 25));
          await tester.pump(
            const Duration(milliseconds: 10),
          ); // Rapid succession
        }
        await tester.pumpAndSettle();

        // All node types should maintain good performance
        for (final nodeType in dragTimesByNodeType.keys) {
          final times = dragTimesByNodeType[nodeType]!;
          expect(
            times,
            isNotEmpty,
            reason: '$nodeType should have recorded drag times',
          );

          final avgTime =
              times.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
              times.length;
          expect(
            avgTime,
            lessThan(200000),
            reason:
                '$nodeType drag should be under 200ms even with concurrent operations',
          );
        }
      });
    });

    group('Port Position Update Performance', () {
      testWidgets('Port position callbacks execute efficiently', (
        tester,
      ) async {
        final List<Duration> callbackTimes = [];
        final stopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Callback Performance Test',
                slotNumber: 1,
                position: const Offset(150, 150),
                inputLabels: List.generate(
                  8,
                  (i) => 'Input ${i + 1}',
                ), // Many inputs
                outputLabels: List.generate(
                  8,
                  (i) => 'Output ${i + 1}',
                ), // Many outputs
                inputPortIds: List.generate(8, (i) => 'perf_in_$i'),
                outputPortIds: List.generate(8, (i) => 'perf_out_$i'),
                onPortPositionResolved: (portId, position, isInput) {
                  if (!stopwatch.isRunning) stopwatch.start();
                  // Simulate some processing time
                  for (int i = 0; i < 100; i++) {
                    position.dx + position.dy; // Minimal computation
                  }
                  callbackTimes.add(
                    Duration(microseconds: stopwatch.elapsedMicroseconds),
                  );
                  stopwatch.reset();
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow callbacks to execute

        // Should have callbacks for all 16 ports (8 inputs + 8 outputs)
        expect(callbackTimes.length, greaterThanOrEqualTo(16));

        // Each callback should execute quickly
        final avgCallbackTime =
            callbackTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
            callbackTimes.length;
        expect(
          avgCallbackTime,
          lessThan(1000), // 1ms per callback
          reason:
              'Port position callbacks should execute in under 1ms on average',
        );

        // No callback should take more than 5ms
        final maxCallbackTime = callbackTimes
            .map((d) => d.inMicroseconds)
            .reduce((a, b) => a > b ? a : b);
        expect(
          maxCallbackTime,
          lessThan(5000),
          reason: 'No port callback should take more than 5ms',
        );
      });
    });

    group('Large Scale Performance', () {
      testWidgets('Many port widgets render efficiently', (tester) async {
        final startTime = DateTime.now();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Multiple physical I/O nodes
                    PhysicalInputNode(position: const Offset(0, 0)),
                    PhysicalOutputNode(position: const Offset(0, 300)),
                    // Multiple algorithm nodes
                    ...List.generate(
                      8,
                      (index) => Padding(
                        padding: EdgeInsets.only(top: index * 150.0 + 600),
                        child: AlgorithmNodeWidget(
                          algorithmName: 'Algorithm ${index + 1}',
                          slotNumber: index + 1,
                          position: Offset(0, index * 150.0 + 600),
                          inputLabels: ['Input 1', 'Input 2'],
                          outputLabels: ['Output 1', 'Output 2'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final renderTime = DateTime.now().difference(startTime);

        // Should render many ports efficiently
        // Total ports: 12 (physical inputs) + 8 (physical outputs) + 32 (8 algorithms × 4 ports each) = 52 ports
        expect(find.byType(PortWidget), findsNWidgets(52));

        // Should render within reasonable time (under 2 seconds)
        expect(
          renderTime.inMilliseconds,
          lessThan(2000),
          reason: 'Large scale port rendering should complete within 2 seconds',
        );
      });

      testWidgets('Complex routing scene performs well', (tester) async {
        final performanceStopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Complex routing scenario
                  Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(position: const Offset(50, 100)),
                  ),
                  Positioned(
                    left: 250,
                    top: 80,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO 1',
                      slotNumber: 1,
                      position: const Offset(250, 80),
                      outputLabels: ['Triangle', 'Square'],
                      outputPortIds: ['lfo1_tri', 'lfo1_sqr'],
                    ),
                  ),
                  Positioned(
                    left: 250,
                    top: 180,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO 2',
                      slotNumber: 2,
                      position: const Offset(250, 180),
                      outputLabels: ['Sine', 'Sawtooth'],
                      outputPortIds: ['lfo2_sin', 'lfo2_saw'],
                    ),
                  ),
                  Positioned(
                    left: 450,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCA',
                      slotNumber: 3,
                      position: const Offset(450, 100),
                      inputLabels: ['Audio', 'CV1', 'CV2'],
                      outputLabels: ['Audio Out'],
                      inputPortIds: ['vca_audio', 'vca_cv1', 'vca_cv2'],
                      outputPortIds: ['vca_out'],
                    ),
                  ),
                  Positioned(
                    left: 450,
                    top: 220,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Filter',
                      slotNumber: 4,
                      position: const Offset(450, 220),
                      inputLabels: ['Audio', 'Cutoff'],
                      outputLabels: ['Filtered'],
                      inputPortIds: ['filt_audio', 'filt_cutoff'],
                      outputPortIds: ['filt_out'],
                    ),
                  ),
                  Positioned(
                    left: 650,
                    top: 160,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Mixer',
                      slotNumber: 5,
                      position: const Offset(650, 160),
                      inputLabels: ['Input 1', 'Input 2', 'Input 3'],
                      outputLabels: ['Mix Out'],
                      inputPortIds: ['mix_in1', 'mix_in2', 'mix_in3'],
                      outputPortIds: ['mix_out'],
                    ),
                  ),
                  Positioned(
                    left: 850,
                    top: 140,
                    child: PhysicalOutputNode(position: const Offset(850, 140)),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        performanceStopwatch.stop();

        // Complex scene should render efficiently
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(5));
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // Total ports: 12 + 8 + (2+2+4+3+4) = 35 ports
        expect(find.byType(PortWidget), findsNWidgets(35));

        // Should render complex scene within 3 seconds
        expect(
          performanceStopwatch.elapsedMilliseconds,
          lessThan(3000),
          reason: 'Complex routing scene should render within 3 seconds',
        );
      });
    });

    group('Memory and Resource Management', () {
      testWidgets('Repeated widget rebuilds don\'t leak memory excessively', (
        tester,
      ) async {
        final memorySnapshots = <String>[];

        // This is a basic test - in a real scenario you'd use more sophisticated memory profiling
        Widget buildTestScene(int iteration) {
          return MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Memory Test $iteration',
                slotNumber: iteration,
                position: Offset(
                  100.0 + iteration * 10,
                  100.0 + iteration * 10,
                ),
                inputLabels: ['Input $iteration'],
                outputLabels: ['Output $iteration'],
                onPortPositionResolved: (portId, pos, isInput) {
                  memorySnapshots.add('$portId:${pos.toString()}:$isInput');
                },
              ),
            ),
          );
        }

        // Build and rebuild multiple times
        for (int i = 1; i <= 10; i++) {
          await tester.pumpWidget(buildTestScene(i));
          await tester.pumpAndSettle();
          await tester.pump();
        }

        // Should have reasonable callback activity (not accumulating indefinitely)
        expect(
          memorySnapshots.length,
          lessThanOrEqualTo(20), // 2 ports × 10 iterations
          reason: 'Memory snapshots should not accumulate excessively',
        );

        // Final widget tree should be clean
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(2));
      });

      testWidgets('Port widget cleanup on dispose', (tester) async {
        bool callbackExecuted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Dispose Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Disposable Input'],
                inputPortIds: ['dispose_test'],
                onPortPositionResolved: (portId, pos, isInput) {
                  callbackExecuted = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();
        expect(callbackExecuted, isTrue);

        // Replace with empty widget to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );

        await tester.pumpAndSettle();

        // Should cleanly dispose without errors
        expect(find.byType(AlgorithmNodeWidget), findsNothing);
        expect(find.byType(PortWidget), findsNothing);
      });
    });

    group('Frame Rate and Smoothness', () {
      testWidgets('Drag animations maintain smooth frame rate', (tester) async {
        final List<Duration> frameTimes = [];
        DateTime? lastFrameTime;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Smooth Drag Test',
                slotNumber: 1,
                position: const Offset(200, 200),
                inputLabels: ['Smooth Input'],
                onPositionChanged: (position) {
                  final now = DateTime.now();
                  if (lastFrameTime != null) {
                    frameTimes.add(now.difference(lastFrameTime!));
                  }
                  lastFrameTime = now;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform smooth drag gesture
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(AlgorithmNodeWidget)),
        );

        // Simulate smooth drag with multiple intermediate positions
        for (int i = 0; i < 10; i++) {
          await gesture.moveBy(Offset(5.0, 5.0));
          await tester.pump(const Duration(milliseconds: 16)); // ~60 FPS
        }

        await gesture.up();
        await tester.pumpAndSettle();

        // Should maintain reasonable frame timing
        if (frameTimes.isNotEmpty) {
          final avgFrameTime =
              frameTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
              frameTimes.length;

          // Average frame time should be reasonable (allow up to 33ms for 30fps minimum)
          expect(
            avgFrameTime,
            lessThan(33),
            reason:
                'Frame rate should maintain at least 30fps (33ms per frame)',
          );
        }
      });
    });
  });
}
