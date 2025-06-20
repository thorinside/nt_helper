import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_message_scheduler.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/request_key.dart';
import 'package:nt_helper/domain/sysex/requests/add_algorithm.dart';
import 'package:nt_helper/domain/sysex/requests/execute_lua.dart';
import 'package:nt_helper/domain/sysex/requests/install_lua.dart';
import 'package:nt_helper/domain/sysex/requests/load_preset.dart';
import 'package:nt_helper/domain/sysex/requests/move_algorithm.dart';
import 'package:nt_helper/domain/sysex/requests/new_preset.dart';
import 'package:nt_helper/domain/sysex/requests/remove_algorithm.dart';
import 'package:nt_helper/domain/sysex/requests/request_all_parameter_values.dart';
import 'package:nt_helper/domain/sysex/requests/request_algorithm_guid.dart';
import 'package:nt_helper/domain/sysex/requests/request_algorithm_info.dart';
import 'package:nt_helper/domain/sysex/requests/request_mappings.dart';
import 'package:nt_helper/domain/sysex/requests/request_num_algorithms.dart';
import 'package:nt_helper/domain/sysex/requests/request_num_algorithms_in_preset.dart';
import 'package:nt_helper/domain/sysex/requests/request_number_of_parameters.dart';
import 'package:nt_helper/domain/sysex/requests/request_parameter_enum_strings.dart';
import 'package:nt_helper/domain/sysex/requests/request_parameter_info.dart';
import 'package:nt_helper/domain/sysex/requests/request_parameter_pages.dart';
import 'package:nt_helper/domain/sysex/requests/request_parameter_value.dart';
import 'package:nt_helper/domain/sysex/requests/request_parameter_value_string.dart';
import 'package:nt_helper/domain/sysex/requests/request_preset_name.dart';
import 'package:nt_helper/domain/sysex/requests/request_routing_information.dart';
import 'package:nt_helper/domain/sysex/requests/request_unit_strings.dart';
import 'package:nt_helper/domain/sysex/requests/request_version_string.dart';
import 'package:nt_helper/domain/sysex/requests/save_preset.dart';
import 'package:nt_helper/domain/sysex/requests/set_cv_mapping.dart';
import 'package:nt_helper/domain/sysex/requests/set_display_mode.dart';
import 'package:nt_helper/domain/sysex/requests/set_focus.dart';
import 'package:nt_helper/domain/sysex/requests/set_i2c_mapping.dart';
import 'package:nt_helper/domain/sysex/requests/set_midi_mapping.dart';
import 'package:nt_helper/domain/sysex/requests/set_parameter_value.dart';
import 'package:nt_helper/domain/sysex/requests/set_parameter_string.dart';
import 'package:nt_helper/domain/sysex/requests/set_preset_name.dart';
import 'package:nt_helper/domain/sysex/requests/set_real_time_clock.dart';
import 'package:nt_helper/domain/sysex/requests/set_slot_name.dart';
import 'package:nt_helper/domain/sysex/requests/take_screenshot.dart';
import 'package:nt_helper/domain/sysex/requests/wake.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/domain/sysex/requests/request_directory_listing.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_download.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_delete.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_rename.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_upload.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_upload_chunk.dart';
import 'package:nt_helper/domain/sysex/requests/request_cpu_usage.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

/// Abstract interface for Disting MIDI communication.

class DistingMidiManager implements IDistingMidiManager {
  // Implement interface
  final DistingMessageScheduler _scheduler;
  final int sysExId;
  String? _firmwareVersion;

  DistingMidiManager({
    required MidiCommand midiCommand,
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
    required this.sysExId,
  }) : _scheduler = DistingMessageScheduler(
          midiCommand: midiCommand,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          sysExId: sysExId,
          maxOutstanding: 1,
          messageInterval:
              Duration(milliseconds: SettingsService().interMessageDelay),
          defaultTimeout:
              Duration(milliseconds: SettingsService().requestTimeout),
          defaultRetryDelay:
              Duration(milliseconds: SettingsService().interMessageDelay) * 2,
        );

