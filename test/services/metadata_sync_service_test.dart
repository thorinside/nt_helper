import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/services/metadata_sync_service.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';

class TestMockDistingMidiManager implements IDistingMidiManager {
  final List<AlgorithmInfo> testAlgorithms;

  TestMockDistingMidiManager({required this.testAlgorithms});

  Future<List<AlgorithmInfo>> scanAlgorithms({
    Function(String algorithmName, double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    return testAlgorithms;
  }

  Future<Map<String, dynamic>> scanSpecs({
    required String algorithmGuid,
    Function(String specName, double progress)? onProgress,
  }) async {
    return {};
  }

  Future<List<int>> scanUnits() async {
    return [];
  }

  Stream<Map<String, dynamic>> get slotUpdateStream =>
      Stream<Map<String, dynamic>>.empty();

  Stream<Map<String, dynamic>> get parameterUpdateStream =>
      Stream<Map<String, dynamic>>.empty();

  @override
  Future<void> dispose() async {}

  Future<void> initialize() async {}

  bool get isConnected => true;

  @override
  Future<void> requestWake() async {}

  @override
  Future<void> requestNewPreset() async {}

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    return 0;
  }

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper to get parameters for an algorithm
Future<List<ParameterEntry>> getParametersForAlgorithm(
  AppDatabase db,
  String algorithmGuid,
) async {
  final query = db.select(db.parameters)
    ..where((p) => p.algorithmGuid.equals(algorithmGuid))
    ..orderBy([(p) => OrderingTerm.asc(p.parameterNumber)]);
  return query.get();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetadataSyncService - Parameter Prefix Preservation', () {
    late AppDatabase database;
    late MetadataSyncService service;

    setUpAll(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDownAll(() async {
      await database.close();
    });

    test('should preserve numeric channel prefixes in parameter names', () async {
      // Arrange - create test data with channel prefixes
      final mockManager = TestMockDistingMidiManager(
        testAlgorithms: [
          AlgorithmInfo(
            algorithmIndex: 0,
            guid: 'multi-channel-algo',
            name: 'Multi Channel Test',
            specifications: [],
            isPlugin: false,
            isLoaded: true,
          ),
        ],
      );

      // Create test parameters through the metadata sync service
      // For this we need to mock the parameters returned by the algorithm
      // Since AlgorithmInfo doesn't have a parameters field, we need to check
      // how the service actually gets parameters

      service = MetadataSyncService(mockManager, database);

      // Act - sync algorithms (this will scan the device)
      await service.syncAllAlgorithmMetadata(
        onProgress: (progress, processed, total, mainMessage, subMessage) {},
      );

      // For this test to work properly, we need to understand how the service
      // actually gets parameter information. Let's check the implementation...

      // Note: The test structure shows we need to modify MetadataSyncService
      // to preserve prefixes. The current test setup needs refinement based on
      // actual service implementation.
    });

    test('should handle parameters without prefixes correctly', () async {
      // This test will verify that parameters without channel prefixes
      // remain unchanged during sync

      final mockManager = TestMockDistingMidiManager(
        testAlgorithms: [
          AlgorithmInfo(
            algorithmIndex: 1,
            guid: 'simple-algo',
            name: 'Simple Test',
            specifications: [],
            isPlugin: false,
            isLoaded: true,
          ),
        ],
      );

      service = MetadataSyncService(mockManager, database);

      // The actual test implementation depends on how MetadataSyncService
      // retrieves parameter information from the device
    });

    test('should preserve letter channel prefixes (A:, B:, C:, D:)', () async {
      // This test verifies that letter-based channel prefixes are preserved

      final mockManager = TestMockDistingMidiManager(
        testAlgorithms: [
          AlgorithmInfo(
            algorithmIndex: 2,
            guid: 'letter-channel-algo',
            name: 'Letter Channel Test',
            specifications: [],
            isPlugin: false,
            isLoaded: true,
          ),
        ],
      );

      service = MetadataSyncService(mockManager, database);

      // Test implementation pending understanding of parameter retrieval
    });

    test('should distinguish parameters from different channels', () async {
      // Verifies that parameters with same base name but different channel
      // prefixes are stored as distinct entries

      // Test implementation pending
    });

    test('should create unique parameter entries for each channel', () async {
      // Ensures each channel parameter gets a unique parameterNumber

      // Test implementation pending
    });
  });
}
