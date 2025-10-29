import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ES-5 Parameters Metadata', () {
    late Map<String, dynamic> metadata;

    setUpAll(() {
      // Load the full_metadata.json file
      // Find the project root by looking for pubspec.yaml
      var current = Directory.current;
      while (!File(path.join(current.path, 'pubspec.yaml')).existsSync()) {
        final parent = current.parent;
        if (parent.path == current.path) {
          throw Exception(
            'Could not find project root (pubspec.yaml not found)',
          );
        }
        current = parent;
      }

      final metadataPath = path.join(
        current.path,
        'assets',
        'metadata',
        'full_metadata.json',
      );
      final file = File(metadataPath);
      final jsonString = file.readAsStringSync();
      metadata = jsonDecode(jsonString) as Map<String, dynamic>;
    });

    group('Clock Algorithm (clck)', () {
      test('should have ES-5 Expander parameter (22)', () {
        final parameters = metadata['tables']['parameters'] as List<dynamic>;
        final es5Expander = parameters.firstWhere(
          (p) => p['algorithmGuid'] == 'clck' && p['parameterNumber'] == 22,
          orElse: () => null,
        );

        expect(
          es5Expander,
          isNotNull,
          reason: 'Clock parameter 22 (ES-5 Expander) should exist',
        );
        expect(es5Expander['name'], equals('1:ES-5 Expander'));
        expect(es5Expander['minValue'], equals(0));
        expect(es5Expander['maxValue'], equals(6));
        expect(es5Expander['defaultValue'], equals(0));
        expect(es5Expander['unitId'], isNull);
        expect(es5Expander['powerOfTen'], equals(0));
        expect(es5Expander['rawUnitIndex'], equals(14)); // Enum type
      });

      test('should have ES-5 Output parameter (23)', () {
        final parameters = metadata['tables']['parameters'] as List<dynamic>;
        final es5Output = parameters.firstWhere(
          (p) => p['algorithmGuid'] == 'clck' && p['parameterNumber'] == 23,
          orElse: () => null,
        );

        expect(
          es5Output,
          isNotNull,
          reason: 'Clock parameter 23 (ES-5 Output) should exist',
        );
        expect(es5Output['name'], equals('1:ES-5 Output'));
        expect(es5Output['minValue'], equals(1));
        expect(es5Output['maxValue'], equals(8));
        expect(es5Output['defaultValue'], equals(1));
        expect(es5Output['unitId'], isNull);
        expect(es5Output['powerOfTen'], equals(0));
        expect(es5Output['rawUnitIndex'], equals(0)); // Numeric type
      });

      test('should have correct enum values for ES-5 Expander', () {
        final parameterEnums =
            metadata['tables']['parameterEnums'] as List<dynamic>;
        final es5ExpanderEnums = parameterEnums
            .where(
              (e) => e['algorithmGuid'] == 'clck' && e['parameterNumber'] == 22,
            )
            .toList();

        // Note: ES-5 Expander enums are no longer in parameterEnums table
        // They are handled by the enum system (rawUnitIndex = 14)
        expect(
          es5ExpanderEnums.length,
          equals(0),
          reason: 'ES-5 Expander enums handled by enum system, not in parameterEnums',
        );
      });
    });

    group('Euclidean Algorithm (eucp)', () {
      test('should have ES-5 Expander parameter (13)', () {
        final parameters = metadata['tables']['parameters'] as List<dynamic>;
        final es5Expander = parameters.firstWhere(
          (p) => p['algorithmGuid'] == 'eucp' && p['parameterNumber'] == 13,
          orElse: () => null,
        );

        expect(
          es5Expander,
          isNotNull,
          reason: 'Euclidean parameter 13 (ES-5 Expander) should exist',
        );
        expect(es5Expander['name'], equals('1:ES-5 Expander'));
        expect(es5Expander['minValue'], equals(0));
        expect(es5Expander['maxValue'], equals(6));
        expect(es5Expander['defaultValue'], equals(0));
        expect(es5Expander['unitId'], isNull);
        expect(es5Expander['powerOfTen'], equals(0));
        expect(es5Expander['rawUnitIndex'], equals(14)); // Enum type
      });

      test('should have ES-5 Output parameter (14)', () {
        final parameters = metadata['tables']['parameters'] as List<dynamic>;
        final es5Output = parameters.firstWhere(
          (p) => p['algorithmGuid'] == 'eucp' && p['parameterNumber'] == 14,
          orElse: () => null,
        );

        expect(
          es5Output,
          isNotNull,
          reason: 'Euclidean parameter 14 (ES-5 Output) should exist',
        );
        expect(es5Output['name'], equals('1:ES-5 Output'));
        expect(es5Output['minValue'], equals(1));
        expect(es5Output['maxValue'], equals(8));
        expect(es5Output['defaultValue'], equals(1));
        expect(es5Output['unitId'], isNull);
        expect(es5Output['powerOfTen'], equals(0));
        expect(es5Output['rawUnitIndex'], equals(0)); // Numeric type
      });

      test('should have correct enum values for ES-5 Expander', () {
        final parameterEnums =
            metadata['tables']['parameterEnums'] as List<dynamic>;
        final es5ExpanderEnums = parameterEnums
            .where(
              (e) => e['algorithmGuid'] == 'eucp' && e['parameterNumber'] == 13,
            )
            .toList();

        // Note: ES-5 Expander enums are no longer in parameterEnums table
        // They are handled by the enum system (rawUnitIndex = 14)
        expect(
          es5ExpanderEnums.length,
          equals(0),
          reason: 'ES-5 Expander enums handled by enum system, not in parameterEnums',
        );
      });
    });

    group('Parameter Number Uniqueness', () {
      test(
        'Clock parameters 22 and 23 should not conflict with existing parameters',
        () {
          final parameters = metadata['tables']['parameters'] as List<dynamic>;
          final clockParams = parameters
              .where((p) => p['algorithmGuid'] == 'clck')
              .toList();

          // Check that we have exactly one parameter with number 22 and one with 23
          final param22Count = clockParams
              .where((p) => p['parameterNumber'] == 22)
              .length;
          final param23Count = clockParams
              .where((p) => p['parameterNumber'] == 23)
              .length;

          expect(
            param22Count,
            equals(1),
            reason: 'Should have exactly one parameter 22',
          );
          expect(
            param23Count,
            equals(1),
            reason: 'Should have exactly one parameter 23',
          );
        },
      );

      test(
        'Euclidean parameters 13 and 14 should not conflict with existing parameters',
        () {
          final parameters = metadata['tables']['parameters'] as List<dynamic>;
          final eucpParams = parameters
              .where((p) => p['algorithmGuid'] == 'eucp')
              .toList();

          // Check that we have exactly one parameter with number 13 and one with 14
          final param13Count = eucpParams
              .where((p) => p['parameterNumber'] == 13)
              .length;
          final param14Count = eucpParams
              .where((p) => p['parameterNumber'] == 14)
              .length;

          expect(
            param13Count,
            equals(1),
            reason: 'Should have exactly one parameter 13',
          );
          expect(
            param14Count,
            equals(1),
            reason: 'Should have exactly one parameter 14',
          );
        },
      );
    });
  });
}
