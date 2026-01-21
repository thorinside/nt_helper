import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/util/ui_helpers.dart';

void main() {
  group('cleanTitle', () {
    group('preserves full parameter name for arbitrary prefixes', () {
      test('letter prefix like "A:Clock" is preserved', () {
        expect(cleanTitle('A:Clock'), 'A:Clock');
      });

      test('letter prefix like "B:Input" is preserved', () {
        expect(cleanTitle('B:Input'), 'B:Input');
      });

      test('word prefix like "in:Level" is preserved', () {
        expect(cleanTitle('in:Level'), 'in:Level');
      });

      test('word prefix like "out:Bus" is preserved', () {
        expect(cleanTitle('out:Bus'), 'out:Bus');
      });

      test('multi-word prefix like "Head A:Routing" is preserved', () {
        expect(cleanTitle('Head A:Routing'), 'Head A:Routing');
      });

      test('prefix without colon like "HeadAClock" is preserved', () {
        expect(cleanTitle('HeadAClock'), 'HeadAClock');
      });
    });

    group('preserves numeric prefixes (changed behavior)', () {
      // Previously these were stripped, now they are preserved
      test('numeric prefix "1:Input" is preserved', () {
        expect(cleanTitle('1:Input'), '1:Input');
      });

      test('numeric prefix "2:Output" is preserved', () {
        expect(cleanTitle('2:Output'), '2:Output');
      });

      test('numeric prefix "12:Channel" is preserved', () {
        expect(cleanTitle('12:Channel'), '12:Channel');
      });

      test('numeric prefix with space "1: Pitch" is preserved', () {
        expect(cleanTitle('1: Pitch'), '1: Pitch');
      });
    });

    group('handles edge cases', () {
      test('empty string returns empty string', () {
        expect(cleanTitle(''), '');
      });

      test('name with only colon ":" is preserved', () {
        expect(cleanTitle(':'), ':');
      });

      test('name starting with colon ":Value" is preserved', () {
        expect(cleanTitle(':Value'), ':Value');
      });

      test('name with multiple colons "A:B:C" is preserved', () {
        expect(cleanTitle('A:B:C'), 'A:B:C');
      });

      test('simple name without prefix "Frequency" is preserved', () {
        expect(cleanTitle('Frequency'), 'Frequency');
      });
    });
  });
}
