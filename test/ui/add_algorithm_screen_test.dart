import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/add_algorithm_screen.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockDistingCubit mockCubit;
  late AlgorithmInfo mockFactoryAlgorithm;
  late AlgorithmInfo mockUnloadedPlugin;
  late AlgorithmInfo mockLoadedPlugin;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(DistingState.initial());
  });

  setUp(() {
    mockCubit = MockDistingCubit();

    // Create mock algorithms for testing
    mockFactoryAlgorithm = const AlgorithmInfo(
      guid: 'clck',
      name: 'Clock',
      numSpecifications: 0,
      specifications: [],
      isLoaded: true, // Factory algorithms are always loaded
    );

    mockUnloadedPlugin = const AlgorithmInfo(
      guid: 'TestPlugin',
      name: 'Test Plugin',
      numSpecifications: 0,
      specifications: [],
      isLoaded: false, // Plugin not loaded
    );

    mockLoadedPlugin = const AlgorithmInfo(
      guid: 'TestPlugin',
      name: 'Test Plugin',
      numSpecifications: 2,
      specifications: [
        SpecificationInfo(name: 'Spec 1', min: 0, max: 10, defaultValue: 5),
        SpecificationInfo(name: 'Spec 2', min: -5, max: 5, defaultValue: 0),
      ],
      isLoaded: true, // Plugin loaded with specifications
    );

    // Set up SharedPreferences mocks
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<DistingCubit>.value(
        value: mockCubit,
        child: const AddAlgorithmScreen(),
      ),
    );
  }

  group('AddAlgorithmScreen Plugin Loading', () {
    testWidgets('displays Load Plugin button for unloaded plugin', (tester) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(
        DistingState.synchronized(
          disting: null,
          distingVersion: '',
          firmwareVersion: null,
          presetName: 'Test Preset',
          algorithms: [mockFactoryAlgorithm, mockUnloadedPlugin],
          slots: const [],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          loading: false,
          offline: false,
          screenshot: null,
          demo: false,
          videoStream: null,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select the unloaded plugin
      await tester.tap(find.text('Test Plugin'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Load Plugin'), findsOneWidget);
      expect(find.text('Add to Preset'), findsNothing);

      // Verify button is enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Load Plugin'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays Add to Preset button for loaded plugin', (tester) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(
        DistingState.synchronized(
          disting: null,
          distingVersion: '',
          firmwareVersion: null,
          presetName: 'Test Preset',
          algorithms: [mockFactoryAlgorithm, mockLoadedPlugin],
          slots: const [],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          loading: false,
          offline: false,
          screenshot: null,
          demo: false,
          videoStream: null,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select the loaded plugin
      await tester.tap(find.text('Test Plugin'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add to Preset'), findsOneWidget);
      expect(find.text('Load Plugin'), findsNothing);

      // Verify button is enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add to Preset'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays Add to Preset button for factory algorithm', (tester) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(
        DistingState.synchronized(
          disting: null,
          distingVersion: '',
          firmwareVersion: null,
          presetName: 'Test Preset',
          algorithms: [mockFactoryAlgorithm],
          slots: const [],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          loading: false,
          offline: false,
          screenshot: null,
          demo: false,
          videoStream: null,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select the factory algorithm
      await tester.tap(find.text('Clock'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add to Preset'), findsOneWidget);
      expect(find.text('Load Plugin'), findsNothing);
    });

    group('Plugin Loading Workflow', () {
      testWidgets('button changes to Add to Preset after successful plugin load', (tester) async {
        // This is the key test for the bug fix
        
        // Initial state: unloaded plugin
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockUnloadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        // Mock successful plugin loading
        when(() => mockCubit.loadPlugin('TestPlugin')).thenAnswer((_) async => mockLoadedPlugin);

        // Stream to simulate state updates
        final stateController = StreamController<DistingState>();
        when(() => mockCubit.stream).thenAnswer((_) => stateController.stream);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select the unloaded plugin
        await tester.tap(find.text('Test Plugin'));
        await tester.pumpAndSettle();

        // Verify initial state shows Load Plugin button
        expect(find.text('Load Plugin'), findsOneWidget);

        // Tap Load Plugin button
        await tester.tap(find.text('Load Plugin'));
        await tester.pump(); // Start the async operation

        // Simulate cubit state update after successful load
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockLoadedPlugin], // Now loaded
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        // Emit the updated state
        stateController.add(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockLoadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        await tester.pumpAndSettle(); // Process the state update

        // Assert: Button should now show "Add to Preset" without requiring another press
        expect(find.text('Add to Preset'), findsOneWidget);
        expect(find.text('Load Plugin'), findsNothing);

        // Verify loadPlugin was called
        verify(() => mockCubit.loadPlugin('TestPlugin')).called(1);

        stateController.close();
      });

      testWidgets('handles plugin loading failure gracefully', (tester) async {
        // Initial state: unloaded plugin
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockUnloadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        // Mock failed plugin loading
        when(() => mockCubit.loadPlugin('TestPlugin')).thenAnswer((_) async => null);

        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select the unloaded plugin
        await tester.tap(find.text('Test Plugin'));
        await tester.pumpAndSettle();

        // Tap Load Plugin button
        await tester.tap(find.text('Load Plugin'));
        await tester.pumpAndSettle();

        // Assert: Button should still show "Load Plugin" since loading failed
        expect(find.text('Load Plugin'), findsOneWidget);
        expect(find.text('Add to Preset'), findsNothing);

        // Check for error snackbar
        expect(find.text('Failed to load Test Plugin'), findsOneWidget);

        // Verify loadPlugin was called
        verify(() => mockCubit.loadPlugin('TestPlugin')).called(1);
      });

      testWidgets('shows loading snackbar during plugin load', (tester) async {
        // Initial state: unloaded plugin
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockUnloadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        // Mock delayed plugin loading
        final completer = Completer<AlgorithmInfo?>();
        when(() => mockCubit.loadPlugin('TestPlugin')).thenAnswer((_) => completer.future);

        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select the unloaded plugin
        await tester.tap(find.text('Test Plugin'));
        await tester.pumpAndSettle();

        // Tap Load Plugin button
        await tester.tap(find.text('Load Plugin'));
        await tester.pump(); // Start the async operation

        // Assert: Loading snackbar should be visible
        expect(find.text('Loading plugin Test Plugin...'), findsOneWidget);

        // Complete the loading
        completer.complete(mockLoadedPlugin);
        await tester.pumpAndSettle();

        // Assert: Success snackbar should now be visible
        expect(find.text('Test Plugin loaded with 2 specifications'), findsOneWidget);

        // Verify loadPlugin was called
        verify(() => mockCubit.loadPlugin('TestPlugin')).called(1);
      });
    });

    group('Plugin Type Detection', () {
      testWidgets('correctly identifies factory algorithms vs plugins', (tester) async {
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockFactoryAlgorithm, mockUnloadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Factory algorithm (lowercase GUID) should show extension icon for community plugins only
        await tester.tap(find.text('Clock'));
        await tester.pumpAndSettle();
        expect(find.text('Add to Preset'), findsOneWidget);

        // Plugin (uppercase GUID) should show load button when unloaded
        await tester.tap(find.text('Test Plugin'));
        await tester.pumpAndSettle();
        expect(find.text('Load Plugin'), findsOneWidget);
      });
    });

    group('State Synchronization', () {
      testWidgets('updates algorithm list when cubit state changes', (tester) async {
        final stateController = StreamController<DistingState>();

        when(() => mockCubit.stream).thenAnswer((_) => stateController.stream);

        // Initial state with one algorithm
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockFactoryAlgorithm],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show only the factory algorithm
        expect(find.text('Clock'), findsOneWidget);
        expect(find.text('Test Plugin'), findsNothing);

        // Update state to include the plugin
        when(() => mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockFactoryAlgorithm, mockLoadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        // Emit new state
        stateController.add(
          DistingState.synchronized(
            disting: null,
            distingVersion: '',
            firmwareVersion: null,
            presetName: 'Test Preset',
            algorithms: [mockFactoryAlgorithm, mockLoadedPlugin],
            slots: const [],
            unitStrings: const [],
            inputDevice: null,
            outputDevice: null,
            loading: false,
            offline: false,
            screenshot: null,
            demo: false,
            videoStream: null,
          ),
        );

        await tester.pumpAndSettle();

        // Should now show both algorithms
        expect(find.text('Clock'), findsOneWidget);
        expect(find.text('Test Plugin'), findsOneWidget);

        stateController.close();
      });
    });
  });
}