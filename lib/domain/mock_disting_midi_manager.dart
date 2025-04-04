import 'dart:async';
import 'dart:typed_data';

import 'package:nt_helper/domain/disting_midi_manager.dart'; // Import to get interface
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

/// Mock implementation for demo mode or testing.
class MockDistingMidiManager implements IDistingMidiManager {
  @override
  void dispose() {
    // No-op
  }

  @override
  Future<Uint8List?> encodeTakeScreenshot() async {
    // Return null or placeholder image data
    return null;
  }

  @override
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex) async {
    if (algorithmIndex == 0) {
      return Algorithm(algorithmIndex: 0, guid: "demo", name: "Demo Algo 1");
    }
    return null;
  }

  @override
  Future<AlgorithmInfo?> requestAlgorithmInfo(int index) async {
    if (index == 0) {
      return AlgorithmInfo(
          algorithmIndex: 0,
          name: 'Demo Algo 1',
          guid: 'demo',
          specifications: [],
          numSpecifications: 0);
    }
    return null;
  }

  @override
  Future<AllParameterValues?> requestAllParameterValues(
      int algorithmIndex) async {
    if (algorithmIndex == 0) {
      return AllParameterValues(algorithmIndex: 0, values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 50)
      ]);
    }
    return null;
  }

  @override
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber) async {
    return ParameterEnumStrings.filler();
  }

  @override
  Future<Mapping?> requestMappings(
      int algorithmIndex, int parameterNumber) async {
    return Mapping.filler();
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) async {
    if (algorithmIndex == 0) {
      return NumParameters(algorithmIndex: 0, numParameters: 1);
    }
    return null;
  }

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    return 1;
  }

  @override
  Future<int?> requestNumberOfAlgorithms() async {
    return 1;
  }

  @override
  Future<ParameterInfo?> requestParameterInfo(
      int algorithmIndex, int parameterNumber) async {
    if (algorithmIndex == 0 && parameterNumber == 0) {
      return ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: 'Demo Param 1',
          min: 0,
          max: 100,
          defaultValue: 50,
          unit: 0, // Assuming unit 0 means no specific unit
          powerOfTen: 0);
    }
    return null;
  }

  @override
  Future<ParameterPages?> requestParameterPages(int algorithmIndex) async {
    if (algorithmIndex == 0) {
      return ParameterPages(algorithmIndex: 0, pages: [
        ParameterPage(name: "Page 1", parameters: [0])
      ]);
    }
    return null;
  }

  @override
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber) async {
    if (algorithmIndex == 0 && parameterNumber == 0) {
      return ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 50);
    }
    return null;
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber) async {
    return ParameterValueString.filler();
  }

  @override
  Future<String?> requestPresetName() async {
    return "Demo Preset";
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) async {
    return RoutingInfo.filler();
  }

  @override
  Future<List<String>?> requestUnitStrings() async {
    return ["%", "Hz", "dB"];
  }

  @override
  Future<String?> requestVersionString() async {
    return "1.17";
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) async {
    // No-op
  }

  @override
  Future<void> requestLoadPreset(String name, bool append) async {
    // No-op
  }

  @override
  Future<void> requestMoveAlgorithmDown(int algorithmIndex) async {
    // No-op
  }

  @override
  Future<void> requestMoveAlgorithmUp(int algorithmIndex) async {
    // No-op
  }

  @override
  Future<void> requestNewPreset() async {
    // No-op
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) async {
    // No-op
  }

  @override
  Future<void> requestSavePreset({int option = 2}) async {
    // No-op
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String newName) async {
    // No-op
  }

  @override
  Future<void> requestSetCVMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {
    // No-op
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) async {
    // No-op
  }

  @override
  Future<void> requestSetI2CMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetMIDIMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetPresetName(String newName) async {
    // No-op
  }

  @override
  Future<void> requestWake() async {
    // No-op
  }

  @override
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value) async {
    // No-op - could potentially store value locally if needed for demo interactions
  }
}
