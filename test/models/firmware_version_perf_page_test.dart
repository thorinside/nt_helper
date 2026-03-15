import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/firmware_version.dart';

void main() {
  group('FirmwareVersion.hasPerfPageItems', () {
    test('returns false for v1.15', () {
      final version = FirmwareVersion('1.15');
      expect(version.hasPerfPageItems, false);
    });

    test('returns true for v1.16', () {
      final version = FirmwareVersion('1.16');
      expect(version.hasPerfPageItems, true);
    });

    test('returns true for v1.17', () {
      final version = FirmwareVersion('1.17');
      expect(version.hasPerfPageItems, true);
    });

    test('returns true for v2.0', () {
      final version = FirmwareVersion('2.0');
      expect(version.hasPerfPageItems, true);
    });

    test('returns false for v1.0', () {
      final version = FirmwareVersion('1.0');
      expect(version.hasPerfPageItems, false);
    });

    test('returns false for v0.99', () {
      final version = FirmwareVersion('0.99');
      expect(version.hasPerfPageItems, false);
    });
  });
}