  Future<void> _checkSdCardSupport() async {
    _firmwareVersion ??= await requestVersionString();
    final version = FirmwareVersion(_firmwareVersion ?? '');
    if (!version.hasSdCardSupport) {
      throw UnsupportedError(
          'SD Card operations require firmware version 1.10 or higher. Found $_firmwareVersion');
    }
  }

  @override
  void dispose() {
    _scheduler.dispose();
  }

  /// Sends a screenshot request and waits for the screenshot response
  // void requestScreenshot() async {
  //   _sendSysExMessage(DistingNT.encodeTakeScreenshot(sysExId));
  // }

  /// Sets the real-time clock
  Future<void> setRealTimeClock(int unixTimeSeconds) async {
    final message = SetRealTimeClockMessage(
        sysExId: sysExId, unixTimeSeconds: unixTimeSeconds);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );
    return await _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<String?> requestVersionString() async {
    final message = RequestVersionStringMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respMessage,
    );

    return await _scheduler.sendRequest<String>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<int?> requestNumberOfAlgorithms() async {
    final message = RequestNumAlgorithmsMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respNumAlgorithms,
    );

    return await _scheduler.sendRequest<int>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    final message = RequestNumAlgorithmsInPresetMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respNumAlgorithmsInPreset,
    );
    return await _scheduler.sendRequest<int>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<AlgorithmInfo?> requestAlgorithmInfo(int algorithmIndex) async {
    final message = RequestAlgorithmInfoMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respAlgorithmInfo,
    );
    return await _scheduler.sendRequest<AlgorithmInfo>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<String?> requestPresetName() async {
    final message = RequestPresetNameMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respPresetName,
    );
    return await _scheduler.sendRequest<String>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) async {
    final message = RequestNumberOfParametersMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
      messageType: DistingNTRespMessageType.respNumParameters,
    );
    return await _scheduler.sendRequest<NumParameters>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<ParameterInfo?> requestParameterInfo(
      int algorithmIndex, int parameterNumber) async {
    final message = RequestParameterInfoMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      messageType: DistingNTRespMessageType.respParameterInfo,
    );
    return await _scheduler.sendRequest<ParameterInfo>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber) async {
    final message = RequestParameterValueMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      messageType: DistingNTRespMessageType.respParameterValue,
    );
    return await _scheduler.sendRequest<ParameterValue>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<List<String>?> requestUnitStrings() async {
    final message = RequestUnitStringsMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respUnitStrings,
    );
    return await _scheduler.sendRequest<List<String>>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber) async {
    final message = RequestParameterEnumStringsMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respEnumStrings,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
    );

    // `optional` => no error if no response arrives within the timeout.
    return await _scheduler.sendRequest<ParameterEnumStrings>(
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<Mapping?> requestMappings(
      int algorithmIndex, int parameterNumber) async {
    // Currently can't do parameter numbers > 128
    if (parameterNumber > 127) return null;

    final message = RequestMappingsMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respMapping,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
    );

    // `optional` => no error if no response arrives within the timeout.
    return await _scheduler.sendRequest<Mapping>(
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber) async {
    final message = RequestParameterValueStringMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respParameterValueString,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
    );

    return await _scheduler.sendRequest<ParameterValueString>(
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex) async {
    final message = RequestAlgorithmGuidMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respAlgorithm,
      algorithmIndex: algorithmIndex,
    );

    return await _scheduler.sendRequest<Algorithm>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<AllParameterValues?> requestAllParameterValues(
      int algorithmIndex) async {
    final message = RequestAllParameterValuesMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respAllParameterValues,
      algorithmIndex: algorithmIndex,
    );

    return await _scheduler.sendRequest<AllParameterValues>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value) {
    final message = SetParameterValueMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> setParameterString(
      int algorithmIndex, int parameterNumber, String value) {
    final message = SetParameterStringMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<String?> executeLua(String luaScript) async {
    final message = ExecuteLuaMessage(sysExId: sysExId, luaScript: luaScript);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respLuaOutput,
    );

    return await _scheduler.sendRequest<String>(
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<String?> installLua(int algorithmIndex, String luaScript) async {
    final message = InstallLuaMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex, luaScript: luaScript);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respLuaOutput,
    );

    return await _scheduler.sendRequest<String>(
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<void> requestWake() {
    final message = WakeMessage(sysExId: sysExId);
    final packet = message.encode();
    return _scheduler.sendRequest<void>(
      packet,
      RequestKey(sysExId: sysExId),
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) {
    final message = AddAlgorithmMessage(
        sysExId: sysExId, guid: algorithm.guid, specifications: specifications);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) {
    final message = RemoveAlgorithmMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) {
    final message = SetFocusMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestSetPresetName(String newName) {
    final message = SetPresetNameMessage(sysExId: sysExId, newName: newName);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestSavePreset({int option = 0}) {
    final message = SavePresetMessage(sysExId: sysExId, option: 2);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestMoveAlgorithmUp(int algorithmIndex) {
    final message = MoveAlgorithmMessage(
        sysExId: sysExId,
        fromIndex: algorithmIndex,
        toIndex: algorithmIndex - 1);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestMoveAlgorithmDown(int algorithmIndex) {
    final message = MoveAlgorithmMessage(
        sysExId: sysExId,
        fromIndex: algorithmIndex,
        toIndex: algorithmIndex + 1);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<Uint8List?> encodeTakeScreenshot() {
    final message = TakeScreenshotMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respScreenshot,
    );

    return _scheduler.sendRequest<Uint8List>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<void> requestNewPreset() {
    final message = NewPresetMessage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
    );

    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestLoadPreset(String presetName, bool append) {
    final message = LoadPresetMessage(
        sysExId: sysExId, presetName: presetName, append: append);
    final packet = message.encode();

    final key = RequestKey(sysExId: sysExId);
    return _scheduler.sendRequest<void>(
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) {
    final cvMessage = SetCVMappingMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        data: data);
    final midiMessage = SetMidiMappingMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        data: data);
    final i2cMessage = SetI2CMappingMessage(
        sysExId: sysExId,
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        data: data);

    final cvPacket = cvMessage.encode();
    final midiPacket = midiMessage.encode();
    final i2cPacket = i2cMessage.encode();

    final key = RequestKey(sysExId: sysExId);

    return Future.wait([
      _scheduler.sendRequest<void>(
        cvPacket,
        key,
        responseExpectation: ResponseExpectation.none,
      ),
      _scheduler.sendRequest<void>(
        midiPacket,
        key,
        responseExpectation: ResponseExpectation.none,
      ),
      _scheduler.sendRequest<void>(
        i2cPacket,
        key,
        responseExpectation: ResponseExpectation.none,
      ),
    ]);
  }

  Future<void> requestSetCVMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) {
    return requestSetMapping(algorithmIndex, parameterNumber, data);
  }

  Future<void> requestSetI2CMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) {
    return requestSetMapping(algorithmIndex, parameterNumber, data);
  }

  Future<void> requestSetMIDIMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) {
    return requestSetMapping(algorithmIndex, parameterNumber, data);
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) async {
    final message = RequestRoutingInformationMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();

    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respRouting,
      algorithmIndex: algorithmIndex,
    );
    return _scheduler.sendRequest<RoutingInfo>(
      maxRetries: 10,
      timeout: Duration(milliseconds: 2500),
      retryDelay: Duration(milliseconds: 250),
      packet,
      key,
      responseExpectation: ResponseExpectation.optional,
    );
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String name) async {
    final message = SetSlotNameMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex, name: name);
    final packet = message.encode();

    final key = RequestKey(
      sysExId: sysExId,
    );
    return _scheduler.sendRequest<void>(
      maxRetries: 1,
      retryDelay: Duration(milliseconds: 250),
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {
    final message =
        SetDisplayModeMessage(sysExId: sysExId, displayMode: displayMode);
    final packet = message.encode();

    final key = RequestKey(
      sysExId: sysExId,
    );
    return _scheduler.sendRequest<void>(
      maxRetries: 1,
      retryDelay: Duration(milliseconds: 250),
      packet,
      key,
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<ParameterPages?> requestParameterPages(int algorithmIndex) {
    final message = RequestParameterPagesMessage(
        sysExId: sysExId, algorithmIndex: algorithmIndex);
    final packet = message.encode();

    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
      messageType: DistingNTRespMessageType.respParameterPages,
    );
    return _scheduler.sendRequest<ParameterPages>(
      maxRetries: 5,
      timeout: Duration(milliseconds: 30000),
      retryDelay: Duration(milliseconds: 250),
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<FullPresetDetails?> requestCurrentPresetDetails() async {
    // 1. Fetch preset name and number of slots
    final presetName = await requestPresetName();
    final numSlots = await requestNumAlgorithmsInPreset();

    if (presetName == null || numSlots == null) {
      debugPrint(
          "[OnlineManager] Failed to get preset name or number of slots.");
      return null; // Cannot proceed
    }

    // 2. Fetch details for each slot
    final List<FullPresetSlot> fullSlots = [];
    for (int i = 0; i < numSlots; i++) {
      try {
        final slotDetails = await _fetchOnlineSlotDetails(i);
        fullSlots.add(slotDetails);
      } catch (e, stackTrace) {
        debugPrint(
            "[OnlineManager] Error fetching details for slot $i: $e\n$stackTrace");
        return null; // If any slot fails, abort
      }
    }

    // 3. Assemble PresetEntry (always use -1 for ID when fetching from device)
    // The DAO will handle potential updates based on name if necessary (though current DAO doesn't)
    final presetEntry = PresetEntry(
      id: -1, // Use -1 to indicate it's fresh from device, not a DB entry ID
      name: presetName,
      lastModified: DateTime.now(), // Use current time for fetched state
    );

    // 4. Return the complete details
    return FullPresetDetails(preset: presetEntry, slots: fullSlots);
  }

  // Helper method to fetch details for a single slot from the device
  Future<FullPresetSlot> _fetchOnlineSlotDetails(int slotIndex) async {
    // Fetch core info (GUID and Name)
    final algoGuidResult = await requestAlgorithmGuid(slotIndex);
    if (algoGuidResult == null) {
      throw Exception("Failed to get algorithm GUID for slot $slotIndex.");
    }
    final guid = algoGuidResult.guid;
    final String customName =
        algoGuidResult.name; // Device returns custom or default

    // Fetch number of parameters for this specific slot instance
    await requestNumberOfParameters(slotIndex);

    // Fetch Parameter Values
    final paramValuesResult = await requestAllParameterValues(slotIndex);
    final parameterValuesMap = <int, int>{};
    if (paramValuesResult != null) {
      for (final pVal in paramValuesResult.values) {
        parameterValuesMap[pVal.parameterNumber] = pVal.value;
      }
    }

    // Fetch Mappings & String Values (based on actual parameters in this slot)
    final Map<int, PackedMappingData> mappingsMap = {};
    final Map<int, String> parameterStringValuesMap = {};
    for (final pNum in parameterValuesMap.keys) {
      // Mapping
      final mappingResult = await requestMappings(slotIndex, pNum);
      if (mappingResult != null && mappingResult.packedMappingData.isMapped()) {
        mappingsMap[pNum] = mappingResult.packedMappingData;
      }
      // String Value
      final stringValueResult =
          await requestParameterValueString(slotIndex, pNum);
      if (stringValueResult?.value != null &&
          stringValueResult!.value.isNotEmpty) {
        parameterStringValuesMap[pNum] = stringValueResult.value;
      }
      // Optional small delay
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Create PresetSlotEntry
    final presetSlotEntry = PresetSlotEntry(
      id: -1, // Placeholder ID
      presetId: -1, // Placeholder ID
      slotIndex: slotIndex,
      algorithmGuid: guid,
      customName: customName, // Name fetched from device
    );

    // We need an AlgorithmEntry. We only have GUID from device.
    // Ideally, we'd fetch this from a local cache (MetadataDao).
    // For now, create a minimal one. This might break saving if metadata isn't cached.
    // TODO: Inject or access MetadataDao to get the full AlgorithmEntry based on GUID.
    final minimalAlgorithmEntry = AlgorithmEntry(
      guid: guid,
      name: "Unknown (Fetch from DB)", // Placeholder name
      numSpecifications: 0,
    );

    return FullPresetSlot(
      slot: presetSlotEntry,
      // Use minimal entry for now. Needs fixing if DAO requires full entry.
      algorithm: minimalAlgorithmEntry,
      parameterValues: parameterValuesMap,
      parameterStringValues: parameterStringValuesMap,
      mappings: mappingsMap,
    );
  }

  @override
  Future<DirectoryListing?> requestDirectoryListing(String path) async {
    await _checkSdCardSupport();
    final message =
        RequestDirectoryListingMessage(sysExId: sysExId, path: path);
    final packet = message.encode();
    return _scheduler.sendRequest<DirectoryListing>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respDirectoryListing,
      ),
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<SdCardStatus?> requestFileDelete(String path) async {
    await _checkSdCardSupport();
    final message = RequestFileDeleteMessage(sysExId: sysExId, path: path);
    final packet = message.encode();
    await _scheduler.sendRequest<SdCardStatus>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respSdStatus,
      ),
      responseExpectation:
          ResponseExpectation.none, // Delete is fire-and-forget
    );
    // Assume success since delete doesn't send a response
    return SdCardStatus(success: true, message: 'Delete command sent');
  }

  @override
  Future<Uint8List?> requestFileDownload(String path) async {
    await _checkSdCardSupport();
    final message = RequestFileDownloadMessage(sysExId: sysExId, path: path);
    final packet = message.encode();
    // TODO: This is a simplified implementation. A real implementation would
    // need to listen for multiple FileChunk responses and assemble them.
    // The scheduler might need a new method for multi-response requests.
    final chunk = await _scheduler.sendRequest<FileChunk>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respFileChunk,
      ),
      responseExpectation: ResponseExpectation.required,
    );
    return chunk?.data;
  }

  @override
  Future<SdCardStatus?> requestFileRename(
      String fromPath, String toPath) async {
    await _checkSdCardSupport();
    final message = RequestFileRenameMessage(
        sysExId: sysExId, oldPath: fromPath, newPath: toPath);
    final packet = message.encode();
    return _scheduler.sendRequest<SdCardStatus>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respSdStatus,
      ),
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<SdCardStatus?> requestFileUpload(String path, Uint8List data) async {
    await _checkSdCardSupport();
    final message = RequestFileUploadMessage(
      sysExId: sysExId,
      path: path,
      fileSize: data.length,
      data: data,
    );
    final packet = message.encode();
    return _scheduler.sendRequest<SdCardStatus>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respSdStatus,
      ),
      responseExpectation: ResponseExpectation.required,
    );
  }

  @override
  Future<SdCardStatus?> requestFileUploadChunk(
      String path, Uint8List data, int position,
      {bool createAlways = false}) async {
    await _checkSdCardSupport();
    final message = RequestFileUploadChunkMessage(
      sysExId: sysExId,
      path: path,
      position: position,
      data: data,
      createAlways: createAlways,
    );
    final packet = message.encode();

    // Based on the Python code, uploads expect a simple ACK response, not SD status
    // For now, let's make it fire-and-forget and assume success
    await _scheduler.sendRequest<SdCardStatus>(
      packet,
      RequestKey(
        sysExId: sysExId,
        messageType: DistingNTRespMessageType.respSdStatus,
      ),
      responseExpectation: ResponseExpectation.none,
      timeout: const Duration(
          seconds: 2), // Shorter timeout since we're not waiting for response
    );

    // Return success status since we can't easily parse the ACK format
    return SdCardStatus(success: true, message: "Upload chunk sent");
  }

  @override
  Future<CpuUsage?> requestCpuUsage() async {
    final message = RequestCpuUsage(sysExId: sysExId);
    final packet = message.encode();
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respCpuUsage,
    );

    return await _scheduler.sendRequest<CpuUsage>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }
}
