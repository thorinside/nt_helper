import 'dart:async';
import 'dart:typed_data';

import 'package:nt_helper/db/daos/presets_dao.dart' show FullPresetDetails;

import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

/// Abstract interface for Disting MIDI communication.
/// Allows for mocking or different implementations.
abstract class IDistingMidiManager {
  // Lifecycle
  void dispose();

  // Requests (returning Futures)
  Future<int?> requestNumberOfAlgorithms();
  Future<AlgorithmInfo?> requestAlgorithmInfo(int index);
  Future<int?> requestNumAlgorithmsInPreset();
  Future<String?> requestVersionString();
  Future<String?> requestPresetName();
  Future<List<String>?> requestUnitStrings();
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex);
  Future<ParameterInfo?> requestParameterInfo(
    int algorithmIndex,
    int parameterNumber,
  );
  Future<ParameterPages?> requestParameterPages(int algorithmIndex);
  Future<AllParameterValues?> requestAllParameterValues(int algorithmIndex);
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
    int algorithmIndex,
    int parameterNumber,
  );
  Future<Mapping?> requestMappings(int algorithmIndex, int parameterNumber);
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex);
  Future<ParameterValueString?> requestParameterValueString(
    int algorithmIndex,
    int parameterNumber,
  );
  Future<ParameterValue?> requestParameterValue(
    int algorithmIndex,
    int parameterNumber,
  );
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex);
  Future<OutputModeUsage?> requestOutputModeUsage(
    int algorithmIndex,
    int parameterNumber,
  );
  Future<Uint8List?>
  encodeTakeScreenshot(); // Assuming this belongs here, might need adjustment
  Future<CpuUsage?> requestCpuUsage();

  // Actions (may return Future<void> or void)
  Future<void> requestWake();
  Future<void> setParameterValue(
    int algorithmIndex,
    int parameterNumber,
    int value,
  );
  Future<void> setParameterString(
    int algorithmIndex,
    int parameterNumber,
    String value,
  );
  Future<void> requestAddAlgorithm(
    AlgorithmInfo algorithm,
    List<int> specifications,
  );
  Future<void> requestRemoveAlgorithm(int algorithmIndex);
  Future<void> requestLoadPlugin(String guid);
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber);
  Future<void> requestSetPresetName(String newName);
  Future<void> requestSavePreset({int option});
  Future<void> requestMoveAlgorithmUp(int algorithmIndex);
  Future<void> requestMoveAlgorithmDown(int algorithmIndex);
  Future<void> requestNewPreset();
  Future<void> requestLoadPreset(String name, bool append);
  Future<void> requestSetMapping(
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  );

  /// Sets the performance page assignment for a parameter.
  ///
  /// - [slotIndex]: Slot index (0-31)
  /// - [parameterNumber]: Parameter number within the algorithm
  /// - [perfPageIndex]: Performance page index (0-15, where 0 = not assigned)
  Future<void> setPerformancePageMapping(
    int slotIndex,
    int parameterNumber,
    int perfPageIndex,
  );
  Future<void> requestSendSlotName(int algorithmIndex, String newName);
  Future<void> requestSetDisplayMode(DisplayMode displayMode);
  Future<void> requestSetRealTimeClock(int unixTimeSeconds);
  Future<FullPresetDetails?> requestCurrentPresetDetails();

  // Lua Operations
  Future<String?> executeLua(String luaScript);
  Future<String?> installLua(int algorithmIndex, String luaScript);

  // SD Card Operations
  Future<DirectoryListing?> requestDirectoryListing(String path);
  Future<Uint8List?> requestFileDownload(String path);
  Future<SdCardStatus?> requestFileDelete(String path);
  Future<SdCardStatus?> requestFileRename(String fromPath, String toPath);
  Future<SdCardStatus?> requestFileUpload(String path, Uint8List data);
  Future<SdCardStatus?> requestFileUploadChunk(
    String path,
    Uint8List data,
    int position, {
    bool createAlways = false,
  });
  Future<SdCardStatus?> requestDirectoryCreate(String path);

  // Scala/Tuning Operations
  Future<void> requestSclFile(String filePath);
  Future<void> requestKbmFile(String filePath);

  // Backup Operations
  Future<void> backupPlugins(
    String backupDirectory, {
    void Function(double progress, String currentFile)? onProgress,
  });
}
