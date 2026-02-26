import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';

void main() {
  group('BusLabelFormatter', () {
    group('formatBusNumber', () {
      test('formats standard buses correctly', () {
        expect(BusLabelFormatter.formatBusNumber(1), 'I1');
        expect(BusLabelFormatter.formatBusNumber(12), 'I12');
        expect(BusLabelFormatter.formatBusNumber(13), 'O1');
        expect(BusLabelFormatter.formatBusNumber(20), 'O8');
        expect(BusLabelFormatter.formatBusNumber(21), 'A1');
        expect(BusLabelFormatter.formatBusNumber(28), 'A8');
      });

      test('formats legacy ES-5 buses (29-30)', () {
        expect(BusLabelFormatter.formatBusNumber(29), 'ES-5 L');
        expect(BusLabelFormatter.formatBusNumber(30), 'ES-5 R');
      });

      test('formats extended aux buses (31-64)', () {
        expect(BusLabelFormatter.formatBusNumber(31), 'A11');
        expect(BusLabelFormatter.formatBusNumber(42), 'A22');
        expect(BusLabelFormatter.formatBusNumber(64), 'A44');
      });

      test('formats extended ES-5 buses (65-66)', () {
        expect(BusLabelFormatter.formatBusNumber(65), 'ES-5 L');
        expect(BusLabelFormatter.formatBusNumber(66), 'ES-5 R');
      });

      test('returns null for invalid bus numbers', () {
        expect(BusLabelFormatter.formatBusNumber(0), isNull);
        expect(BusLabelFormatter.formatBusNumber(67), isNull);
        expect(BusLabelFormatter.formatBusNumber(null), isNull);
      });
    });

    group('getBusType', () {
      test('classifies extended ES-5 buses as es5', () {
        expect(BusLabelFormatter.getBusType(65), BusType.es5);
        expect(BusLabelFormatter.getBusType(66), BusType.es5);
      });

      test('classifies legacy ES-5 buses as es5', () {
        expect(BusLabelFormatter.getBusType(29), BusType.es5);
        expect(BusLabelFormatter.getBusType(30), BusType.es5);
      });

      test('classifies aux buses correctly', () {
        expect(BusLabelFormatter.getBusType(21), BusType.auxiliary);
        expect(BusLabelFormatter.getBusType(31), BusType.auxiliary);
        expect(BusLabelFormatter.getBusType(64), BusType.auxiliary);
      });
    });

    group('getLocalBusNumber', () {
      test('returns correct local number for extended ES-5', () {
        expect(BusLabelFormatter.getLocalBusNumber(65), 1);
        expect(BusLabelFormatter.getLocalBusNumber(66), 2);
      });

      test('returns correct local number for legacy ES-5', () {
        expect(BusLabelFormatter.getLocalBusNumber(29), 1);
        expect(BusLabelFormatter.getLocalBusNumber(30), 2);
      });

      test('returns correct local number for extended aux', () {
        expect(BusLabelFormatter.getLocalBusNumber(31), 11);
        expect(BusLabelFormatter.getLocalBusNumber(42), 22);
        expect(BusLabelFormatter.getLocalBusNumber(64), 44);
      });
    });

    group('isValidBusNumber', () {
      test('accepts extended range up to 66', () {
        expect(BusLabelFormatter.isValidBusNumber(64), isTrue);
        expect(BusLabelFormatter.isValidBusNumber(65), isTrue);
        expect(BusLabelFormatter.isValidBusNumber(66), isTrue);
        expect(BusLabelFormatter.isValidBusNumber(67), isFalse);
      });
    });
  });
}
