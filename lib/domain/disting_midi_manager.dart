import 'dart:async';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/disting_message_scheduler.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';

class DistingMidiManager {
  final DistingMessageScheduler _scheduler;
  final int sysExId;

  DistingMidiManager({
    required MidiCommand midiCommand,
    required MidiDevice device,
    required this.sysExId,
  }) : _scheduler = DistingMessageScheduler(
          midiCommand: midiCommand,
          device: device,
          sysExId: sysExId,
        );

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

  /// Requests the version string
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

  /// Requests the number of algorithms
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

  /// Requests the number of algorithms in the preset
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

  /// Requests algorithm information by index
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

  /// Requests the preset name
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

  /// Requests the number of parameters for an algorithm
  Future<int?> requestNumberOfParameters(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestNumParameters(sysExId, algorithmIndex);
    final key = RequestKey(
      sysExId: sysExId,
      algorithmIndex: algorithmIndex,
      messageType: DistingNTRespMessageType.respNumParameters,
    );
    return await _scheduler.sendRequest<int>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

  /// Requests parameter info for a given parameter
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

  /// Requests the parameter value for a given parameter
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

  Future<Mapping?> requestMappings(
      int algorithmIndex, int parameterNumber) async {
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

  Future<AlgorithmGuid?> requestAlgorithmGuid(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestAlgorithmGuid(sysExId, algorithmIndex);
    final key = RequestKey(
      sysExId: sysExId,
      messageType: DistingNTRespMessageType.respAlgorithmGuid,
      algorithmIndex: algorithmIndex,
    );

    return await _scheduler.sendRequest<AlgorithmGuid>(
      packet,
      key,
      responseExpectation: ResponseExpectation.required,
    );
  }

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

  Future<void> requestWake() {
    final packet = DistingNT.encodeWake(sysExId);
    return _scheduler.sendRequest<void>(
      packet,
      RequestKey(sysExId: sysExId),
      responseExpectation: ResponseExpectation.none,
    );
  }

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

  /// Requests routing information for a given algorithm
// Future<RoutingInfo> requestRoutingInformation(int algorithmIndex) async {
//   final packet = DistingNT.encodeRequestRouting(sysExId, algorithmIndex);
//   final key = RequestKey(
//     sysExId: sysExId,
//     algorithmIndex: algorithmIndex,
//     messageType: DistingNTRespMessageType.respRouting,
//   );
//   return await _sendRequest<RoutingInfo>(packet, key);
// }
}
