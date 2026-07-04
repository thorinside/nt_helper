import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_loose_wav_import_cubit.dart';

void main() {
  group('PolyLooseWavImportCubit', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_loose_wav_import_cubit_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('owns file selection and mapping options before staging', () async {
      final c = File('${tempRoot.path}/Loose_C3.wav')..writeAsBytesSync([0]);
      final d = File('${tempRoot.path}/Loose_D3.wav')..writeAsBytesSync([0]);
      final cubit = PolyLooseWavImportCubit();
      addTearDown(cubit.close);

      await cubit.setFiles([c.path, d.path]);
      expect(cubit.state.selectedPaths, {c.path, d.path});
      expect(cubit.state.canContinue, isTrue);

      cubit.clearSelection();
      expect(cubit.state.canContinue, isFalse);

      cubit.selectAll();
      cubit.setMappingOptions(
        const PolyLooseWavMappingOptions(
          mode: PolyLooseWavMappingMode.velocityLayers,
          startMidi: 60,
        ),
      );
      await cubit.continueImport();

      expect(cubit.state.status, PolyLooseWavImportStatus.completed);
      expect(
        cubit.state.stagedImport!.regions.map((region) => region.velocityLayer),
        [1, 2],
      );
    });
  });
}
