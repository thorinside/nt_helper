import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late DistingCubit cubit;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late MockDistingMidiManager mockDisting;

  late AlgorithmInfo unloadedPlugin;
  late AlgorithmInfo loadedPlugin;
  late AlgorithmInfo factoryAlgorithm;

  setUpAll(() {
    registerFallbackValue(DistingState.initial());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();
    mockDisting = MockDistingMidiManager();

    // Setup database mock
    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);
    when(() => mockMetadataDao.hasCachedAlgorithms()).thenAnswer((_) async => false);

    cubit = DistingCubit(mockDatabase);

    // Create test algorithm data
    unloadedPlugin = const AlgorithmInfo(
      guid: 'TestPlugin',
      name: 'Test Plugin',
      numSpecifications: 0,
      specifications: [],
      isLoaded: false,
    );

    loadedPlugin = const AlgorithmInfo(
      guid: 'TestPlugin',
      name: 'Test Plugin',
      numSpecifications: 2,
      specifications: [
        SpecificationInfo(name: 'Param 1', min: 0, max: 100, defaultValue: 50),
        SpecificationInfo(name: 'Param 2', min: -10, max: 10, defaultValue: 0),
      ],
      isLoaded: true,
    );

    factoryAlgorithm = const AlgorithmInfo(
      guid: 'clck',
      name: 'Clock',
      numSpecifications: 1,
      specifications: [
        SpecificationInfo(name: 'Rate', min: 0, max: 255, defaultValue: 128),
      ],
      isLoaded: true,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DistingCubit loadPlugin', () {
    test('returns null when not in synchronized state', () async {
      // Arrange - cubit starts in initial state
      expect(cubit.state, isA<DistingStateInitial>());

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, isNull);
    });

    test('returns null when algorithm not found', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [factoryAlgorithm],
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

      // Act
      final result = await cubit.loadPlugin('NonExistentPlugin');

      // Assert
      expect(result, isNull);
    });

    test('returns algorithm immediately if already loaded', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [loadedPlugin], // Already loaded
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

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, equals(loadedPlugin));
      verifyNever(() => mockDisting.requestLoadPlugin(any()));
    });

    test('loads plugin and updates state correctly', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [factoryAlgorithm, unloadedPlugin],
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
      when(() => mockDisting.requestLoadPlugin('TestPlugin')).thenAnswer((_) async => {});
      when(() => mockDisting.requestAlgorithmInfo(1)).thenAnswer((_) async => loadedPlugin);

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, equals(loadedPlugin));

      // Verify the state was updated correctly
      final newState = cubit.state as DistingStateSynchronized;
      expect(newState.algorithms.length, equals(2));
      expect(newState.algorithms[0], equals(factoryAlgorithm)); // Unchanged
      expect(newState.algorithms[1], equals(loadedPlugin)); // Updated
      expect(newState.algorithms[1].isLoaded, isTrue);
      expect(newState.algorithms[1].numSpecifications, equals(2));

      // Verify correct calls were made
      verify(() => mockDisting.requestLoadPlugin('TestPlugin')).called(1);
      verify(() => mockDisting.requestAlgorithmInfo(1)).called(1);
    });

    test('handles plugin loading failure gracefully', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [unloadedPlugin],
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
      when(() => mockDisting.requestLoadPlugin('TestPlugin')).thenThrow(Exception('Load failed'));

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, isNull);

      // State should remain unchanged
      final state = cubit.state as DistingStateSynchronized;
      expect(state.algorithms.length, equals(1));
      expect(state.algorithms[0], equals(unloadedPlugin));
      expect(state.algorithms[0].isLoaded, isFalse);

      verify(() => mockDisting.requestLoadPlugin('TestPlugin')).called(1);
      verifyNever(() => mockDisting.requestAlgorithmInfo(any()));
    });

    test('handles algorithm info request failure gracefully', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [unloadedPlugin],
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

      // Mock successful load but failed info request
      when(() => mockDisting.requestLoadPlugin('TestPlugin')).thenAnswer((_) async => {});
      when(() => mockDisting.requestAlgorithmInfo(0)).thenAnswer((_) async => null);

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, isNull);

      // State should remain unchanged
      final state = cubit.state as DistingStateSynchronized;
      expect(state.algorithms.length, equals(1));
      expect(state.algorithms[0], equals(unloadedPlugin));

      verify(() => mockDisting.requestLoadPlugin('TestPlugin')).called(1);
      verify(() => mockDisting.requestAlgorithmInfo(0)).called(1);
    });

    test('preserves other algorithms when loading one plugin', () async {
      // Arrange
      final anotherPlugin = const AlgorithmInfo(
        guid: 'AnotherPlugin',
        name: 'Another Plugin',
        numSpecifications: 0,
        specifications: [],
        isLoaded: false,
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '1.0',
          firmwareVersion: null,
          presetName: 'Test',
          algorithms: [factoryAlgorithm, unloadedPlugin, anotherPlugin],
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
      when(() => mockDisting.requestLoadPlugin('TestPlugin')).thenAnswer((_) async => {});
      when(() => mockDisting.requestAlgorithmInfo(1)).thenAnswer((_) async => loadedPlugin);

      // Act
      final result = await cubit.loadPlugin('TestPlugin');

      // Assert
      expect(result, equals(loadedPlugin));

      // Verify all algorithms are preserved with only the target one updated
      final newState = cubit.state as DistingStateSynchronized;
      expect(newState.algorithms.length, equals(3));
      expect(newState.algorithms[0], equals(factoryAlgorithm)); // Unchanged
      expect(newState.algorithms[1], equals(loadedPlugin)); // Updated
      expect(newState.algorithms[2], equals(anotherPlugin)); // Unchanged
    });

    group('Plugin Loading Integration', () {
      test('demonstrates fix for double-button-press bug', () async {
        // This test demonstrates that the cubit properly updates the algorithm
        // state, which should be reflected in the UI without requiring a second button press.

        // Arrange - Start with unloaded plugin
        cubit.emit(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '1.0',
            firmwareVersion: null,
            presetName: 'Test',
            algorithms: [unloadedPlugin],
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

        // Mock successful loading
        when(() => mockDisting.requestLoadPlugin('TestPlugin')).thenAnswer((_) async => {});
        when(() => mockDisting.requestAlgorithmInfo(0)).thenAnswer((_) async => loadedPlugin);

        // Verify initial state
        var currentState = cubit.state as DistingStateSynchronized;
        expect(currentState.algorithms[0].isLoaded, isFalse);
        expect(currentState.algorithms[0].numSpecifications, equals(0));

        // Act - Load plugin
        final result = await cubit.loadPlugin('TestPlugin');

        // Assert - Algorithm is now loaded in the cubit's state
        expect(result, equals(loadedPlugin));
        
        currentState = cubit.state as DistingStateSynchronized;
        expect(currentState.algorithms[0].isLoaded, isTrue);
        expect(currentState.algorithms[0].numSpecifications, equals(2));
        expect(currentState.algorithms[0].specifications.length, equals(2));

        // This updated state should cause the widget to rebuild and show
        // the "Add to Preset" button without requiring a second button press
      });
    });
  });
}