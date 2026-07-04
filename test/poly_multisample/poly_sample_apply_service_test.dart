import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/poly_sample_apply_service.dart';

void main() {
  group('PolySampleApplyService', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_sample_apply_service_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('builds target filenames while preserving source prefixes', () {
      final source = File('${tempRoot.path}/SoftPiano_C3_SW48_V1_RR1.wav')
        ..writeAsBytesSync([1, 2, 3]);
      final baseline = [
        PolyMultisampleParser.parseFile(source, basePath: tempRoot.path),
      ];
      final edited = [
        baseline.single.copyWith(
          rootMidi: 62,
          rootName: 'D3',
          switchPoint: 50,
          velocityLayer: 2,
          roundRobin: 1,
        ),
      ];

      final plan = PolySampleApplyService().buildPlan(
        baselineRegions: baseline,
        editedRegions: edited,
        targetFolder: tempRoot.path,
      );

      expect(plan.hasConflicts, isFalse);
      expect(plan.renames, hasLength(1));
      expect(plan.renames.single.fromPath, source.path);
      expect(
        plan.renames.single.toPath.replaceAll('\\', '/'),
        endsWith('/SoftPiano_D3_SW50_V2.wav'),
      );
    });

    test('detects local target conflicts before mutation', () {
      final source = File('${tempRoot.path}/SoftPiano_C3.wav')
        ..writeAsBytesSync([1]);
      final conflict = File('${tempRoot.path}/SoftPiano_D3.wav')
        ..writeAsBytesSync([2]);
      final baseline = [
        PolyMultisampleParser.parseFile(source, basePath: tempRoot.path),
      ];
      final edited = [baseline.single.copyWith(rootMidi: 62, rootName: 'D3')];

      final plan = PolySampleApplyService().buildPlan(
        baselineRegions: baseline,
        editedRegions: edited,
        targetFolder: tempRoot.path,
        existingPaths: {conflict.path},
      );

      expect(plan.conflicts, hasLength(1));
      expect(plan.conflicts.single.path, conflict.path);
      expect(source.existsSync(), isTrue);
      expect(conflict.readAsBytesSync(), [2]);
    });

    test(
      'applies local two-step renames without overwriting swapped targets',
      () async {
        final c3 = File('${tempRoot.path}/SoftPiano_C3.wav')
          ..writeAsBytesSync([3]);
        final d3 = File('${tempRoot.path}/SoftPiano_D3.wav')
          ..writeAsBytesSync([4]);
        final baseline = [
          PolyMultisampleParser.parseFile(c3, basePath: tempRoot.path),
          PolyMultisampleParser.parseFile(d3, basePath: tempRoot.path),
        ];
        final edited = [
          baseline[0].copyWith(rootMidi: 62, rootName: 'D3'),
          baseline[1].copyWith(rootMidi: 60, rootName: 'C3'),
        ];

        final plan = PolySampleApplyService().buildPlan(
          baselineRegions: baseline,
          editedRegions: edited,
          targetFolder: tempRoot.path,
        );

        expect(plan.hasConflicts, isFalse);

        await PolySampleApplyService().applyLocalPlan(plan);

        expect(File('${tempRoot.path}/SoftPiano_C3.wav').readAsBytesSync(), [
          4,
        ]);
        expect(File('${tempRoot.path}/SoftPiano_D3.wav').readAsBytesSync(), [
          3,
        ]);
      },
    );
  });
}
