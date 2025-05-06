import 'dart:async';
import 'dart:typed_data';

import 'package:nt_helper/db/daos/presets_dao.dart' show FullPresetDetails;
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

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
      int algorithmIndex, int parameterNumber);
  Future<ParameterPages?> requestParameterPages(int algorithmIndex);
  Future<AllParameterValues?> requestAllParameterValues(int algorithmIndex);
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber);
  Future<Mapping?> requestMappings(int algorithmIndex, int parameterNumber);
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex);
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber);
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber);
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex);
  Future<Uint8List?>
      encodeTakeScreenshot(); // Assuming this belongs here, might need adjustment

  // Actions (may return Future<void> or void)
  Future<void> requestWake();
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value);
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications);
  Future<void> requestRemoveAlgorithm(int algorithmIndex);
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber);
  Future<void> requestSetPresetName(String newName);
  Future<void> requestSavePreset({int option});
  Future<void> requestMoveAlgorithmUp(int algorithmIndex);
  Future<void> requestMoveAlgorithmDown(int algorithmIndex);
  Future<void> requestNewPreset();
  Future<void> requestLoadPreset(String name, bool append);
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data);
  Future<void> requestSendSlotName(int algorithmIndex, String newName);
  Future<void> requestSetDisplayMode(DisplayMode displayMode);
  Future<FullPresetDetails?> requestCurrentPresetDetails();
  // Add any other methods from DistingMidiManager used by the Cubit
}
