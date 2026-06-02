import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/database_integrity_service.dart';

void main() {
  group('DatabaseIntegrityService', () {
    test('does not classify missing sqlite native library as corruption', () {
      const error =
          "Invalid argument(s): Couldn't resolve native function "
          "'sqlite3_initialize' in 'package:sqlite3/src/ffi/libsqlite3.g.dart' : "
          "Failed to load dynamic library 'sqlite3.dll': The specified module "
          'could not be found.';

      expect(
        DatabaseIntegrityService.isDatabaseCorruptionError(error),
        isFalse,
      );
    });

    test('classifies integrity check failures as corruption', () {
      expect(
        DatabaseIntegrityService.isDatabaseCorruptionError(
          'database disk image is malformed',
        ),
        isTrue,
      );
    });
  });
}
