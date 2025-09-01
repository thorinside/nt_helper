import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';

void main() {
  group('BusLabelFormatter', () {
    group('formatBusNumber', () {
      test('should format input buses (1-12) as I1-I12', () {
        expect(BusLabelFormatter.formatBusNumber(1), 'I1');
        expect(BusLabelFormatter.formatBusNumber(6), 'I6');
        expect(BusLabelFormatter.formatBusNumber(12), 'I12');
      });

      test('should format output buses (13-20) as O1-O8', () {
        expect(BusLabelFormatter.formatBusNumber(13), 'O1');
        expect(BusLabelFormatter.formatBusNumber(16), 'O4');
        expect(BusLabelFormatter.formatBusNumber(20), 'O8');
      });

      test('should format auxiliary buses (21-28) as A1-A8', () {
        expect(BusLabelFormatter.formatBusNumber(21), 'A1');
        expect(BusLabelFormatter.formatBusNumber(24), 'A4');
        expect(BusLabelFormatter.formatBusNumber(28), 'A8');
      });

      test('should return null for invalid bus numbers', () {
        expect(BusLabelFormatter.formatBusNumber(0), null);
        expect(BusLabelFormatter.formatBusNumber(-1), null);
        expect(BusLabelFormatter.formatBusNumber(29), null);
        expect(BusLabelFormatter.formatBusNumber(100), null);
      });

      test('should handle null input', () {
        expect(BusLabelFormatter.formatBusNumber(null), null);
      });
    });

    group('getBusType', () {
      test('should identify input buses', () {
        expect(BusLabelFormatter.getBusType(1), BusType.input);
        expect(BusLabelFormatter.getBusType(6), BusType.input);
        expect(BusLabelFormatter.getBusType(12), BusType.input);
      });

      test('should identify output buses', () {
        expect(BusLabelFormatter.getBusType(13), BusType.output);
        expect(BusLabelFormatter.getBusType(16), BusType.output);
        expect(BusLabelFormatter.getBusType(20), BusType.output);
      });

      test('should identify auxiliary buses', () {
        expect(BusLabelFormatter.getBusType(21), BusType.auxiliary);
        expect(BusLabelFormatter.getBusType(24), BusType.auxiliary);
        expect(BusLabelFormatter.getBusType(28), BusType.auxiliary);
      });

      test('should return null for invalid bus numbers', () {
        expect(BusLabelFormatter.getBusType(0), null);
        expect(BusLabelFormatter.getBusType(-1), null);
        expect(BusLabelFormatter.getBusType(29), null);
        expect(BusLabelFormatter.getBusType(100), null);
      });

      test('should handle null input', () {
        expect(BusLabelFormatter.getBusType(null), null);
      });
    });

    group('isValidBusNumber', () {
      test('should return true for valid bus numbers', () {
        expect(BusLabelFormatter.isValidBusNumber(1), true);
        expect(BusLabelFormatter.isValidBusNumber(12), true);
        expect(BusLabelFormatter.isValidBusNumber(13), true);
        expect(BusLabelFormatter.isValidBusNumber(20), true);
        expect(BusLabelFormatter.isValidBusNumber(21), true);
        expect(BusLabelFormatter.isValidBusNumber(28), true);
      });

      test('should return false for invalid bus numbers', () {
        expect(BusLabelFormatter.isValidBusNumber(0), false);
        expect(BusLabelFormatter.isValidBusNumber(-1), false);
        expect(BusLabelFormatter.isValidBusNumber(29), false);
        expect(BusLabelFormatter.isValidBusNumber(100), false);
      });

      test('should return false for null', () {
        expect(BusLabelFormatter.isValidBusNumber(null), false);
      });
    });

    group('getBusRange', () {
      test('should return correct range for input buses', () {
        expect(BusLabelFormatter.getBusRange(BusType.input), [1, 12]);
      });

      test('should return correct range for output buses', () {
        expect(BusLabelFormatter.getBusRange(BusType.output), [13, 20]);
      });

      test('should return correct range for auxiliary buses', () {
        expect(BusLabelFormatter.getBusRange(BusType.auxiliary), [21, 28]);
      });
    });

    group('getLocalBusNumber', () {
      test('should convert global bus number to local input number', () {
        expect(BusLabelFormatter.getLocalBusNumber(1), 1);
        expect(BusLabelFormatter.getLocalBusNumber(6), 6);
        expect(BusLabelFormatter.getLocalBusNumber(12), 12);
      });

      test('should convert global bus number to local output number', () {
        expect(BusLabelFormatter.getLocalBusNumber(13), 1);
        expect(BusLabelFormatter.getLocalBusNumber(16), 4);
        expect(BusLabelFormatter.getLocalBusNumber(20), 8);
      });

      test('should convert global bus number to local auxiliary number', () {
        expect(BusLabelFormatter.getLocalBusNumber(21), 1);
        expect(BusLabelFormatter.getLocalBusNumber(24), 4);
        expect(BusLabelFormatter.getLocalBusNumber(28), 8);
      });

      test('should return null for invalid bus numbers', () {
        expect(BusLabelFormatter.getLocalBusNumber(0), null);
        expect(BusLabelFormatter.getLocalBusNumber(29), null);
        expect(BusLabelFormatter.getLocalBusNumber(null), null);
      });
    });
  });
}