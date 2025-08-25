import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
// import 'package:nt_helper/cubit/disting_cubit.dart'; // For future TDD phases
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
// import 'package:nt_helper/models/connection.dart'; // For future TDD phases
import 'package:nt_helper/models/tidy_result.dart';

import 'tidy_action_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NodeRoutingCubit>()])
void main() {
  // Configure Mockito to provide dummy values for sealed classes
  provideDummy<NodeRoutingState>(const NodeRoutingState.initial());

  group('Tidy Action UI Integration', () {
    late MockNodeRoutingCubit mockNodeRoutingCubit;

    setUp(() {
      mockNodeRoutingCubit = MockNodeRoutingCubit();

      // Setup default stream behavior for BlocProvider
      when(mockNodeRoutingCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([const NodeRoutingState.initial()]),
      );
      when(
        mockNodeRoutingCubit.state,
      ).thenReturn(const NodeRoutingState.initial());
    });

    testWidgets('should call performTidy when tidy button is pressed', (
      tester,
    ) async {
      // Create a simple widget that tests the tidy functionality
      final testWidget = MaterialApp(
        home: Scaffold(
          body: BlocProvider<NodeRoutingCubit>.value(
            value: mockNodeRoutingCubit,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await context.read<NodeRoutingCubit>().performTidy();
                  },
                  child: const Text('Tidy'),
                );
              },
            ),
          ),
        ),
      );

      // Mock the performTidy method
      when(mockNodeRoutingCubit.performTidy()).thenAnswer(
        (_) async => TidyResult.success(
          originalConnections: const [],
          optimizedConnections: const [],
          busesFreed: 1,
          changes: const {},
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Find and tap the tidy button
      final tidyButton = find.text('Tidy');
      expect(tidyButton, findsOneWidget);

      await tester.tap(tidyButton);
      await tester.pump();

      // Verify that performTidy was called
      verify(mockNodeRoutingCubit.performTidy()).called(1);
    });

    testWidgets('should handle tidy operation errors gracefully', (
      tester,
    ) async {
      // Create a simple test widget
      final testWidget = MaterialApp(
        home: Scaffold(
          body: BlocProvider<NodeRoutingCubit>.value(
            value: mockNodeRoutingCubit,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final result = await context
                        .read<NodeRoutingCubit>()
                        .performTidy();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.success
                              ? 'Success: ${result.busesFreed} buses freed'
                              : 'Error: ${result.errorMessage}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Tidy'),
                );
              },
            ),
          ),
        ),
      );

      // Mock failed tidy operation
      when(
        mockNodeRoutingCubit.performTidy(),
      ).thenAnswer((_) async => TidyResult.failed('Test optimization failed'));

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Tap the tidy button
      await tester.tap(find.text('Tidy'));
      await tester.pump();

      // Verify that performTidy was called
      verify(mockNodeRoutingCubit.performTidy()).called(1);

      // Should show error in snackbar
      await tester.pump();
      expect(find.text('Error: Test optimization failed'), findsOneWidget);
    });
  });
}
