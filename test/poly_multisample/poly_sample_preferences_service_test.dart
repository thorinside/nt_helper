import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_sample_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PolySamplePreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists typed picker paths', () async {
      final service = await PolySamplePreferencesService.create();

      await service.setLastLocalFolder('/local');
      await service.setLastSourceFolder('/source');
      await service.setLastImportOutputFolder('/import');
      await service.setLastCustomOutputFolder('/custom');
      await service.setLastWavExportFolder('/wav');

      expect(service.lastLocalFolder, '/local');
      expect(service.lastSourceFolder, '/source');
      expect(service.lastImportOutputFolder, '/import');
      expect(service.lastCustomOutputFolder, '/custom');
      expect(service.lastWavExportFolder, '/wav');
    });
  });
}
