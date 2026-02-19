import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/mcp/utils/bus_mapping.dart';

void main() {
  group('BusMapping', () {
    group('busToName', () {
      test('returns None for bus 0', () {
        expect(BusMapping.busToName(0), 'None');
      });

      test('returns correct names for all input buses 1-12', () {
        for (var i = 1; i <= 12; i++) {
          expect(BusMapping.busToName(i), 'Input $i');
        }
      });

      test('returns correct names for all output buses 13-20', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.busToName(12 + i), 'Output $i');
        }
      });

      test('returns correct names for all aux buses 21-28', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.busToName(20 + i), 'Aux $i');
        }
      });

      test('returns null for negative bus number', () {
        expect(BusMapping.busToName(-1), isNull);
      });

      test('returns null for bus number 29 (out of range)', () {
        expect(BusMapping.busToName(29), isNull);
      });

      test('returns null for very large bus number', () {
        expect(BusMapping.busToName(1000), isNull);
      });
    });

    group('nameToBus', () {
      test('returns 0 for None', () {
        expect(BusMapping.nameToBus('None'), 0);
      });

      test('returns correct bus number for Input 1', () {
        expect(BusMapping.nameToBus('Input 1'), 1);
      });

      test('returns correct bus number for Output 1', () {
        expect(BusMapping.nameToBus('Output 1'), 13);
      });

      test('returns correct bus number for Aux 1', () {
        expect(BusMapping.nameToBus('Aux 1'), 21);
      });

      test('is case-insensitive', () {
        expect(BusMapping.nameToBus('input 1'), 1);
        expect(BusMapping.nameToBus('INPUT 1'), 1);
        expect(BusMapping.nameToBus('none'), 0);
        expect(BusMapping.nameToBus('NONE'), 0);
        expect(BusMapping.nameToBus('output 1'), 13);
        expect(BusMapping.nameToBus('AUX 1'), 21);
      });

      test('trims whitespace', () {
        expect(BusMapping.nameToBus('  Input 1  '), 1);
        expect(BusMapping.nameToBus('  None  '), 0);
      });

      test('returns null for unknown name', () {
        expect(BusMapping.nameToBus('Unknown'), isNull);
      });

      test('returns null for empty string', () {
        expect(BusMapping.nameToBus(''), isNull);
      });

      test('returns null for partial match', () {
        expect(BusMapping.nameToBus('Input'), isNull);
        expect(BusMapping.nameToBus('Aux'), isNull);
      });

      test('returns correct values for all input names', () {
        for (var i = 1; i <= 12; i++) {
          expect(BusMapping.nameToBus('Input $i'), i);
        }
      });

      test('returns correct values for all output names', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.nameToBus('Output $i'), 12 + i);
        }
      });

      test('returns correct values for all aux names', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.nameToBus('Aux $i'), 20 + i);
        }
      });
    });

    group('allBusNames', () {
      test('contains 29 entries (0 through 28)', () {
        expect(BusMapping.allBusNames.length, 29);
      });

      test('starts with None', () {
        expect(BusMapping.allBusNames.first, 'None');
      });

      test('contains all input names', () {
        for (var i = 1; i <= 12; i++) {
          expect(BusMapping.allBusNames, contains('Input $i'));
        }
      });

      test('contains all output names', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.allBusNames, contains('Output $i'));
        }
      });

      test('contains all aux names', () {
        for (var i = 1; i <= 8; i++) {
          expect(BusMapping.allBusNames, contains('Aux $i'));
        }
      });
    });

    group('allBusNumbers', () {
      test('contains 29 entries', () {
        expect(BusMapping.allBusNumbers.length, 29);
      });

      test('contains all numbers 0 through 28', () {
        for (var i = 0; i <= 28; i++) {
          expect(BusMapping.allBusNumbers, contains(i));
        }
      });
    });

    group('isValidBusNumber', () {
      test('returns true for 0', () {
        expect(BusMapping.isValidBusNumber(0), isTrue);
      });

      test('returns true for all valid bus numbers 1-28', () {
        for (var i = 1; i <= 28; i++) {
          expect(BusMapping.isValidBusNumber(i), isTrue);
        }
      });

      test('returns false for -1', () {
        expect(BusMapping.isValidBusNumber(-1), isFalse);
      });

      test('returns false for 29', () {
        expect(BusMapping.isValidBusNumber(29), isFalse);
      });

      test('returns false for very large number', () {
        expect(BusMapping.isValidBusNumber(9999), isFalse);
      });
    });

    group('isValidBusName', () {
      test('returns true for valid names', () {
        expect(BusMapping.isValidBusName('None'), isTrue);
        expect(BusMapping.isValidBusName('Input 1'), isTrue);
        expect(BusMapping.isValidBusName('Output 1'), isTrue);
        expect(BusMapping.isValidBusName('Aux 1'), isTrue);
      });

      test('returns true for case-insensitive valid names', () {
        expect(BusMapping.isValidBusName('none'), isTrue);
        expect(BusMapping.isValidBusName('input 1'), isTrue);
        expect(BusMapping.isValidBusName('OUTPUT 1'), isTrue);
      });

      test('returns false for invalid names', () {
        expect(BusMapping.isValidBusName('Unknown'), isFalse);
        expect(BusMapping.isValidBusName(''), isFalse);
        expect(BusMapping.isValidBusName('Input'), isFalse);
        expect(BusMapping.isValidBusName('Bus 1'), isFalse);
      });
    });

    group('formatBus', () {
      test('formats bus 0 as None (0)', () {
        expect(BusMapping.formatBus(0), 'None (0)');
      });

      test('formats valid bus with name and number', () {
        expect(BusMapping.formatBus(1), 'Input 1 (1)');
        expect(BusMapping.formatBus(13), 'Output 1 (13)');
        expect(BusMapping.formatBus(21), 'Aux 1 (21)');
      });

      test('formats invalid bus as Unknown with number', () {
        expect(BusMapping.formatBus(-1), 'Unknown (-1)');
        expect(BusMapping.formatBus(29), 'Unknown (29)');
        expect(BusMapping.formatBus(100), 'Unknown (100)');
      });
    });

    group('parseBus', () {
      test('parses valid int bus numbers', () {
        expect(BusMapping.parseBus(0), 0);
        expect(BusMapping.parseBus(1), 1);
        expect(BusMapping.parseBus(28), 28);
      });

      test('returns null for invalid int bus numbers', () {
        expect(BusMapping.parseBus(-1), isNull);
        expect(BusMapping.parseBus(29), isNull);
        expect(BusMapping.parseBus(100), isNull);
      });

      test('parses numeric string as bus number', () {
        expect(BusMapping.parseBus('0'), 0);
        expect(BusMapping.parseBus('1'), 1);
        expect(BusMapping.parseBus('28'), 28);
      });

      test('returns null for invalid numeric strings', () {
        expect(BusMapping.parseBus('29'), isNull);
        expect(BusMapping.parseBus('-1'), isNull);
        expect(BusMapping.parseBus('100'), isNull);
      });

      test('parses bus name strings', () {
        expect(BusMapping.parseBus('None'), 0);
        expect(BusMapping.parseBus('Input 1'), 1);
        expect(BusMapping.parseBus('Output 1'), 13);
        expect(BusMapping.parseBus('Aux 1'), 21);
      });

      test('parses bus name strings case-insensitively', () {
        expect(BusMapping.parseBus('none'), 0);
        expect(BusMapping.parseBus('input 1'), 1);
        expect(BusMapping.parseBus('OUTPUT 1'), 13);
      });

      test('returns null for invalid string names', () {
        expect(BusMapping.parseBus('Unknown'), isNull);
        expect(BusMapping.parseBus(''), isNull);
        expect(BusMapping.parseBus('Input'), isNull);
      });

      test('returns null for non-int non-string types', () {
        expect(BusMapping.parseBus(1.5), isNull);
        expect(BusMapping.parseBus(true), isNull);
        expect(BusMapping.parseBus(null), isNull);
        expect(BusMapping.parseBus([1]), isNull);
      });

      test('returns null for float-like strings', () {
        expect(BusMapping.parseBus('1.5'), isNull);
        expect(BusMapping.parseBus('0.0'), isNull);
      });
    });

    group('describeRouting', () {
      test('describes valid routing between named buses', () {
        expect(BusMapping.describeRouting(1, 13), 'Input 1 → Output 1');
      });

      test('describes routing with None', () {
        expect(BusMapping.describeRouting(0, 13), 'None → Output 1');
        expect(BusMapping.describeRouting(1, 0), 'Input 1 → None');
      });

      test('describes routing with aux buses', () {
        expect(BusMapping.describeRouting(21, 13), 'Aux 1 → Output 1');
      });

      test('uses Unknown for invalid bus numbers', () {
        expect(BusMapping.describeRouting(-1, 13), 'Unknown → Output 1');
        expect(BusMapping.describeRouting(1, 29), 'Input 1 → Unknown');
        expect(BusMapping.describeRouting(-1, 29), 'Unknown → Unknown');
      });
    });

    group('round-trip consistency', () {
      test('busToName and nameToBus are inverse for all valid buses', () {
        for (var i = 0; i <= 28; i++) {
          final name = BusMapping.busToName(i);
          expect(name, isNotNull, reason: 'Bus $i should have a name');
          expect(BusMapping.nameToBus(name!), i,
              reason: 'nameToBus(busToName($i)) should return $i');
        }
      });

      test('nameToBus and busToName are inverse for all valid names', () {
        for (final name in BusMapping.allBusNames) {
          final bus = BusMapping.nameToBus(name);
          expect(bus, isNotNull, reason: 'Name "$name" should have a bus number');
          expect(BusMapping.busToName(bus!), name,
              reason: 'busToName(nameToBus("$name")) should return "$name"');
        }
      });
    });
  });
}
