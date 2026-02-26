import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';

void main() {
  group('BusSpec', () {
    group('isValid', () {
      test('accepts buses 1-66', () {
        expect(BusSpec.isValid(0), isFalse);
        expect(BusSpec.isValid(1), isTrue);
        expect(BusSpec.isValid(28), isTrue);
        expect(BusSpec.isValid(29), isTrue);
        expect(BusSpec.isValid(30), isTrue);
        expect(BusSpec.isValid(64), isTrue);
        expect(BusSpec.isValid(65), isTrue);
        expect(BusSpec.isValid(66), isTrue);
        expect(BusSpec.isValid(67), isFalse);
        expect(BusSpec.isValid(null), isFalse);
      });
    });

    group('isEs5 (legacy)', () {
      test('matches buses 29-30 only', () {
        expect(BusSpec.isEs5(28), isFalse);
        expect(BusSpec.isEs5(29), isTrue);
        expect(BusSpec.isEs5(30), isTrue);
        expect(BusSpec.isEs5(31), isFalse);
        expect(BusSpec.isEs5(65), isFalse);
        expect(BusSpec.isEs5(66), isFalse);
      });
    });

    group('isEs5Extended', () {
      test('matches buses 65-66 only', () {
        expect(BusSpec.isEs5Extended(29), isFalse);
        expect(BusSpec.isEs5Extended(30), isFalse);
        expect(BusSpec.isEs5Extended(64), isFalse);
        expect(BusSpec.isEs5Extended(65), isTrue);
        expect(BusSpec.isEs5Extended(66), isTrue);
      });
    });

    group('isEs5ForFirmware', () {
      test('old firmware: ES-5 at 29-30', () {
        expect(
          BusSpec.isEs5ForFirmware(29, hasExtendedAuxBuses: false),
          isTrue,
        );
        expect(
          BusSpec.isEs5ForFirmware(30, hasExtendedAuxBuses: false),
          isTrue,
        );
        expect(
          BusSpec.isEs5ForFirmware(65, hasExtendedAuxBuses: false),
          isFalse,
        );
        expect(
          BusSpec.isEs5ForFirmware(66, hasExtendedAuxBuses: false),
          isFalse,
        );
      });

      test('firmware 1.15+: ES-5 at 65-66', () {
        expect(
          BusSpec.isEs5ForFirmware(29, hasExtendedAuxBuses: true),
          isFalse,
        );
        expect(
          BusSpec.isEs5ForFirmware(30, hasExtendedAuxBuses: true),
          isFalse,
        );
        expect(
          BusSpec.isEs5ForFirmware(65, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isEs5ForFirmware(66, hasExtendedAuxBuses: true),
          isTrue,
        );
      });
    });

    group('isAuxForFirmware', () {
      test('old firmware: aux is 21-28, excludes 29-30 (ES-5)', () {
        expect(
          BusSpec.isAuxForFirmware(21, hasExtendedAuxBuses: false),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(28, hasExtendedAuxBuses: false),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(29, hasExtendedAuxBuses: false),
          isFalse,
        );
        expect(
          BusSpec.isAuxForFirmware(30, hasExtendedAuxBuses: false),
          isFalse,
        );
      });

      test('firmware 1.15+: aux is 21-64, includes 29-30', () {
        expect(
          BusSpec.isAuxForFirmware(21, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(28, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(29, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(30, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(64, hasExtendedAuxBuses: true),
          isTrue,
        );
        expect(
          BusSpec.isAuxForFirmware(65, hasExtendedAuxBuses: true),
          isFalse,
        );
        expect(
          BusSpec.isAuxForFirmware(66, hasExtendedAuxBuses: true),
          isFalse,
        );
      });
    });

    group('toLocalNumberForFirmware', () {
      test('old firmware: bus 29 is ES-5 L (local 1)', () {
        expect(
          BusSpec.toLocalNumberForFirmware(29, hasExtendedAuxBuses: false),
          1,
        );
        expect(
          BusSpec.toLocalNumberForFirmware(30, hasExtendedAuxBuses: false),
          2,
        );
      });

      test('firmware 1.15+: bus 29 is Aux 9, bus 65 is ES-5 L', () {
        expect(
          BusSpec.toLocalNumberForFirmware(29, hasExtendedAuxBuses: true),
          9,
        );
        expect(
          BusSpec.toLocalNumberForFirmware(30, hasExtendedAuxBuses: true),
          10,
        );
        expect(
          BusSpec.toLocalNumberForFirmware(65, hasExtendedAuxBuses: true),
          1,
        );
        expect(
          BusSpec.toLocalNumberForFirmware(66, hasExtendedAuxBuses: true),
          2,
        );
      });

      test('physical buses are unchanged by firmware', () {
        expect(
          BusSpec.toLocalNumberForFirmware(1, hasExtendedAuxBuses: false),
          1,
        );
        expect(
          BusSpec.toLocalNumberForFirmware(13, hasExtendedAuxBuses: true),
          1,
        );
      });
    });
  });
}
