import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/disting_message_scheduler.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:flutter/foundation.dart';

/// Abstract interface for Disting MIDI communication.
abstract class IDistingMidiManager {
  void dispose();
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
  Future<Uint8List?> encodeTakeScreenshot();
  Future<void> requestWake();
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value);
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications);
  Future<void> requestRemoveAlgorithm(int algorithmIndex);
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber);
  Future<void> requestSetPresetName(String newName);
  Future<void> requestSavePreset(); // Simplified based on cubit usage
  Future<void> requestMoveAlgorithmUp(int algorithmIndex);
  Future<void> requestMoveAlgorithmDown(int algorithmIndex);
  Future<void> requestNewPreset();
  Future<void> requestLoadPreset(String name, bool append);
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data);
  Future<void> requestSendSlotName(int algorithmIndex, String newName);
  Future<void> requestSetDisplayMode(DisplayMode displayMode);
}

class DistingMidiManager implements IDistingMidiManager {
  // Implement interface
  final DistingMessageScheduler _scheduler;
  final int sysExId;

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
          defaultTimeout:
              Duration(milliseconds: SettingsService().requestTimeout),
          defaultRetryDelay:
              Duration(milliseconds: SettingsService().interMessageDelay),
        );

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
    final packet = DistingNT.encodeSetRealTimeClock(sysExId, unixTimeSeconds);
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
    final packet = DistingNT.encodeRequestVersionString(sysExId);
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
    final packet = DistingNT.encodeRequestNumAlgorithms(sysExId);
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
    final packet = DistingNT.encodeNumAlgorithmsInPreset(sysExId);
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
    final packet =
        DistingNT.encodeRequestAlgorithmInfo(sysExId, algorithmIndex);
    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
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
    final packet = DistingNT.encodeRequestPresetName(sysExId);
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
    final packet =
        DistingNT.encodeRequestNumParameters(sysExId, algorithmIndex);
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
    final packet = DistingNT.encodeRequestParameterInfo(
        sysExId, algorithmIndex, parameterNumber);
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
    final packet = DistingNT.encodeRequestParameterValue(
        sysExId, algorithmIndex, parameterNumber);
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
    final packet = DistingNT.encodeRequestUnitStrings(sysExId);
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
    final packet = DistingNT.encodeRequestEnumStrings(
        sysExId, algorithmIndex, parameterNumber);
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

    final packet = DistingNT.encodeRequestMappings(
        sysExId, algorithmIndex, parameterNumber);
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
    final packet = DistingNT.encodeRequestParameterValueString(
        sysExId, algorithmIndex, parameterNumber);
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
    final packet =
        DistingNT.encodeRequestAlgorithmGuid(sysExId, algorithmIndex);
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
    final packet =
        DistingNT.encodeRequestAllParameterValues(sysExId, algorithmIndex);
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
    final packet = DistingNT.encodeSetParameterValue(
        sysExId, algorithmIndex, parameterNumber, value);
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
  Future<void> requestWake() {
    final packet = DistingNT.encodeWake(sysExId);
    return _scheduler.sendRequest<void>(
      packet,
      RequestKey(sysExId: sysExId),
      responseExpectation: ResponseExpectation.none,
    );
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) {
    final packet =
        DistingNT.encodeAddAlgorithm(sysExId, algorithm.guid, specifications);
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
    final packet = DistingNT.encodeRemoveAlgorithm(sysExId, algorithmIndex);
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
    final packet =
        DistingNT.encodeSetFocus(sysExId, algorithmIndex, parameterNumber);
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
    final packet = DistingNT.encodeSetPresetName(sysExId, newName);
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
  Future<void> requestSavePreset() {
    final packet = DistingNT.encodeSavePreset(sysExId, 2);
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
    final packet = DistingNT.encodeMoveAlgorithm(
        sysExId, algorithmIndex, algorithmIndex - 1);
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
    final packet = DistingNT.encodeMoveAlgorithm(
        sysExId, algorithmIndex, algorithmIndex + 1);
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
    final packet = DistingNT.encodeTakeScreenshot(sysExId);
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respScreenshot,
    );

    return _scheduler.sendRequest<Uint8List>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
      timeout: Duration(milliseconds: 500),
      maxRetries: 5,
      retryDelay: Duration(milliseconds: 50),
    );
  }

  @override
  Future<void> requestNewPreset() {
    final packet = DistingNT.encodeNewPreset(sysExId);
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
    final packet = DistingNT.encodeLoadPreset(sysExId, presetName, append);

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
    final cvPacket = DistingNT.encodeSetCVMapping(
        sysExId, algorithmIndex, parameterNumber, data);
    final midiPacket = DistingNT.encodeSetMIDIMapping(
        sysExId, algorithmIndex, parameterNumber, data);
    final i2cPacket = DistingNT.encodeSetI2CMapping(
        sysExId, algorithmIndex, parameterNumber, data);
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

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestRoutingInformation(sysExId, algorithmIndex);

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
    final packet = DistingNT.encodeSendSlotName(sysExId, algorithmIndex, name);

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
    final packet = DistingNT.encodeSetDisplayMode(sysExId, displayMode);

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
    final packet =
        DistingNT.encodeRequestParameterPages(sysExId, algorithmIndex);

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
}
