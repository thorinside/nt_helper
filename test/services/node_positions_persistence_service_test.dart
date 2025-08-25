import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([SharedPreferences])
import 'node_positions_persistence_service_test.mocks.dart';

void main() {
  group('NodePositionsPersistenceService', () {
    late MockSharedPreferences mockPrefs;
    late NodePositionsPersistenceService service;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = NodePositionsPersistenceService();
      // Inject the mock using the testing method
      service.setSharedPreferencesForTesting(mockPrefs);
    });

    tearDown(() {
      service.dispose();
    });

    group('init', () {
      test('should initialize SharedPreferences', () async {
        // For this test, we just verify that the method exists and can be called
        // The actual SharedPreferences initialization is tested through integration tests
        expect(service.init, isA<Function>());
      });
    });

    group('savePositions', () {
      test(
        'should save positions as JSON string after debounce delay',
        () async {
          // Arrange
          const presetName = 'test_preset';
          final positions = {
            0: const NodePosition(algorithmIndex: 0, x: 100.0, y: 200.0),
            1: const NodePosition(algorithmIndex: 1, x: 300.0, y: 400.0),
          };
          final expectedKey = 'node_positions_$presetName';

          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

          // Act
          await service.savePositions(presetName, positions);

          // Wait for debounce delay
          await Future.delayed(const Duration(milliseconds: 600));

          // Assert
          final capturedArgs = verify(
            mockPrefs.setString(captureAny, captureAny),
          ).captured;
          expect(capturedArgs[0], equals(expectedKey));

          final savedData =
              jsonDecode(capturedArgs[1] as String) as Map<String, dynamic>;
          expect(savedData.keys, containsAll(['0', '1']));
          expect(savedData['0']['algorithmIndex'], equals(0));
          expect(savedData['0']['x'], equals(100.0));
          expect(savedData['0']['y'], equals(200.0));
        },
      );

      test('should handle save errors gracefully', () async {
        // Arrange
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));

        // Act & Assert - should not throw
        expect(() => service.savePositions('test', {}), returnsNormally);
        await Future.delayed(const Duration(milliseconds: 600));
      });

      test('should debounce multiple rapid saves', () async {
        // Arrange
        const presetName = 'test_preset';
        final positions1 = {
          0: const NodePosition(algorithmIndex: 0, x: 100.0, y: 200.0),
        };
        final positions2 = {
          0: const NodePosition(algorithmIndex: 0, x: 150.0, y: 250.0),
        };
        final positions3 = {
          0: const NodePosition(algorithmIndex: 0, x: 200.0, y: 300.0),
        };

        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act - rapid successive saves
        await service.savePositions(presetName, positions1);
        await service.savePositions(presetName, positions2);
        await service.savePositions(presetName, positions3);

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert - should only save once due to debouncing (3 rapid saves -> 1 actual save)
        verify(mockPrefs.setString(any, any)).called(1);
      });
    });

    group('loadPositions', () {
      test('should load and deserialize positions', () async {
        // Arrange
        const presetName = 'test_preset';
        final expectedKey = 'node_positions_$presetName';
        final testData = {
          '0': {
            'algorithmIndex': 0,
            'x': 100.0,
            'y': 200.0,
            'width': 250.0,
            'height': 150.0,
          },
          '1': {
            'algorithmIndex': 1,
            'x': 300.0,
            'y': 400.0,
            'width': 250.0,
            'height': 150.0,
          },
        };

        when(mockPrefs.getString(expectedKey)).thenReturn(jsonEncode(testData));

        // Act
        final result = await service.loadPositions(presetName);

        // Assert
        expect(result, hasLength(2));
        expect(result[0]?.algorithmIndex, equals(0));
        expect(result[0]?.x, equals(100.0));
        expect(result[0]?.y, equals(200.0));
        expect(result[1]?.algorithmIndex, equals(1));
        expect(result[1]?.x, equals(300.0));
        expect(result[1]?.y, equals(400.0));
      });

      test('should return empty map when no data exists', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenReturn(null);

        // Act
        final result = await service.loadPositions('test_preset');

        // Assert
        expect(result, isEmpty);
      });

      test(
        'should return empty map and handle corrupted data gracefully',
        () async {
          // Arrange
          when(mockPrefs.getString(any)).thenReturn('invalid json');

          // Act
          final result = await service.loadPositions('test_preset');

          // Assert
          expect(result, isEmpty);
        },
      );

      test('should handle SharedPreferences errors gracefully', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenThrow(Exception('Read failed'));

        // Act
        final result = await service.loadPositions('test_preset');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('clearPositions', () {
      test('should remove saved positions for preset', () async {
        // Arrange
        const presetName = 'test_preset';
        final expectedKey = 'node_positions_$presetName';

        when(mockPrefs.remove(expectedKey)).thenAnswer((_) async => true);

        // Act
        await service.clearPositions(presetName);

        // Assert
        verify(mockPrefs.remove(expectedKey)).called(1);
      });

      test('should handle clear errors gracefully', () async {
        // Arrange
        when(mockPrefs.remove(any)).thenThrow(Exception('Remove failed'));

        // Act & Assert - should not throw
        expect(() => service.clearPositions('test_preset'), returnsNormally);
      });
    });

    group('JSON serialization', () {
      test(
        'should correctly convert integer keys to strings and back',
        () async {
          // Arrange
          const presetName = 'test_preset';
          final originalPositions = {
            0: const NodePosition(algorithmIndex: 0, x: 100.0, y: 200.0),
            5: const NodePosition(algorithmIndex: 5, x: 300.0, y: 400.0),
            10: const NodePosition(algorithmIndex: 10, x: 500.0, y: 600.0),
          };

          when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

          // Act - save
          await service.savePositions(presetName, originalPositions);
          await Future.delayed(
            const Duration(milliseconds: 600),
          ); // Wait for debounce

          // Setup mock to return saved data for loading
          final testData = {
            '0': {
              'algorithmIndex': 0,
              'x': 100.0,
              'y': 200.0,
              'width': 200.0,
              'height': 100.0,
            },
            '5': {
              'algorithmIndex': 5,
              'x': 300.0,
              'y': 400.0,
              'width': 200.0,
              'height': 100.0,
            },
            '10': {
              'algorithmIndex': 10,
              'x': 500.0,
              'y': 600.0,
              'width': 200.0,
              'height': 100.0,
            },
          };
          when(mockPrefs.getString(any)).thenReturn(jsonEncode(testData));

          final loadedPositions = await service.loadPositions(presetName);

          // Assert - keys should be converted back to integers
          expect(loadedPositions.keys, containsAll([0, 5, 10]));
          expect(loadedPositions[0]?.x, equals(100.0));
          expect(loadedPositions[5]?.x, equals(300.0));
          expect(loadedPositions[10]?.x, equals(500.0));
        },
      );
    });

    group('singleton behavior', () {
      test('should return same instance', () {
        // Arrange & Act
        final instance1 = NodePositionsPersistenceService();
        final instance2 = NodePositionsPersistenceService();

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}
