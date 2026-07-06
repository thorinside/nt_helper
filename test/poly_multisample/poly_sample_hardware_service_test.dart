import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/poly_sample_hardware_service.dart';

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

DirectoryEntry _file(String name, {int size = 0}) =>
    DirectoryEntry(name: name, attributes: 0x20, date: 0, time: 0, size: size);

DirectoryEntry _dir(String name) =>
    DirectoryEntry(name: '$name/', attributes: 0x10, date: 0, time: 0, size: 0);

void main() {
  late MockDistingMidiManager manager;
  late PolySampleHardwareService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    manager = MockDistingMidiManager();
    service = const PolySampleHardwareService();
  });

  group('PolySampleHardwareService', () {
    test('lists visible folders under /samples', () async {
      when(() => manager.requestDirectoryListing('/samples')).thenAnswer(
        (_) async => DirectoryListing(
          entries: [_dir('Piano'), _file('loose.wav'), _dir('.trash')],
        ),
      );

      final folders = await service.listSampleFolders(manager);

      expect(folders, ['/samples/Piano']);
    });

    test('reads hardware sample folders recursively', () async {
      when(() => manager.requestDirectoryListing('/samples/Piano')).thenAnswer(
        (_) async => DirectoryListing(
          entries: [_file('Piano_C3.wav'), _dir('Layer'), _file('.DS_Store')],
        ),
      );
      when(
        () => manager.requestDirectoryListing('/samples/Piano/Layer'),
      ).thenAnswer(
        (_) async => DirectoryListing(
          entries: [_file('Piano_D3_V2.wav'), _file('._Piano_E3.wav')],
        ),
      );

      final instrument = await service.readSampleFolder(
        manager,
        '/samples/Piano',
      );

      expect(instrument.name, 'Piano');
      expect(instrument.sourcePath, '/samples/Piano');
      expect(instrument.regions.map((region) => region.displayName), [
        'Piano_C3.wav',
        'Layer/Piano_D3_V2.wav',
      ]);
      expect(instrument.regions.first.rootMidi, 48);
      expect(instrument.regions.last.velocityLayer, 2);
    });

    test('downloads sample bytes in 512-byte chunks', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(1200, (index) => index % 256),
      );
      when(() => manager.requestDirectoryListing('/samples/Piano')).thenAnswer(
        (_) async =>
            DirectoryListing(entries: [_file('Piano_C3.wav', size: 1200)]),
      );
      when(
        () => manager.requestFileDownloadChunk(
          '/samples/Piano/Piano_C3.wav',
          any(),
          any(),
        ),
      ).thenAnswer((invocation) async {
        final position = invocation.positionalArguments[1] as int;
        final count = invocation.positionalArguments[2] as int;
        return Uint8List.fromList(bytes.sublist(position, position + count));
      });

      final result = await service.downloadSampleBytes(
        manager,
        '/samples/Piano/Piano_C3.wav',
      );

      expect(result, bytes);
      verifyNever(() => manager.requestFileDownload(any()));
      verify(
        () => manager.requestFileDownloadChunk(
          '/samples/Piano/Piano_C3.wav',
          0,
          512,
        ),
      ).called(1);
      verify(
        () => manager.requestFileDownloadChunk(
          '/samples/Piano/Piano_C3.wav',
          512,
          512,
        ),
      ).called(1);
      verify(
        () => manager.requestFileDownloadChunk(
          '/samples/Piano/Piano_C3.wav',
          1024,
          176,
        ),
      ).called(1);
    });

    test('delegates apply operations through the MIDI manager', () async {
      when(
        () => manager.requestFileDelete('/samples/Piano/Old_C3.wav'),
      ).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'deleted'),
      );
      when(
        () => manager.requestFileRename('/samples/Piano/A_C3.wav', any()),
      ).thenAnswer((_) async => SdCardStatus(success: true, message: 'staged'));
      when(
        () => manager.requestFileRename(any(), '/samples/Piano/A_D3.wav'),
      ).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'renamed'),
      );
      when(
        () => manager.requestFileUploadChunk(
          '/samples/Piano/New_C4.wav',
          any(),
          0,
          createAlways: true,
        ),
      ).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'uploaded'),
      );
      when(() => manager.requestDirectoryCreate(any())).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'created'),
      );

      final plan = PolySampleApplyPlan(
        removals: [
          PolySampleFileRemoval(
            path: '/samples/Piano/Old_C3.wav',
            region: PolyMultisampleParser.parsePath(
              '/samples/Piano/Old_C3.wav',
            ),
          ),
        ],
        renames: [
          PolySampleFileRename(
            fromPath: '/samples/Piano/A_C3.wav',
            toPath: '/samples/Piano/A_D3.wav',
            region: PolyMultisampleParser.parsePath('/samples/Piano/A_C3.wav'),
          ),
        ],
        additions: [
          PolySampleFileAddition(
            sourcePath: 'ignored-local-path',
            toPath: '/samples/Piano/New_C4.wav',
            region: PolyMultisampleParser.parsePath('/tmp/New_C4.wav'),
          ),
        ],
      );

      await service.applyPlan(
        manager,
        plan,
        readAdditionBytes: (addition) async => Uint8List.fromList([1, 2, 3]),
      );

      verify(
        () => manager.requestFileDelete('/samples/Piano/Old_C3.wav'),
      ).called(1);
      verify(
        () => manager.requestFileRename('/samples/Piano/A_C3.wav', any()),
      ).called(1);
      verify(
        () => manager.requestFileRename(any(), '/samples/Piano/A_D3.wav'),
      ).called(1);
      verify(
        () => manager.requestFileUploadChunk(
          '/samples/Piano/New_C4.wav',
          any(
            that: isA<Uint8List>().having((bytes) => bytes.toList(), 'bytes', [
              1,
              2,
              3,
            ]),
          ),
          0,
          createAlways: true,
        ),
      ).called(1);
      verifyNever(() => manager.requestFileUpload(any(), any()));
    });
  });
}
