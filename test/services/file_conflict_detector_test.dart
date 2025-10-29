import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/package_analysis.dart';
import 'package:nt_helper/models/package_file.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/services/file_conflict_detector.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

// Helper to create a minimal valid package analysis
PackageAnalysis createTestAnalysis({
  String packageName = 'test-package',
  String presetName = 'Test Preset',
  List<PackageFile> files = const [],
}) {
  return PackageAnalysis(
    packageName: packageName,
    presetName: presetName,
    author: 'Test Author',
    version: '1.0.0',
    files: files,
    manifest: const {'version': '1.0.0'},
    isValid: true,
  );
}

// Helper to create a minimal valid synchronized state
DistingStateSynchronized createTestSyncState({
  bool offline = false,
  IDistingMidiManager? disting,
}) {
  return DistingStateSynchronized(
    disting: disting ?? MockDistingMidiManager(),
    distingVersion: 'NT',
    firmwareVersion: FirmwareVersion('1.10'),
    presetName: 'Test',
    algorithms: const [],
    slots: const [],
    unitStrings: const [],
    offline: offline,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDistingCubit mockCubit;
  late MockDistingMidiManager mockDisting;
  late FileConflictDetector detector;

  setUp(() {
    mockCubit = MockDistingCubit();
    mockDisting = MockDistingMidiManager();
    detector = FileConflictDetector(mockCubit);
  });

  group('FileConflictDetector - detectConflicts', () {
    test('returns original analysis when offline', () async {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/test.json',
            targetPath: 'presets/test.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      when(() => mockCubit.state).thenReturn(
        createTestSyncState(offline: true),
      );

      // Act
      final result = await detector.detectConflicts(analysis);

      // Assert
      expect(result.conflictCount, 0);
      expect(result.files.first.hasConflict, false);
    });

    test('returns original analysis when not synchronized', () async {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/test.json',
            targetPath: 'presets/test.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      when(() => mockCubit.state).thenReturn(const DistingStateInitial());

      // Act
      final result = await detector.detectConflicts(analysis);

      // Assert
      expect(result.conflictCount, 0);
      expect(result.files.first.hasConflict, false);
    });

    test('detects conflicts when files exist on SD card', () async {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/existing.json',
            targetPath: 'presets/existing.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/presets/new.json',
            targetPath: 'presets/new.json',
            size: 2048,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      final existingEntry = DirectoryEntry(
        name: 'existing.json',
        attributes: 0,
        date: 0,
        time: 0,
        size: 1024,
      );

      when(() => mockCubit.state).thenReturn(
        createTestSyncState(offline: false, disting: mockDisting),
      );
      when(() => mockCubit.disting()).thenReturn(mockDisting);
      when(() => mockDisting.requestWake()).thenAnswer((_) async {});
      when(() => mockDisting.requestDirectoryListing('/presets')).thenAnswer(
        (_) async => DirectoryListing(entries: [existingEntry]),
      );

      // Act
      final result = await detector.detectConflicts(analysis);

      // Assert
      expect(result.conflictCount, 1);
      expect(result.files[0].hasConflict, true); // existing.json
      expect(result.files[1].hasConflict, false); // new.json
    });

    test('handles directory listing errors gracefully', () async {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/test.json',
            targetPath: 'presets/test.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      when(() => mockCubit.state).thenReturn(
        createTestSyncState(offline: false, disting: mockDisting),
      );
      when(() => mockCubit.disting()).thenReturn(mockDisting);
      when(() => mockDisting.requestWake()).thenAnswer((_) async {});
      when(() => mockDisting.requestDirectoryListing('/presets'))
          .thenThrow(Exception('Directory not found'));

      // Act
      final result = await detector.detectConflicts(analysis);

      // Assert - should return original analysis without conflicts
      expect(result.conflictCount, 0);
      expect(result.files.first.hasConflict, false);
    });

    test('groups files by directory for efficient scanning', () async {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/preset1.json',
            targetPath: 'presets/preset1.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/presets/preset2.json',
            targetPath: 'presets/preset2.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/samples/sample1.wav',
            targetPath: 'samples/sample1.wav',
            size: 4096,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      when(() => mockCubit.state).thenReturn(
        createTestSyncState(offline: false, disting: mockDisting),
      );
      when(() => mockCubit.disting()).thenReturn(mockDisting);
      when(() => mockDisting.requestWake()).thenAnswer((_) async {});
      when(() => mockDisting.requestDirectoryListing(any())).thenAnswer(
        (_) async => DirectoryListing(entries: const []),
      );

      // Act
      final result = await detector.detectConflicts(analysis);

      // Assert - should have called requestDirectoryListing for each directory
      verify(() => mockDisting.requestDirectoryListing('/presets')).called(1);
      verify(() => mockDisting.requestDirectoryListing('/samples')).called(1);
      expect(result.conflictCount, 0);
    });
  });

  group('FileConflictDetector - updateFileAction', () {
    test('updates action for specific file', () {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/file1.json',
            targetPath: 'presets/file1.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/presets/file2.json',
            targetPath: 'presets/file2.json',
            size: 2048,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      // Act
      final result = FileConflictDetector.updateFileAction(
        analysis,
        'presets/file1.json',
        FileAction.skip,
      );

      // Assert
      expect(result.files[0].action, FileAction.skip);
      expect(result.files[1].action, FileAction.install);
    });
  });

  group('FileConflictDetector - setActionForConflicts', () {
    test('sets action for all conflicting files', () {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/conflict.json',
            targetPath: 'presets/conflict.json',
            size: 1024,
            hasConflict: true,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/presets/noconflict.json',
            targetPath: 'presets/noconflict.json',
            size: 2048,
            hasConflict: false,
            action: FileAction.install,
          ),
        ],
      );

      // Act
      final result = FileConflictDetector.setActionForConflicts(
        analysis,
        FileAction.skip,
      );

      // Assert
      expect(result.files[0].action, FileAction.skip);
      expect(result.files[1].action, FileAction.install);
    });
  });

  group('FileConflictDetector - setActionForAllFiles', () {
    test('sets action for all files', () {
      // Arrange
      final analysis = createTestAnalysis(
        files: [
          const PackageFile(
            relativePath: 'root/presets/file1.json',
            targetPath: 'presets/file1.json',
            size: 1024,
            hasConflict: false,
            action: FileAction.install,
          ),
          const PackageFile(
            relativePath: 'root/presets/file2.json',
            targetPath: 'presets/file2.json',
            size: 2048,
            hasConflict: true,
            action: FileAction.skip,
          ),
        ],
      );

      // Act
      final result = FileConflictDetector.setActionForAllFiles(
        analysis,
        FileAction.skip,
      );

      // Assert
      expect(result.files[0].action, FileAction.skip);
      expect(result.files[1].action, FileAction.skip);
    });
  });
}
